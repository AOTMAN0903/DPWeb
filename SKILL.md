---
name: dpweb
description: Build or modify high-fidelity Vue 3 digital-twin dashboard pages in the DPWeb project style extracted from HJGWeb. Use when the user provides a Figma file, screenshot, mockup, current design, or existing DPWeb page and asks to create another page, card, chart, table, UE-linked control, or screen that should follow the DPWeb front-end architecture, sizing, reusable components, data polling pattern, Unreal Engine event bridge conventions, and the exact visual/interaction intent of the source design.
---

# DPWeb

Use this skill to implement high-fidelity pages that follow the DPWeb digital twin dashboard implementation pattern.

DPWeb work is both implementation work and visual reconstruction work. When a Figma file, screenshot, mockup, or current design is provided, treat it as the visual source of truth. The final page must preserve the DPWeb architecture while matching the supplied design's layout, spacing, typography, colors, density, assets, interaction states, and dashboard behavior.

## 1. Working Sequence

Follow this sequence; use the detailed sections below as the rules for each stage.

1. Inspect the target repo before editing. Confirm it is HJGWeb-like by checking for `zf-dbs`, `src/config/index.ts`, `PageScreen`, `PageCard`, `PageTable`, and `VueEcharts`. Inspect existing routes, components, data helpers, assets, and UE bridge before adding abstractions.
2. Read `references/hjgweb-patterns.md` before non-trivial page, card, chart, table, video, or UE interaction work. Check the pnpm workspace before scaffolding or changing dependencies.
3. Resolve the exact visual target from the request, existing page, Figma frame/node, screenshot, or mockup. If it cannot be inferred, ask for the exact frame or image. For Figma, follow the bounded evidence workflow in section 2.
4. Read the project canvas values, compare them with the source dimensions, and measure major regions. Establish coordinate conversion before choosing dimensions or assets.
5. Complete the in-scope asset/font preparation and blocking gate in section 2 before component layout.
6. For a new full dashboard or layout-sensitive change, inspect the shared shell and create or update `adaptation-contract.md` before coding. For scoped non-layout changes, reuse the existing contract and record affected-region risk.
7. Implement the page, charts, tables, data, interactions, and UE wiring using sections 3–5. Keep scope limited to the requested screen and visible states.
8. Select the required QA level, build and test, compare visual evidence, repair blocking findings, and hand off using section 6. Process multiple screens sequentially unless the user explicitly requests parallel implementation.

Keep core implementation rules in this file. Existing references supply project examples, asset procedures, or bridge-specific details; load them only under the conditions stated here.

## 2. Design Evidence and Asset Preparation

### Visual Source Requirements

- Treat the supplied visual as the fidelity target subject to explicit user and runtime constraints. Preserve its hierarchy, density, region proportions, typography, colors, spacing, chart/table geometry, and interaction states; document necessary deviations.
- Decompose and measure major regions before coding. Do not simplify dense dashboard areas into generic cards, empty panels, or unrelated grids.
- Preserve the center UE/3D scene role and reproduce its designed overlays, masks, controls, labels, legends, callouts, minimaps, and drill-down UI.

### Figma MCP Usage

Use Figma MCP only to answer implementation facts that are missing from local evidence.

- Resolve the exact target frame before requesting design details. If the supplied URL points to a page, canvas, section, or multi-screen container, use metadata only as a locator: inspect the smallest possible set of immediate/top-level children needed to identify the requested screen, and emit only their names, node IDs, and dimensions into model context. If the user provides an exact frame URL/node, skip locator discovery and read that frame directly.
- Do not request, print, or retain the full metadata tree for an entire Figma file, page, canvas, or multi-screen container when the task concerns one screen. Never use a whole-file or whole-page `get_design_context` call as a shortcut for locating the target.
- For a first full-page build, after locating the exact frame, call `get_design_context` once on that frame and treat it as the initial scope boundary. Extract the digest evidence and screenshot needed for implementation; query smaller descendant nodes later only when cached evidence is missing, stale, or contradicted by QA.
- Treat the complete React/Tailwind reference code returned by `get_design_context` as tool-side raw evidence. Never emit the complete generated code for a full page or other large frame/node into model context. When transient storage is available, cache the raw text under a key tied to the Figma file and frame node.
- Emit a compact structured digest rather than raw dumps. Preserve the selected frame name/ID and dimensions, major region hierarchy and bounds, visible text, typography, colors, effects, asset role-to-URL mappings, chart/table geometry, relevant states, and design annotations. Preserve exact source snippets only when they are small and materially required.
- For follow-up, scoped work, or QA gaps, reuse existing screenshots, measurements, inventories, exports, caches, and digests first. If a fact is still missing, extract the smallest relevant cached fragment before querying the smallest relevant descendant node/property. Do not re-emit the whole frame response.
- When multiple screens are requested, a single minimal locator pass may identify frame names, node IDs, dimensions, and implementation order. Sequential processing is the default: only one frame may be active for detailed work at a time, and later frames must not be prefetched before the active frame completes evidence collection, asset inventory, implementation, build, and required visual QA.
- If the user explicitly requests multi-agent parallel implementation, read `references/figma-mcp-parallel.md` before assigning frames or fetching detailed design content for concurrent work.

### Asset and Font Preparation — Blocking Gate

For Figma/screenshot/mockup-driven visual reconstruction, read `references/asset-fidelity.md` before implementation and follow its blocking gates. This is mandatory for new full-page builds and for any scoped change where source-specific static visuals, finite-state controls, icons, decorative chrome, logos, rare title lettering, scene imagery, or fonts affect fidelity.

For narrow non-visual edits or small changes inside an existing page, apply the asset/font process only to the affected regions and nearby dependent layout. Reuse existing inventories, exports, screenshots, and font evidence when they already answer the affected question.

Keep the core rule in mind: source-specific static and finite-state visuals prefer Figma exports or exact repo assets; CSS/SCSS and ECharts are for basic layout primitives, live text, data-driven marks, and runtime-variable states unless the asset inventory documents a concrete reason.

The asset gate is blocking for visual reconstruction, including static-only prototypes and newly scaffolded workspaces. For scoped visual edits, apply it only to affected source-specific static visuals and finite-state assets. For non-visual logic, copy, data, or wiring changes, do not require a full-page inventory unless the change exposes or alters visual fidelity.

Do not begin component layout with missing, duplicated, screenshot-derived, or uninspected required in-scope assets unless the asset source is genuinely blocked. If an asset cannot be exported, reused, or inspected, record it as `blocked` in `asset-inventory.md`, document any temporary fallback, write `design-qa.md` with `final result: blocked`, and tell the user what prevents final fidelity.

## 3. Layout and Screen Adaptation

### Design Canvas and Source Coordinates

Use the principle: Figma frame first, DPWeb canvas as the design baseline.

- The DPWeb fixed design canvas is the base coordinate system, not necessarily the final visible viewport bounds. Keep `appWidth`, `appHeight`, and `useScale` as the design reference unless the user explicitly asks to change project sizing, then adapt real screens through anchored UI groups and elastic center spacing instead of deforming elements.
- The selected Figma frame, screenshot, or mockup is the visual source of truth. Use its coordinates, proportions, density, hierarchy, and interaction states inside the DPWeb canvas. User requirements and real project/runtime constraints take precedence when they conflict; document any visual deviation they require.
- When the Figma frame size matches the DPWeb config, implement the design at the same absolute px positions and dimensions whenever feasible.
- When the Figma frame size differs from the DPWeb config, establish the scale conversion first. For example, a `3840 x 2160` design implemented in a `1920 x 1080` DPWeb canvas should use a `0.5` coordinate conversion before coding dimensions, offsets, font sizes, and asset sizes.
- `PageScreen` slots are engineering containers, not permission to override the design. Use `left`, `middle`, and `right` when they fit the source frame; if the source design shows different proportions or panel placement, adapt slot contents and scoped layout styles to match the source while staying inside the DPWeb architecture.
- The common DPWeb left/right panel width of about `400px` is a fallback only. Use it when the source design or nearby project pages do not provide a more specific layout. Otherwise follow the measured source layout unless a higher-priority user or runtime constraint requires a documented deviation.

