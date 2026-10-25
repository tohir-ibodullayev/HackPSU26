# Studyday (iOS)

SwiftUI frontend for **Studyday** — syllabus-aware study chat and course home. Auth, Apple Intelligence extraction, and LLM replies are **local mocks** so you can open and demo in Xcode without a backend. Protocols are ready for a real API later.

## Requirements

- macOS with **Xcode 15+** (iOS 17 deployment target)
- iPhone or iOS Simulator

## Open & run

1. Clone this repo and open **`Studyday.xcodeproj`** in Xcode (double-click or `open Studyday.xcodeproj`).
2. Select the **Studyday** scheme and an iPhone simulator (e.g. iPhone 16).
3. Press **Run** (⌘R).

No server, API keys, or signing team is required for the simulator demo. If Xcode asks for a Development Team for a physical device, pick your Apple ID team under **Signing & Capabilities**.

## Demo flow

1. **Login** — tap Gmail, Penn State, or Apple (stubbed; continues into the app).
2. **AI Chat** (first tab) — tap **+ Add syllabus**, pick a sample file. Mock “Apple Intelligence” extracts fields; a stub LLM reply confirms; the course is added to **Home**.
3. **Home** — open a course for **Exams / Quizzes / Assignments**; tap **Edit** to fix extraction mistakes.
4. **You** — see the mock session and sign out.

## Project layout

```
Studyday.xcodeproj          Xcode project
Studyday/
  StudydayApp.swift         App entry
  Models/                   Course, chat, session types
  Services/
    ServiceProtocols.swift  Auth / extract / chat protocols (plug API here)
    MockServices.swift      Local stubs
    AppModel.swift          App state
  Theme/                    Colors & background
  Views/                    Login, tabs, chat, home, course edit
  Resources/Assets.xcassets
  Info.plist
```

## Plugging in a real backend later

Replace the defaults in `AppModel`’s initializer:

| Protocol | Mock today | Later |
|----------|------------|--------|
| `AuthServiceProtocol` | `MockAuthService` | OAuth / Penn State SSO |
| `SyllabusExtractorProtocol` | `MockSyllabusExtractor` | Apple Intelligence / parse API |
| `ChatServiceProtocol` | `MockChatService` | Friend’s LLM HTTP API |

## Notes

- Visual language matches the Studyday MHTML mockup (soft mint→sky paper wash, `studyday·` wordmark, near-black primary CTAs, blue accent `#4388ED`, welcome copy).
- Login opens on the mockup welcome (“Get started” / “Try the demo”); Get started reveals Gmail / Penn State / Apple stubs.
- Chat / Home reuse the same tokens (mockup only captured the welcome screen).
