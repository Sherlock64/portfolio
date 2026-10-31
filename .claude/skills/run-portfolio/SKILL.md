---
name: run-portfolio
description: Build, run, preview, and screenshot the Jekyll portfolio site locally. Use when asked to start or serve the site, build it, preview a change or a new blog post, take a screenshot of a page, or check that the site still builds.
---

This repo is a Jekyll site deployed to GitHub Pages. Drive it with
`.claude/skills/run-portfolio/site.sh`, which runs Jekyll and headless Chromium
in podman containers, so this machine needs no Ruby or Chrome. Paths are
relative to the repo root.

## Prerequisites

`podman` and `git`. That's all; containers provide Ruby 3.3 and Chromium.

## Run (agent path)

```bash
.claude/skills/run-portfolio/site.sh serve                           # -> "ready: http://localhost:4000/"
.claude/skills/run-portfolio/site.sh shot /                          # -> /tmp/portfolio-shots/home.png
.claude/skills/run-portfolio/site.sh shot blog/hello-world/          # -> /tmp/portfolio-shots/blog_hello-world.png
SIZE=390,844 .claude/skills/run-portfolio/site.sh shot blog/hello-world/ post-mobile.png
.claude/skills/run-portfolio/site.sh stop
```

Open the screenshot with the Read tool and look at it. For clicking and typing
(search, theme toggle, mobile menu), open `http://localhost:4000/` in the
built-in browser pane while `serve` is running.

| command | what it does |
|---|---|
| `serve` | `jekyll serve` in container `portfolio-preview` on `$PORT` (4000). Waits until ready. Rebuilds automatically when files change, except `_config.yml` (run `stop` then `serve`). |
| `shot PATH [OUT]` | Full-window PNG of `http://localhost:$PORT/PATH` into `$SHOTS` (`/tmp/portfolio-shots`). `SIZE=w,h` sets the window size. Needs `serve` running. |
| `build` | One-off production build into `$DEST` (`_site`). Exit code is Jekyll's. |
| `status` / `logs [N]` | Is the preview up? / last N log lines (Jekyll warnings show here). |
| `stop` | Remove the preview container. |

`FETCH=0` skips the GitHub API call that fills in project cards (faster, works
offline; cards then show only what's in `_data/projects.yml`).

## Run (human path)

Same `serve` command, then open http://localhost:4000 in any browser.

## Test

No unit tests. "It builds and the page looks right" is the test:

```bash
FETCH=0 .claude/skills/run-portfolio/site.sh build
```

To check a single blog post, use `.claude/skills/write-blog-post/check-post.sh blog/<file>.md`.

## Gotchas

- **The first run is slow.** `bundle install` takes about a minute, then the
  `portfolio-gems` volume caches gems and `serve` is ready in about 2s. The
  first `shot` builds the `localhost/portfolio-chromium` image (about 50s).
- **Screenshots use a fallback font, not Roboto.** The site loads Google Fonts
  with `display=optional`, and headless Chromium renders before the font
  arrives. That's expected, not a bug.
- **Screenshots are always dark mode.** Dark is the site default, and the light
  theme is only reachable through the toggle (stored in `localStorage`), which
  `shot` can't click. Use the browser pane to see light mode.
- **Jekyll problems don't fail the build.** A bad YAML front matter or an
  undefined `{{ variable }}` only logs a yellow warning, or renders as nothing.
  Check `logs`, or run `check-post.sh` for posts.

## Troubleshooting

- **`serve FAILED (container exited)` with exit code 137 and empty logs**: the
  container was killed from outside. This happened when other podman containers
  on the host restarted at the same moment. Run `serve` again.
- **`preview not running; run: ... serve`** from `shot`: start `serve` first.
  `shot` reaches the site over `--network host`.
