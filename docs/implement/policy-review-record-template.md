# Family-Safety Policy Review Record Template

Use this record before changing the v1 policy taxonomy, default actions, enforcement modes, boundary requirements, or explainability contract.

## Summary

- Policy version:
- Reviewer:
- Review date:
- Change type:
  - New category
  - Category removal
  - Default action change
  - Enforcement mode change
  - Boundary requirement change
  - Explainability requirement change
- Decision:
  - Approved
  - Rejected
  - Pending more evidence

## Local-Only Rule

- All inference remains local-only:
- Hosted VLM/LLM/embedding/reranking/moderation APIs remain prohibited:
- Approved transports unchanged:
  - In-process native runtime
  - Local helper process
  - Local loopback server on `localhost` or `127.0.0.1`
- Non-loopback URLs rejected:

## Policy Taxonomy

- Categories reviewed:
  - `explicit_nudity`
  - `sexual_content`
  - `suggestive_content`
  - `immodest_female_clothing`
  - `violence`
  - `gore`
  - `blood`
  - `weapons`
  - `substances`
  - `profanity`
- Category changes:
- Backward compatibility impact:

## Default Actions

- Region blur:
- Full-frame blur:
- Cut scene:
- Beep/mute:
- Review only:
- Action changes and rationale:

## Enforcement Modes

- Review-first categories:
- Enforce-when-high-confidence categories:
- Always-manual-review categories:
- Enforcement changes and rationale:

## Boundary Requirements

- Explicit nudity uses region bounds when available:
- Immodest female clothing uses region bounds when available:
- Blood/gore uses region bounds when available:
- Weapons use object bounds when available:
- Violence can be scene-level when no object boundary is meaningful:
- Boundary changes and rationale:

## Explainability Contract

Every detection must include:

- User-facing category:
- Severity:
- Confidence:
- Short rationale:
- Timestamp range:
- Region/scene-level status:
- Source model names:
- Supporting evidence IDs:

Explainability changes and rationale:

## Validation Evidence

- Validation dataset version:
- Golden fixture changes:
- Recall impact:
- False positive impact:
- Review burden impact:
- Temporal localization impact:
- Boundary quality impact:
- UI/review impact:

## Final Decision

- Approved status:
- Blocking issues:
- Follow-up requirements:
- Expiration / re-review date:

