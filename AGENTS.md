# ShellX

- Native macOS 14+, Swift / SwiftUI / AppKit / SwiftPM, following EnglishX and createX.
- This version is a local mock only. No SSH, SFTP, shell process execution, credentials or server access. All commands, addresses, logs and files are synthetic. Do not add network operations without a new user request.
- Keep sibling projects unchanged. No remote repository, publishing, OTA or installation outside the local preview.
- Warm paper shell, quiet inset dividers, readable monospaced terminal. Compact controls and minimal explanatory copy. Errors and mock status remain visible.
- Retain the shared cursorUpdate tracking, native resize priority and I-beam for editable/selectable text. Personal cursor artwork and its NOTICE stay in ignored .local/cursor-preview and local .preview app bundles only.
- Commands must go through the explicit in-memory mock dispatcher. Never pass user text to a shell.
- Local preview: dist/preview/ShellX.app, bundle ID cc.anjing.shellx.preview. Sidebar/file visibility and split proportions persist, never terminal commands or credentials.

- Server sidebar is editable in memory only: top + offers server/group creation; group + preselects its group. Row ellipsis offers existing-session activation, explicit new tab and edit/move. Plain row clicks reuse the most recently opened session for that server.
- Search uses whitespace-separated AND terms across name/address/group/user, temporarily expands matching groups and preserves prior collapse state. Enter activates the first match; Escape clears. Keep zero-result and empty-group add actions.
- Same-window paper panels, with Escape/outside-click dismissal, autofocus and visible field errors. Main fields are name/address/group; user/port are optional disclosure. No passwords, key files, real connection or config persistence. Existing sessions retain their original server snapshot; edited settings apply to newly opened tabs.

- App icon is the user-supplied crayon snail with terminal shell. Preserve Resources/AppIcon-source.png byte-for-byte; build-icon.py uses ShellX.icon and native Assets.car to avoid a nested legacy icon. prepare-icon.swift crops only the original tile margin and extends paper beneath transparent corners; never repaint the snail. Package a hashed ICNS filename. Never reset system icon caches or restart Dock.

- Public repository: anjing-le/anjing-shell. Publishing the source is authorized; do not imply a signed/notarized app release. Never commit .local, .build, dist or private cursor artwork; base cursor PNGs remain local until redistribution rights are verified. Public checkouts use built-in cursor fallbacks.
- README hero is an AI-generated concept illustration, not evidence of implemented UI or remote connectivity. Keep the exact image-generation prompt and asset attribution in docs/artwork.md.
