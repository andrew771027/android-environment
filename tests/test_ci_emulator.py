"""Fast offline contract tests. No Android SDK, KVM, or emulator needed."""

import os
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "scripts/lib/ci_emulator.sh"


def fake(tmp_path: Path, name: str, body: str) -> Path:
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir(exist_ok=True)
    p = bin_dir / name
    p.write_text("#!/usr/bin/env bash\n" + body, encoding="utf-8")
    p.chmod(0o755)
    return p


def build_env(tmp_path, **overrides):
    """只修改子程序的環境，讓假 adb 優先於真實 SDK。"""
    env = os.environ.copy()
    env.update({
        "PATH": str(tmp_path / "bin") + os.pathsep + env["PATH"],
        "ANDROID_HOME": str(tmp_path / "empty-sdk"),
        "EMULATOR_SERIAL": "emulator-5554",
        "AVD_NAME": "cookbook_pixel_api_36",
        "EMULATOR_BOOT_TIMEOUT_SECONDS": "1",
        "EMULATOR_STOP_TIMEOUT_SECONDS": "1",
        "EMULATOR_POLL_INTERVAL_SECONDS": "1",
        "TEST_AVD": "cookbook_pixel_api_36",
        "TEST_BOOT": "1",
        "TEST_API": "36",
        "TEST_DELETE_STATUS": "0",
    })
    env.update(overrides)
    return env


def run_bash(args, env):
    """統一收集 stdout、stderr 與退出碼，最多等待 15 秒。"""
    return subprocess.run(
        ["bash", *args],
        env=env,
        text=True,
        capture_output=True,
        timeout=15,
        check=False,
    )


def run(tmp_path, expression, *, extra_env=None):
    script = f'set -euo pipefail\nsource "{LIB}"\n{expression}'
    return run_bash(["-c", script], build_env(tmp_path, **(extra_env or {})))


def run_smoke(tmp_path, **overrides):
    return run_bash(
        [str(ROOT / "scripts/smoke_test.sh")],
        build_env(tmp_path, **overrides),
    )


def fake_ready_adb(tmp_path):
    """預設為 API 36、已開機的專案 AVD；個別測試可用環境變數改變回應。"""
    fake(tmp_path, "adb", '''
case "$*" in
    "-s emulator-5554 get-state") echo device ;;
    "-s emulator-5554 emu avd name") echo "${TEST_AVD:-cookbook_pixel_api_36}" ;;
    "-s emulator-5554 shell getprop sys.boot_completed") echo "${TEST_BOOT:-1}" ;;
    "-s emulator-5554 shell getprop ro.build.version.sdk") echo "${TEST_API:-36}" ;;
    "-s emulator-5554 shell cat "*) echo smoke-ok ;;
    "-s emulator-5554 shell printf "*) exit 0 ;;
    "-s emulator-5554 shell rm -f "*) exit "${TEST_DELETE_STATUS:-0}" ;;
    *) exit 1 ;;
esac
''')


def test_ready_requires_boot_completed_and_avd_identity(tmp_path):
    fake_ready_adb(tmp_path)
    result = run(tmp_path, "wait_for_boot $$")
    assert result.returncode == 0, result.stderr
    assert "READY" in result.stdout


def test_wrong_avd_fails_closed(tmp_path):
    fake_ready_adb(tmp_path)
    result = run(tmp_path, "wait_for_boot $$", extra_env={"TEST_AVD": "another_avd"})
    assert result.returncode != 0
    assert "Unexpected AVD identity" in result.stderr


def test_boot_not_completed_times_out(tmp_path):
    fake_ready_adb(tmp_path)
    result = run(tmp_path, "wait_for_boot $$", extra_env={"TEST_BOOT": "0"})
    assert result.returncode != 0
    assert "timed out" in result.stderr


def test_other_existing_emulator_is_rejected(tmp_path):
    fake(tmp_path, "adb", '''
echo 'List of devices attached'
echo 'emulator-5556 offline'
''')
    result = run(tmp_path, "check_isolated_adb")
    assert result.returncode != 0
    assert "isolated runner" in result.stderr


def test_physical_pixel_does_not_count_as_emulator(tmp_path):
    fake(tmp_path, "adb", '''
echo 'List of devices attached'
echo 'PIXEL123 device'
''')
    result = run(tmp_path, "check_isolated_adb")
    assert result.returncode == 0


def test_positive_timeout_validation(tmp_path):
    result = run(tmp_path, """
validate_positive_integer 20
if validate_positive_integer 0; then exit 1; fi
if validate_positive_integer abc; then exit 1; fi
""")
    assert result.returncode == 0


def test_smoke_round_trip_succeeds(tmp_path):
    fake_ready_adb(tmp_path)
    result = run_smoke(tmp_path)
    assert result.returncode == 0, result.stderr
    assert "Smoke PASS" in result.stdout


def test_smoke_fails_on_wrong_api(tmp_path):
    fake_ready_adb(tmp_path)
    result = run_smoke(tmp_path, TEST_API="35")
    assert result.returncode != 0
    assert "API mismatch" in result.stderr


