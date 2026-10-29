# portfolio

Coding portfolio for job hunts: a small, fast personal site built with
[Jekyll](https://jekyllrb.com/) and deployed to GitHub Pages by a GitHub
Actions workflow. You update it by editing a few plain-text files and pushing.
You don't need to touch any HTML.

Live at **https://sherlock64.github.io/portfolio/**

| To change…                        | Edit this file             |
| --------------------------------- | -------------------------- |
| Name, tagline, bio, links         | `_config.yml`              |
| Resume-request email text         | `_config.yml`              |
| Skills                            | `_data/skills.yml`         |
| Projects                          | `_data/projects.yml`       |
| Blog posts                        | add `.md` files to `blog/` |

---

## 1. Publish the site (one-time setup)

1. **Make sure the repo is public.** GitHub Pages on a free account only works
   for public repositories (**Settings → General → Danger Zone → Change
   visibility**).
2. **Turn on Pages with Actions as the source.** Go to
   `https://github.com/Sherlock64/portfolio/settings/pages`. Under **Build and
   deployment → Source**, choose **GitHub Actions**. Don't pick "Deploy from a
   branch". There's no Save button: the choice applies right away.
3. **Check that Actions are allowed.** Under **Settings → Actions → General**,
   make sure **Allow all actions and reusable workflows** is selected. That's
   the default.
4. **Commit and push** everything to `main`:
   ```bash
   git add .
   git commit -m "Add portfolio site"
   git push origin main
   ```
5. **Watch the deploy.** Open the **Actions** tab and click the **Build and
   deploy site** run. It has two jobs, `build` and `deploy`, and takes about a
   minute. If it ran before step 2 and failed, click **Re-run all jobs**.
6. **Open the site.** When the run is green, the URL appears on the run
   summary under the `deploy` job, and in **Settings → Pages**:
   `https://sherlock64.github.io/portfolio/`.
7. Optional: on the repo's main page, click the ⚙️ next to **About** and tick
   **Use your GitHub Pages website** so the link shows on the repo.

If a deploy fails with *"Branch main is not allowed to deploy to
github-pages"*, go to **Settings → Environments → github-pages → Deployment
branches** and add `main`.

From then on the site rebuilds on every push to `main`, and every Monday so
that star counts and descriptions stay fresh. To rebuild right away, go to
**Actions → Build and deploy site → Run workflow**.

> **Want the site at `https://sherlock64.github.io/` instead?** Rename this repo
> to `Sherlock64.github.io` (**Settings → General → Repository name**). The
> workflow sets `baseurl` automatically, so nothing else needs to change. If you
> add a custom domain, update `url:` in `_config.yml`.

## 2. Add a project

Open `_data/projects.yml` and add a line:

```yaml
- repo: Sherlock64/my-new-repo
```

Commit and push. The build reads the repo's description, language, topics,
star count, homepage URL, and last-updated date from GitHub.

To override anything GitHub provides, add any of these fields:

```yaml
- repo: Sherlock64/my-new-repo
  title: My New Project              # default: the repo name
  description: What it does.         # default: the GitHub description
  image: /assets/img/my-project.png  # a screenshot (put the file in assets/img/)
  demo_url: https://example.com      # default: the repo's "homepage" URL
  tags: [terraform, aws]             # default: the repo's topics
  featured: true                     # pin it to the top
```

Your values always win over GitHub's. If a repo can't be fetched (a typo, or a
private repo), the build logs a warning and still shows a card from your
overrides.

> **Tip:** the easiest way to set the description, topics, and homepage is on
> GitHub itself: click the ⚙️ next to **About** on the repo's page.

## 3. Add a blog post

Create a Markdown file in `blog/`, for example `blog/terraform-tips.md`, then
commit and push. That's all. The file name becomes the URL
(`/blog/terraform-tips/`).

The block at the top is optional, but it lets you control the details:

````markdown
---
title: Five Terraform Tips
date: 2026-11-03
tags: [terraform, iac]
summary: One sentence for the blog list and the RSS feed.
---

Your post starts here. Use normal Markdown.

```bash
terraform plan -out tfplan
```
````

Fields you leave out are filled in for you:

- **title**: from the file name (`terraform-tips.md` → "Terraform Tips")
- **date**: the date the file was first committed
- **summary**: the post's first paragraph

Code blocks marked with a language (` ```bash `, ` ```python `, ` ```yaml `…)
get syntax highlighting and a copy button. Each `##` heading shows up in the
"On this page" list on the right.

For a callout box, write a blockquote whose first line is the title, then add a
class line right after it. The styles are `note`, `tip`, `info`, `warning`, and
`danger`:

```markdown
> Heads up
>
> This command deletes the bucket.
{: .admonition .warning}
```

New posts appear on the blog page, in the left-hand menu, on the homepage (the
3 most recent), in site search, and in the feed at `/feed.xml`.

## 4. Edit skills, bio, and resume email

- **Skills:** `_data/skills.yml`. Each group has a `category` and a list of
  `items`. Add, remove, or reorder them freely.
- **Bio, tagline, links:** `_config.yml` → `bio`, `tagline`, `linkedin_url`,
  `github_username`, `email`. Set `linkedin_url` to your profile URL to show a
  LinkedIn link; leave it `""` to hide it.
- **Resume request email:** `_config.yml` → `resume_request`. Change
  `subject`, `body`, or `button_label`. Write the body as plain text with real
  line breaks; the site encodes it for the email link automatically.

The site opens in dark mode. Visitors can switch to light mode with the
sun/moon button in the header, and their choice is remembered. To change the
colors, edit the variables at the top of `assets/css/main.scss`. The first
block is dark mode and the `[data-theme="light"]` block is light mode.

The resume itself isn't hosted on the site. The button opens the visitor's
email client with a message to you, already filled in.

## 5. Run the site locally

**Option A: with Ruby.** You need Ruby 3.1 or newer. On macOS:
`brew install ruby`. On Ubuntu: `sudo apt install ruby-full build-essential`.

```bash
bundle install
```

Optional: fetch live project data. Without it, cards show only what's in
`projects.yml`.

```bash
ruby scripts/fetch_projects.rb
```

```bash
bundle exec jekyll serve --livereload
```

**Option B: with Podman (or Docker), no Ruby install needed.**

```bash
podman run -d --name portfolio-preview -p 4000:4000 -v "$PWD":/site:Z -w /site docker.io/library/ruby:3.3 bash -c 'git config --global --add safe.directory /site && bundle install && ruby scripts/fetch_projects.rb && bundle exec jekyll serve --host 0.0.0.0'
```

Stop it with `podman rm -f portfolio-preview`.

Either way, open <http://localhost:4000>. Most edits show up when you refresh.
Restart the server after editing `_config.yml`.

## How it fits together

```
.github/workflows/pages.yml   build + deploy (push to main, weekly, manual)
scripts/fetch_projects.rb     GitHub API → _data/projects_generated.json
_plugins/blog.rb              blog/*.md → posts (title/date fallbacks), mailto encoding
_data/                        skills.yml, projects.yml (you edit these)
_layouts/, _includes/         page templates
assets/css/main.scss          styles, dark/light themes, code highlighting
assets/js/site.js             theme toggle, mobile menu, search, copy buttons
index.html, blog/index.html   homepage and blog index
search.json                   search index (built automatically)
feed.xml                      Atom feed
```

`_data/projects_generated.json` is created at build time and isn't committed.
