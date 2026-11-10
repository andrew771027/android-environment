import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

LIB = ROOT / "scripts" / "lib" / "usb.sh"

def make_fake_command(
    bin_dir: Path,
    name: str,
    body: str,
) -> Path:

    path = bin_dir / name

    path.write_text(
        "!/usr/bin/env bash\n"
        f"{body}\n",
        encoding="utf-8"
    )

    path.chmod(0o755)

    return path

def run_bash(
    command: str,
    *,
    env:dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:

    return subprocess.run(
        [
            "bash",
            "-c",
            f'source "{LIB}"; {command}',
        ],
        env=env,
        text=True,
        capture_output=True,
        check=False,
        timeout=10,
    )

def test_linux_lsusb_available(
    tmp_path: Path,
):

    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()

    make_fake_command(
        bin_dir,
        "lsusb",
        "exit 0",
    )

    env = os.environ.copy()
    env["PATH"] = f"{bin_dir}:{env['PATH']}"

    result = run_bash(
        "linux_lsusb_available",
        env=env,
    )

    assert result.returncode == 0

def test_linux_lsusb_missing(
    tmp_path: Path,
):

    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()

    env = os.environ.copy()

    env["PATH"] = str(bin_dir)

    result = subprocess.run(
        [
            "/bin/bash",
            "-c",
            f'source "{LIB}"; linux_lsusb_available',
        ],
        env=env,
        text=True,
        capture_output=True,
        check=False,
        timeout=10,
    )

    assert result.returncode != 0

def test_linux_usb_devices(
    tmp_path: Path,
):

    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()

    make_fake_command(
        bin_dir,
        "lsusb",
        'echo "Bus 001 Device 004: ID 18d1:4ee7 Google Inc."',
    )

    env = os.environ.copy()
    env["PATH"] = f"{bin_dir}:{env['PATH']}"

    result = run_bash(
        "linux_usb_devices",
        env=env,
    )

    assert result.returncode == 0
    assert "Google Inc." in result.stdout

def test_linux_user_in_plugdev(
    tmp_path: Path,
):

    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()

    make_fake_command(
        bin_dir,
        "id",
        'echo "codespace docker plugdev"',
    )

    env = os.environ.copy()
    env["PATH"] = f"{bin_dir}:{env['PATH']}"

    result = run_bash(
        "linux_user_in_plugdev",
        env=env,
    )

    assert result.returncode == 0

def test_linux_user_not_in_plugdev(
    tmp_path: Path
):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()

    make_fake_command(
        bin_dir,
        "id",
        'echo "codespace docker"',
    )

    env = os.environ.copy()
    env["PATh"] = f"{bin_dir}:{env['PATH']}"

    result = run_bash(
        "linux_user_in_plugdev",
        env=env,
    )

    assert result.returncode != 0

def test_linux_android_udev_rule_present(
    tmp_path: Path,
):
    lib_dir = tmp_path / "lib"
    etc_dir = tmp_path / "etc"

    lib_dir.mkdir()
    etc_dir.mkdir()

    rule = lib_dir / "51-android.rules"

    rule.write_text(
        '# Android device rules\n',
        encoding="utf-8"
    )

    result = run_bash(
        (
            "linux_android_udev_rules_present "
            f'"{lib_dir}" "{etc_dir}"'
        )
    )

def test_linux_android_udev_rule_missing(
    tmp_path: Path,
):

    lib_dir = tmp_path / "lib"
    etc_dir = tmp_path / "etc"

    lib_dir.mkdir()
    etc_dir.mkdir()

    result = run_bash(
        (
            "linux_android_udev_rules_present "
            f'"{lib_dir}" "{etc_dir}"'
        )
    )

    assert result.returncode != 0

def test_macos_system_profiler_available(
    tmp_path: Path,
):

    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()

    make_fake_command(
        bin_dir,
        "system_profiler",
        "exit 0",
    )

    env = os.environ.copy()
    env["PATH"] = f"{bin_dir}:{env['PATH']}"

    result = run_bash(
        "macos_system_profiler_available",
        env=env,
    )

    assert result.returncode == 0

def test_macos_usb_devices(
    tmp_path: Path,
):

    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()

    make_fake_command(
        bin_dir,
        "system_profiler",
        (
            'if [[ "$1" == "SPUSBDataType" ]]; then\n'
            '  echo "Android USB Device"\n'
            "fi"
        ),
    )

    env = os.environ.copy()
    env["PATH"] = f"{bin_dir}:{env['PATH']}"

    result = run_bash(
        "macos_usb_devices",
        env=env,
    )

    assert result.returncode == 0
    assert "Android USB Device" in result.stdout

def test_linux_host_supported():

    result = run_bash(
        'usb_host_supported "linux"'
    )

    assert result.returncode == 0

def test_linux_host_supported():

    result = run_bash(
        'usb_host_supported "darwin"'
    )

    assert result.returncode == 0

def test_windows_not_supported_in_v051():

    result = run_bash(
        'usb_host_supported "windows"'
    )

    assert result.returncode != 0