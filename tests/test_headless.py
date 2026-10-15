import os
import subprocess
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]

LIB = PROJECT_ROOT / "scripts" / "lib" / "headless.sh"


def test_status_reports_adb_failure(tmp_path: Path):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    adb = bin_dir / "adb"
    adb.write_text("#!/usr/bin/env bash\nexit 1\n", encoding="utf-8")
    adb.chmod(0o755)
    env = os.environ.copy()
    env["PATH"] = f"{bin_dir}:{env['PATH']}"

    result = subprocess.run(
        ["bash", str(PROJECT_ROOT / "scripts" / "headless_status.sh")],
        env=env,
        text=True,
        capture_output=True,
        timeout=15,
    )

    assert result.returncode == 1
    assert "Unable to query ADB devices" in result.stderr
    assert "STOPPED" not in result.stdout


# --------------------------------------------------
# Test helper: fake adb
# --------------------------------------------------


def fake_adb(
    tmp_path: Path,
    boot_value: str,
) -> dict[str, str]:

    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()

    adb = bin_dir / "adb"

    adb.write_text(
        "#!/usr/bin/env bash\n"
        'if [[ "$1" == "devices" ]]; then\n'
        '  printf "List of devices attached\\nemulator-5554\\tdevice\\n"\n'
        'elif [[ "$3" == "get-state" ]]; then\n'
        "  echo device\n"
        'elif [[ "$3" == "shell" ]]; then\n'
        f'  echo "{boot_value}"\n'
        'elif [[ "$3" == "emu" && "$4" == "avd" && "$5" == "name" ]]; then\n'
        '  printf "cookbook_pixel_api_36\\r\\nOK\\r\\n"\n'
        "else\n"
        '  echo "Unexpected adb arguments: $*" >&2\n'
        "  exit 2\n"
        "fi\n",
        encoding="utf-8",
    )

    adb.chmod(0o755)

    env = os.environ.copy()

    env["PATH"] = f"{bin_dir}:{env['PATH']}"

    return env


# --------------------------------------------------
# Test helper: run Bash
# --------------------------------------------------


def run_bash(
    command: str,
    env: dict[str, str],
) -> subprocess.CompletedProcess[str]:

    return subprocess.run(
        ["bash", "-c", f'source "{LIB}"; {command}'],
        env=env,
        text=True,
        capture_output=True,
        check=False,
        timeout=15,
    )


# --------------------------------------------------
# Test 1: emulator listed
# --------------------------------------------------


def test_device_listed(tmp_path: Path):

    env = fake_adb(tmp_path, "0")

    result = run_bash(
        "emulator_listed",
        env,
    )

    assert result.stderr == ""
    assert result.returncode == 0


# --------------------------------------------------
# Test 2: boot not ready
# --------------------------------------------------


def test_boot_not_ready(tmp_path: Path):

    env = fake_adb(tmp_path, "0")

    result = run_bash(
        "boot_ready",
        env,
    )

    assert result.stderr == ""
    assert result.returncode == 1


# --------------------------------------------------
# Test 3: boot ready
# --------------------------------------------------


def test_boot_ready(tmp_path: Path):

    env = fake_adb(tmp_path, "1")

    result = run_bash(
        "boot_ready",
        env,
    )

    assert result.stderr == ""
    assert result.returncode == 0


# --------------------------------------------------
# Test 4: wait timeout
# --------------------------------------------------


def test_wait_timeout(tmp_path: Path):

    env = fake_adb(tmp_path, "0")

    result = run_bash(
        "wait_for_boot 1",
        env,
    )

    assert result.stderr == ""
    assert result.returncode == 1


# --------------------------------------------------
# Test 5: wait success
# --------------------------------------------------


def test_wait_success(tmp_path: Path):

    env = fake_adb(tmp_path, "1")

    result = run_bash("wait_for_boot 1", env)

    assert result.stderr == ""
    assert result.returncode == 0


def test_avd_name_for_serial(tmp_path: Path):
    env = fake_adb(tmp_path, "1")

    result = run_bash("avd_name_for_serial", env)

    assert result.returncode == 0
    assert result.stderr == ""
    assert result.stdout == "cookbook_pixel_api_36\n"


def test_stop_reports_adb_failure(tmp_path):
    env = fake_adb(tmp_path, "1")

    (tmp_path / "bin" / "adb").write_text("#!/bin/bash\nexit 1\n")

    result = subprocess.run(
        [
            "bash",
            str(PROJECT_ROOT / "scripts" / "headless_stop.sh"),
        ],
        env=env,
        text=True,
        capture_output=True,
        timeout=10,
    )
    assert result.returncode == 1
    assert "Unable to query ADB devices" in result.stderr
    assert "Already stopped" not in result.stdout


def test_start_does_not_launch_when_adb_listing_fails(tmp_path):
    env = fake_adb(tmp_path, "1")

    (tmp_path / "bin" / "adb").write_text("#!/bin/bash\nexit 1\n")

    marker = tmp_path / "launched"

    emulator = tmp_path / "bin" / "emulator"

    emulator.write_text(
        "#!/bin/bash\n"
        'case "$1" in\n'
        " -accel-check) exit 0 ;;\n"
        " -list-avds) echo cookbook_pixel_api_36; exit 0 ;;\n"
        f' *) touch "{marker}"; exit 1 ;;\n'
        "esac\n"
    )
    emulator.chmod(0o755)
    # Make the acceleration branch independent of the real host.
    uname = tmp_path / "bin" / "uname"

    uname.write_text(
        '#!/bin/bash\ncase "$1" in -s) echo Darwin ;; *) echo x86_64 ;; esac\n'
    )

    uname.chmod(0o755)

    result = subprocess.run(
        [
            "bash",
            str(PROJECT_ROOT / "scripts" / "headless_start.sh"),
        ],
        env=env,
        text=True,
        capture_output=True,
        timeout=10,
    )
    assert result.returncode == 1
    assert "Unable to query ADB devices" in result.stderr
    assert not marker.exists()
