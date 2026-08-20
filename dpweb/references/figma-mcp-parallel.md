# Figma MCP Parallel Work

Use this reference only when the user explicitly requests multi-agent parallel implementation for multiple Figma frames or screens.

## Parallel Setup

Before parallel work begins, the coordinator must run only the minimal locator pass needed to identify the exact frame assigned to each agent. Record:

- frame-to-agent mapping
- implementation boundaries
- file ownership
- shared-component ownership
- shared-asset ownership
- expected implementation order or integration order

Each assigned unit must be an exact frame node. Do not assign a broad page, canvas, section, or unbounded multi-screen container to an agent.

## Agent Scope

Each agent must remain strictly scoped to its assigned frame and owned files.

- Do not fetch another agent's frame or descendant nodes.
- Do not implement another agent's screen.
- Do not edit another agent's owned files.
- Do not prefetch future or unassigned frame context, screenshots, descendant metadata, or assets.
- Reuse already validated shared components and assets when ownership allows it.

Parallel work does not waive frame-scoped Figma queries, asset gates, per-page build checks, or required visual QA.

## Evidence And Handoff

Each agent must record the selected Figma frame name, node ID, digest evidence, owned files, owned assets, and QA evidence for its assigned frame.

Before final handoff, the coordinator must confirm:

- all frames followed the documented parallel assignment
- no whole-file, unrelated multi-screen, unassigned-frame, or future-frame metadata/context was loaded when a frame-scoped query could answer the task
- shared components and assets were reconciled
- final cross-page validation passed or blockers were documented