def test_adb_failure_rejects_isolation_check(tmp_path):
    fake(tmp_path, "adb", "exit 7\n")
    result = run(tmp_path, "check_isolated_adb")
    assert result.returncode != 0


def test_cleanup_escalates_only_owned_pid(tmp_path):
    # Shell doubles avoid signalling any real process.
    fake(tmp_path, "adb", 'printf "%s\\n" "$*" > "$ADB_CALLS"\n')
    result = run(tmp_path, '''
SECONDS=2
EMULATOR_STOP_TIMEOUT_SECONDS=1
kill() {
    if [[ "$1" == -0 ]]; then return 0; fi
    printf 'signal:%s:%s\\n' "$1" "$2"
}
sleep() { SECONDS=$((SECONDS + $1)); }
wait() { printf 'wait:%s\\n' "$1"; }
stop_owned_emulator 424242
''', extra_env={"ADB_CALLS": str(tmp_path / "adb-calls")})

    assert result.returncode == 0, result.stderr
    assert (tmp_path / "adb-calls").read_text().strip() == "-s emulator-5554 emu kill"
    assert "signal:-TERM:424242" in result.stdout
    assert "signal:-KILL:424242" in result.stdout
    assert "wait:424242" in result.stdout


def test_smoke_preserves_injected_adb_and_checks_delete(tmp_path):
    sdk = tmp_path / "sdk"
    platform_tools = sdk / "platform-tools"
    platform_tools.mkdir(parents=True)
    decoy = platform_tools / "adb"
    decoy.write_text("#!/usr/bin/env bash\necho SDK_ADB_USED >&2\nexit 99\n")
    decoy.chmod(0o755)
    fake_ready_adb(tmp_path)
    result = run_smoke(tmp_path, ANDROID_HOME=str(sdk), TEST_DELETE_STATUS="8")
    assert result.returncode == 8, result.stderr
    assert "SDK_ADB_USED" not in result.stderr
    assert "Smoke PASS" not in result.stdout


def test_headless_launcher_preserves_status_and_cleans_owned_process(tmp_path):
    """Run the real launcher in a copied project with fake SDK tools."""
    project = tmp_path / "project"
    (project / "scripts/lib").mkdir(parents=True)
    (project / "config").mkdir()
    for name in ("run_headless_smoke.sh", "smoke_test.sh"):
        shutil.copy2(ROOT / "scripts" / name, project / "scripts" / name)
    shutil.copy2(ROOT / "config/android.env", project / "config/android.env")
    library = project / "scripts/lib/ci_emulator.sh"
    library.write_text(LIB.read_text() + '\ncheck_linux_kvm() { return 0; }\n')
    fake(tmp_path, "emulator", '''
if [[ "$1" == -list-avds ]]; then echo cookbook_pixel_api_36; exit 0; fi
printf '%s\\n' "$@" > "$ARGS_FILE"
echo $$ > "$PID_FILE"
echo emulator-started
exec sleep 60
''')
    fake(tmp_path, "adb", '''
if [[ "$1" == devices ]]; then echo 'List of devices attached'; exit 0; fi
if [[ "$3" == get-state ]]; then
    [[ -f "$PID_FILE" ]] || exit 1
    echo device
elif [[ "$3" == emu && "$4" == avd ]]; then echo cookbook_pixel_api_36
elif [[ "$3" == emu && "$4" == kill ]]; then kill "$(cat "$PID_FILE")"
elif [[ "$3" == shell && "$4" == getprop && "$5" == ro.build.version.sdk ]]; then echo "$TEST_API"
elif [[ "$3" == shell && "$4" == getprop ]]; then echo 1
elif [[ "$3" == shell && "$4" == cat ]]; then echo smoke-ok
fi
''')
    env = build_env(
        tmp_path,
        PID_FILE=str(tmp_path / "pid"),
        ARGS_FILE=str(tmp_path / "args"),
    )
    for api, expected_status in (("36", 0), ("35", 1)):
        (tmp_path / "pid").unlink(missing_ok=True)
        env["TEST_API"] = api
        try:
            result = run_bash([str(project / "scripts/run_headless_smoke.sh")], env)
            assert result.returncode == expected_status, result.stderr
            args = (tmp_path / "args").read_text().splitlines()
            assert args == [
                "-avd", "cookbook_pixel_api_36", "-port", "5554",
                "-no-window", "-no-audio", "-no-boot-anim", "-no-snapshot",
                "-gpu", "swiftshader_indirect",
            ]
            assert "Cleaning up owned emulator" in result.stdout
            assert (project / "artifacts/emulator.log").read_text().strip() == "emulator-started"
            pid = int((tmp_path / "pid").read_text())
            try:
                os.kill(pid, 0)
            except ProcessLookupError:
                pass
            else:
                raise AssertionError("Owned emulator survived cleanup")
        finally:
            if (tmp_path / "pid").exists():
                try:
                    os.kill(int((tmp_path / "pid").read_text()), 9)
                except ProcessLookupError:
                    pass
