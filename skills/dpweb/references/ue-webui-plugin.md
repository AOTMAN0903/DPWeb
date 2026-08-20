# UE WebUI Plugin Communication

Use this reference when a DPWeb/HJGWeb page communicates with Unreal Engine through the WebUI plugin / UE Web Browser bridge that provides `ue.interface.broadcast` and the `ue5(...)` helper.

## Runtime Contract

- The page must load the standard WebUI bootstrap script before the Vue app code.
- The bootstrap creates or reuses `window.ue`, `window.ue.interface`, and `window.ue5`.
- Frontend-to-UE calls go through `ue5(eventName, payload?, callback?, timeoutSeconds?)`.
- UE-to-frontend calls go through functions assigned to `window.ue.interface`.
- Send `ready` after frontend functions are registered, so UE knows it can call back into the page.

## Frontend To UE

Use bare commands only when there is no payload:

```ts
window.ue5?.('ready')
window.ue5?.('play')
window.ue5?.('quit')
```

Use one object payload for almost all DPWeb business events:

```ts
window.ue5?.('volume', { value: 0.5 })
window.ue5?.('station', { berthNo: '309', expanded: true })
window.ue5?.('device-focus', {
  id: 'pump-001',
  source: 'equipment-page',
  action: 'focus'
})
```

Avoid new positional-argument contracts unless the UE side already expects them:

```ts
// Supported by the bridge, but not preferred for new work.
window.ue5?.('station', '309', true)
```

Recommended helper:

```ts
type UEPayload = Record<string, unknown>

export function emitUE(name: string, payload?: UEPayload) {
  if (payload === undefined) {
    window.ue5?.(name)
    return
  }
  window.ue5?.(name, payload)
}
```

If the project already uses `zf-dbs` and wires `ue.emit(...)` to `window.ue5`, prefer the project wrapper:

```ts
ue.emit('volume', { value: 0.5 })
ue.emit('station', { berthNo: '309', expanded: true })
```

## Tool Toggle Pattern

For mutually exclusive UE tools, close the previous tool before opening the next one. Always keep Vue state and UE state aligned.

```ts
const activeTool = ref('')

function toggleUETool(name: string) {
  if (activeTool.value) {
    emitUE(activeTool.value, { enabled: false })
  }

  activeTool.value = activeTool.value === name ? '' : name

  if (activeTool.value) {
    emitUE(activeTool.value, { enabled: true })
  }
}

onUnmounted(() => {
  if (activeTool.value) {
    emitUE(activeTool.value, { enabled: false })
  }
})
```

## UE To Frontend

Expose frontend functions on `window.ue.interface`. Register page-scoped functions on mount and remove them on unmount.

```ts
declare global {
  interface Window {
    ue?: {
      interface?: Record<string, (...args: any[]) => void>
    }
    ue5?: (name: string, payload?: unknown, callback?: Function, timeoutSeconds?: number) => void
  }
}

const fps = ref(0)
const volume = ref(0.5)
const deviceStatus = ref<unknown>(null)

onMounted(() => {
  window.ue ||= {}
  window.ue.interface ||= {}

  window.ue.interface.setFPS = (value: number) => {
    fps.value = value
  }

  window.ue.interface.setVolume = (value: number) => {
    volume.value = value
  }

  window.ue.interface.setDeviceStatus = (payload: unknown) => {
    deviceStatus.value = payload
  }

  emitUE('ready')
})

onUnmounted(() => {
  delete window.ue?.interface?.setFPS
  delete window.ue?.interface?.setVolume
  delete window.ue?.interface?.setDeviceStatus
})
```

## Callback Pattern

The WebUI bootstrap supports callback registration by passing a function to `ue5`. Use this only when the UE side is known to call the callback id.

```ts
window.ue5?.(
  'request-device-status',
  { id: 'pump-001' },
  (result: unknown) => {
    deviceStatus.value = result
  },
  10
)
```

The last number is the callback retention time in seconds. Keep it short and avoid relying on callbacks for long-lived subscriptions; use `window.ue.interface.xxx` for persistent UE-to-frontend events.

## Ready Sequence

Use this order for app or page initialization:

1. Load WebUI bootstrap in HTML before the Vue app script.
2. Mount Vue page.
3. Register `window.ue.interface.xxx` functions needed by the page.
4. Emit `ready`.
5. Let UE push initial state through the registered frontend functions.

## Payload Rules

- Use JSON-serializable data only: strings, numbers, booleans, arrays, plain objects, and null.
- Do not pass Vue refs, proxies, DOM nodes, class instances, functions, Dates, Maps, Sets, or circular objects as payload values.
- Use stable field names that describe business meaning: `berthNo`, `deviceId`, `enabled`, `action`, `source`, `value`.
- Include `source` when multiple pages can emit the same UE event.
- Keep command events verb-like, such as `device-focus`, `tool-toggle`, `camera-reset`, or follow the existing UE contract exactly.
