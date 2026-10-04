---
name: dpweb
description: Build or modify high-fidelity Vue 3 digital-twin dashboard pages in the DPWeb project style extracted from HJGWeb, and package DPWeb/Vite pages as standalone offline HTML files. Use for Figma/screenshot/mockup-to-dashboard work, DPWeb pages/cards/charts/tables/UE controls, or requests such as single HTML, offline HTML, double-click-to-open, and Vite asset inlining.
---

# DPWeb

Use this skill to implement high-fidelity pages that follow the DPWeb digital twin dashboard implementation pattern.

DPWeb work is both implementation work and visual reconstruction work. When a Figma file, screenshot, mockup, or current design is provided, treat it as the visual source of truth. The final page must preserve the DPWeb architecture while matching the supplied design's layout, spacing, typography, colors, density, assets, interaction states, and dashboard behavior.

## Layout Model

Use the principle: Figma frame first, DPWeb canvas as the design baseline.

- The DPWeb fixed design canvas is the base coordinate system, not necessarily the final visible viewport bounds. Keep `appWidth`, `appHeight`, and `useScale` as the design reference unless the user explicitly asks to change project sizing, then adapt real screens through anchored UI groups and elastic center spacing instead of deforming elements.
- The selected Figma frame, screenshot, or mockup is the visual source of truth. Use its coordinates, proportions, density, hierarchy, and interaction states inside the DPWeb canvas. User requirements and real project/runtime constraints take precedence when they conflict; document any visual deviation they require.
- When the Figma frame size matches the DPWeb config, implement the design at the same absolute px positions and dimensions whenever feasible.
- When the Figma frame size differs from the DPWeb config, establish the scale conversion first. For example, a `3840 x 2160` design implemented in a `1920 x 1080` DPWeb canvas should use a `0.5` coordinate conversion before coding dimensions, offsets, font sizes, and asset sizes.
- `PageScreen` slots are engineering containers, not permission to override the design. Use `left`, `middle`, and `right` when they fit the source frame; if the source design shows different proportions or panel placement, adapt slot contents and scoped layout styles to match the source while staying inside the DPWeb architecture.
- The common DPWeb left/right panel width of about `400px` is a fallback only. Use it when the source design or nearby project pages do not provide a more specific layout. Otherwise follow the measured source layout unless a higher-priority user or runtime constraint requires a documented deviation.

## Screen Adaptation Model

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

## Adaptation Implementation and Contract

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

## Technical Implementation Bias

Use the principle: DPWeb stack first, image-to-code fidelity workflow as the method.

- Implement inside the DPWeb/HJGWeb technical architecture: Vue 3 SFCs, `src/pages/*.vue`, generated routes, default layout, `PageScreen`, `PageCard`, `PageTable`, `VueEcharts`, `usePolling`/`usePollingRef`, `ZfTweenNumber`, local assets, scoped SCSS, and `ue.emit(...)`.
- Prefer existing project components, composables, mock-data patterns, animation/count-up conventions, and auto-imports. Do not introduce a new UI framework, chart wrapper, state library, CSS methodology, or route structure for a single screen unless the repo already uses it or the user asks for it.
- ECharts options must be design-led, not generic. First identify the source chart's actual mark type and geometry, then match it: straight polyline vs smooth curve, area fill, stacked area, step line, dashed/solid style, spline tension, symbol visibility/size, endpoint markers, line/bar/ring thickness, gradients, shadows/glows, grid bounds, axis visibility, tick density, label placement, legend layout, tooltip behavior, colors, and empty/loading states. Do not default every trend chart to a standard straight `line` series; if the source shows curved/smoothed paths, use `smooth`, appropriate sampling, area/gradient settings, or a custom/ECharts-supported rendering approach that visually matches the design.
- For trend or area charts that visually read as smooth dashboard trends, match both the curve renderer and the data rhythm. Do not create mock data with abrupt alternating peaks and troughs unless the source clearly shows that volatility. Use gradual neighboring values so the rendered line preserves the intended flowing shape. Avoid midpoint-only cubic curves that create visible kinked bends at every point; prefer ECharts `smooth` with appropriate tension, monotone/spline interpolation where available, or a low-tension Catmull-Rom/cubic path. Tune the tension so the curve is smooth without overshooting the plot or inventing false extrema. Visual QA must inspect trend charts at card-level crop, not only full-page scale; if the curve looks jagged, over-bent, or more volatile than the source, adjust interpolation and/or mock values before handoff.
- Tables must be design-led, not merely data-rendered. Match row height, column widths, alignment, typography, zebra/hover/selected states, status colors, scroll region, pagination, empty state, and density shown in the source design.
- Keep scoped SCSS and fixed-px implementation for screen fidelity. Use UnoCSS utilities only where the repo already does and where they do not obscure precise design measurements.

