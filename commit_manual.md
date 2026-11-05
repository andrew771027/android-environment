# Commit Manual

- Update source code.
- Update test code.
- Run unit tests without starting an emulator (`make unit-test`).
- Run integration tests against an already booted emulator (`make integration-test`).
- Update the README and relevant docs with human-readable instructions that match implemented commands.
- Record verification results and coverage limits in `docs/testing.md`; distinguish fake-tool coverage from real hardware checks.
- Update the roadmap and project version.
- Create the release commit, then point the version tag at that commit. A tag does not include uncommitted workspace changes.

For v0.5.0, physical-device and Fastboot tests use fake commands. The existing integration suite checks the emulator only; record real USB, authorization, and Fastboot checks separately when performed.
