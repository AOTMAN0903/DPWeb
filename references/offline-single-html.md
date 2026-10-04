# Offline Single-HTML Packaging

Use this procedure only when the user explicitly requests an offline version, single-file HTML, or equivalent deliverable, and after normal page implementation, browser QA, type checks, and production-build checks are complete.

## Required outcome

- Generate one standalone local HTML artifact only when the user explicitly requests an offline version, single-file HTML, or equivalent deliverable. Do not generate it by default.
- Keep the editable Vue source and normal production build. The standalone HTML is a delivery artifact, not the source of truth.
- Report the generated file path in the handoff.

## Build procedure

Use `scripts/build-single-html.mjs`. It builds the Vite project and inlines local CSS, JavaScript chunks, PNG/SVG images, fonts, audio, and video referenced by the selected built HTML entry.

Run it from the target project directory:

```text
node C:\Users\8888\.codex\skills\dpweb\scripts\build-single-html.mjs --entry <built-entry.html> --output dist/<name>.html
```

Useful options:

- `--project <dir>`
- `--dist <dir>`
- `--entry <file>`
- `--output <file>`
- `--build-command <command>`
- `--no-build`

For repeatable user-side packaging, add or reuse a package script:

```json
{
  "scripts": {
    "build:single": "node C:\\Users\\8888\\.codex\\skills\\dpweb\\scripts\\build-single-html.mjs --entry dashboard.html --output dist/dashboard-offline.html"
  }
}
```

## Completion rule

- A zero script exit code plus an existing, non-empty output file completes packaging.
- Do not open the generated `file://` URL, repeat interaction/console QA, or run an additional offline/static-inlining audit unless the user explicitly asks to test, validate, inspect, or troubleshoot the standalone HTML.
- Requested single-HTML generation is not a separate visual-QA scope and must not prolong handoff after the script succeeds.

## Runtime boundaries

Inlining local build assets does not make external APIs, remote fonts/media, WebSockets, UE bridges, authentication, or browser-blocked `file://` fetches offline. Report any such known dependency without adding unrequested offline validation.
