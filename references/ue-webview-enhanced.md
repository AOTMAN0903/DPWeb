# UE WebViewEnhanced Communication

Use this reference when a DPWeb/HJGWeb page communicates with Unreal Engine through the `WebViewEnhancedByCengJia` plugin, whose sample page exposes `window.ue.web`.

## Runtime Contract

- The plugin injects `window.ue.web` into the browser page.
- Frontend-to-UE calls directly invoke functions on `window.ue.web`.
- UE-to-frontend calls directly invoke globally available JavaScript functions on the page.
- This is not the WebUI `ue5(eventName, payload)` event bridge. Do not use `ue5(...)` unless the project also includes the WebUI bootstrap.

## Frontend To UE

Call UE functions through `window.ue.web.<functionName>(...args)`.

```ts
window.ue?.web?.js_call_ue_no_param?.()
window.ue?.web?.js_call_ue_with_params?.('dse', 12)
```

Recommended helper for page code:

```ts
type UEWebViewEnhanced = Record<string, (...args: unknown[]) => unknown>

function callUE(name: string, ...args: unknown[]) {
  const web = window.ue?.web as UEWebViewEnhanced | undefined
  const fn = web?.[name]
  if (typeof fn !== 'function') {
    return undefined
  }
  return fn(...args)
}

callUE('js_call_ue_no_param')
callUE('js_call_ue_with_params', 'dse', 12)
```

For DPWeb business controls, make the UE function names explicit and stable:

```ts
callUE('set_tool_enabled', 'guandao', true)
callUE('focus_station', '309')
callUE('focus_device', 'pump-001')
callUE('open_menu', 'equipment')
```

Use positional arguments when the UE function signature expects them. If the UE function expects JSON, stringify explicitly and document that contract:

```ts
callUE('set_scene_state', JSON.stringify({
  source: 'equipment-page',
  tool: 'guandao',
  enabled: true
}))
```

## Tool Toggle Pattern

For mutually exclusive scene tools, close the previous UE function state before opening the next.

```ts
const activeTool = ref('')

function setToolEnabled(name: string, enabled: boolean) {
  callUE('set_tool_enabled', name, enabled)
}

function toggleUETool(name: string) {
  if (activeTool.value) {
    setToolEnabled(activeTool.value, false)
  }

  activeTool.value = activeTool.value === name ? '' : name

  if (activeTool.value) {
    setToolEnabled(activeTool.value, true)
  }
}

onUnmounted(() => {
  if (activeTool.value) {
    setToolEnabled(activeTool.value, false)
  }
})
```

## UE To Frontend

Expose functions on `window` so UE can call them by name. The sample uses plain global functions:

```js
function CallJsNoParam() {
  alert('UECallJsNoParam')
}

function CallJsWithParams(p1, p2) {
  alert('UECallJsWithParams param1=' + p1 + ' param2=' + p2)
}
```

In Vue/TypeScript, register page-scoped functions on mount and remove them on unmount:

```ts
declare global {
  interface Window {
    ue?: {
      web?: Record<string, (...args: unknown[]) => unknown>
    }
    CallJsNoParam?: () => void
    CallJsWithParams?: (p1: string, p2: number) => void
    SetDeviceStatus?: (payload: unknown) => void
  }
}

const deviceStatus = ref<unknown>(null)

onMounted(() => {
  window.CallJsNoParam = () => {
    // Update Vue state or trigger UI behavior.
  }

  window.CallJsWithParams = (p1, p2) => {
    // Handle UE parameters.
  }

  window.SetDeviceStatus = (payload) => {
    deviceStatus.value = payload
  }

  callUE('frontend_ready')
})

onUnmounted(() => {
  delete window.CallJsNoParam
  delete window.CallJsWithParams
  delete window.SetDeviceStatus
})
```

## Ready Sequence

The sample does not include an automatic ready event, but DPWeb pages should still use a project-level convention:

1. Load the page in WebViewEnhanced.
2. Mount Vue.
3. Register global UE-callable functions on `window`.
4. Call a UE function such as `frontend_ready` if the UE side provides one.
5. Let UE call the registered global functions to push initial state.

## Payload Rules

- Match the UE function signature exactly; this bridge is function-call based, not event-name based.
- Prefer simple JSON-serializable arguments: strings, numbers, booleans, arrays, plain objects, and null.
- If object arguments are unreliable in the target plugin/runtime, pass `JSON.stringify(payload)` and parse it in UE.
- Avoid passing Vue refs, proxies, DOM nodes, functions, Dates, Maps, Sets, or circular objects.
- Keep global JS callback names unique enough to avoid collisions, such as `DPWeb_SetDeviceStatus` instead of generic names on shared pages.