Treat the center as the UE/3D scene surface; place only designed overlays, bottom-right controls, or contextual drill-down UI there.

### Screen Adaptation Model

Use the principle: fixed logical-size UI, elastic spacing, no deformation. Uniform whole-shell scaling is allowed by the rules below; independent element scaling is not.

- This is not breakpoint-first responsive layout. Do not redesign the dashboard at arbitrary breakpoints; keep fixed-size UI components, anchor left/right regions, and let the center scene/spacing absorb viewport differences.
- Implement UI elements at the design-canvas sizes and proportions. Buttons, cards, icons, typography, charts, tables, logos, and decorative assets must not stretch, squash, or change aspect ratio to fit the screen.
- For screens wider than the design canvas, do not solve the layout by simply centering a fixed canvas with blank side gutters when the page is expected to fill the display. Keep left-anchored UI groups against the left side and right-anchored UI groups against the right side, while the center scene/UE area and the spacing between left, center, and right regions absorb the extra width.
- For screens narrower than the design canvas, preserve UI element sizes and proportions first. Reduce the center spacing/scene width before shrinking or distorting side panels, buttons, text, icons, or charts.
- Define a minimum safe aspect ratio for each page from the narrowest logical composition that keeps the fixed header, left/right UI groups, and minimum center scene from overlapping. Treat this as a ratio boundary, not a fixed viewport width or height.
- At or above the minimum safe aspect ratio, the rendered page must cover the full viewport at every pixel width: keep left/right UI groups anchored to the two viewport edges, let the center scene/background absorb the width difference, and do not leave side gutters. A short viewport may use one uniform height scale while expanding the logical width so the rendered canvas still covers the viewport.
- Below the minimum safe aspect ratio, lock the complete page shell to the documented safe reference ratio and uniformly scale the whole shell from the limiting width. The scene raster, ambient background, masks, panels, charts, tables, icons, typography, footer, and decorative chrome must share the same transform. Only this below-safe-ratio mode may introduce proportional top/bottom letterboxing.
- Do not trigger whole-page scaling merely because `viewportWidth` is below a fixed number such as `1540px`. Compare `viewportWidth / viewportHeight` with the documented `minSafeAspectRatio`; a small but sufficiently wide-ratio viewport must still use the full-viewport branch.
- Extra width may expand the center UE/3D scene, ambient background, or non-critical visual space. It must not stretch charts, tables, buttons, logos, icons, or panel chrome.
- Critical controls must remain anchored to their intended edges or regions. Top navigation and header status groups should preserve their left/right anchors; side panels should preserve their side anchors; center overlays should remain tied to the scene or design-specified coordinates.
- Avoid horizontal scrolling for normal dashboard viewing. Use the safe-ratio whole-shell scale first; report a limitation only when the result remains unusable or a runtime constraint prevents the documented model.

### Shared-Shell Implementation and Contract

- Inspect `src/config/index.ts`, `PageScreen`, the default layout, scale helpers, global styles, and any shell that controls dimensions, transforms, anchoring, or overflow before changing layout behavior.
- Implement adaptation in the shared shell, not separately inside cards. The scene/background and every UI layer must enter the same branch and share the same whole-shell transform.
- For a new full dashboard or a layout-sensitive change, create or update `adaptation-contract.md` before coding. Scoped non-layout changes may reuse the existing contract and record only affected-region risk; do not require a new contract for copy, data, small style, or non-visual logic changes unless they alter the shared shell or page geometry.
- The contract must record the design canvas/conversion ratio, anchor groups, center absorber, `minSafeAspectRatio`, safe reference ratio/canvas, branch behavior, non-deformable elements, and implementation variables.
- Do not use contain scaling as the wide-screen strategy. It is allowed only below the safe ratio, for an explicitly centered experience, or for a documented shell constraint.

Use this default shell formula unless the existing shell requires a documented equivalent:

