#!/usr/bin/env bash
# Check a blog post before publishing. Lints the source for the mistakes that
# break silently, builds the site, and confirms the post shows up on its own
# page, the blog index, the RSS feed, and site search.
#
#   .claude/skills/write-blog-post/check-post.sh blog/my-post.md
#
# Exit 0 = publishable (warnings are advice). Exit 1 = something is broken.
set -uo pipefail

ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
SITE="$ROOT/.claude/skills/run-portfolio/site.sh"
OUT=.jekyll-check
file=${1:?usage: check-post.sh blog/<file>.md}
cd "$ROOT"
[ -f "$file" ] || { echo "FAIL no such file: $file"; exit 1; }
case "$file" in blog/*.md|blog/*.markdown) ;; *) echo "FAIL posts must live in blog/ and end in .md: $file"; exit 1;; esac

errors=0

# 1. Lint with Ruby's YAML parser (the same one Jekyll uses).
lint=$(cat <<'RUBY'
require "yaml"; require "date"
path = ARGV[0]; src = File.read(path)
out = ->(lvl, msg) { puts "#{lvl} #{msg}" }
m = src.match(/\A---\s*\n(.*?)\n---\s*\n/m)
body = m ? m.post_match : src
body_line0 = m ? m[0].count("\n") : 0
if m.nil?
  out.("WARN", "no front matter: title, date, and summary will be guessed")
  fm = {}
else
  begin
    fm = YAML.safe_load(m[1], permitted_classes: [Date, Time]) || {}
  rescue Psych::Exception => e
    msg = e.message.sub(/^\(<unknown>\): /, "").sub(/at line (\d+)/) { "at line #{$1.to_i + 1}" }
    out.("FAIL", "front matter is not valid YAML (#{msg}). Quote values that contain a colon, e.g. title: \"Terraform: lessons learned\"")
    fm = nil
  end
end
if fm
  title = fm["title"].to_s.strip
  title.empty? ? out.("WARN", "no title: it will come from the file name") : out.("ok  ", "title: #{title}")
  d = fm["date"]
  if d.nil? then out.("WARN", "no date: the first git commit date will be used")
  elsif d.is_a?(Date) || d.is_a?(Time) then out.("ok  ", "date: #{d}")
  else
    begin Date.parse(d.to_s); out.("ok  ", "date: #{d}")
    rescue ArgumentError then out.("FAIL", "date is not a valid date: #{d.inspect} (use YYYY-MM-DD)") end
  end
  s = fm["summary"].to_s.strip
  if s.empty? then out.("WARN", "no summary: the first paragraph will be used")
  elsif s.length > 160 then out.("WARN", "summary is #{s.length} chars; keep it under 160 so it isn't cut off in search results")
  else out.("ok  ", "summary: #{s.length} chars") end
  tags = fm["tags"]
  if tags.nil? || Array(tags).empty? then out.("WARN", "no tags")
  elsif !tags.is_a?(Array) && !tags.to_s.include?(",") && tags.to_s.include?(" ") then out.("WARN", "tags is one string with spaces; use a list: tags: [a, b]")
  else out.("ok  ", "tags: #{Array(tags).join(", ")}") end
end

fence = nil; raw = false; h2 = 0; bare_fences = 0
body.each_line.with_index(body_line0 + 1) do |line, n|
  raw = true if line =~ /\{%-?\s*raw\s*-?%\}/
  if line =~ /\{%-?\s*endraw\s*-?%\}/ then raw = false; next end
  if (f = line[/^\s*(```+|~~~+)/, 1])
    if fence.nil?
      fence = f
      bare_fences += 1 if line.strip == f
    elsif line.strip.start_with?(fence) then fence = nil end
  end
  if !raw && line =~ /\{\{|\{%/
    out.("FAIL", "line #{n}: '{{' or '{%' is treated as a template tag and will vanish from the page. Wrap that block in {% raw %} ... {% endraw %}")
  end
  next if fence
  out.("FAIL", "line #{n}: '# ' heading in the body. The page already shows the title as the H1; use '## ' for sections") if line =~ /^# \S/
  h2 += 1 if line =~ /^## \S/
end
out.("WARN", "#{bare_fences} code block(s) have no language, so they won't be highlighted (```bash, ```yaml, ...)") if bare_fences > 0
words = body.gsub(/```.*?```/m, "").split.size
out.("ok  ", "#{words} words, #{h2} section heading(s)")
out.("WARN", "no '## ' section headings, so the 'On this page' sidebar will be empty") if h2.zero? && words > 400
RUBY
)
echo "== lint $file"
lint_out=$(podman run --rm -v "$ROOT":/site:Z -w /site docker.io/library/ruby:3.3 ruby -e "$lint" "$file" 2>&1)
echo "$lint_out"
grep -q '^FAIL' <<<"$lint_out" && errors=1

# 2. Build into a scratch directory (doesn't disturb a running preview).
echo "== build"
build_out=$(FETCH=0 DEST="$OUT" "$SITE" build 2>&1)
status=$?
build_out=$(sed 's/\x1b\[[0-9;]*m//g' <<<"$build_out")
problems=$(grep -E "Exception|Error|Liquid Warning" <<<"$build_out" | sed 's/^ *//')
mine=$(grep -F "/site/$file" <<<"$problems")
others=$(grep -vF "/site/$file" <<<"$problems")
[ -n "$mine" ] && { sed 's/^/FAIL /' <<<"$mine"; errors=1; }
[ -n "$others" ] && sed 's/^/WARN another file: /' <<<"$others" | head -5
if [ $status -ne 0 ]; then
  echo "FAIL build exited with $status:"; tail -15 <<<"$build_out"; errors=1
elif [ -z "$mine" ]; then
  echo "ok   site built"
fi

# 3. Confirm the post shows up everywhere it should.
slug=$(basename "$file"); slug=${slug%.*}; slug=$(sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2}-//' <<<"$slug")
url="/blog/$slug/"
page="$OUT/blog/$slug/index.html"
echo "== output $url"
if [ -f "$page" ]; then
  echo "ok   page: $page"
  h1=$(grep -o '<h1' "$page" | wc -l)
  [ "$h1" -eq 1 ] && echo "ok   one H1" || { echo "FAIL page has $h1 H1 headings"; errors=1; }
  toc=$(grep -o 'class="md-toc__link"' "$page" | wc -l)
  echo "ok   'On this page' entries: $toc"
else
  echo "FAIL page was not generated: $page"; errors=1
fi
grep -q "href=\"$url\"" "$OUT/blog/index.html" 2>/dev/null && echo "ok   listed on /blog/" || { echo "FAIL not listed on /blog/"; errors=1; }
grep -q "$url" "$OUT/feed.xml" 2>/dev/null && echo "ok   in feed.xml" || echo "WARN not in feed.xml (only the newest 20 posts are)"
if python3 -c "import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if any(x['url']==sys.argv[2] for x in d) else 1)" "$OUT/search.json" "$url" 2>/dev/null; then
  echo "ok   in search"
else
  echo "FAIL missing from search.json (or search.json is invalid JSON)"; errors=1
fi

echo
if [ $errors -eq 0 ]; then echo "PASS $file is ready to publish"; else echo "BROKEN fix the FAIL lines above"; exit 1; fi
