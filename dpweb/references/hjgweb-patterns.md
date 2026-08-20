# DPWeb Implementation Patterns

## Architecture Snapshot

- Vue 3 + TypeScript + Vite, with `zf-dbs-vite` wrapping Vite configuration.
- `src/main.ts` imports authorization placeholder, `virtual:uno.css`, `@/config`, global SCSS, and `animate.css`, then mounts `App`.
- `src/App.vue` wraps the route outlet in `ZfApp`.
- Routing uses `createWebHashHistory`, `virtual:generated-pages`, and `virtual:generated-layouts`; adding `src/pages/foo.vue` creates `/foo`.
- `src/layouts/default.vue` renders `components/AppLayout`.
- `src/service/index.ts` auto-globs sibling service modules, but the current project mostly keeps mock data inside components.
- Auto-imports are expected: Vue, VueUse, `zf-dbs`, router helpers, `service`, and global components are available without explicit imports.

## Screen Sizing

- The project uses a fixed design canvas and whole-screen scaling through `ZfApp`/`zf-dbs`.
- Default config: `appHeight: 1080`, `appWidth: 1600`, `useScale: true`.
- Business components use fixed px sizes. Do not redesign them as mobile-first responsive components.
- `PageScreen` establishes the page geometry:
  - top content offset: about `45px`
  - side panel width: about `400px` plus side margin
  - side panel height: about `920px`
  - middle area flexes between the two side panels
- UE-specific entries in `ue-web/*` reuse `src/main.ts` and override config/style for no-scale or no-background embedding.

## Page Layout Pattern

Use this shape for a new full page:

```vue
<template>
  <PageScreen>
    <template #left>
      <PageXxxLeftCard1 />
      <PageXxxLeftCard2 />
    </template>

    <template #middle>
      <div class="absolute bottom-0 right-0">
        <!-- UE controls or overlays -->
      </div>
    </template>

    <template #right>
      <PageXxxRightCard1 />
      <PageXxxRightCard2 />
    </template>
  </PageScreen>
</template>
```

Keep full-page files as composition shells. Put actual UI logic in card components under `src/components`.

## Card Pattern

- Use `PageCard header="..."` for every side-panel module.
- Use the `header-right` slot for tabs, "全部" buttons, or compact filters.
- Keep card styles `scoped` and use BEM-like class names such as `.cargo-left-card1__summary`.
- Use `ZfTweenNumber` for changing numbers.
- Use local PNG/SVG assets for ornamental backgrounds, status icons, and button frames.

## Table Pattern

Use `PageTable` for dashboard lists:

```vue
<PageTable
  :thead-col="theadCol"
  :data-list="dataList"
  :show-head="true"
  :limit-scroll="10"
/>
```

- `theadCol` items use `{ key, name, width?, align? }`.
- Use slots named after column keys for custom cells.
- Set `show-head="false"`, `row-height`, `row-gap`, `row-padding-x`, and `row-align="flex-start"` for card-like alarm feeds.
- `limitScroll` enables automatic vertical scrolling when rows exceed the visible count.

## Chart Pattern

- Use `VueEcharts :option="chartOption"`.
- Build `chartOption` with `computed`.
- Take colors, typography, spacing, grid density, gradients, and tooltip presentation from the actual design for the page being implemented. Do not hard-code the HJGWeb cyan palette or compact grid as a universal rule.
- Keep the code pattern consistent even when the visual treatment changes: computed option, concise data mapping, clear units, and reusable chart container sizing.
- `VueEcharts` already registers common ECharts chart/component types and handles resize.

## Data Pattern

- Use `usePollingRef(async () => data, fallback)` for simple ref-like state.
- Use `const { state, execute } = usePolling(async () => data, fallback)` when tabs or controls need manual refresh.
- Use `SeededRandom` from `zf-utilz` for mock values when no API exists.
- Keep explicit TypeScript types near the component using them.
- Do not add global state management unless the feature genuinely needs shared state.

## UE Interaction Pattern

Always confirm the intended control grouping before implementing UE state. Some projects/pages allow several controls to be active at once; some define one or more mutually exclusive groups.