```ts
const viewportAspectRatio = viewportWidth / viewportHeight
const belowSafeRatio = viewportAspectRatio < minSafeAspectRatio
const safeLogicalWidth = designHeight * minSafeAspectRatio
const scale = belowSafeRatio
  ? viewportWidth / safeLogicalWidth
  : Math.min(1, viewportHeight / designHeight)
const logicalWidth = belowSafeRatio ? safeLogicalWidth : viewportWidth / scale
const logicalHeight = belowSafeRatio ? designHeight : viewportHeight / scale
```

Center the safe-ratio shell only below the safe ratio. At or above it, transformed shell bounds must equal viewport bounds and left/right groups must remain symmetrically edge-anchored. Verify the selected QA level before handoff.

## 4. DPWeb Implementation

### Stack and Reuse

Use the principle: DPWeb stack first, image-to-code fidelity workflow as the method.

- Implement inside the DPWeb/HJGWeb technical architecture: Vue 3 SFCs, `src/pages/*.vue`, generated routes, default layout, `PageScreen`, `PageCard`, `PageTable`, `VueEcharts`, `usePolling`/`usePollingRef`, `ZfTweenNumber`, local assets, scoped SCSS, and `ue.emit(...)`.
- Prefer existing project components, composables, mock-data patterns, animation/count-up conventions, and auto-imports. Do not introduce a new UI framework, chart wrapper, state library, CSS methodology, or route structure for a single screen unless the repo already uses it or the user asks for it.
- Keep scoped SCSS and fixed-px implementation for screen fidelity. Use UnoCSS utilities only where the repo already does and where they do not obscure precise design measurements.

### Workspace and Dependency Management

- Before scaffolding a project or changing dependencies, search upward from the target directory for `pnpm-workspace.yaml`. For projects anywhere under `D:\Codex\WebFrame`, treat `D:\Codex\WebFrame` as the pnpm workspace root and use its workspace configuration and lockfile.
- Keep every package's direct runtime and development dependencies declared in that package's own `package.json`; workspace sharing does not replace correct dependency declarations.
- Run dependency operations from the workspace root. Use `pnpm install` for reconciliation, `pnpm --filter <package-name> add <dependency>` for a package dependency, and add `-D` for a package development dependency. Use `pnpm add -w` only when the dependency genuinely belongs to the workspace root.

### Page, Component, and Data Workflow

1. Add or edit pages under `src/pages/*.vue`; rely on generated file-system routes and the default layout.
2. Compose full dashboards with `PageScreen` slots when they faithfully carry the source layout. Wrap side-panel content in `PageCard`; keep card contents self-contained and scoped.
3. Use `PageTable` for dashboard lists and `VueEcharts` for charts; apply the chart/table fidelity rules below.
4. Use `usePolling` or `usePollingRef` for refreshed data, matching the repo's mock/seeded-data pattern when no real API exists. Keep mock data realistic and stable enough to preserve chart/table density, labels, and number formatting.
5. Match existing scoped SCSS, BEM-like class names, local assets, and `ZfTweenNumber`; take colors, fonts, chart density, and decoration from the actual source design.
6. Implement local control state and UE events using section 5. Keep adaptation in the shared shell using section 3, not as an unverified page-level assumption.

Implementation boundaries:

- Do not add unrelated routes, auth, persistence, backend integrations, or broad product behavior. Adding the requested page through generated routes remains in scope.
- Do not invent real APIs for mock-only modules. If real data access is requested, create focused modules under `src/service` and keep component state shapes stable.
- When using Element Plus, follow existing cards' scoped `:deep(...)` overrides.
- For video, reuse `VideoPlay`; do not hand-roll HLS/FLV playback.

### Chart and Table Fidelity

