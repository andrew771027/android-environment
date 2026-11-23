# Commit Manual

- Update source code.
- Update test code.
- Run unit tests without starting an emulator (`make unit-test`).
- Run integration tests against an already booted emulator (`make integration-test`).
- Before committing source or test changes, review the README, roadmap, and all files under `docs/` for affected content. Keep command examples, defaults, platform behavior, error handling, test counts, and coverage claims aligned with the current source and tests. Verify affected examples and test collection, and date recorded results so readers can identify which revision they describe.
- Record verification results and coverage limits in `docs/testing.md`.
- Update the roadmap and project version.
- Keep the README current with the prerequisites, setup steps, commands, defaults, and platform-specific guidance users need to use the project. Keep the README version-neutral and link to `roadmap.md` for release versions and their changes.
- Create the release commit, then point the version tag at that commit. A tag does not include uncommitted workspace changes.