Top navigation menus are a single mutually exclusive group by default. When switching from one top menu to another, trigger the previous menu's close event before opening the newly clicked menu. Follow the host project's event naming/API; if the current code hides that close behavior in UE or a shared bridge, preserve that contract instead of adding a second conflicting close mechanism.

Current HJGWeb page-bottom buttons use a single mutually exclusive group per page. The pattern is:

- store one `activeBtn` value for the group
- when clicking a different button, emit `false` for the previously active button
- set the new active value
- emit `true` for the newly active button
- when clicking the active button again, clear it and emit `false`
- on unmount, emit `false` for anything still active

```ts
const activeBtn = ref('')

const handleActiveBtn = (btn: { value: string }) => {
  if (activeBtn.value) ue.emit(activeBtn.value, false)
  activeBtn.value = activeBtn.value === btn.value ? '' : btn.value
  if (activeBtn.value) ue.emit(activeBtn.value, true)
}

onUnmounted(() => {
  if (activeBtn.value) ue.emit(activeBtn.value, false)
})
```

Use this exact close-previous behavior only for a mutually exclusive group.

For independent toggles, store state per button, for example a `Set<string>` or record, and do not close unrelated buttons:

```ts
const activeBtns = ref(new Set<string>())

const handleToggleBtn = (btn: { value: string }) => {
  const next = new Set(activeBtns.value)
  const opening = !next.has(btn.value)
  if (opening) next.add(btn.value)
  else next.delete(btn.value)
  activeBtns.value = next
  ue.emit(btn.value, opening)
}

onUnmounted(() => {
  for (const value of activeBtns.value) ue.emit(value, false)
})
```

For multiple mutually exclusive groups, keep one active value per group and only close the previous button inside the same group:

```ts
type GroupKey = 'view' | 'analysis'
const activeByGroup = ref<Record<GroupKey, string>>({ view: '', analysis: '' })

const handleGroupedBtn = (btn: { value: string, group: GroupKey }) => {
  const oldValue = activeByGroup.value[btn.group]
  if (oldValue) ue.emit(oldValue, false)
  activeByGroup.value[btn.group] = oldValue === btn.value ? '' : btn.value
  const nextValue = activeByGroup.value[btn.group]
  if (nextValue) ue.emit(nextValue, true)
}
```

When requirements are unclear, ask whether the controls are independent, one mutually exclusive group, or several mutually exclusive groups.

Use existing event naming style: short pinyin-like event ids such as `bowei`, `quyu`, `fengxian`, `shebei`, `guandao`.

For navigation from UE:
- `AppLayout` listens for `device-detail-to` and routes to `/device-detail`.
- detail pages can emit a back event such as `device-detail-back` on unmount.

## Video Pattern

- Use `VideoPlay` for actual streams.
- It chooses HLS for `.m3u8`, FLV for `.flv`, and native `<video>` otherwise.
- For video preview grids, match `PageSafetyRightCard3`: image thumbnail, corner lines, caption gradient, compact two-column layout.

## Styling Pattern

- Use scoped SCSS for component-specific visuals; utility classes may be mixed in for spacing and quick layout.
- Use BEM-like class names and local assets as the existing project does.
- Do not preserve HJGWeb fonts, colors, palette, chart density, or decorative effects as universal requirements. Follow the current design draft and project style instead.
- Keep layout mechanics and component composition consistent even when the visual skin changes.

## Common Pitfalls

- Do not forget `onUnmounted` UE cleanup for toggle controls.
- Do not assume UE controls are mutually exclusive. Ask or use the provided grouping requirement.
- Do not place heavy UI cards in the center over the UE scene unless the design calls for a contextual overlay.
- Do not add a manual route entry for ordinary pages; generated routes handle `src/pages`.
- Do not assume the date picker filters data just because UI exists; implement the filtering explicitly.
- Do not reference missing assets when copying old Element Plus styles; verify asset paths.
- Do not force HJGWeb's original palette, fonts, or chart spacing onto a different design.
