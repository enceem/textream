---
name: atdd-feature-writer
description: Turn product requirements and user stories into clear, reviewable Gherkin acceptance scenarios. Use when drafting or revising acceptance criteria or .feature files.
---

# ATDD Feature Writer

Translate stated behavior into acceptance scenarios that stakeholders can review and teams can automate.

## Workflow

1. **Understand the behavior.** Identify the actor, goal, trigger, starting conditions, observable result, and stated exceptions. Separate requirements from assumptions.
2. **Inspect the repository.** Look for existing feature files, step definitions, test targets, and runner conventions. Use the existing setup when available. If none exists, recommend a runner and identify what integration remains to be done.
3. **Find material gaps.** Check permissions, authentication, invalid input, failure recovery, and state changes. Ask only about decisions that materially change acceptance; otherwise record a clear assumption.
4. **Draft a small set of scenarios.** Cover the main successful behavior and important alternatives or failures. Give each scenario one purpose, use concrete examples, and prefer `Scenario Outline` when the same behavior applies to clear data values.
5. **Review the draft.** Keep steps externally observable, use consistent product terms, and remove duplicates, vague outcomes, and implementation details.

## Output and boundaries

- Return proposed `.feature` content in fenced Gherkin blocks, followed by material assumptions and a brief repository-fit note when applicable.
- Do not claim scenarios are executable or passing until the runner and step definitions have been verified.
- Do not write step definitions or application code unless requested.
- Preserve the user's scope and permissions; do not infer extra product requirements.
