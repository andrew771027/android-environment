import os
import subprocess
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]

LIB = PROJECT_ROOT / "scripts" / "lib" / "kvm.sh"


def run_bash(
    script: str,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:

    return subprocess.run(
        ["bash", "-c", script],
        text=True,
        capture_output=True,
        env=env,
        check=False,
    )


def make_fake_command(directory: Path, name: str, content: str) -> Path:

    command = directory / name

    command.write_text(content, encoding="utf-8")

    command.chmod(0o775)

    return command


def test_kvm_device_exists(tmp_path: Path):

    fake_kvm = tmp_path / "kvm"

    fake_kvm.touch()

    result = run_bash(
        f"""
source "{LIB}"

if kvm_device_exists "{fake_kvm}"; then
    echo EXISTS
else
    echo MISSING
fi
"""
    )

    assert result.returncode == 0
    assert result.stderr == ""
    assert result.stdout.strip() == "EXISTS"


def test_kvm_device_missing(tmp_path: Path):

    fake_kvm = tmp_path / "missing-kvm"

    result = run_bash(
        f"""
source "{LIB}"

if kvm_device_exists "{fake_kvm}"; then
    echo EXISTS
else
    echo MISSING
fi
"""
    )

    assert result.returncode == 0
    assert result.stderr == ""
    assert result.stdout.strip() == "MISSING"


def test_emulator_acceleration_available(tmp_path: Path):

    fake_bin = tmp_path / "bin"

    fake_bin.mkdir()

    make_fake_command(
        fake_bin,
        "emulator",
        """#!/usr/bin/env bash
if [[ "$1" == "-accel-check" ]]; then
    echo "KVM is installed and usable."
    exit 0
fi

exit 1
""",
    )

    env = os.environ.copy()
    env["PATH"] = f"{fake_bin}:" f"{env['PATH']}"

    result = run_bash(
        f"""
    source "{LIB}"

if emulator_acceleration_available; then
    echo AVAILABLE
else
    echo UNAVAILABLE
fi
""",
        env,
    )

    assert result.returncode == 0
    assert result.stderr == ""
    assert result.stdout.strip() == "AVAILABLE"


def test_emulator_acceleration_unavailable(tmp_path: Path):

    fake_bin = tmp_path / "bin"

    fake_bin.mkdir()

    make_fake_command(
        fake_bin,
        "emulator",
        """#!/usr/bin/env bash

if [[ "$1" == "-accel-check" ]]; then

    echo "KVM is not available."
    exit 1
fi

exit 1
""",
    )

    env = os.environ.copy()

    env["PATH"] = f"{fake_bin}:{env['PATH']}"

    result = run_bash(
        f"""
source "{LIB}"

if emulator_acceleration_available; then
    echo AVAILABLE
else
    echo UNAVAILABLE
fi
""",
        env,
    )

    assert result.returncode == 0
    assert result.stderr == ""
    assert result.stdout.strip() == "UNAVAILABLE"
