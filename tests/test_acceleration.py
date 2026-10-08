import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

LIB = ROOT / "scripts" / "lib" / "acceleration.sh"

def make_fake_emulator(tmp_path: Path, *, accel_exit_code: int, ) -> dict[str, str]:

    bin_dir = tmp_path / "bin"

    bin_dir.mkdir()

    emulator = bin_dir / "emulator"

    emulator.write_text(
        "#!/usr/bin/env bash\n"
        "\n"
        'if [[ "$1" == "-accel-check" ]]; then\n'
        '    echo "accel:"\n'
        f"    exit {accel_exit_code}\n"
        "fi\n"
        "\n"
        "exit 1\n",
        encoding="utf-8",
    )

    emulator.chmod(0o755)

    env = os.environ.copy()

    env["PATH"] = f"{bin_dir}:{env['PATH']}"

    return env

def run_bash(
    command: str,
    env: dict[str, str],
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

def test_macos_acceleration_available(tmp_path: Path):

    env = make_fake_emulator(
        tmp_path,
        accel_exit_code=0,
    )

    result = run_bash(
        "check_macos_acceleration",
        env,
    )

    assert result.returncode == 0

def test_macos_acceleration_unavailable(tmp_path: Path):

    env = make_fake_emulator(
        tmp_path,
        accel_exit_code=1,
    )

    result = run_bash(
        "check_macos_acceleration",
        env,
    )

    assert result.returncode != 0

def test_emulator_exists(tmp_path: Path):

    env = make_fake_emulator(
        tmp_path,
        accel_exit_code=0,
    )

    result = run_bash(
        "check_emulator_exists",
        env,
    )

    assert result.returncode == 0

def test_emulator_missing(tmp_path: Path):

    empty_bin = tmp_path / "bin"

    empty_bin.mkdir()

    env = os.environ.copy()

    env["PATH"] = str(empty_bin)

    result = subprocess.run(
        [
            "/bin/bash",
            "-c",
            f'source "{LIB}"; check_emulator_exists';
        ],
        env=env,
        text=True,
        capture_output=True,
        check=False,
        timeout=10,
    )

    assert result.returncode != 0

def test_macos_dispatch(tmp_path: Path):

    bin_dir = tmp_path / "bin"
    
    bin_dir.mkdir()

    uname = bin_dir / "uname"

    uname.write_text(
        "#!/usr/bin/env bash\n"
        'if [[ "$1" == "-s" ]]; then\n'
        '    echo "Darwin"\n'
        'elif [[ "$1" == "-m" ]]; then\n'
        '    echo "x86_64"\n'
        "else\n"
        '    echo "Darwin"\n'
        "fi\n",
        encoding="utf-8",
    )

    uname.chmod(0o755)

    emulator = bin_dir / "emulator"

    emulator.write_text(
        "#!/usr/bin/env bash\n"
        'if [[ "$1" == "-accel-check" ]]; then\n'
        "    exit 0\n"
        "fi\n"
        "exit 1\n",
        encoding="utf-8",
    )

    emulator.chmod(0o755)

    env = os.environ.copy()

    env["PATH"] = f"{bin_dir}:{env['PATH']}"

    result = subprocess.run(
        [
            "bash",
            str(ROOT / "scripts" / "check_acceleration.sh"),
        ],
        env=env,
        text=True,
        capture_output=True,
        check=False,
        timeout=10,
    )

    assert result.returncode == 0

    assert "macOS Emulator Acceleration Chcek PASSED" in result.stdout