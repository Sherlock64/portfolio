---
name: write-blog-post
description: Turn rough notes, a brain dump, a voice-memo transcript, or a half-formed idea into a finished blog post in blog/ for this portfolio site. Interviews the user to fill the gaps, then writes, checks, and previews the post. Use when the user says "write a blog post", "turn this into a post", "blog about ...", "draft a post", or pastes messy thoughts they want published.
---

# Write a blog post from rough thoughts

The user (Patrick, a platform engineer specializing in automation) gives you
messy, incomplete thoughts. Your job is to turn them into a clear, well-shaped
post without making him think about structure or formatting. You ask about the
substance. Structure, headings, front matter, tags, and site conventions are
yours to handle.

Paths are relative to the repo root. Posts are Markdown files in `blog/`. The
file name becomes the URL: `blog/terraform-drift.md` → `/blog/terraform-drift/`.

## 1. Read the notes and the site

Read what the user gave you, and also:

```bash
grep -h '^tags:' blog/*.md | sort | uniq -c   # tags already in use; reuse them
ls blog/                                      # existing posts (avoid duplicate slugs)
```

Skim one existing post for voice. From the notes, privately draft a brief:

- **Thesis**: the one thing a reader should take away (a guess is fine for now)
- **Reader**: who this is for, and what they already know
- **Material**: the concrete stories, numbers, tools, commands, and mistakes in the notes
- **Gaps**: what's missing, vague, or contradictory

## 2. Interview: ask about substance, never about formatting

Use `AskUserQuestion`. Rules:

- **Only ask what you can't infer.** At most 4 questions per round and 2 rounds.
  A one-line idea can get a third round.
- **Make every question one click.** Each option is a concrete guess built from
  the user's own notes, with your best guess first, marked "(Recommended)". The
  automatic "Other" option covers anything else.
- **Ask in this priority order:**
  1. **The takeaway.** Offer 2–3 one-sentence theses you can see in the notes.
  2. **The reader.** For example: engineers new to the tool, experienced
     platform or DevOps folks, or hiring managers and non-specialists. This
     sets how much jargon to use and how much to explain.
  3. **The proof.** The specific story, result, or example that backs the
     thesis: what happened, which tools, before/after numbers. If the notes
     have none, ask for one. A post with no concrete example is the main thing
     to avoid.
  4. **Boundaries.** Anything to leave out, such as employer names, internal
     systems, or confidential numbers. Ask this whenever the notes mention work.
  5. **Size.** A quick tip (~400 words), a standard post (~800–1200), or a deep
     dive with full code. Skip this if it's obvious.
- **Never ask** about headings, tags, title wording, SEO, or Markdown. You
  decide those.
- **Know when to stop.** Stop once you can state the thesis in one sentence and
  have at least one concrete example. If an answer opens an important new gap,
  ask about it in round 2.

## 3. Confirm the outline (one question)

Ask one `AskUserQuestion` whose first option, "Write it (Recommended)", has a
`preview` showing:

```
Title:   <title>
Summary: <one-sentence summary>

## <Section 1>: <what it covers, one line>
## <Section 2>: ...
## <Wrap-up heading>: ...
```

Make the other option "Change the angle". If they pick it or answer with
"Other", adjust and ask once more. Don't loop more than twice.

## 4. Write `blog/<slug>.md`

**Slug:** 2–5 lowercase, hyphenated words taken from the title, with no date
prefix. Never overwrite an existing file. The slug is the permanent URL, so
choose it carefully.

**Front matter.** Always use this exact shape. Double-quote every text value:

```yaml
---
title: "Specific title in sentence case, under 60 chars"
date: YYYY-MM-DD          # today
tags: [existing-tag, another]   # 2-4, lowercase, reuse existing tags where they fit
summary: "One sentence, under 160 chars, saying what the reader gets."
---
```

**Body shape:**

