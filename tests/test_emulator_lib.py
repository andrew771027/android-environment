import os
import subprocess
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]

EMULATOR_LIB = PROJECT_ROOT / "scripts" / "lib" / "emulator.sh"

COMMON_LIB = PROJECT_ROOT / "scripts" / "lib" / "common.sh"


def make_fake_command(directory: Path, name: str, content: str) -> Path:
    command = directory / name

    command.write_text(content, encoding="utf-8")

    command.chmod(0o755)

    return command


def run_bash(script: str, env: dict[str, str]) -> subprocess.CompletedProcess[str]:

    return subprocess.run(
        ["bash", "-c", script], text=True, capture_output=True, env=env, check=False
    )


def build_env(fake_bin: Path) -> dict[str, str]:
    env = os.environ.copy()

    env["PATH"] = f"{fake_bin}:" f"{env['PATH']}"

    return env


def test_get_emulator_serial(tmp_path: Path):

    fake_bin = tmp_path / "bin"
    fake_bin.mkdir()

    make_fake_command(
        fake_bin,
        "adb",
        """#!/usr/bin/env bash

if [[ "$1" == "devices" ]]; then
    echo "List of devices attached"
    echo "emulator-5554    device"
    echo "ABC123           device"
fi
""",
    )

    env = build_env(fake_bin)

    result = run_bash(
        f"""
source "{EMULATOR_LIB}"

get_emulator_serial
""",
        env,
    )

    assert result.returncode == 0
    assert result.stdout.strip() == "emulator-5554"


def test_get_emulator_serial_returns_empty_when_no_emulator(tmp_path: Path):

    fake_bin = tmp_path / "bin"
    fake_bin.mkdir()

    make_fake_command(
        fake_bin,
        "adb",
        """#!/usr/bin/env bash

if [[ "$1" == "devices" ]]; then
    echo "List of devices attached"
    echo "ABC123    device"
fi
"""
    )

    env = build_env(fake_bin)

    result = run_bash(
        f"""
source "{EMULATOR_LIB}"

get_emulator_serial
""",
        env,
    )

    assert result.returncode == 0
    assert result.stdout.strip() == ""


def test_emulator_boot_completed(tmp_path: Path):

    fake_bin = tmp_path / "bin"
    fake_bin.mkdir()

    make_fake_command(
        fake_bin,
        "adb",
        """#!/usr/bin/env bash

if [[ "$1" == "devices" ]]; then

    echo "List of devices attached"
    echo "emulator-5554    device"

    exit 0
fi


if [[ "$1" == "-s" ]]; then

    echo "1"

    exit 0
fi
"""
    )


    env = build_env(fake_bin)

    result = run_bash(
        f"""
source "{EMULATOR_LIB}"

if is_emulator_boot_completed; then
    echo READY
else
    echo NOT_READY
fi
""",
        env,
    )

    assert result.returncode == 0
    assert result.stdout.strip() == "READY"


def test_emulator_not_bnoot_completed(tmp_path: Path):

    fake_bin = tmp_path / "bin"
    fake_bin.mkdir()

    make_fake_command(
        fake_bin,
        "adb",
        """#!/usr/bin/env bash

if [[ "$1" == "devices" ]]; then

    echo "List of devices attached"
    echo "emulator-5554    device"

    exit 0
fi


if [[ "$1" == "-s" ]]; then

    echo "0"

    exit 0
fi
"""
    )


    env = build_env(fake_bin)

    result = run_bash(
        f"""
source "{EMULATOR_LIB}"

if is_emulator_boot_completed; then
    echo READY
else
    echo NOT_READY
fi
""",
        env,
    )

    assert result.returncode == 0
    assert "NOT_READY" in result.stdout


def test_boot_complated_returns_false_when_no_emulator(tmp_path: Path):

    fake_bin = tmp_path / "bin"
    fake_bin.mkdir()

    make_fake_command(
        fake_bin,
        "adb",
        """#!/usr/bin/env bash

echo "List of devices attached"
"""
    )

    env = build_env(fake_bin)

    result = run_bash(
        f"""
source "{EMULATOR_LIB}"

if is_emulator_boot_completed; then
    echo READY
else
    echo NOT_READY
fi
""",
        env,
    )

    assert result.returncode == 0
    assert "NOT_READY" in result.stdout


def test_wait_for_emulator_boot_timeout(tmp_path: Path):

    fake_bin = tmp_path / "bin"
    fake_bin.mkdir()

    make_fake_command(
        fake_bin,
        "adb",
        """#!/usr/bin/env bash

if [[ "$1" == "devices" ]]; then
    echo "List of devices attached"
    exit 0
fi
"""
    )

    env = build_env(fake_bin)
    result = run_bash(
        f"""
source "{COMMON_LIB}"
source "{EMULATOR_LIB}"

if wait_for_emulator_boot 2 1; then
    echo READY
else
    echo TIMEOUT
fi
""",
        env,
    )

    assert result.returncode == 0
    assert result.stdout.splitlines()[-1] == "TIMEOUT"
