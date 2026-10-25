# Avelo UI v2 + Groq — integration verification

Repository: `tohir-ibodullayev/HackPSU26`, inspected/cloned at `12cef10`. Local checkout: `/Users/jasurbekelmuratov/Documents/passion/HackPSU26`. Verification date: October 25, 2026 (America/New_York).

## What was actually present

The repository had one iOS 17+ Studyday target, four working SwiftUI tabs, `AppModel`, `BuddyServiceProtocol`, `MockBuddyService`, `BuddyContext`, `BuddyReply`, typed `BuddyCard` values, a deterministic `LocalGradeCalculator`, saved manual scores/targets, five fictional events, profile/memory editing, UserDefaults demo persistence and local proactive exam/grade-risk checks. Baseline Xcode build succeeded and its 38 original model checks passed before integration.

Its syllabus extraction was a filename-based mock. The real PDFKit/Vision/Foundation Models parser is in the older separate project; it was not connected here, replaced or misrepresented as working extraction. Real email auth was and remains unavailable.

## Integration

`StudydayApp` now injects `ConfiguredBuddyService` through the unchanged `BuddyServiceProtocol`. It selects real `GroqBuddyService` or the original local mock. Provider/error origin is visible on each new reply. API failures preserve useful errors and render **Demo fallback · not a Groq response**. The mode choice persists with backward-compatible optional fields. Late sign-out replies remain isolated.

The frontend talks only to `http://127.0.0.1:8001/v2/chat`, using ephemeral URLSession state, timeouts and no redirects. A key is never embedded in Swift. The backend uses official `groq==0.37.1`, a configurable `GROQ_MODEL` (default `openai/gpt-oss-120b`), and `GROQ_API_KEY` loaded server-side from the private ignored `.env`. It binds to loopback, disables access logging, and returns sanitized errors. Existing Groq/domain-guard code was reused/adapted; SQLite/old grade engines were not copied into this UI.

The allowlisted DTO contains only coded synthetic course controls, the existing Swift calculator's validated results, permitted interest tags, a system-generated fictional calendar anchor, and a coded proactive reference. It never serializes whole `BuddyContext`, `CourseItem`, profile text, memories, instructor/semester/location/policies, files, quotes or local chat history. Imported/edited/unverified course structures are blocked. Raw academic score/declaration text is rejected; ordinary study-duration budgets are permitted. Server Pydantic validation rejects unknown records/fields and inconsistent calculations.

Read-only tools retrieve goals, course information, the verified local grade scenario, preferences and canonical fictional events. Required evidence is retrieved before a factual reply, then further tool calls are disabled for the explanation. A rejected grade draft gets one restatement using the retrieved evidence and the same validator; a second failure produces an explicit error/fallback. Tool-call IDs and actual outputs are preserved. Typed card IDs map back to existing local grade/event/goal objects; model text never supplies numeric card values. Server domain checks run independently of frontend checks. Generated percentages/dates and explicit grade claims are checked against permitted evidence.

**The existing grade calculator and proactive evaluator were verified byte-for-byte unchanged against the base commit.** The prototype's 30/40/30 assessment weights are retained. A 60% midterm gives 18 earned course points, 30% completed weight, 60% recorded-work average, 88% maximum final and 107.14% required remaining for an A/93% target. This is different from the old parser demo's grading scheme.

## Verification actually run

| Check | Actual result |
| --- | --- |
| Untouched baseline simulator build | Succeeded |
| Original baseline model checks | 38 passed |
| Expanded native model/integration script | **64 checks passed** |
| Final iOS Simulator Xcode build | **BUILD SUCCEEDED** |
| Backend offline suite | **26 passed, 1 live case skipped by default** |
| Full backend suite with explicit live opt-in and the private key | **27 passed**, including the real Groq multi-turn goal → grade-risk reply → activity/tool test |
| Restarted running HTTP service | `/health` reported Groq configured; a synthetic `/v2/chat` request returned real Groq with the verified 88% maximum and the existing grade-card identifier |
| Dependencies | Project-local `.venv`, `pip check`: no broken requirements; exact versions in `backend/requirements.lock` |
| Plist/project/whitespace | `plutil -lint` and `git diff --check` passed |
| Credential check | `.env`/`.venv` are ignored; template blank; no credential-pattern matches outside ignored `.env` |

Native checks preserve all original arithmetic, bounds, invalid/incomplete-data handling, quiet hours, opt-in/deduplication, persistence, event actions, account isolation and unconfigured-auth cases. Added checks exercise privacy serialization, local-source numeric cards, missing values/nulls, actual URLSession adapter decoding, quota-error fallback labeling, local memory routing, no request in demo-only mode, coded proactive context, backward-compatible saves and persistent mode selection. HTTP fixtures are not counted as live Groq inference.

Backend tests exercise the official SDK via local mock transports plus real Python tool functions, original call IDs, typed cards, wrong arithmetic rejection, grade-summary tampering, unsupported scopes/records, private input blocking, domain vetoes without opening a provider, idempotency, missing-key/rate errors, study-duration exceptions, preventing a maximum-grade assumption from becoming a claimed entered score, and rejecting invented upcoming quizzes/homework in grade explanations. The explicit live test separately exercised actual Groq authentication, model access, tool selection/results, continuity and natural replies. A single upstream Starlette/httpx deprecation warning remains.

## iPhone Simulator walkthrough observed