- **No `# ` heading.** The page already shows the title as the H1.
- **Open with the point.** One or two short paragraphs: the problem and the
  takeaway. No "In this post I will…".
- **2–5 `## ` sections** with headings that say what the section is about.
  They become the "On this page" sidebar. Use `### ` sparingly.
- **Concrete beats abstract.** Commands go in fenced code blocks with a
  language (` ```bash `, ` ```yaml `, ` ```hcl `, ` ```python `) and should be
  ready to copy. Mark placeholders clearly, like `<your-bucket>`.
- **Steps go in numbered lists.** Keep paragraphs to 4 sentences or fewer.
- **At most 1–2 callout boxes**, for real warnings or tips:
  ```markdown
  > Watch out
  >
  > Explanation here.
  {: .admonition .warning}
  ```
  The styles are `note`, `tip`, `info`, `warning`, and `danger`.
- **End with a short `## ` wrap-up**: the lesson or what to do next. No "thanks
  for reading" and no generic call to action.

**Voice:** first person, plain, and practical, like one engineer explaining to
another. Keep the user's own good phrasings from the notes. Avoid hype and
filler: "game-changer", "delve", "leverage", "seamless", "in today's fast-paced
world", "unlock", "robust" (unless literal).

**Truth:** never invent experiences, employers, numbers, results, quotes, or
tool behavior. If something important is missing, you should have asked; if it
was minor, leave it out. Link only to URLs the user gave or to official
documentation.

**Template syntax:** any line containing `{{` or `{%` (GitHub Actions
`${{ secrets.X }}`, Helm, Jinja, Go templates) must sit inside a
`{% raw %}` … `{% endraw %}` block, or it silently disappears. Put the raw tags
on their own lines around the whole code fence.

## 5. Check it

```bash
.claude/skills/write-blog-post/check-post.sh blog/<slug>.md
```

It lints the front matter (with the same YAML parser Jekyll uses), headings, and
template syntax. Then it builds the site into `.jekyll-check/` and confirms the
post has its own page, appears on `/blog/`, and is in the feed and in search.
Fix every `FAIL` line and rerun until you see `PASS`. Fix `WARN` lines unless
they're intentional.

## 6. Preview it

```bash
.claude/skills/run-portfolio/site.sh serve
.claude/skills/run-portfolio/site.sh shot blog/<slug>/
```

Read the screenshot (`/tmp/portfolio-shots/blog_<slug>.png`) and look at it.
Fix anything that looks wrong: overflowing code, a wall of text, a missing
section. Send the screenshot to the user with `SendUserFile` and give them
`http://localhost:4000/blog/<slug>/`.

## 7. Hand off

Tell the user the title, the URL path, and the word count. Then ask whether to
commit and push. **Never commit or push without a yes.** On a yes:

```bash
git add blog/<slug>.md
git commit -m "Add post: <title>"
git push origin main
```

The GitHub Actions workflow deploys in about a minute, to
`https://sherlock64.github.io/portfolio/blog/<slug>/`. For revisions, edit the
file, rerun step 5, and reshoot.

## Gotchas (all verified on this site)

- **`{{ … }}` and `{% … %}` vanish silently.** `${{ secrets.GITHUB_TOKEN }}`
  renders as just `$`, and the build still succeeds. Wrap such blocks in
  `{% raw %}`. `check-post.sh` flags these.
- **An unquoted colon breaks all the front matter.** `title: Terraform: lessons`
  is invalid YAML. Jekyll only warns, then builds the post with no front
  matter, so the title, date, and summary all fall back to guesses. Always
  quote text values.
- **A `# ` heading in the body produces two H1s.** The layout already renders
  the title.
- **Future dates publish immediately.** Posts here are pages, not Jekyll
  "posts", so a future `date` puts the post at the top of the list right away.
  Use today's date.
- **Without a `date`,** the date of the commit that added the file is used, or
  the file's modification time while it's uncommitted. Always set it.
- **Renaming a published file changes its URL** and breaks existing links.
