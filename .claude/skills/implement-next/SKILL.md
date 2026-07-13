---
name: implement-next
description: Pick up the next unchecked task from the revamp checklist and drive it to completion with tests, gates, and a checked box. Use when asked to "continue the revamp", "do the next task", or implement a specific checklist item.
---

# Implement the next revamp task

1. **Read the plan context.** Open `docs/implement/revamp-checklist.md`; find the first unchecked `[ ]` task in the earliest incomplete phase (or the specific task the user named). Read the corresponding section of `docs/implement/revamp-plan.md` — especially the decision (D1–D10) and any appendix it cites. Do not start a later phase while an earlier phase's exit criteria fail.
2. **Respect gates.** If the task is marked **HUMAN-GATED**, stop and tell the user exactly what input/hardware/decision is needed — never fabricate its output (validation reports, checksums, curated datasets).
3. **Plan the change.** List the files the task names, read them, and confirm the checklist's line references still hold (the codebase moves; the inventory was written 2026-07-13). If reality diverges, follow the task's *intent* and note the divergence in the commit message.
4. **Implement** following `CLAUDE.md` conventions and the hard invariants (local-only, official sources, evidence-first, fail-visible). Write the task's listed tests in the same change — a task without its tests is not done.
5. **Run `/quality-gates`.** All gates green.
6. **Close out.** Check the box in `revamp-checklist.md` with a short commit reference (e.g. `[x] ... (abc1234)`). If the task completed a phase, verify the phase's **Exit criteria** and say so explicitly. Summarize what changed, what was verified, and what the next task is.
