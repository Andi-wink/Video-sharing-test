# Bingley Sales skills → ten reps at a client

Response to Sully. Draft — two sections need Andrew's own material before this goes out (marked **[ANDREW]**).

---

## Cover note

Sully,

I read the repo before writing this — all six skills, the Python engines under them, and the
shared brain library. Three things in there change the shape of the job, so I've led with those
rather than with a methodology.

Short version: I'd deploy this on Claude for Work with a private plugin marketplace, not
self-hosted, and the only bespoke code I'd write is a small shared-state service for
suppression and dedupe. The reason isn't preference — it's that the skills lean on host
affordances (the sandbox, the connector layer, the artifact and clickable-question tools) that
self-hosting means rebuilding, and the actual thing that breaks at ten people is a single line
in `sales-brain-setup`, not the delivery model.

---

## What's actually in the repo

Grounding for everything below. Paths are from `bingley-ai/bingley-skills` at v1.0.0.

| Finding | Where | Why it matters at ten users |
|---|---|---|
| It's a Claude Code plugin marketplace — one plugin, six skills | `.claude-plugin/marketplace.json`, `plugins/bingley-sales/.claude-plugin/plugin.json` | Distribution is already solved. Fork it private, pin the version, and rollout is an install, not an engineering project. |
| Not just markdown — real runtime deps | `python3` + `pandas`/`openpyxl` (`sales-control-panel/SKILL.md`), `jq` and a bash tool (`list-builder-apollo/SKILL.md:137` — "stop before Stage 1" if absent) | Whatever hosts this needs a working Python sandbox. That rules a lot of "just put it in a chat widget" options out. |
| **One brain per working folder, by design** | `sales-brain-setup/SKILL.md:36` — *"This setup keeps one AI sales brain per working folder, and this one belongs to [name]"*, with an identity check and a `replace it` archive path | This is the single-user assumption, and it's explicit and defended, not an oversight. Ten reps means ten folders, not one shared one. |
| Shared state that matters is file-based and per-user | `Prospects_[Niche]_MASTER.xlsx` scanned recursively per working folder for dedupe (`list-builder-apollo/SKILL.md:152`); durable `disqualifier` notes in `working-context.jsonl`; `crm/pipeline-accounts.csv` | Ten reps on ten folders will prospect the same companies and email the same people. This is the real problem to solve, and it's a commercial one (domain reputation), not a technical nicety. |
| The store is well-built for one machine, and hostile to a synced folder | `brainstore.py` uses `fcntl.flock` + atomic `os.replace`; the code itself carries FUSE workarounds (`_read_log_text` retry loop) and `ledger.py` notes *"the FUSE mount may refuse the write — both seen in the wild"* | The obvious cheap answer — put `Claude HQ` on a shared Drive/Dropbox and let ten people share it — is the one approach that will silently corrupt data. `flock` does not do what you want over network filesystems. I would not do this. |
| Apollo is a per-user OAuth connector, no API key | `list-builder-apollo/SKILL.md:65,303,541` — `apollo_people_bulk_match`, OAuth via the connected app, direct REST 403s on Basic | Ten reps = ten Apollo seats and ten credit pools. Spend gates are per-run confirms; there is no org-level cap anywhere in the skill. Credit burn is a governance question on day one. |
| **Instantly is not an integration** | `list-builder-apollo/SKILL.md:14,82` — the Excel is the deliverable, plain First/Last/Email/Company columns, *"Instantly is one consumer, not the only one"* | The client believes they bought three integrations. They bought one (Apollo), one file handoff (Instantly), and a read-only CRM path. Better said in week one than month two. |
| Nothing writes back to the CRM | `sales-brain-setup` reads a CRM connector or falls back to CSV import; `sales-control-panel` — *"The engine reads files, never an API"* | Same point. Reps will ask "does it log the activity?" on day one. Answer is no, and that's a scope decision, not a bug. |
| `LOCAL.md` beside any `SKILL.md` overrides it and survives updates | Header of every `SKILL.md` | This is the supported customisation seam. It means client-specific behaviour without forking the skills — which is how the deployment stays updatable. |
| The v1.0.0 update path is "remove and re-add both" | `README.md` → Updates | Untenable to ask ten non-technical reps to do. Version control has to sit with us, not with them. |
| HTML outputs carry a "built by Bingley" strip that `LOCAL.md` explicitly cannot remove | Every `SKILL.md` header carve-out | MIT licence permits a fork, but that's a product instruction rather than a licence term. Worth a two-minute conversation with you rather than a surprise for the client's brand team. |

---

## 1. Putting this in front of a client

### Experience

