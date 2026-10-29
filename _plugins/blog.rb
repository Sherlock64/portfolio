# frozen_string_literal: true

# Turns every Markdown file in blog/ into a post, without requiring Jekyll's
# YYYY-MM-DD-title.md filename convention or any front matter.
#
#   title   -> front matter, else derived from the filename
#   date    -> front matter, else the git commit that added the file,
#              else the file's modification time
#   tags    -> front matter (list or comma-separated string)
#   summary -> front matter, else the first paragraph of the post
#
# Posts are exposed to templates as `site.blog_posts`, newest first.

require "erb"
require "open3"
require "time"

module Portfolio
  module Blog
    DIR = "blog"
    MARKDOWN_EXT = %w(.md .markdown).freeze
    DATE_PREFIX = /\A\d{4}-\d{2}-\d{2}-/.freeze
    SUMMARY_LENGTH = 200

    module_function

    def post_path?(relative_path)
      path = relative_path.sub(%r!\A/!, "")
      path.start_with?("#{DIR}/") &&
        MARKDOWN_EXT.include?(File.extname(path).downcase) &&
        File.basename(path, ".*") != "index"
    end

    def titleize(slug)
      slug.tr("-_", "  ").split.map { |w| w[0].upcase + w[1..] }.join(" ")
    end

    def normalize_date(value, path)
      case value
      when nil, "" then nil
      when Time then value
      when Date then value.to_time
      else Jekyll::Utils.parse_date(value.to_s, "Invalid date in #{path}")
      end
    rescue Jekyll::Errors::InvalidDateError => e
      Jekyll.logger.warn "Blog:", "#{e.message}; falling back to git/file date."
      nil
    end

    # Date of the commit that first added the file (so edits don't move it).
    def git_date(source, relative_path)
      out, status = Open3.capture2(
        "git", "log", "--follow", "--format=%aI", "--", relative_path,
        :chdir => source, :err => File::NULL
      )
      first = out.lines.last.to_s.strip
      status.success? && !first.empty? ? Time.parse(first) : nil
    rescue StandardError
      nil
    end

    def normalize_tags(value)
      list = value.is_a?(String) ? value.split(",") : Array(value)
      list.map { |t| t.to_s.strip }.reject(&:empty?)
    end

    # First prose paragraph, with Markdown syntax stripped.
    def summarize(markdown)
      text = markdown.to_s.gsub(%r!^(```|~~~).*?^\1\s*$!m, "")
      para = text.split(%r!\n\s*\n!).map(&:strip).find do |block|
        !block.empty? && !block.match?(/\A([#>|<]|[-*+] |\d+\. |!\[|---|\{%)/)
      end
      return nil unless para

      plain = para
        .gsub(%r!\[([^\]]*)\]\([^)]*\)!, "\\1")
        .gsub(%r![*_`~]!, "")
        .gsub(%r!\s+!, " ")
        .strip
      return plain if plain.length <= SUMMARY_LENGTH

      "#{plain[0, SUMMARY_LENGTH].sub(%r!\s+\S*\z!, "")}…"
    end
  end

  class BlogGenerator < Jekyll::Generator
    safe true
    priority :highest

    def generate(site)
      # Markdown files with no front matter are read as static files.
      # Promote them to pages so they get rendered.
      bare = site.static_files.select { |f| Blog.post_path?(f.relative_path) }
      site.static_files -= bare
      bare.each do |f|
        dir = File.dirname(f.relative_path).sub(%r!\A/!, "")
        site.pages << Jekyll::Page.new(site, site.source, dir, f.name)
      end

      posts = site.pages.select { |p| Blog.post_path?(p.relative_path) }
      posts.each { |page| prepare(site, page) }

      site.config["blog_posts"] = posts.sort_by { |p| p.data["date"] }.reverse

      # Pages such as the feed read rendered post content, so render them last.
      last, rest = site.pages.partition { |p| p.data["render_last"] }
      site.pages.replace(rest + last)
    end

    private

    def prepare(site, page)
      data = page.data
      rel = page.relative_path.sub(%r!\A/!, "")
      slug = File.basename(page.name, ".*").sub(Blog::DATE_PREFIX, "")

      data["layout"] ||= "post"
      data["title"] = Blog.titleize(slug) if data["title"].to_s.strip.empty?
      data["date"] = Blog.normalize_date(data["date"], rel) ||
                     Blog.git_date(site.source, rel) ||
                     File.mtime(File.join(site.source, rel))
      data["tags"] = Blog.normalize_tags(data["tags"])
      data["summary"] = Blog.summarize(page.content) if data["summary"].to_s.strip.empty?
      data["permalink"] ||= "/#{Blog::DIR}/#{slug}/"
      data["is_post"] = true
      page.instance_variable_set(:@url, nil) # recompute with the new permalink
    end
  end

  module Filters
    # Percent-encodes text for a mailto: subject/body (RFC 6068): spaces
    # become %20, line breaks become %0D%0A.
    def mailto_encode(input)
      ERB::Util.url_encode(input.to_s.gsub(%r!\r?\n!, "\r\n"))
    end
  end
end

Liquid::Template.register_filter(Portfolio::Filters)
