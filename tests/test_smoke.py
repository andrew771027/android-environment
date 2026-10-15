import os
import subprocess
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]

LIB = ROOT / "scripts" / "lib" / "smoke.sh" 

SERIAL = "emulator-5554"

def create_fake_adb(
    tmp_path: Path,
    *,
    adb_start: str = "device",
    boot_completed: str = "1",
    sdk_version: str = "36",
    device_model: str = "Pixel_7",
    package_manager_exit_code: int = 0,
    shell_result: str = "smoke-ok",
) -> dict[str, str]:

    bin_dir = tmp_path / "bin"

    bin_dir.mkdir()

    adb = bin_dir / "adb"

    adb.write_text(
        "#!/usr/bin/env bash\n"
        "\n"
        'if [[ "$3" == "get-state" ]]; then\n'
        f'  echo "{adb_state}"\n'
        "   exit 0\n"
        "fi\n"
        "\n"
        'if [[ "$3" == "shell" && "$4" == "getprop" ]]; then\n'
        '    if [[ "$5" == "sys.boot_completed" ]]; then\n'
        f'        echo "{boot_completed}"\n'
        "        exit 0\n"
        "    fi\n"
        "\n"
        '    if [[ "$5" == "ro.build.version.sdk" ]]; then\n'
        f'        echo "{sdk_version}"\n'
        "        exit 0\n"
        "    fi\n"
        "\n"
        '    if [[ "$5" == "ro.product.model" ]]; then\n'
        f'        echo "{device_model}"\n'
        "        exit 0\n"
        "    fi\n"
        "fi\n"
        "\n"
        'if [[ "$3" == "shell" && "$4" == "pm" ]]; then\n'
        f"    exit {package_manager_exit_code}\n"
        "fi\n"
        "\n"
        'if [[ "$3" == "shell" && "$4" == "echo" ]]; then\n'
        f'    echo "{shell_result}"\n'
        "    exit 0\n"
        "fi\n"
        "\n"
        "exit 1\n",
        encoding="utf-8"
    )

    adb.chmod(0o755)

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

def test_smoke_adb_ready(tmp_path: Path):

    env = create_fake_adb(tmp_path)

    result = run_bash(
        f'smoke_adb_ready "{SERIAL}"',
    )

    assert result.returncode == 0

def test_smoke_adb_offline(tmp_path: Path):

    env = create_fake_adb(
        tmp_path,
        adb_state="offline",
    )

    result = run_bash(
        f'smoke_adb_ready "{SERIAL}"',
        env,
    )

    assert result.returncode != 0

def test_smoke_boot_completed(tmp_path: Path):

    env = create_fake_adb(tmp_path)

    result = run_bash(
        f'smoke_boot_completed "{SERIAL}"',
        env,
    )

    assert result.returncode == 0

def test_smoke_boot_not_completed(tmp_path: Path):

    env = create_fake_adb(
        tmp_path,
        boot_completed="0",
    )

    result = run_bash(
        f'smoke_boot_complated "{SERIAL}',
        env,
    )

    assert result.returncode != 0

def test_smoke_android_sdk(tmp_path: Path):

    env = create_fake_adb(
        tmp_path,
        sdk_version="36",
    )

    result = run_bash(
        f'smoke_android_sdk "{SERIAL}"',
        env,
    )

    assert result.returncode == 0

def test_smoke_android_sdk_invalid(tmp_path: Path):

    env = create_fake_adb(
        tmp_path,
        sdk_version="unknown",
    )

    result = run_bash(
        f'smoke_android_sdk "{SERIAL}"',
        env,
    )

    assert result.returncode != 0

def test_smoke_device_model(tmp_path: Path):

    env = create_fake_adb(
        tmp_path,
        device_model="Pixel_7",
    )

    result = run_bash(
        f'smoke_device_model "{SERIAL}"',
        env,
    )

    assert result.returncode == 0

def test_smoke_device_model_missing(tmp_path: Path):


    env = create_fake_adb(
        tmp_path,
        device_model="",
    )

    result = run_bash(
        f'smoke_device_model "{SERIAL}"',
        env,
    )

    assert result.returncode != 0

def test_smoke_package_manager(tmp_path: Path):

    env = create_fake_adb(
        tmp_path,
        package_manager_exit_code=0,
    )

    result = run_bash(
        f'smoke_package_manager "{SERIAL}"',
        env,
    )

    assert result.returncode == 0

def test_smoke_package_manager_failure(tmp_path: Path):


    env = create_fake_adb(
        tmp_path,
        package_manager_exit_code=1,
    )

    result = run_bash(
        f'smoke_package_manager "{SERIAL}"',
        env,
    )

    assert result.returncode != 0

def test_smoke_shell_command(tmp_path: Path):

    env = create_fake_adb(tmp_path)

    result = run_bash(
        f'smoke_shell_command "{SERIAL}"',
        env,
    )

    assert result.returncode == 0

def test_smoke_shell_command_failure(tmp_path: Path):
    
    env = create_fake_adb(
        tmp_path,
        shell_result="unexpected",
    )

    result = run_bash(
        f'smoke_shell_command "{SERIAL}"',
        env,
    )

    assert result.returncode != 0