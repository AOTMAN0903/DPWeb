# DPWeb Asset Fidelity

Use this reference for Figma, screenshot, mockup, or visual-reconstruction work where source-specific static visuals affect fidelity. For narrow edits, apply it only to the affected region and nearby dependent layout.

## Blocking Gate

Before page layout or component implementation, inventory, export or locate, inspect, and map the required visual assets and fonts for the in-scope source design.

For a full page, create or update `asset-inventory.md` before coding. For scoped edits, update or create the inventory only for the affected visual regions. If an existing inventory already contains the needed evidence, reuse it and record only new or changed items.

Do not call Figma/screenshot/mockup-driven visual reconstruction `passed`, `done`, `complete`, `ready`, or handoff-ready while `asset-inventory.md` is missing, or while any required Figma-exportable or exact repo-reusable static visual remains implemented as CSS, text, generic icon, hand-written SVG, or other approximation.

If required source assets cannot be exported or located because of tooling, permissions, Figma access, or source ambiguity, record each item as `blocked` in `asset-inventory.md`, write `design-qa.md` with `final result: blocked`, and report the blocker to the user.

## Inventory Scope

Walk the full source design for new full-page builds. For scoped edits, walk the affected regions and dependent nearby layout. Record one row per required asset or composed visual element:

- design location
- implementation role
- source type: `Figma export`, `repo asset`, `CSS/SCSS`, `ECharts`, `icon library`, `generated/created`, `screenshot fallback`, or `blocked`
- output path or component target
- required states
- chosen file format
- crop, transparency, scale, or substitution notes

Every visible static or finite-state icon, title mark, decorative chrome, status marker, control background, miniature visual component, logo, brand mark, rare special-font text asset, panel ornament, chart chrome, and scene/background asset in scope must be listed. Default these entries to `Figma export` or `repo asset`.

## Asset Selection

Prefer direct Figma exports or exact repo assets over screenshots whenever a layer, component, frame, image fill, vector, or asset node is available. Screenshots are acceptable only when the source cannot expose the asset separately, no original image exists, or the user only provided a screenshot.

For static composed visuals, prefer exporting the whole visual group as one SVG asset when child layers depend on Figma transforms, clipping, filters, masks, shadows, rotations, or `preserveAspectRatio` behavior. Split a composed visual only when part of it is data-driven, changes at runtime, has independent finite states, or is independently animated/interacted with.

Prefer SVG for vectors, components, instances, icons, decorative chrome, finite-state control backgrounds, status markers, title marks, and other non-photo visuals. Use PNG only for inherently raster imagery such as photos, screenshots, bitmap textures, or image fills that cannot be meaningfully exported as vectors. If downloaded bytes are SVG, save and reference them as `.svg` even if the URL or filename suggests `.png`.

Export or reuse each distinct source-specific icon. Do not export one icon and reuse it for another role unless the source design truly uses the same symbol.

Use project iconfont/SVG/icon assets only when they exactly match the source. Use an icon library only for standard UI icons when no source or repo asset exists. Do not replace source-specific icons with generic approximations when Figma/repo assets are available.

Treat logos, brand marks, fixed title marks, stylized system names, and rare custom letterforms as assets when export gives higher fidelity with lower implementation cost. Do not recreate them with plain text, CSS lettering, emoji, approximate fonts, or ad hoc SVG unless the project already uses that exact pattern.

Do not export ordinary repeated module titles as images merely because the text is static. If the typography repeats across cards, panels, tables, or navigation labels, implement it with the correct font/style tokens.

## CSS And Runtime Rendering

CSS, SVG, Canvas, ECharts, or rendered primitives are appropriate for:

- data-driven charts and graph marks
- dynamic progress values, widths, colors, thresholds, and calculated runtime values
- simple runtime-controlled table states such as hover, selected, focus, loading, disabled, empty, success, and error
- runtime status coloring when the shape is simple and the inventory documents why rendering is necessary
- basic layout containers, text, translucent masks, simple backgrounds, simple borders, ordinary spacing, simple dots, simple separators, and simple glows

Prefer exported or repo assets for:

- static icons and semantic symbols
- decorative title marks, title icons, card chrome, panel ornaments, and fixed divider ornaments
- finite-state buttons, tabs, segmented controls, filter chips, and scene-tool backgrounds, including normal/selected/current variants
- fixed-enum status badges, markers, and icons such as inbound/outbound, safe/danger, online/offline, warning/error, and similar business states
- non-data decorative chart chrome, chart frame artwork, special legend icons, and ornamental chart backgrounds
- complex panel ornaments, tank/container shells, miniature fixed widgets, map pins, callout chrome, custom gauges, and non-standard visual widgets

Charts are the main exception: chart marks, axes, grids, and data-driven shapes may be rendered by ECharts/SVG/Canvas/CSS. Static chart chrome, title icons, frame artwork, special legend icons, decorative backgrounds, and fixed ornaments around charts still prefer Figma or repo assets.

If a CSS approximation is used for any static or finite-state visual that would normally be exported, record the concrete dynamic requirement or export blockage in `asset-inventory.md`.

## Fonts

Before implementation, prepare a compact font inventory for the in-scope source:

- source font
- required weights/styles and numeric styles
- project or local match
- fallback or download status
- substitution risk

If a required font is missing, first look for an existing project font or bundled asset. If none exists and network/access is available, download an appropriate licensed/free font or choose a visually close fallback. Document substitutions in `design-qa.md`.

## Placement And Inspection

Place exported or created assets in the repo's established asset folders and use the repo's import/path conventions. Use descriptive role names such as `logo-hapco`, `nav-selected-bg`, `ue-action-selected`, `panel-title-icon`, or `scene-port-bg`.

After assets are placed, inspect crop, transparency, scale, sharpness, and visual fit before wiring them into components.

For UE/3D scene areas, use the live UE surface when available. If implementing a static visual fallback from Figma, use the actual scene or screenshot asset rather than a blank gradient or generic placeholder.