| Requested scenario | Evidence |
| --- | --- |
| 1. Launch | Installed/launched com.studyday.app on iPhone 17 Pro / iOS 26.5; Avelo welcome, onboarding and original tabs were visible |
| 2. Real response | In Buddy, a typed question received a reply labeled **Groq · fictional demo**, not a mock/fallback |
| 3. Calculus goal | Actual reply stated A / 93%, with the existing goal card reconstructed locally |
| 4. Low score/card | Entered fictional **60** through the existing Midterm sheet and saved; Academics displayed **88.0% maximum**, recorded-work 60%, completed weight 30%, and impossible remaining requirement |
| 5. Proactivity/persistence | One existing local MATH 141 risk message/card appeared. Saved data after relaunch retained score 60, target A and exactly one risk alert |
| 6. Reply to alert | “Yes can we look at the numbers” received an actual Groq explanation of target 93%, maximum 88% and approximately 107% required, with the unchanged grade card |
| 7. Activity | Actual Groq reply used AI/football interests and returned Build with AI plus Saturday fan meetup cards, with matching fictional dates/locations |
| 8. Out-of-domain | “Who won the world cup” returned the fixed friendly college redirect labeled **Avelo · domain guard** |
| 9. Failure | An early live tool-loop failure visibly produced a useful error and **Demo fallback · not a Groq response**. The loop was corrected and subsequent real grade/activity responses succeeded. Offline tests also exercised HTTP 429 and native fallback decoding |

A simulator clipboard synchronization issue inserted a stale URL into one test draft. The native privacy gate blocked it before any API request. Only that accidental local test input and its fallback were removed using a private reversible backup; the fictional score, risk alert and all other chat history were preserved. No source documents or actual restricted records were sent.

After the user unlocked the Mac, the final installed build was visually rechecked. Try the demo restored the latest saved conversation; a new typed grade question received an actual **Groq · fictional demo** reply with the correct 93% target, 88% maximum and original grade card. Opening that card confirmed the saved 60% midterm, unknown final/coursework and unchanged local what-if controls. An earlier draft in this final check mentioned unsupported quizzes/homework; a small prompt/response-validation fix and regression test were added. The restarted backend's subsequent simulator reply stayed within the known assessment structure.

## Files changed

| Files | Purpose |
| --- | --- |
| `Studyday/Services/GroqBuddyService.swift` (new) | Protocol adapter, coded DTO/privacy gate, URLSession transport, typed card mapping and explicit mock fallback |
| `Studyday/Services/AppModel.swift` | Context/result metadata, current local summaries, recent risk references, mode persistence and cancellation on sign-out; existing calculator/trigger behavior retained |
| `Studyday/Models/Models.swift` | Backward-compatible optional reply origin/mode persistence and additive context/reply fields; BuddyCard and protocol method retained |
| `Studyday/StudydayApp.swift` | Inject the configured live/demo service |
| `Studyday/Views/Chat/ChatView.swift` | Small existing-chat mode control, origin labels, privacy caption and resume at latest message |
| `Studyday/Views/Course/CourseDetailView.swift` | Explicit fictional-score warning; original grade editor/calculations unchanged |
| `Studyday/Views/MainTabView.swift` | Avelo branding and accurate local/cloud privacy footer; tabs/profile/memory features retained |
| `Studyday/Views/RootView.swift`, `Studyday/Views/Auth/LoginView.swift`, `Studyday/Services/MockServices.swift` | Visible Avelo wording only |
| `Studyday/Info.plist`, `Studyday.xcodeproj/project.pbxproj` | Backend URL, local networking allowance, display name, single new service source reference |
| `Tests/CampusMateChecks.swift`, `scripts/check-models.sh` | Original checks plus integration/privacy regressions |
| `backend/avelo_backend/{app,models,guards,__init__}.py` (new) | Small FastAPI/Groq service, typed synthetic contract and adapted lightweight domain guard |
| `backend/tests/test_chat.py` (new) | Offline and opt-in real SDK tests |
| `backend/run.py`, `backend/pyproject.toml`, `backend/requirements.lock`, `backend/.env.example`, `backend/.gitignore` (new) | Reproducible local setup and key-safe launcher |
| `.gitignore`, `README.md`, this report | Credential/build exclusions, exact commands and handoff documentation |

Private `backend/.env` and `.venv` are local runtime files, not commit deliverables. No API key was committed or put into a client bundle.

## Remaining mocks and limits

- Syllabus import is still the original filename-based mock; real Apple extraction is a separate app/component.
- Email authentication, live campus discovery, production account storage and remote push are not implemented. Events are explicitly fictional; memories remain local.
- Use the two original coded demo courses and synthetic score/target controls for the live demo. Adding/importing/editing arbitrary course structures or policies intentionally causes local fallback. No consent toggle authorizes actual university records. Human intent cannot be detected if someone deliberately types a real grade into a fictional control—do not do that.
- The lightweight rule/context guard and output checks are practical, not unbypassable or exhaustive factual verification. This unauthenticated loopback backend must not be exposed publicly.
- Cloud history is bounded, in-memory and resets on server/app-session restart. Local history persists but is not automatically uploaded. Physical iPhone-to-Mac connectivity is intentionally unconfigured; use the simulator.
- No observed build failure remains, and the final post-install simulator check is complete. Quota/timeout behavior is implemented and covered by controlled tests; actual provider quota exhaustion was not induced.

## Exact run commands

Backend (already running on port 8001 in this session; stop the existing instance before starting a second):

```sh
cd /Users/jasurbekelmuratov/Documents/passion/HackPSU26/backend
.venv/bin/python run.py
```

Frontend:

```sh
cd /Users/jasurbekelmuratov/Documents/passion/HackPSU26
open Studyday.xcodeproj
```

Select Studyday → iPhone 17 Pro → Run; choose Try the demo. Terminal build/install/launch and first-time backend setup are in the [README](../README.md). Logs are under `/private/tmp/avelo-v2-*`, outside source control.
