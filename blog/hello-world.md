---
title: Hello, World
date: 2026-10-29
tags: [meta, automation]
summary: Why this site exists, and how it builds itself with a little automation.
---

Welcome to my corner of the internet. I'll write here about platform
engineering, automation, and the small tools that remove toil from a team's day.

## How this site works

Every post is a plain Markdown file in the `blog/` folder. Everything at the
top between the `---` lines is optional: leave out the title or date and the
build fills them in for me.

> Tip
>
> Want a callout box like this one? Write a blockquote whose first line is the
> title, then add `{: .admonition .tip}` on the line after it. Other styles:
> `note`, `info`, `warning`, and `danger`.
{: .admonition .tip}

Project cards come from GitHub as well. A small script runs at build time and
pulls fresh metadata for each repo:

```ruby
res = Net::HTTP.get_response(URI("https://api.github.com/repos/#{repo}"))
data = JSON.parse(res.body)
puts "#{data["full_name"]}: #{data["stargazers_count"]} stars"
```

And a scheduled GitHub Actions job rebuilds the site weekly:

```yaml
on:
  push:
    branches: [main]
  schedule:
    - cron: "17 6 * * 1"
```

More soon.
