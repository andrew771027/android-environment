import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

LIB = ROOT / "scripts" / "lib" / "physical_device.sh"

SERIAL = "ABC123"

def make_fake_tools(
    tmp_path: Path,
    *,
    adb_state: str = device,
    include_emulator: bool = False,
    fastboot_emulator: bool = False,
) -> dict[str, str]:

    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()

    adb = bin_dir / "adb"

    device_lines = []

    if include_emulator:
        device_lines.append("emulator-5554\tdevice")
    
    device_lines.append(
        f"{SERIAL}\t{adb_state}"
    )

    adb_devices_output = "\\n".join(device_lines)

    adb.write_text(
        "#!/usr/bin/env bash\n"
        "\n"
        'if [[ "$1" == "devices" ]]; then\n'
        '    echo "List of devices attached"\n'
        f'    printf "%b\\n" "{adb_devices_output}"\n'
        "    exit 0\n"
        "fi\n"
        "\n"
        'if [[ "$1" == "-s" && "$3" == "shell" '
        '&& "$4" == "getprop" ]]; then\n'
        "\n"
        '    case "$5" in\n'
        '        ro.product.manufacturer)\n'
        '            echo "Google"\n'
        '            ;;\n'
        '        ro.product.model)\n'
        '            echo "Pixel Test"\n'
        '            ;;\n'
        '        ro.product.name)\n'
        '            echo "test_product"\n'
        '            ;;\n'
        '        ro.product.device)\n'
        '            echo "test_device"\n'
        '            ;;\n'
        '        ro.build.version.release)\n'
        '            echo "16"\n'
        '            ;;\n'
        '        ro.build.version.sdk)\n'
        '            echo "36"\n'
        '            ;;\n'
        '        ro.build.fingerprint)\n'
        '            echo "google/test/test:16/test"\n'
        '            ;;\n'
        '    esac\n'
        "\n"
        "    exit 0\n"
        "fi\n"
        "\n"
        "exit 1\n",
        encoding="utf-8",
    )

    adb.chmod(0o755)

    fastboot = bin_dir / "fastboot"

    if fastboot_present:

        fastboot_output = (
            f'echo "{SERIAL}\\tfastboot"'
        )
    
    else:

        fastboot_output = "true"
    
    fastboot.write_text(
        "#!/usr/bin/env bash\n"
        "\n"
        'if [[ "$1" == "devices" ]]; then\n'
        f"    {fastboot_output}\n"
        "    exit 0\n"
        "fi\n"
        "\n"
        "exit 1\n",
        encoding="utf-8",
    )

    fastboot.chmod(0o755)

    env = os.environ.copy()

    env["PATH"] = (
        f"{bin_dir}:{env['PATH']}"
    )

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


def test_list_physical_deivce(
    tmp_path: Path,
):

    env = make_fake_tools(tmp_path)

    result = run_bash(
        "list_physical_adb_devices",
        env,
    )

    assert result.returncode == 0
    
    assert result.stdout.strip() == (
        f"{SERIAL} device"
    )

def test_emulator_is_excluded(
    tmp_path: Path,
):

    env = make_fake_tools(
        tmp_path,
        include_emulator=True,
    )

    result = run_bash(
        "list_physical_adb_devices",
        env,
    )

    assert result.returncode == 0

    assert "emulator-5554" not in result.stdout

    assert SERIAL in result.stdout

def test_authorized_deivce(
    tmp_path: Path,
):

    env = make_fake_tools(
        tmp_path,
        adb_state="device",
    )

    result = run_bash(
        f'physical_device_is_authorized "{SERIAL}"',
        env,
    )

    assert result.returncode == 0

def test_unauthorized_device(
    tmp_path: Path,
):
    env = make_fake_tools(
        tmp_path,
        adb_state="unauthorized",
    )

    result = run_bash(
        f'physical_device_is_authorized "{SERIAL}"',
    )

    assert result.returncode != 0

def test_physical_device_state(
    tmp_path: Path,
):

    env = make_fake_tools(
        tmp_path,
        adb_state="offline"
    )

    result = run_bash(
        f'physical_device_state "{SERIAL}"',
        env,
    )

    assert result.returncode == 0

    assert result.stdout.strip() == "offline"


def test_select_single_physical_device(
    tmp_path: Path,
):

    env = make_fake_tools(tmp_path)

    result = run_bash(
        "select_single_physical_device",
        env,
    )

    assert result.returncode == 0

    assert result.stdout.strip() == SERIAL

def test_device_model(
    tmp_path: Path,
): 

    env = make_fake_tools(tmp_path)

    result = run_bash(
        f'device_model "{SERIAL}"',
        env,
    )

    assert result.returncode == 0

    assert result.stdout.strip() == "Pixel Test"

def test_deivce_sdk_level(
    tmp_path: Path,
):

    env = make_fake_tools(tmp_path)

    result = run_bash(
        f'device_sdk_level "{SERIAL}"',
    )

    assert result.returncode == 0

    assert result.stdout.strip() == "36"

def test_fastboot_device_present(
    tmp_path: Path,
):

    env = make_fake_tools(
        tmp_path,
        fastboot_present=True,
    )

    result = run_bash(
        f'fastboot_device_present "{SERIAL}"',
        env,
    )

    assert result.returncode == 0

def test_fastboot_device_missing(
    tmp_path: Path,
):

    env = make_fake_tools(
        tmp_path,
        fastboot_present=False,
    )

    result = run_bash(
        f'fastboot_device_present "{SERIAL}"',
        env,
    )

    assert result.returncode != 0

def test_multiple_devices_requires_explicit_serial(
    tmp_path: Path,
):

    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()

    adb = bin_dir / "adb"

    adb.write_text(
        "#!/usr/bin/env bash\n"
        'if [[ "$1" == "devices" ]]; then\n'
        '    echo "List of devices attached"\n'
        '    printf "ABC123\\tdevice\\n"\n'
        '    printf "DEF456\\tdevice\\n"\n'
        "fi\n",
        encoding="utf-8",
    )

    adb.chmod(0o755)

    env = os.environ.copy()

    env["PATH"] = f"{bin_dir}:{env['PATH']}"

    result = run_bash(
        "select_single_physical_device",
        env,
    )

    assert result.returncode == 2