## Workspace and Dependency Management

- Before scaffolding a project or changing dependencies, search upward from the target directory for `pnpm-workspace.yaml`. For projects anywhere under `D:\Codex\WebFrame`, treat `D:\Codex\WebFrame` as the pnpm workspace root and use its workspace configuration and lockfile.
- Keep every package's direct runtime and development dependencies declared in that package's own `package.json`; workspace sharing does not replace correct dependency declarations.
- Run dependency operations from the workspace root. Use `pnpm install` for reconciliation, `pnpm --filter <package-name> add <dependency>` for a package dependency, and add `-D` for a package development dependency. Use `pnpm add -w` only when the dependency genuinely belongs to the workspace root.

## Figma MCP Usage

Use Figma MCP only to answer implementation facts that are missing from local evidence.

- Treat Figma evidence as three layers: tool-side raw evidence, a compact structured digest in model context, and the smallest on-demand extracts needed to resolve later gaps. Never discard raw evidence merely to save context when transient tool storage is available; never emit raw evidence merely because it is cached.
- Resolve the exact target frame before requesting design details. If the supplied URL points to a page, canvas, section, or multi-screen container, use metadata only as a locator: inspect the smallest possible set of immediate/top-level children needed to identify the requested screen, and emit only their names, node IDs, and dimensions into model context. If the user provides an exact frame URL/node, skip locator discovery and read that frame directly.
- Do not request, print, or retain the full metadata tree for an entire Figma file, page, canvas, or multi-screen container when the task concerns one screen. Never use a whole-file or whole-page `get_design_context` call as a shortcut for locating the target.
- For a first full-page build, after locating the exact frame, call `get_design_context` once on that frame and treat it as the initial scope boundary. Extract the digest evidence and screenshot needed for implementation; query smaller descendant nodes later only when cached evidence is missing, stale, or contradicted by QA.
- Treat the complete React/Tailwind reference code returned by `get_design_context` as tool-side raw evidence. Never emit the complete generated code for a full page or other large frame/node into model context. When transient storage is available, cache the raw text under a key tied to the Figma file and frame node.
- Emit a compact structured digest rather than raw dumps. Preserve the selected frame name/ID and dimensions, major region hierarchy and bounds, visible text, typography, colors, effects, asset role-to-URL mappings, chart/table geometry, relevant states, and design annotations. Preserve exact source snippets only when they are small and materially required.
- For follow-up, scoped work, or QA gaps, reuse existing screenshots, measurements, inventories, exports, caches, and digests first. If a fact is still missing, extract the smallest relevant cached fragment before querying the smallest relevant descendant node/property. Do not re-emit the whole frame response.
- When multiple screens are requested, a single minimal locator pass may identify frame names, node IDs, dimensions, and implementation order. Sequential processing is the default: only one frame may be active for detailed work at a time, and later frames must not be prefetched before the active frame completes evidence collection, asset inventory, implementation, build, and required visual QA.
- If the user explicitly requests multi-agent parallel implementation, read `references/figma-mcp-parallel.md` before assigning frames or fetching detailed design content for concurrent work.
- When missing in-scope asset or font facts appear, follow `references/asset-fidelity.md`.

## UE Communication Patterns

Select the UE communication pattern by inspecting the target project's existing bridge code. Do not mix protocols or assume a bridge without checking the repo.

- Prefer the repo's existing UE wrapper such as `ue.emit(...)`; do not invent a new global bridge when the project already has one.
- Keep frontend UI state and UE events synchronized. When a visible scene/tool control is clicked, update the local selected/open state and send the matching UE command.
- Treat top navigation and mutually exclusive scene tools as single-selection groups by default unless the source design or existing project behavior shows otherwise.
- Register UE-to-frontend callbacks only when the project bridge supports them, keep page-scoped callbacks lifecycle-safe, and clean them up on unmount where applicable.
- Send a page/app `ready` event only after required frontend callbacks are registered, when the selected bridge uses a ready handshake.
- If the project uses WebUI / `ue5(...)`, read `references/ue-webui-plugin.md` for implementation examples.
- If the project uses `WebViewEnhancedByCengJia` / `window.ue.web`, read `references/ue-webview-enhanced.md` for implementation examples.
- If the project uses Pixel Streaming, WebSocket, `postMessage`, or another bridge, inspect that bridge first and follow its existing contract.


