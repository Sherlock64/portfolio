---
title: "A retro on my phone-run software factory"
date: 2026-11-08
tags: [automation, ai, claude-code, retro]
summary: "What worked, what hurt, and what I'd change after building the Osusume site with AI agents, mostly from my phone."
---

Lately I've been taking care of a family member who's recovering from surgery. That meant my free time basically vanished, but I didn't want to stop building things. So I tried an experiment: could I run a small software factory entirely from my phone?

The project is [Osusume](https://github.com/Sherlock64/osusume), an anime watch tracker, and it doubled as my practice run. This post is a retro, the kind a team writes after a project: the methods I used, the problems I hit, and what I'd do better next time. The "team" was me and a lot of agents.

If you've been stuck at one-prompt-at-a-time and the next step feels intimidating, this one's for you. It's a little scary at first, and it gets easier faster than you'd expect.

## The methods I used

### Remote sessions

Every piece of work started as a new item in the Claude app on my computer, with the remote option switched on. From there I could send instructions from the Claude app on my phone while the work ran on my computer. I just had to tell it what to do.

That's the part that gave me my time back. I could be there for my family and still nudge the project forward between everything else.

### The AI Organizer

Almost every session started the same way: I told the main chat its personality was "AI Organizer," and its only job was to spin up sub-agents for small, focused tasks. It never wrote code itself.

Keeping the tasks small turned out to matter a lot. A sub-agent with one narrow job tends to make fewer mistakes, and it comes back with a short report, which is exactly what you want to read on a phone.

### The adversarial council

I watched a few tutorials on the "adversarial council" method, where a group of agents reviews the work and each one tries to poke holes in it. I used a council for the UI, and it caught things I would have missed on my own.

### The ponytail skill

I also stumbled onto a skill called ponytail, which nudges the agent toward the smallest change that actually solves the problem. That kept the diffs small enough that I could make sense of them from a phone screen.

### Design review on my phone

For the interface, I didn't wait for a finished page. The agents built a prototype, took a snapshot, and sent it to my phone. I'd look at it and say yes, no, or "move that over there."

This was my favorite habit of the whole project. I caught bad ideas before anyone wrote the real code. Here's the Constellations page, one of the main features of the final site:

![The Osusume Constellations page. Three anime series sit on a dark star map, in two named groups, with green lines between them.](../../assets/images/osusume_recommendation_canvas.png)

## What went well

- **Small jobs.** The Organizer and its sub-agents kept every task short and easy to review.
- **Early design review.** Snapshots on my phone saved me from a lot of late changes.
- **Plain writing.** This one surprised me, so it gets its own section.

### Simplified Technical English fixed the walls of text

AI agents write a lot, and their reports were hard to read on a small screen. The fix was ASD-STE100 Simplified Technical English, a writing standard built on short sentences, simple words, and one meaning per word. I told the agents to write that way, and the reports got dramatically shorter and clearer. The project documents improved too.

It's great for documentation and agent reports. I wouldn't write a blog post in it, though, which is why this one sounds like me.

## What went wrong

### I never built a shared Playwright setup

This was my biggest cost by far. The UI council needed to check the interface in a browser, and I never gave it one shared Playwright setup to use. So every council member wrote its own, over and over.

That burned hundreds of thousands of tokens, and most of it was work I didn't need.

> Watch out
>
> When agents don't have a shared tool, each one solves the same problem from scratch, and you pay for every attempt.
{: .admonition .warning}

### TypeScript without a guide gets messy

I used TypeScript but gave the agents no guide for it, so each one made its own choices. The code worked, but the style drifted. I want an actual rule, like keeping types in `*.types.ts` files and logic in separate files.

### My process was too loose

I had a flow, but it wasn't written down in any detail. I also kept forgetting to ask for the documents that make a plan clear. A short requirements doc up front, or a retro as an HTML or PDF page, would have helped me check that the agents were building what I actually wanted.

## What I'd do differently

1. Build one Playwright validation setup first, and tell every council member to use it.
2. Write a TypeScript guide before the first line of code, including the `*.types.ts` rule.
3. Write the process down step by step so every session follows the same flow.
4. Ask for a requirements document at the start of each feature, and read it before the agents build anything.
5. Ask for a retro document at the end of each feature.

## It gets better as you go

Setting up a software factory for the first time is as wonderful as it is painful. I paid for my mistakes in tokens, and I learned from every one of them. Each session went a little smoother than the last.

If you've only worked one prompt at a time, try a small project. Hand the work to agents, keep each job small, and when you're done, have Claude write the retro. It knows how to use itself better than you do, so it can point out where you could have saved time and tokens. Your second run will be better than your first.
