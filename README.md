# Avelo · your campus buddy

An iPhone-first SwiftUI prototype with a conversation at its center. The existing Xcode project and internal `Studyday` directory names are retained; the app displays **Avelo**.


## Live Groq setup — UI v2

Use this checkout, **HackPSU26**, rather than replacing it with the older separate parser application. All four tabs, manual grades, target controls, cards, reminders and `campusmate.demo.v1` persistence are retained. Visible branding is Avelo; identifiers/project names are unchanged.

```sh
cd backend
python3.11 -m venv .venv
.venv/bin/python -m pip install -e '.[test]'
cp -n .env.example .env
```

Put `GROQ_API_KEY` in **backend/.env**, not `.env.example`, Swift, Git or chat. `GROQ_MODEL` defaults to `openai/gpt-oss-120b`. Preserve any existing private `.env` when updating the checkout. Then:

```sh
.venv/bin/python run.py
```

The server binds only `127.0.0.1:8001`, loads only the two documented env names without shell evaluation, and disables request access logs. Health: [localhost API health](http://127.0.0.1:8001/health); schemas: [API docs](http://127.0.0.1:8001/docs). The iPhone Simulator on this Mac can reach this loopback address. Physical phones cannot; do not bind this unauthenticated synthetic demo publicly.

From a separate terminal at the repository root:

```sh
open Studyday.xcodeproj
```

Select **Studyday → iPhone 17 Pro → Run**. Alternatively:

```sh
xcodebuild -project Studyday.xcodeproj -scheme Studyday \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath /private/tmp/avelo-v2-build CODE_SIGNING_ALLOWED=NO build
xcrun simctl install booted /private/tmp/avelo-v2-build/Build/Products/Debug-iphonesimulator/Studyday.app
xcrun simctl launch booted com.studyday.app
```

Choose **Try the demo**, complete/skip onboarding and leave **Use Groq for the fictional demo** enabled. Its choice persists. Real replies say **Groq · fictional demo**. Domain redirects say **Avelo · domain guard**. Failures show a useful error and **Demo fallback · not a Groq response**; toggling off uses the original mock locally. Loading/late sign-out isolation are preserved. Local memories are answered locally and never sent to Groq.

### Reliable demonstration

1. In Me, set fictional interests to `AI, football`; enable proactive reminders and disable quiet hours for the demo if necessary.
2. Ask “What's my goal in Calculus II?” Groq retrieves the local synthetic target A / 93% and returns the goal card.
3. Academics → MATH 141 → Midterm → enter fictional **60** → Save. The unchanged Swift engine shows recorded-work average **60%**, completed weight **30%**, maximum possible final **88%**, and required remaining **107.14%**. This fixture uses a 30% midterm; do not substitute the older parser/demo's grading weights.
4. Buddy shows one persisted risk alert with the existing grade card. Reply “Yes, can we look at the numbers?” Groq retrieves the current verified Swift result. Re-entering the same score or reopening does not duplicate the risk alert.
5. Ask “Recommend a campus activity for my interests.” Real preference/event tools return the five code-owned fictional events, and the original event cards open their existing detail views.
6. Ask “Who won the World Cup?” to see the fixed friendly domain redirect. A following college-related request still works.
7. Toggle Groq off to demonstrate labeled local mode, or stop the backend and send a college question to see explicit network-error fallback. Restart it for the live demo.

### Privacy and scope

Cloud uses an allowlisted `synthetic_ui_v2` DTO, not `BuddyContext`/`CourseItem` serialization. Only the original coded two-course fixtures, target selection, explicitly fictional score controls, existing deterministic summaries, approved interest tags and a coded proactive reference are permitted. Names, majors, free-form goals/memories, instructor/location/semester/policy strings, local conversation history, documents and source quotations are excluded. Imported or edited course structure/policies revoke cloud eligibility and use labeled local fallback. Raw numerical academic records and document-like chat are blocked; ordinary study-duration budgets are allowed.

The backend independently validates the schema and grade-summary consistency, executes only five read-only academic/profile/event tools, guards unrelated input and checks generated numeric claims. Grade arithmetic/cards remain sourced from `LocalGradeCalculator`, not model-generated numbers. No original PDFs/images/text or actual restricted records are uploaded. This gate cannot determine whether a human intentionally entered actual grades into fictional controls: **use synthetic scores only**. It is not a production DLP or authentication system.

The separate Apple syllabus parser still exists in the earlier project. UI v2's picker remains its honest filename-based mock; real parsing was not silently claimed or reimplemented here. Email auth and live campus events also remain unconfigured/fictional. No remote push, background service, additional tabs or agent framework was added. Cloud history is bounded and process-local; UI history remains device-local and is never automatically replayed to Groq.

### Tests

```sh
./scripts/check-models.sh
cd backend
.venv/bin/python -m pytest -q
```

The ordinary Python suite does not call external APIs. Opt in to the synthetic live goal → risk reply → activity test:

```sh
.venv/bin/python -c 'import os, pytest; from run import load_environment; load_environment(); os.environ["AVELO_LIVE_TEST"]="1"; raise SystemExit(pytest.main(["-q", "-m", "live", "tests"]))'
```

See [files changed and verification](docs/integration-verification.md). Keep one app/backend demo instance running per bundle/port.

## Original prototype walkthrough

Requires **macOS, Xcode 15+, and an installed iOS 17+ simulator**. Open `Studyday.xcodeproj`, choose the **Studyday** scheme and an available iPhone simulator, then Run. The local mock demo needs no key/backend. Live Groq conversations use the included localhost backend; credentials stay in its ignored `.env`. No signing team or Canvas integration is required for Simulator. Linux cannot build or run this SwiftUI application.

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
| `BuddyServiceProtocol` | `ConfiguredBuddyService` / `GroqBuddyService`, with `MockBuddyService` fallback | Live Groq replies and locally reconstructed typed cards; explicit local/fallback mode |
| `SyllabusExtractorProtocol` | `MockSyllabusExtractor` | Real file parsing and syllabus confirmation |
| `GradeCalculating` | `LocalGradeCalculator` | Teammate's grade engine with explicit incomplete-data semantics |
| `StudentStateStoring` | `LocalStudentStore` | Account-scoped persistence and student memory |

`BuddyContext` supplies profile/preferences/memories, courses, and events locally to the service. The explicit mock mode answers a few intents and is **not live AI**. Groq mode uses real server tool calls, bounded server conversation history and the existing Swift calculator results. Communication style remains local for a future integration. The implemented development endpoint is `http://127.0.0.1:8001/v2/chat`, configurable through `AveloBackendURL` in Info.plist or the `AVELO_BACKEND_URL` launch environment. Only loopback HTTP is allowed in this build. Swift's Codable representation of `BuddyCard` is for local storage. The implemented adapter maps server card identifiers to existing local grade summaries, goals and fictional events; it never constructs numeric cards from generated text. Proactive metadata remains on the existing `ChatMessage`.

Demo persistence uses `campusmate.demo.v1` in UserDefaults. It is device-local prototype data, not encrypted account storage. Authenticated sessions do not load or save demo state. Real persistent accounts, remote push, live campus data, and production-grade auth still require backend integration.

## Validation

Run the model regression checks on a Mac:

```sh
./scripts/check-models.sh
```

The script compiles the actual model/services and exercises grade bounds, incomplete/invalid data, weighted arithmetic, goal feasibility, quiet hours, consent/deduplication, persistence, event actions, async sign-out isolation, and unconfigured auth. It needs SwiftUI and Combine on macOS. It does not replace an Xcode build or UI walkthrough.

The integration was built on this Mac: **64 native checks passed**, the iOS Simulator build succeeded, and **27 backend tests passed with explicit live Groq opt-in** (26 pass and one skips without live opt-in). The simulator walkthrough exercised a real goal reply, fictional score entry, local calculation/proactive alert, real follow-up, activity cards and domain redirection. After the Mac was unlocked, the final installed build was visually checked again: latest chat restored, the saved score remained 60%, and a fresh Groq reply correctly explained the 88% maximum. See the [verification report](docs/integration-verification.md) for evidence and remaining limits.
