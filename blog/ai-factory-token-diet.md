---
title: "How I put my AI software factory on a token diet"
date: 2026-11-16
tags: [automation, ai, claude-code, retro]
summary: "I compared my AI workflow to three good ones, adopted the best parts a phase at a time, and let retros catch my mistakes."
---

My budgets say I should have a healthy chunk of savings. My bank account says otherwise. Either I'm spending in places I don't track, or I'm recording things wrong, and I wanted to find out which. So I started building Zeni, a desktop app that imports my bank data, builds budgets, and uses AI to categorize transactions and suggest where to cut.

I'll write about what Zeni finds later. This post covers what building it did to my AI workflow, which changed a lot. My factory got better through three things: retros (analysis), reading how people better at this do it (research), and building real versions with it (use). When I didn't watch it, it ate through my usage.

I'm on the flat $20 plan, so no bill showed up. What I got was stalled sessions, waiting on the 5-hour limit to reset. That's annoying enough.

![The Zeni Transactions page in its empty state, with a sidebar for Transactions, Nicknames, Accounts and Settings, and buttons to import a file or history.](../../assets/images/zeni_transactions.png)

## Letting it run unwatched

My early factory had one organizer agent that planned the work, several dev agents that built in parallel, and a council of eight reviewers that checked everything. Every round, even for small fixes.

The V3.1 build (CSV import) cost about 19.9M weighted tokens across 44 agents. The council alone took 8.05M. Most of that was repetition: the same test suites run three times, eight reviewers each loading the same context, and a full council re-review after a one-line fix.

## Reading three setups that work

I ran a comparison report of my repo against three well-regarded workflows. Here's what I took from each:

- **Poteto's pstack:** a different playbook for each kind of work, since a question isn't a feature. It also has an architect step that stress-tests risky designs before anyone writes code.
- **Matt Pocock's skills:** small slices that each deliver one testable behavior, red-green TDD, a short glossary, and retros that improve the setup itself.
- **Addy Osmani's agent-skills:** if a script can check a rule, use a script. Run cheap checks while editing, run the big suites once at integration, and keep orchestration shallow.

The report didn't tell me to copy everything. For each idea it listed what to adopt, what it costs, and when to skip it. It also warned that fewer agents doesn't automatically mean fewer tokens, so I should measure.

## One phase at a time

I didn't apply the whole report at once. I held Phase 2 until Phase 1 was built and measured, so I'd know which change caused which result.

**Phase 1** (v3.1.1) was the mechanical work:

1. A `check.sh` script with fast, task, and integration tiers.
2. An evidence file, so reviewers could see the tests had already passed on that exact code.
3. Council members picked by risk instead of all eight every time.
4. Re-reviews limited to the members who had findings.

The next build, V4, cost 5.84M weighted tokens against V3.1's 19.9M. That's about 71% less, with 13 council launches instead of 32.

**Phase 2** (v4.0.1) added trimmed context, behavior slices with tests first, separate playbooks for bugs and questions, a small glossary, and a few ADRs. V5 (nicknames) cost 11.8M with 27 agents, and its council cost 2.77M against 8.05M. V5 was a bigger feature than V4, so it isn't a fair comparison with V4, but it's well under V3.1.

## What the retros caught

Every version ends with a retro, and every retro ends with changes to the rules. These are the mistakes it found:

- **The agent cut items from my report without saying so.** The first plan dropped a few of them, and I had to ask whose decision that was. Now there's a memory rule: ask before deviating from something I adopted.
- **My contracts had errors.** I wrote one message shared by two flows that fail differently. I also swapped two limits (100 and 500) without checking the code. Each mistake cost a council round. The rule now: grep a value before quoting it.
- **One session carried four branches.** The organizer's context grew to around 400k tokens and got re-read on every request. That session was 44% of the whole run. Now it's one branch per session.
- **Tiny edits cost too much.** Spawning or resuming an agent for a one-line change ran 100 to 200k tokens each. Now the organizer makes edits of about five lines or less itself.
- **Fixing every LOW finding was too much.** In the V5.1 cleanup I asked for all of them, then decided it was a lot. That was about 4.2M extra tokens. Now cleanup fixes the MEDIUMs and lists the LOWs for me to pick from.

A few habits came out of this too. A usage gate stops new agents at 80% and notifies me. While a session waits on a reset, a small ping every 55 minutes keeps the cache warm. Each ping costs roughly 25k, and resuming afterward is cheap.

One more from the V5.1.1 retro: I had overridden the AI's recommendations five times in one interview, because it kept leaning on Pocock's structure. It's good input, but I still have to say what my unit of work is.

## The loop

Analyze with retros, research what the best people do, and build with it, one measured change at a time. Human input doesn't stop after the factory is built. If anything, it matters more than ever.
