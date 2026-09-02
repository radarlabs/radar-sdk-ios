---
name: objc-to-swift
description: >-
  Guides Objective-C to Swift migrations in radar-sdk-ios. Converts a named file or ranks the
  remaining ObjC backlog to recommend the next logical target. Requires confirmation of the file
  and strategy before editing (repo policy: never migrate without asking). Selects a pure-Swift
  Codable value struct, full @objc replacement, _Swift-suffixed coexisting twin, or a
  useSwiftLocationManager seam using the team's conventions, interop rules, and migration
  gotchas; updates project.pbxproj, adds Swift Testing coverage, and runs build/test/lint.
  Supports unattended `batch` mode for nightly CI: convert one safe leaf file and open a PR for
  human approval. Use when asked to convert or port ObjC to Swift, migrate a file, or recommend
  the next file to convert.
---

# objc-to-swift — migrate a radar-sdk-ios file from Objective-C to Swift

Runs the ObjC→Swift migration the way the team's PRs did: pick a target, confirm it,
choose the right strategy, convert, test, verify, and open a PR.

**Golden rule (repo policy in `CLAUDE.md` and `CONTRIBUTING.md`): never migrate a file
without the user's explicit yes.** This skill always stops at the confirm-gate (Step 1)
before editing. The one sanctioned exception is **batch mode** (see the last section),
where per repo policy the explicit yes is given at PR review instead of in chat.

**Deep reference:** `references/patterns.md` (in this skill dir) has the five strategies
with exemplars, the naming table, interop rules, pbxproj mechanics, the gotcha catalog,
and testing conventions. Open it once you know the strategy. This file is the workflow.

Confirm you're in the repo first: the working directory should contain `RadarSDK/` and a
`Makefile`. If not, ask the user for the repo path.

---

## Step 0 — Pick the target file

Ask the user: **"Do you have a specific file to convert, or should I find the next logical
one?"**

- **They name a file** → use it. Sanity-check it's still ObjC (`RadarSDK/<Name>.m` exists,
  no `RadarSDK/<Name>.swift` twin already).
- **They want a recommendation** → run the bundled finder, `scripts/find-next-candidate.sh`
  (in this skill's directory). It locates the repo via `git rev-parse` (run it from inside
  the radar-sdk-ios checkout) or takes the repo root as its first argument:
  ```bash
  bash "<this-skill-dir>/scripts/find-next-candidate.sh"           # from inside the repo
  bash "<this-skill-dir>/scripts/find-next-candidate.sh" /path/to/radar-sdk-ios
  ```
  It lists the backlog (ObjC classes with no `.swift` twin) ranked **most-trivial-first**
  (fewest lines, then lowest coupling, flag-free files before flagged ones), with
  LINES / COUPLING / TESTS / KIND / FLAGS columns, and names the top few. **The script
  narrows and signals; you judge.** Open the top 2–3 candidates, prefer a test-covered,
  low-coupling file that is *not* part of a tightly-coupled cluster (the `Route*` and
  `Trip*` families reference each other) — a `KIND=model` file converts most mechanically
  via Strategy D — then present your pick with a one-line rationale.

## Step 1 — Confirm gate (MANDATORY — do not skip)

State the file, the chosen strategy (Step 2), and roughly what will change (new `.swift`,
pbxproj edits, whether the `.m`/`.h` stay or go, new tests). Get an explicit **yes** before
editing anything. If the user hasn't decided the strategy, propose one and confirm.

## Step 2 — Classify and choose a strategy

Read the target `.m`/`.h`, then use the decision table in `references/patterns.md`:

| The file is… | Strategy |
|---|---|
| A leaf data model (has `initWithObject:` / `dictionaryValue` JSON serialization) | **D** — `struct RadarFooSwift: Codable, Sendable` alongside the `.m` |
| Small, self-contained, ObjC constructs/uses it directly, convertible in one shot | **A** — `@objc(RadarFoo) @objcMembers class`, delete `.m`, keep `.h` |
| A Swift twin ObjC must call while a same-named ObjC class still exists | **C** — `@objc(RadarFoo_Swift)` |
| A Swift-only helper ObjC doesn't need | **E** — no `@objc`; reach old behavior via `RadarSwift.bridge` |
| A large, stateful manager (can't convert at once) | **B** — per-method seam behind `useSwiftLocationManager` |

Most backlog leaves are **D**. Reach for **B** only for the managers (`Radar.m`,
`RadarLocationManager.m`, `RadarBeaconManager.m`, `RadarVerificationManager.m`); those need
extra buy-in — reconfirm with the user.

## Step 3 — Execute the conversion

Follow the strategy's exemplar in `references/patterns.md`. Common steps:

- Write `RadarSDK/RadarFoo.swift` matching the pattern (CodingKeys, `init(from:)` +
  memberwise init for D; `@objc(...)` selectors for A/C; static twins + hand-maintained
  `RadarFooSwift.h` + dispatch guard + 🦅 log for B).
- **`project.pbxproj`**: add the `.swift` (PBXBuildFile + PBXFileReference + PBXGroup +
  Sources phase). Full conversion (A/C): remove the `.m` from those sections; **keep the
  `.h`** while any ObjC still `#import`s it. Copy the exact shape of an existing sibling
  entry. Then `plutil -lint RadarSDK.xcodeproj/project.pbxproj`.
- If Swift needs an internal ObjC API, **add a method to `RadarSwiftBridgeProtocol`**
  (`RadarSwiftBridge.{swift,h,m}`) — do not try to import internal headers.
- Watch the gotchas as you write (see checklist below / patterns.md §5).

## Step 4 — Add or update tests

- **Swift Testing** (`@Suite`, `@Test`, `#expect`), `@testable import RadarSDK`.
- Use dependency injection + mocks; assert real outcomes (not state the code always clears).
- **Seam (B)**: add a test that calls the Swift twin directly *and* the ObjC entry point
  with the flag toggled, asserting both reach the same end state; nest it under a
  `@Suite(.serialized)` parent if it mutates global `RadarSettings`/`UserDefaults`.
- Register new test files in the test target and add any needed `+Internal.h` / ObjC mock to
  `RadarSDKTests/RadarSDKTests-Bridging-Header.h`.

## Step 5 — Verify

```bash
make build          # or make build-pretty
make test           # or make test-pretty (skips InAppMessageTest/RadarSettingsTest/RadarNotificationHelperTest)
make lint-swift     # MUST pass — CI fails on new SwiftLint violations
```

- **Format only the files you changed**: `swift-format -i RadarSDK/RadarFoo.swift`.
  **Never run repo-wide `make format`** — it reformats ~86 files and churns the diff.
- `make lint-swift` and `make format-check` diff against `origin/master`, so make sure your
  branch is based on it.
- **Strategy B manual check**: force the flag on (`useSwiftLocationManager` default in
  `RadarSdkConfiguration.swift`), run the Example app, confirm the 🦅-prefixed logs appear
  (Swift path) and are absent with the flag off. **Revert the hardcoded flag before committing.**

## Step 6 — Open the PR

Only commit/push when the user asks; branch off `master` if on it. Write the PR body as:

- `## Summary`: 2–4 concise bullets naming the migration, its compatibility approach, and
  public API impact.
- `## Test Plan`: numbered, concrete manual steps that use the Example app whenever it can
  exercise the change. Include required setup, the controls to use, and the observable result.
  For a refactor with no user-facing behavior, use the Example app to confirm it loads and can
  perform a relevant SDK action without an error.

Do not include automated commands, build/test/lint/CI results, automated-test counts, or a
checklist in the PR body. Keep automated coverage in the code and validation in the local
workflow, not the PR description.

---

## Gotchas quick checklist (detail in `references/patterns.md` §5)

- [ ] **Name collision** — Swift `@objc` class shadowing a same-named ObjC class → use
      `_Swift` (C) or drop `@objc` (E).
- [ ] **Swift can't see internal ObjC** — add to `RadarSwiftBridgeProtocol`, or pass state
      as arguments in a seam.
- [ ] **`async` overload ambiguity** — two ObjC completion methods → same Swift `async` name;
      add `NS_SWIFT_DISABLE_ASYNC`.
- [ ] **`String`→`Int` silent `?? 0`** — use `guard let` and skip/log on failure.
- [ ] **App-group `UserDefaults` split** — move getter and setter together onto the same suite.
- [ ] **Vacuous test** — assert real outcomes, not state the code always clears.
- [ ] **Actor SIGTRAP** ("Incorrect actor executor assumption") — make `shared`/`init`
      `nonisolated`; keep async methods actor-isolated.
- [ ] **Hand-mirrored constants** — mark "kept in sync by hand until cutover"; delete the
      ObjC copy at cutover.
- [ ] **pbxproj** — `.swift` in Sources; `.h` in Headers; `plutil -lint` after editing.

---

## Batch mode (unattended CI runs)

Activated **only** when the skill is invoked with the `batch` argument (`/objc-to-swift
batch`) — the radar-sdk-ios nightly workflow (`.github/workflows/objc-to-swift-nightly.yml`)
does this. When `batch` is not passed, nothing in this section applies; the interactive
workflow above is unchanged.

In batch mode the repo policy's "explicit yes" is granted at **PR review** (sanctioned in
radar-sdk-ios `AGENTS.md`), so there is no user to ask. That trust is earned by being
strictly conservative:

**Candidate selection (replaces Step 0 and the Step 1 confirm gate):**
- Run `scripts/find-next-candidate.sh`. It ranks **most-trivial-first** (fewest lines,
  then lowest coupling, flag-free files before flagged ones). Take the **top-ranked
  flag-free candidate** — i.e. the smallest, least-coupled file with an empty FLAGS column.
  Trivial-first is the whole point of batch mode: burn down the easy leaves unattended and
  leave the hard files for a human.
- Hard-skip, no matter the rank: any flagged file (`manager`, `sys`, `large`, `partial`,
  or `covered`) and any file in the tightly-coupled `Route*` / `Trip*` clusters — even
  when one tops the ranking because it is small (e.g. `RadarRouteMode`). Move to the next
  eligible candidate.
- **If no eligible candidate remains, stop cleanly**: print a summary of why the top
  candidates were skipped and exit **without editing anything and without opening a PR**.
- Convert **exactly one file per invocation**.

**Strategy restriction (Step 2):** only Strategy **D** (pure-Swift Codable value struct) or
Strategy **A** (straightforward full `@objc` class replacement). Never B (seam/flag),
C, or E unattended — if the eligible candidate turns out to need one of those on closer
reading, skip it, pick the next eligible candidate, and note the skip in the run summary.

**Verification (replaces Step 5):** The nightly runner is macOS with Xcode 26.3,
`swift-format`, `swiftlint`, and `plutil`. `MIGRATION_DESTINATION` contains an available
iPhone simulator destination. Before pushing:

1. Create a local commit on `claude/migrate-<FileName>` without pushing, so
   `make lint-swift` can diff the committed changes against `origin/master`.
2. Run `make lint-swift`, `make format-check`, and
   `plutil -lint RadarSDK.xcodeproj/project.pbxproj`.
3. Run `make build DESTINATION="$MIGRATION_DESTINATION"` and
   `make test DESTINATION="$MIGRATION_DESTINATION"`. The Makefile quotes the destination
   when it invokes `xcodebuild`; pass the value without embedded quotes.
4. If any command fails, diagnose and fix the migration, amend the local commit, and rerun
   every failed check. Do not push or open a PR unless all checks pass. If validation is
   unavailable, exit without pushing or opening a PR.

**PR conventions (replaces Step 6's "only commit/push when the user asks"):**
- Branch `claude/migrate-<FileName>` off `master`; commit and push without asking.
- Open the PR with the `swift-migration` label. Follow Step 6 for the PR body; do not use
  the generic PR template sections.
- One open `swift-migration` PR is the WIP cap — the workflow checks this before invoking
  the skill, but if you notice an open migration PR anyway, stop without editing.