**[ANDREW — your material goes here.]** What this section needs: one deployment you've run
end-to-end, the number of users, and specifically *what went wrong with adoption* and what you
did about it. Sully has said twice he wants how you think, not the textbook — so the honest
version ("the first two weeks were quiet and here's what I changed") will land harder than a
clean success story. Your Fortune 500 years are the asset here: you've watched enterprise
software land badly with sales teams more times than most consultancies have deployed anything.

### How I'd do it here

Claude for Work, with the six skills served from a **private fork of the marketplace repo** that
we control, plus one small shared-state service. Reps install one plugin. That's their entire
technical involvement.

Staged:

- **Phase 0 — scoping (paid, short).** Confirm the Apollo plan and seat model, the CRM, who owns
  domain reputation, and what IT will need. Written scope out the other end. Everything below is
  priced off this.
- **Phase 1 — pilot, 2–3 reps, two weeks.** Pick one enthusiast and one sceptic deliberately.
  The sceptic is the one who tells you the truth.
- **Phase 2 — the other seven,** once the pilot's shared-state and credit questions are settled.
- **Phase 3 — four weeks of support,** then a decision about ongoing retainer.

### Why this over the alternatives

**Versus self-hosting.** The skills are markdown, but they're markdown written against a host.
They call clickable-question tools, artifact create/update tools, a file-presenting tool, a
sandboxed bash workspace with pandas/openpyxl/jq, and an OAuth connector layer for Apollo — and
`sales-advisory-board/SKILL.md:121` is explicit that `window.cowork` exposes exactly three
things and nothing else carries typed text out of an artifact. Self-hosting means rebuilding
that entire surface before you deliver any sales value, and then owning it. You'd also lose the
thing that makes this product good: a fix ships as a markdown edit the same day. I'd revisit
self-hosting when the client's requirements genuinely diverge from the platform — data
residency, an air-gapped CRM, or wanting this in their own product. Not for ten reps.

**Versus Claude Code per rep.** It works and it's cheap. It's a terminal. Ten non-technical
salespeople is the wrong audience for it, and the first `python3: command not found` ends the
project.

**Versus doing nothing custom at all** — just installing the plugin ten times. Tempting, and it
would demo beautifully in week one. It fails in week three when two reps have emailed the same
CFO. The shared-state piece is small, but it isn't optional.

---

## 2. One person's tool, ten people's data

### The data

The instinct is to give the ten reps one shared `Claude HQ`. Don't. The store is guarded by
`fcntl.flock`, the code carries scars from FUSE mounts, and the setup skill actively refuses to
show one person's brain to another. Fighting all three is how you get silent corruption of the
thing the whole product reads.

I'd split the state by what it actually is:

**Stays private, per rep** — their brain profile (`sales-os-profile.json`), their voice and
tone, their working context, their own ledger, their rendered panels. Nobody benefits from
sharing these, and a rep whose email voice is really someone else's stops using the tool.

**Must be shared, and is the whole job** —

1. **Suppression / do-not-contact.** Non-negotiable, both commercially and for GDPR.
2. **Already-contacted.** Today this is a per-folder `Prospects_[Niche]_MASTER.xlsx`. Ten copies
   of it is the duplicate-outreach bug.
3. **Account ownership / territory.** Who owns Acme. Sales teams have opinions about this and
   the tool needs to respect them or it gets blamed for a commission argument.
4. **Company research cache.** Deep research per company is the expensive call. Ten reps
   re-researching the same accounts is money on the floor — this one pays for itself.

Mechanically: one small append-only shared store (a hosted table — Postgres/Supabase — rather
than a file on a synced drive, precisely because of the locking problem above), and a thin
client the skills call. The skills reach it through `LOCAL.md` files beside each `SKILL.md`,
which is the repo's own supported override seam and survives plugin updates. Two touch points
only: a suppression-and-dedupe check before the Apollo spend gate in `list-builder-apollo`, and
a write on delivery. That's the bespoke code in this project, and it's deliberately small.

Two things I'd raise with the client early rather than discover later:

- **Apollo credits.** Per-run confirms are per-user; nothing aggregates. Ten reps can burn a
  month's credits in a week with everyone individually saying yes. Needs an org policy and, if
  they want it enforced, a cap in the shared service.
- **Right to erasure.** The ledger is append-only across monthly files and `snapshots/` archives
  are explicitly never pruned. Deleting one prospect's data across ten reps' local folders is
  genuinely hard as built. Worth designing for before there's two years of it, not after.

### Getting them to actually use it

The failure mode with ten non-technical reps isn't bugs, it's silence. So:

**Day one is a room, not an email.** Ninety minutes, all ten, and the only goal is that ten
brains are filled in before anyone leaves. Every skill in this repo degrades to generic output
without the brain — that's the thing that makes a rep try it once, get something bland, and
never come back. It's five clickable questions; it takes two minutes; and if you leave it to
homework, half of them won't.

