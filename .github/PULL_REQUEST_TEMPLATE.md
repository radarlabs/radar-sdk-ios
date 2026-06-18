<!--
Thanks for contributing to the Radar iOS SDK! 💙

External contributors: a Radar team member will review your PR. By contributing you
agree your changes are licensed under this repo's Apache 2.0 license. No CLA needed.

Before opening, please run the same checks CI runs:
  make lint-swift
  make format-check
  make test
-->

## Summary

<!-- What does this PR do, and why? Keep it focused. -->

## Linear ticket (Radar internal)

<!-- Internal contributors: link the Linear ticket, e.g. FENCE-1234. External contributors can delete this section. -->

## Related issue

<!-- Link any related GitHub issue, e.g. Closes #123. -->


## Manual test steps

<!--
How did you verify this? Give steps a reviewer can follow when possible — ideally
via the example app in `Example/`. Include device / OS / simulator and any setup.
-->

1.
2.
3.

## Checklist

- [ ] New code is written in Swift (the SDK is migrating off Objective-C)
- [ ] Added or updated unit tests (`make test`)
- [ ] `make lint-swift` and `make format-check` pass locally
- [ ] For breaking changes: added a `MIGRATION.md` entry and bumped the version with `./set-version.sh`
- [ ] Updated README / public docs if the public API changed
- [ ] No real API keys committed in the example app
- [ ] Only fixed lint/format violations on lines I changed; removed any now-stale `.swiftlint-baseline.json` entries

## Screenshots / recordings (optional)

<!-- For example-app or other user-visible changes. -->