## Interaction and State

- Implement controls that are part of the requested/core flow or are clearly interactive in the source. Purely decorative or status-only elements may remain non-interactive; document any visually control-like exception in QA.
- Treat repeated controls as component families. Implement normal and selected/current variants for the whole family, plus hover, focus, disabled, loading, empty, success, or error states when implied by the design or core flow.
- Keep hover-, click-, focus-, expanded-, drill-down-, tooltip-, and popover-only content hidden in the default state unless the source explicitly shows it active by default.
- Identify and wire the correct trigger for every revealed layer. If ambiguous, infer from hierarchy and document the assumption in `design-qa.md`.
- Tabs, filters, legends, tables, menus, and UE controls included in the core flow must update visible local state; UE controls must also follow the selected bridge contract.
- QA must verify a clean default state and at least one triggered-state capture whenever interaction-revealed content is in scope.

## Asset and Font Preparation

For Figma/screenshot/mockup-driven visual reconstruction, read `references/asset-fidelity.md` before implementation and follow its blocking gates. This is mandatory for new full-page builds and for any scoped change where source-specific static visuals, finite-state controls, icons, decorative chrome, logos, rare title lettering, scene imagery, or fonts affect fidelity.

For narrow non-visual edits or small changes inside an existing page, apply the asset/font process only to the affected regions and nearby dependent layout. Reuse existing inventories, exports, screenshots, and font evidence when they already answer the affected question.

Keep the core rule in mind: source-specific static and finite-state visuals prefer Figma exports or exact repo assets; CSS/SCSS and ECharts are for basic layout primitives, live text, data-driven marks, and runtime-variable states unless the asset inventory documents a concrete reason.
## First Steps

1. Inspect the target repo before editing. Confirm it is HJGWeb-like by checking for `zf-dbs`, `src/config/index.ts`, `PageScreen`, `PageCard`, `PageTable`, and `VueEcharts`.
2. Read `references/hjgweb-patterns.md` before implementing non-trivial page, card, chart, table, video, or UE interaction work.
3. Resolve the exact visual target before building. Prefer a Figma frame/node, screenshot, or mockup over a written brief. If the target cannot be inferred from the request, existing page, or available visual evidence, ask for the exact frame or image.
4. Read the project canvas values from `src/config/index.ts`, compare them with the selected Figma frame or screenshot size, and decompose the source into major layout regions before choosing dimensions, assets, or conversion ratios.
5. For Figma/screenshot/mockup-driven work, complete the relevant asset/font preparation from `references/asset-fidelity.md` before page construction.
6. For a new full dashboard or layout-sensitive change, inspect the actual scaling/layout shell and create or update `adaptation-contract.md` before coding. Scoped non-layout changes may reuse the existing contract and record only affected-region risk.
7. Prefer existing project components, generated routes, auto-imports, local assets, mock-data patterns, polling helpers, animation/count-up conventions, and UE bridge code before adding new abstractions.
## Visual Source Requirements

- Treat the supplied visual as the fidelity target subject to explicit user and runtime constraints. Preserve its hierarchy, density, region proportions, typography, colors, spacing, chart/table geometry, and interaction states; document necessary deviations.
- Decompose and measure major regions before coding. Do not simplify dense dashboard areas into generic cards, empty panels, or unrelated grids.
- Preserve the center UE/3D scene role and reproduce its designed overlays, masks, controls, labels, legends, callouts, minimaps, and drill-down UI.
- Follow `Screen Adaptation Model` for width changes and `Asset and Font Preparation` for every visible source asset; do not restate those policies at page level.

## Implementation Workflow

