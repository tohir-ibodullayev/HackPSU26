# CampusMate · your campus buddy

An iPhone-first SwiftUI prototype with a conversation at its center. The existing Xcode project and internal `Studyday` directory names are retained; the app displays **CampusMate**.

## Run

Requires **macOS, Xcode 15+, and an installed iOS 17+ simulator**. Open `Studyday.xcodeproj`, choose the **Studyday** scheme and an available iPhone simulator, then Run. No API key, backend, package installation, signing team, or Canvas integration is needed for the simulator demo. Linux cannot build or run this SwiftUI application.

Choose **Try the demo**. Optional onboarding asks for your name, major/year, goals, interests, and reminder consent. Returning demo users resume their device-local data. Use Me → Delete all local demo data to start fresh.

Login, sign-up, and password recovery screens validate input, provide progress/error feedback, and call an injectable auth service. **Real authentication is not configured.** Submitting these forms reports that the service is unavailable; it does not create an account or claim to send an email. Passwords are never persisted. Demo access is separate from real account sessions.

## What is implemented

- **Buddy:** left/right conversation bubbles, suggested replies, typing/error state, interactive grade, goal, and event cards, and labeled proactive reminders. Grade cards are snapshots at message time; opening one shows live course details.
- **Academics:** labeled demo courses, manual percentage entry/removal, target letters, assessment weights, upcoming deadlines, syllabus policies, maximum possible grade, remaining-score requirement, and a what-if slider. No invented scores or Canvas averages.
- **Discover:** five fictional events, category filtering, interest-based ordering, event details, and Ask Buddy actions. All events are clearly labeled demo data.
- **Me:** editable profile/goals/interests, communication preference, reminders, local-time quiet hours, editable/deletable memories, sign-out, and demo-data deletion.
- Light/dark surfaces, rounded cards, and the original mint/sky welcome styling.

Demo syllabus selection and the PDF/text picker use **filename-based sample extraction**. Documents are not read or uploaded, and no real extraction is implied. Duplicate imports preserve existing grades. Add or correct assessment weights and policies using course Edit.

## Demo acceptance walkthrough

1. Try the demo, complete or skip onboarding, and send a Buddy message. Tap **Show my grades** and open the Calculus II card.
2. In Academics → MATH 141, select target **A (93%)**. All scores initially remain unknown.
3. Tap Midterm / Add Grade and enter **60**. The demo midterm weight is 30%, so the entered-work average is **60%**, completed weight **30%**, and maximum possible final is **88%**. No 60% final-course average is claimed.
4. In What if, use **80%** on remaining work. Projected final is **74%** (18 earned course points + 56 remaining points).
5. In Me, enable proactive reminders and disable quiet hours for this demo. Buddy adds one clearly marked risk message with a grade card. Reopening the app or saving the same score does not repeat the alert. Quiet hours or lack of consent suppress it; an unresolved alert is evaluated again on foreground. Updating scores/targets so a goal is feasible resets the risk trigger. Upcoming exams within seven days also generate a single in-app reminder per deadline. No push notification permission is requested.
6. Open Discover, choose an event, and tap Ask Buddy. The app switches to Buddy, sends the question, and displays its event card.
7. Edit your goal and add a memory in Me. Ask Buddy “What do you remember?” Edit/delete that memory. Sign out and choose Try the demo again to check local persistence.
8. Check sign-up password mismatch, invalid email, and valid form submission. A valid form still reports that the real account service is not connected. Check dark mode and larger text on a simulator.

## Grade assumptions

Each assessment is an individual weighted portion of the final grade. Weights must be finite, positive, and total 100%. Scores must be finite percentages in 0–100. A category total can only be entered when the whole category is graded; do not double-count category totals and individual work. Missing scores remain unknown.

`earned = sum(score × weight / 100)`; `completedWeight = sum(weights with scores)`; recorded-work average is `earned / completedWeight × 100`. Maximum final assumes 100% on every ungraded portion. What-if uses the selected score across all remaining work. With no scores or invalid weights, no feasibility estimate is shown. Grade-letter thresholds (A 93, A− 90, B+ 87, B 83, C 73) are **prototype conventions**, not official course policies. Curves, rounding, dropped work, and extra credit are not modeled.

## Backend handoff

Inject dependencies through `AppModel`:

| Boundary | Prototype | Integration |
| --- | --- | --- |
| `AuthServiceProtocol` | `UnconfiguredAuthService` | Real sign-in, sign-up, recovery, sign-out; use provider-managed secure session storage |
| `BuddyServiceProtocol` | `MockBuddyService` | Gemini/agent adapter returning `BuddyReply` with typed `BuddyCard` values |
| `SyllabusExtractorProtocol` | `MockSyllabusExtractor` | Real file parsing and syllabus confirmation |
| `GradeCalculating` | `LocalGradeCalculator` | Teammate's grade engine with explicit incomplete-data semantics |
| `StudentStateStoring` | `LocalStudentStore` | Account-scoped persistence and student memory |

`BuddyContext` supplies profile/preferences/memories, courses, and events to the service. The mock answers a few intents; it is **not live AI**. Communication style is saved and passed as context for the future agent. No endpoint URL has been invented. Swift's Codable representation of `BuddyCard` is for local storage, not a promised wire format. For the proposed API `grade_summary` card, an adapter must map the server's target, maximum, completion/earned weights, validity, status, and course ID into `GradeSummary` and `.grade(...)`. The proactive flag belongs on `ChatMessage`. Do not fabricate missing calculation fields from a partial API payload.

Demo persistence uses `campusmate.demo.v1` in UserDefaults. It is device-local prototype data, not encrypted account storage. Authenticated sessions do not load or save demo state. Real persistent accounts, remote push, live campus data, and production-grade auth still require backend integration.

## Validation

Run the model regression checks on a Mac:

```sh
./scripts/check-models.sh
```

The script compiles the actual model/services and exercises grade bounds, incomplete/invalid data, weighted arithmetic, goal feasibility, quiet hours, consent/deduplication, persistence, event actions, async sign-out isolation, and unconfigured auth. It needs SwiftUI and Combine on macOS. It does not replace an Xcode build or UI walkthrough.

This implementation was edited in a Linux cloud machine. Swift syntax-tree parsing, plist/XML/asset validation, and whitespace checks were performed there. **The model regression checks and simulator walkthrough have not run on macOS; compilation, visual layout, keyboard behavior, and navigation still require Xcode verification.**
