---
title: "Stop hoping your AAP config matches the repo"
date: 2026-10-31
tags: [automation, ansible, gitops]
summary: "Why I'm building an ArgoCD-style drift dashboard for AAP/AWX and infra.aap_configuration, and how it will work."
---

If you manage AAP or AWX with `infra.aap_configuration`, you have a repo that
describes how the platform should look. You also have the platform itself, and
a handful of people with admin rights and a browser. Those two things drift
apart, and nothing tells you when they do.

I've lived with that gap for a long time, so I started building
[ansible-infra-cd](https://github.com/Sherlock64/ansible-infra-cd): an
ArgoCD-style tool where the repo is the source of truth, AAP is the target, and
a dashboard shows you exactly where they disagree. Visibility beats hope.

## Pushing config isn't the same as knowing it's applied

There are plenty of ways to get config from a repo into AAP. A webhook on
merge, a scheduled job template, Event-Driven Ansible reacting to a push. At
work we use AAP and I've built some of those myself. They work. They push.

What they don't do is tell you anything afterwards. Here's the classic case:

1. Someone opens a job template in the UI and "just quickly" changes the
   inventory or adds an extra var to fix something.
2. They don't commit it. Maybe they meant to. They definitely meant to.
3. The repo still says the old thing. AAP says the new thing.
4. Next config run either quietly reverts their fix, or never touches that
   object and the difference lives on forever.

Either way you find out when something breaks, not when it changed. Until then
you're just *hoping* it's all correct and no one has been messing with it.
(There's always someone. So many troublemakers.)

## Borrowing the ArgoCD model

What I like about ArgoCD isn't any single feature. It's the feel: everything is
at your fingertips and reported on. You open it and you know which apps are
synced, which have drifted, and what the diff is. You sync now, or let it sync
on its own.

ansible-infra-cd applies that model to AAP:

- **Desired state:** a config-as-code repo written for `infra.aap_configuration`.
- **Live state:** your AAP or AWX instance, read through its API.
- **The diff:** per object, so you can see *what* someone changed, not just
  that something did.
- **Sync:** push the repo's config to AAP on demand, or schedule it through the
  API.

The dashboard is for more than the person on call. An overview page shows
health, drift counts, sync success rate, and recent activity, which means a
manager can glance at it and see when a team isn't doing what they're supposed
to. A visibly happy system makes a happy engineer, and a visibly unhappy one
makes for a short, specific conversation.

## How drift detection will work

The obvious approach is to run the collection in check mode and read the
result. Unfortunately `infra.aap_configuration` doesn't implement check mode
properly, so I compute drift in Python instead:

1. **Parse the repo.** Read the collection's variable files (the
   `controller_*` and `gateway_*` vars) into a normalized model keyed by
   object kind and name.
2. **Pull live state.** Read-only, paginated GETs against the controller and
   gateway APIs.
3. **Compare.** Classify each object as one of:
   - `synced`: matches
   - `drifted`: exists in both, with a field-level diff
   - `missing`: in the repo, not in AAP
   - `extra`: in AAP, not in the repo (what you'd prune)
4. **Store and show.** Save results per repository and run the check on a
   schedule and on demand.

So for a repo entry like this:

```yaml
controller_templates:
  - name: "Patch web servers"
    job_type: run
    inventory: "Production"
    project: "Ops playbooks"
    playbook: "patch.yml"
```

the tool looks up "Patch web servers" in AAP and compares field by field. If
someone swapped the inventory in the UI, that template shows up as `drifted`
with the inventory as the changed field.

> Avoiding false alarms
>
> AAP fills in defaults and server-side fields the repo never mentions, and it
> never returns secret values. The comparison normalizes defaults and only
> checks that secrets are present, otherwise every credential would look
> drifted forever.
{: .admonition .note}

Each repository also gets a flowchart of its objects and their dependencies
(organizations to credentials and inventories, projects and inventories to job
templates, templates to workflows) colored by status. If a credential is
drifted, you see every template that depends on it.

## Where it stands and what's next

Being honest about the state of things: the scaffold is up, and the core isn't
written yet. Today it's a Django app with a PatternFly frontend, Celery for
background jobs, Postgres and Redis, all running under Podman Compose. Login,
the overview page, the repository list, and a settings page with a working
"Test connection" against AAP or AWX all work. The flowchart still runs on
sample data.

If you want to poke at it:

```bash
git clone https://github.com/Sherlock64/ansible-infra-cd.git
cd ansible-infra-cd
make up          # web, worker, beat, postgres, redis on :8000
make superuser   # create your login
make seed        # optional demo data
```

The roadmap, roughly in order:

1. Repository management and git access, with credentials encrypted in the
   database.
2. Drift detection, as described above.
3. Sync from repo to AAP, with a diff to confirm before applying and pruning
   behind an explicit opt-in.
4. Export from AAP back to a repo.

That last one is the piece I'm most excited about. People like to tinker in
the UI, and that's fine for figuring things out. When it's time to go to
production, they export what they built into a new branch and open a pull
request, never pushing straight to main. Then it gets deployed from the repo,
set up correctly, like everything else.

## A visibly happy system

Webhooks, schedules, and EDA get your config into AAP. They don't tell you
whether it stayed there. I want a page that answers "does AAP match the repo?"
at a glance, with a diff when the answer is no.

If you run AAP with `infra.aap_configuration` and have opinions on what that
page should show, the [repo](https://github.com/Sherlock64/ansible-infra-cd)
is open. I'll write more as the drift engine comes together.
