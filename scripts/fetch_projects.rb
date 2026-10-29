#!/usr/bin/env ruby
# frozen_string_literal: true

# Reads _data/projects.yml, fetches each repo's metadata from the GitHub API,
# merges in any manual overrides, and writes _data/projects_generated.json for
# Jekyll to render.
#
# Uses GITHUB_TOKEN when set (the Actions workflow provides it). A repo that
# can't be fetched is logged as a warning and rendered from its overrides only;
# this script never fails the build.
#
# Usage: ruby scripts/fetch_projects.rb

require "date"
require "json"
require "net/http"
require "uri"
require "yaml"

ROOT = File.expand_path("..", __dir__)
INPUT = File.join(ROOT, "_data", "projects.yml")
OUTPUT = File.join(ROOT, "_data", "projects_generated.json")
OVERRIDES = %w(title description image demo_url tags featured).freeze

def warn_msg(message)
  # Shows up as an annotation in the GitHub Actions run summary.
  prefix = ENV["GITHUB_ACTIONS"] ? "::warning::" : "WARNING: "
  warn "#{prefix}#{message}"
end

def fetch_repo(repo)
  uri = URI("https://api.github.com/repos/#{repo}")
  req = Net::HTTP::Get.new(uri)
  req["Accept"] = "application/vnd.github+json"
  req["X-GitHub-Api-Version"] = "2022-11-28"
  req["User-Agent"] = "portfolio-site-build"
  token = ENV["GITHUB_TOKEN"].to_s
  req["Authorization"] = "Bearer #{token}" unless token.empty?

  res = Net::HTTP.start(uri.host, uri.port, :use_ssl => true, :open_timeout => 10, :read_timeout => 20) do |http|
    http.request(req)
  end
  unless res.is_a?(Net::HTTPSuccess)
    warn_msg "Could not fetch #{repo} (HTTP #{res.code}); rendering it from projects.yml only."
    return nil
  end
  JSON.parse(res.body)
rescue StandardError => e
  warn_msg "Could not fetch #{repo} (#{e.class}: #{e.message}); rendering it from projects.yml only."
  nil
end

def load_entries
  raw = File.exist?(INPUT) ? YAML.safe_load(File.read(INPUT), :permitted_classes => [Date]) : nil
  Array(raw).filter_map do |entry|
    entry = { "repo" => entry } if entry.is_a?(String)
    repo = entry.is_a?(Hash) ? entry["repo"].to_s.strip : ""
    if repo.match?(%r{\A[\w.-]+/[\w.-]+\z})
      entry.merge("repo" => repo)
    else
      warn_msg "Skipping projects.yml entry without a valid `repo: owner/name`: #{entry.inspect}"
      nil
    end
  end
rescue Psych::Exception => e
  warn_msg "Could not parse _data/projects.yml: #{e.message}"
  []
end

def build(entry)
  repo = entry["repo"]
  api = fetch_repo(repo) || {}

  project = {
    "repo" => repo,
    "repo_url" => api["html_url"] || "https://github.com/#{repo}",
    "title" => api["name"] || repo.split("/").last,
    "description" => api["description"],
    "language" => api["language"],
    "topics" => api["topics"] || [],
    "tags" => api["topics"] || [],
    "stars" => api["stargazers_count"],
    "homepage" => api["homepage"].to_s.empty? ? nil : api["homepage"],
    "demo_url" => api["homepage"].to_s.empty? ? nil : api["homepage"],
    "updated_at" => api["pushed_at"] || api["updated_at"],
    "featured" => false,
    "fetched" => !api.empty?,
  }

  OVERRIDES.each do |key|
    next unless entry.key?(key) && !entry[key].nil?

    project[key] = key == "tags" ? Array(entry[key]).map(&:to_s) : entry[key]
  end
  project["featured"] = project["featured"] == true
  project
end

projects = load_entries.map { |e| build(e) }
# Featured first; otherwise keep the order from projects.yml.
projects = projects.each_with_index.sort_by { |p, i| [p["featured"] ? 0 : 1, i] }.map(&:first)

File.write(OUTPUT, JSON.pretty_generate(projects) + "\n")
fetched = projects.count { |p| p["fetched"] }
puts "Wrote #{projects.size} project(s) to #{File.basename(OUTPUT)} (#{fetched} fetched from GitHub)."
