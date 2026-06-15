# Desktop Application Template

## Overview
Use this template for cross-platform desktop apps built with Electron or Tauri. Suited for teams that need native OS integration (file system, notifications, tray), offline-first behavior, and auto-update delivery — while reusing web-stack skills. Choose Electron for the widest ecosystem and quickest ramp-up; choose Tauri for a smaller binary and better memory footprint with a Rust backend.

## Recommended Architecture Options
- **Electron (main + renderer process)** — Mature ecosystem, large binary (~80 MB), Chromium bundled; ideal when team is JS-only.
- **Tauri (Rust core + WebView)** — Tiny binary (~5 MB), lower RAM, Rust required for native logic; ideal for performance-sensitive tools.
- **Electron + React + Vite** — Best DX with hot-reload in dev; most common production setup as of 2025.

## Recommended Frameworks & Platforms
| Layer | Options |
|---|---|
| Shell | Electron 30+, Tauri 2+ |
| UI | React + Tailwind, Svelte, Vue |
| Build / bundle | Vite, esbuild |
| Auto-update | electron-updater (electron-builder), Tauri built-in updater |
| IPC | Electron contextBridge + ipcMain/ipcRenderer, Tauri commands |
| Persistence | SQLite (better-sqlite3 / rusqlite), lowdb, electron-store |
| Native OS | node-notifier, shell-open, Tauri plugins |
| Code signing | electron-builder + Apple Developer ID / Windows EV cert |
| Packaging | electron-builder, electron-forge, cargo-tauri |

## Required Components
- Main process / Rust core: window management, IPC handlers, file I/O
- Renderer: isolated web UI, no direct Node access (contextIsolation: true)
- Preload script: safe bridge exposing only needed APIs to renderer
- Auto-updater: checks update server on launch, downloads in background, prompts user
- Crash reporter: Sentry or electron-log for uncaught exceptions in both processes
- Tray icon + context menu (if background process needed)
- Secure storage for credentials (keytar / OS keychain)
- Deep-link handler (custom URL scheme, e.g. `myapp://`)

## Security Checklist
- [ ] `contextIsolation: true` and `nodeIntegration: false` on every BrowserWindow
- [ ] Preload exposes minimal surface area via `contextBridge.exposeInMainWorld`
- [ ] All external URLs open in default browser (`shell.openExternal`), never in app window
- [ ] CSP header set on loaded HTML (`Content-Security-Policy`)
- [ ] Auto-update channel verified with code signature before install
- [ ] App signed and notarized (macOS) / signed with EV cert (Windows)
- [ ] No secrets stored in renderer or bundled JS — use OS keychain via main process
- [ ] `webSecurity: true` (never disable in production)
- [ ] Dependencies audited: `npm audit` / `cargo audit` in CI

## Testing Checklist
- [ ] Unit tests for main-process logic (Vitest / Jest)
- [ ] Unit tests for preload API shape
- [ ] Integration tests with Spectron or Playwright (Electron Playwright driver)
- [ ] IPC round-trip tests (mock main process in renderer tests)
- [ ] Auto-update flow tested against a local update server (electron-builder's `publish: generic`)
- [ ] Manual smoke test on all target OS versions (macOS 13+, Windows 10/11, Ubuntu 22+)
- [ ] Deep-link registration tested on each platform

## Deployment Checklist
- [ ] Version bumped in `package.json` / `Cargo.toml` before release
- [ ] Release build compiled with production env vars (no devtools)
- [ ] Binaries signed and notarized before upload
- [ ] Update manifest (`latest.yml`) published to update server / S3 / GitHub Releases
- [ ] Delta updates configured to minimize download size
- [ ] Release notes written (used by auto-updater UI)
- [ ] Rollback plan: keep previous version on update channel until stable confirmation
- [ ] Crash reporting DSN points to production project

## Starter Templates

| Option | Description | Recommended |
|---|---|---|
| [tauri-apps/create-tauri-app](https://github.com/tauri-apps/create-tauri-app) | Tauri 2.0 CLI scaffolding tool, Rust backend + any JS frontend | ✅ Best pick |
| [electron/electron-quick-start](https://github.com/electron/electron-quick-start) | Official Electron minimal starter | |
| [tauri-apps/tauri/examples](https://github.com/tauri-apps/tauri/tree/dev/examples) | Official Tauri examples with different frontend frameworks | |

**Best Pick:** [tauri-apps/create-tauri-app](https://github.com/tauri-apps/create-tauri-app) — Smaller bundle than Electron, better security model, modern Tauri 2.0 with official CLI scaffolding

## Reference Repositories
- [electron/electron-quick-start](https://github.com/electron/electron-quick-start) — Minimal Electron boilerplate to understand main/renderer split
- [tauri-apps/tauri](https://github.com/tauri-apps/tauri) — Official Tauri repo with examples and plugin ecosystem
- [electron-react-boilerplate/electron-react-boilerplate](https://github.com/electron-react-boilerplate/electron-react-boilerplate) — Production-grade Electron + React + Vite starter
- [SimulatedGREG/electron-vue](https://github.com/SimulatedGREG/electron-vue) — Electron + Vue reference (legacy but useful for Vue patterns)

## Official Documentation
- [Electron Docs](https://www.electronjs.org/docs/latest) — Process model, IPC, security, packaging, auto-update
- [Tauri Docs](https://tauri.app/v2/guide/) — Tauri v2 architecture, commands, plugins, updater
- [electron-builder](https://www.electron.build/) — Code signing, auto-update, multi-platform packaging
- [Playwright for Electron](https://playwright.dev/docs/api/class-electronapplication) — End-to-end testing of Electron apps