1. Add or edit pages under `src/pages/*.vue`; rely on generated file-system routes and default layout.
2. Compose every full dashboard page with `PageScreen` slots: `left`, `middle`, and `right` when that matches or can faithfully carry the source layout.
3. Wrap side-panel content in `PageCard`; keep card contents self-contained and scoped.
4. Use `PageTable` for dashboard lists and `VueEcharts` for charts.
5. Use `usePolling` or `usePollingRef` for periodically refreshed data, matching the repo's current mock/seeded-data pattern when no real API exists.
6. Use `ue.emit(...)` for scene controls, following `UE Communication Patterns` and the matching plugin subsection. Treat top navigation menus as a single mutually exclusive group by default; confirm grouping for other controls before implementing toggle state.
7. Match existing scoped SCSS, BEM-like class names, local image assets, and `ZfTweenNumber`; take colors, fonts, chart density, and decorative styling from the actual design for the current page/project.
8. Implement and verify the in-scope controls and variants defined by `Interaction and State`, using realistic mock data when no real API exists.
9. Do not create new routes, auth, persistence, backend integrations, or broad product behavior unless requested. Keep the implementation scoped to the requested DPWeb screen and its visible states.
10. Do not begin component layout with missing, duplicated, screenshot-derived, or uninspected required in-scope assets unless the asset source is genuinely blocked. If blocked, use a clearly documented temporary fallback and mark visual QA as blocked until the asset issue is resolved.
11. Implement screen adaptation in the shared layout/screen shell when the current repo behavior conflicts with the required model. Do not leave responsive behavior as an unverified assumption inside an individual page.
12. Generate a standalone local HTML artifact only when the user explicitly requests an offline version, single-file HTML, or equivalent deliverable. After the page implementation and its normal browser/build QA are complete, read and follow `references/offline-single-html.md`, then report the output path in the handoff. Do not generate this artifact by default.

## Hard Rules

- Keep the design baseline at the project config values unless the user asks to change sizing: `appWidth`, `appHeight`, and `useScale` live in `src/config/index.ts`.
- Treat the center area as the UE/3D scene surface. Put only overlays, bottom-right control buttons, or contextual drill-down UI there.
- Use the source design's panel widths, gutters, and card positions when Figma/screenshot data is available. Keep left/right panels approximately `400px` wide through `PageScreen` only as a DPWeb default fallback when the source does not specify a clearer layout.
- Use fixed px dimensions and scoped SCSS for design-fidelity screen elements; UnoCSS utility classes are acceptable where the repo already uses them.
- Do not stretch, squeeze, non-uniformly scale, or reflow UI elements to fill unusual aspect ratios. Use elastic spacing and scene/background expansion or contraction while keeping UI components visually intact.
- Do not let default DPWeb proportions or generic components override a clearly measured source composition.
- Follow `Interaction and State` for selected/current variants and `Asset and Font Preparation` plus `Asset Gate Is Blocking` for source-specific visuals.
- Do not hand off with missing visual assets, placeholder regions, clipped text, horizontal overflow, broken control states, or obvious mismatch in major-region proportions.
- Do not invent real API integrations when the existing module is mock-only. If adding real data access, create focused modules under `src/service` and keep component state shapes stable.
- When using Element Plus, style it through scoped `:deep(...)` overrides as existing cards do.
- For video, reuse `VideoPlay`; do not hand-roll HLS/FLV playback.

## Asset Gate Is Blocking

For Figma/screenshot/mockup-driven full-page visual reconstruction, the asset gate in `references/asset-fidelity.md` is blocking. A static-only, prototype, or newly scaffolded workspace does not relax the gate when the task is visual reconstruction.

For scoped visual edits, apply the same gate to the affected source-specific static visuals and finite-state assets only. For non-visual logic, copy, data, or wiring changes, do not require a full-page asset inventory unless the change exposes or alters visual fidelity.

If an in-scope required asset cannot be exported, reused, or inspected, record it as `blocked` in `asset-inventory.md`, write `design-qa.md` with `final result: blocked`, and tell the user what prevents final fidelity.

## Offline Single-HTML Packaging

When the user explicitly requests a standalone offline HTML artifact, read and follow `references/offline-single-html.md`. Do not run the packaging procedure otherwise. Keep the packaging procedure in that reference rather than duplicating it in this file.
## Output Shape

- The result should be a runnable DPWeb/HJGWeb-style Vue page, not a static screenshot approximation.
- The implemented page should use the repo's real layout, route generation, cards, tables, charts, polling helpers, animation/count-up components, assets, and UE event bridge conventions.
- The page should visually match the selected Figma frame/screenshot after any documented canvas conversion, with the same primary interaction state available for review.
- Keep mock data realistic and stable enough that chart/table density, labels, and number formatting look like the design.
- Leave the local dev server running when feasible and provide the local URL in Codex Desktop handoff.

## Validation

Visual QA is a blocking gate for Figma/screenshot/mockup-driven work; build success alone is not enough. Select one QA level before validation and escalate when observed impact exceeds the chosen scope. QA level never relaxes `Asset and Font Preparation`, `Asset Gate Is Blocking`, or the required DPWeb architecture.

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