- ECharts options must be design-led, not generic. First identify the source chart's actual mark type and geometry, then match it: straight polyline vs smooth curve, area fill, stacked area, step line, dashed/solid style, spline tension, symbol visibility/size, endpoint markers, line/bar/ring thickness, gradients, shadows/glows, grid bounds, axis visibility, tick density, label placement, legend layout, tooltip behavior, colors, and empty/loading states. Do not default every trend chart to a standard straight `line` series; if the source shows curved/smoothed paths, use `smooth`, appropriate sampling, area/gradient settings, or a custom/ECharts-supported rendering approach that visually matches the design.
- For trend or area charts that visually read as smooth dashboard trends, match both the curve renderer and the data rhythm. Do not create mock data with abrupt alternating peaks and troughs unless the source clearly shows that volatility. Use gradual neighboring values so the rendered line preserves the intended flowing shape. Avoid midpoint-only cubic curves that create visible kinked bends at every point; prefer ECharts `smooth` with appropriate tension, monotone/spline interpolation where available, or a low-tension Catmull-Rom/cubic path. Tune the tension so the curve is smooth without overshooting the plot or inventing false extrema. Visual QA must inspect trend charts at card-level crop, not only full-page scale; if the curve looks jagged, over-bent, or more volatile than the source, adjust interpolation and/or mock values before handoff.
- Tables must be design-led, not merely data-rendered. Match row height, column widths, alignment, typography, zebra/hover/selected states, status colors, scroll region, pagination, empty state, and density shown in the source design.

## 5. Interaction State and UE Communication

### Interaction and State

- Implement controls that are part of the requested/core flow or are clearly interactive in the source. Purely decorative or status-only elements may remain non-interactive; document any visually control-like exception in QA.
- Treat repeated controls as component families. Implement normal and selected/current variants for the whole family, plus hover, focus, disabled, loading, empty, success, or error states when implied by the design or core flow.
- Keep hover-, click-, focus-, expanded-, drill-down-, tooltip-, and popover-only content hidden in the default state unless the source explicitly shows it active by default.
- Identify and wire the correct trigger for every revealed layer. If ambiguous, infer from hierarchy and document the assumption in `design-qa.md`.
- Tabs, filters, legends, tables, menus, and UE controls included in the core flow must update visible local state; UE controls must also follow the selected bridge contract.
- QA must verify a clean default state and at least one triggered-state capture whenever interaction-revealed content is in scope.

### UE Communication Patterns

Select the UE communication pattern by inspecting the target project's existing bridge code. Do not mix protocols or assume a bridge without checking the repo.

- Prefer the repo's existing UE wrapper such as `ue.emit(...)`; do not invent a new global bridge when the project already has one.
- Keep frontend UI state and UE events synchronized. When a visible scene/tool control is clicked, update the local selected/open state and send the matching UE command.
- Treat top navigation and mutually exclusive scene tools as single-selection groups by default unless the source design or existing project behavior shows otherwise.
- Register UE-to-frontend callbacks only when the project bridge supports them, keep page-scoped callbacks lifecycle-safe, and clean them up on unmount where applicable.
- Send a page/app `ready` event only after required frontend callbacks are registered, when the selected bridge uses a ready handshake.
- If the project uses WebUI / `ue5(...)`, read `references/ue-webui-plugin.md` for implementation examples.
- If the project uses `WebViewEnhancedByCengJia` / `window.ue.web`, read `references/ue-webview-enhanced.md` for implementation examples.
- If the project uses Pixel Streaming, WebSocket, `postMessage`, or another bridge, inspect that bridge first and follow its existing contract.

## 6. Validation and Handoff

Visual QA is a blocking gate for Figma/screenshot/mockup-driven work; build success alone is not enough. Select one QA level before validation and escalate when observed impact exceeds the chosen scope. QA level never relaxes the asset/font preparation and blocking gate in section 2, or the required DPWeb architecture.

### QA Level Selection

- **QA-Extended (highest): mandatory for the first implementation of every new full page.** Also use it for a new dashboard shell, adaptation/layout-shell changes, multi-region redesigns, scene/background replacement, navigation/header restructuring, asset-strategy changes, or any change whose visual blast radius is uncertain. A first page build must never be downgraded because it appears simple or time is limited.
- **QA-Standard: default for later visual or behavioral changes** affecting a component, card, chart, table, control family, interaction, or asset without changing the shared page shell or several major regions.
- **QA-Lite: only for later narrowly scoped changes** such as copy, data values, a localized style correction, or non-visual logic with a clearly bounded visual risk.
- Escalate `Lite -> Standard -> Extended` whenever the change affects additional regions, shared components, layout/adaptation, background/scene composition, or reveals a broader regression. Do not downgrade merely because a higher level is inconvenient.