**Attach it to a ritual they already have.** Not "here's a tool". The control panel runs at
Monday pipeline review, on the sales manager's screen. List building has a slot on Tuesday. The
tool has to be in an existing meeting or it competes with one.

**One champion, named, with something in it for them.** Usually the rep who was already messing
about with ChatGPT. They answer the small questions so ten people don't queue for me.

**A one-page card of the exact things to type.** "get me started", "write me a cold email",
"research [company]", "is my pipeline ok". Not documentation — four lines.

**Weekly office hour for four weeks,** then stop.

**Measure output, not logins.** Lists built, emails actually sent through Instantly off
skill-built lists, and reply rate against their baseline. Get the baseline in phase 0, before
anything is installed — it's the only chance.

---

## 3. Working with IT on security

**[ANDREW — your material goes here.]** Structure that works: what the concern actually was
(usually not what they said first), who you had to get in the room, what you changed versus what
you explained, how long it took, and the outcome. One example told properly beats three
summarised.

A framing worth considering if it's true for you: sixteen years at a Fortune 500 means you've
been on the *other* side of this — the vendor whose deal sat in a security review for six weeks.
That's a credible reason you now pre-empt it rather than react to it, and it's a story only
someone with your background can tell.

What I'd bring to IT here, unprompted, in the first conversation rather than the fourth — this
part is real and you can use it as-is:

- **These skills execute Python in a sandbox.** Say it first. IT finding it themselves is a much
  worse meeting. Then: which sandbox, what it can reach, what it can't.
- **Prompt injection is the honest risk, and I'd name it.** `company-researcher` reads scraped
  web pages and `list-builder-apollo` scrapes directories — untrusted third-party content enters
  the model's context by design. The mitigations are that these skills read and render, they
  don't send email or write to the CRM, and every credit spend sits behind an explicit human
  confirm. Naming the risk and showing the blast radius is what gets you through the review;
  claiming there isn't one is what gets you a second review.
- **Data flow, on one page.** Prospect PII from Apollo lands in local Excel files and an
  append-only ledger. Apollo authenticates per user by OAuth, no API keys and no `.env` anywhere
  in the repo — which is genuinely good news and worth saying explicitly.
- **The one outbound call.** A version check against the plugin's own `plugin.json`, nothing
  sent. Their egress logs will show it; better they hear it from us.
- **The enterprise answers to the two questions they always ask** — data isn't trained on, and
  admin controls exist for connectors. This is normally the thing that unblocks the review.
- **The GDPR piece** from section 2. Legitimate-interest basis for B2B outreach, suppression
  handling, and the erasure problem in the append-only ledger.

---

## 4. Doing this inside a company

**[ANDREW — your material goes here, if you have it.]** Sully asked as an "if", so a short
honest answer is fine. If the closest thing is enterprise software you sold and then watched get
rolled out badly, say that plainly and say what you learned from it — it's more useful to him
than a stretched claim, and he's clearly testing for straight answers.

---

## 5. Pricing

**Fixed price, in phases, off a written scope — with a day rate held in reserve for the
open-ended parts.**

The reasoning I'd give Sully, since he's asking how you think: hourly puts the estimating risk
on the client, and a non-technical client feels that as anxiety on every invoice. Fixed price
puts it on me, which is where it belongs, but it only works if the scope is written down — so
phase 0 is a small paid scoping engagement that produces exactly that. Then phase 1 and phase 2
are fixed. Support after go-live is a monthly retainer, or a day rate if he'd rather keep it
loose. The two genuinely unpredictable things — how the client's IT review goes, and whatever
their CRM turns out to be — sit outside the fixed price and get flagged as such up front rather
than absorbed silently.

**[ANDREW — put your numbers in.]** Phase 0, phase 1, phase 2, retainer or day rate. I've
deliberately not guessed; you know your market and your floor. Worth saying: he's building a
bench and this is explicitly the first of several jobs, so price it as the first of several, not
as a one-off.

---

## 6. Format

Send both. The written version above is the proof you read the code. Then a **five-minute
Loom**, screen-sharing the repo, on the three findings that change the job:

1. `sales-brain-setup/SKILL.md` — one brain per folder, by design, with the identity check.
2. `list-builder-apollo/SKILL.md` — the per-folder master file, and what that means for ten reps
   emailing the same CFO.
3. Instantly is a spreadsheet handoff, not an integration.

Almost nobody applying will have opened the repo. Five minutes of you pointing at actual lines
of it is the whole differentiator, and it answers his real question — how you think — better
than any amount of prose.
