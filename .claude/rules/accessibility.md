---
paths:
  - "App/**/*.swift"
  - "Tests/MacallaUITests/**/*.swift"
---

# Accessibility (WCAG 2.2 AA, plus PRD accessibility requirements)

Applies to every SwiftUI view and to AR overlays.

- **Labels:** every control has a VoiceOver label that names its action (`.accessibilityLabel`), and state where it has one (`.accessibilityValue`, e.g. "Coverage 64 percent"). Icon-only buttons are never unlabelled.
- **Capture without watching the screen:** shutter, rejection and coverage events give a haptic and a spoken cue (`AccessibilityNotification.Announcement`), as well as the visual one. Don't let cues spam: coalesce repeats within a second.
- **Colour is never the only signal:** the coverage heat map and ghost states use a colour-blind-safe palette (not red/green alone) plus a second channel (pattern, icon, opacity, or text).
- **Contrast:** text at least 4.5:1 (3:1 for large text and UI components), also over the live camera feed, so give overlays a backing material.
- **Dynamic Type:** use text styles, not fixed sizes; layouts reflow at accessibility sizes without truncating actions.
- **Targets:** hit areas at least 44×44 pt.
- **Motion:** respect Reduce Motion for ghost fades and dome animations; respect Reduce Transparency for overlay materials.
- **Identifiers for tests:** stable `.accessibilityIdentifier` on anything a UI test drives, named `area.element` (e.g. `capture.shutter`).
- **Strings** are externalised (`String(localized:)`) for English and Irish; don't concatenate localised fragments.
