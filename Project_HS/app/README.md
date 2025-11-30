# app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
## Rendering fixes: card duplication and overlap

This update addresses issues where match cards were duplicating and overlapping on Flutter Web.

Root cause
- AnimatedSwitcher’s default `layoutBuilder` stacks the current and previous children during transitions. Rapid state changes (date/time filter, auto-refresh of reservations and participant updates) caused multiple `ListView` instances and status chips to overlap, leading to huge render surfaces and duplicate key exceptions.

Changes
- Match list: AnimatedSwitcher now uses a `layoutBuilder` that returns only the current child to prevent stacking old `ListView`s.
- Status chip: Removed explicit child `key` and added the same `layoutBuilder` restriction to avoid duplicate keys during transitions.
- Stable card identity: Each `MatchCard` receives a `ValueKey<int>(reservation.id)` to keep widget identity stable across updates.
- Responsive player layout: The row of four player slots now switches to a `Wrap` when the available width is narrow, preventing horizontal overflow.

Verification
- Tested in Flutter Web on Chrome/Edge across narrow and wide viewports.
- No duplicate keys errors; no RenderFlex overflows; card transitions are stable.

Notes
- If future animations are added around lists or dynamic chips, prefer using `layoutBuilder` to avoid stacking, and ensure children have stable, unique keys.