### Browser QA Tool Preference

- Use the Codex in-app Browser by default for local page testing, interaction checks, console inspection, screenshots, and visual QA.
- Do not use the user's Chrome browser, profile, tabs, login state, or extensions unless the user explicitly asks for Chrome.
- Fall back to Playwright only when the in-app Browser is unavailable or cannot perform the required terminal-driven automation.

### Checks Required at Every Level

1. Run the repository's relevant type, lint, test, and production-build checks when available.
2. Open the page in a real browser, check the console, and verify the requested behavior rather than relying on compilation alone.
3. Compare against the saved source visual or established page baseline at a viewport relevant to the change.
4. Update `design-qa.md` with the selected QA level, affected scope, evidence paths, findings, and `final result: passed` or `final result: blocked`.

### QA-Lite

- Capture the affected region and enough surrounding context to detect local regression.
- Test the changed state at one representative viewport and exercise the directly affected behavior.
- Record residual risk. Escalate to Standard if the change alters geometry, shared styles/components, assets, or another region.

### QA-Standard

- Capture the full page plus focused crops of affected dense regions at the design/baseline viewport.
- Test at least one additional viewport relevant to the change and measure DOM bounds when geometry is involved.
- Verify affected default, hover, selected, open, empty, loading, or error states and capture at least one triggered state when applicable.
- Audit changed assets and CSS-generated visual objects in the affected scope; classify them as `CSS allowed`, `replace with asset`, or `blocked`.
- Escalate to Extended if the shell, safe-ratio behavior, scene/background, navigation/header, or multiple major regions are affected.

### QA-Extended

- Use for every first full-page implementation and all other cases listed in `QA Level Selection`.
- Capture and compare the source and implementation at full-page and focused-region scale. Verify typography, spacing, colors, hierarchy, asset/icon fidelity, chart/table geometry, content density, and interaction states.
- Test the design viewport plus: a wide viewport above the safe ratio, a pixel-narrow viewport still above it, viewports immediately above and below `minSafeAspectRatio`, and a tall/narrow viewport below it.
- Measure and record `minSafeAspectRatio`, `viewportAspectRatio`, `scale`, logical dimensions, transformed shell/scene bounds, and left/right rendered edge gaps. Confirm the shell fills the viewport above the safe ratio and that the complete shell/background shares one transform below it.
- Verify clean default state plus every in-scope triggered/revealed state, browser console output, core interactions, and UE events when applicable.
- Run the full CSS-generated visual-object and asset-format audit. Static or finite-state visuals must follow the asset gate; verify SVG for vectors/chrome and PNG only for raster sources.
- `design-qa.md` must include source and implementation evidence, tested viewport matrix, adaptation contract/formula, interactions, console result, visual findings, asset/font inventory summary, CSS audit, comparison history, and final result.

At any level, fix all P0/P1/P2 visual, asset, icon, layout, adaptation, chart-geometry, or interaction issues and repeat the required checks before marking `passed`. P3 polish may remain documented. If dependencies, browser capture, Figma access, or visual comparison block the required level, mark `design-qa.md` as `blocked` and report the specific blocker.

### Output and Handoff

- The result should be a runnable DPWeb/HJGWeb-style Vue page, not a static screenshot approximation.
- The implemented page should use the repo's real layout, route generation, cards, tables, charts, polling helpers, animation/count-up components, assets, and UE event bridge conventions.
- The page should visually match the selected Figma frame/screenshot after any documented canvas conversion, with the same primary interaction state available for review.
- Keep mock data realistic and stable enough that chart/table density, labels, and number formatting look like the design.
- Leave the local dev server running when feasible and provide the local URL in Codex Desktop handoff.

Do not hand off as complete with missing visual assets, placeholder regions, clipped text, horizontal overflow, broken control states, or obvious mismatch in major-region proportions. Report blocked work explicitly under the QA rules above.
