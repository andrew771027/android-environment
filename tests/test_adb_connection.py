import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

LIB = ROOT / "scripts" / "lib" / "adb_connection.sh"

SERIAL = "ABC123"

def make_fake_adb(
    tmp_path: Path,
    *,
    state: str = "device",
) -> dict[str, str]:

    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()

    adb = bin_dir / "adb"

    adb.write_text(
        "#!/usr/bin/env bash\n"
        "\n"
        'if [[ "$1" == "devices" ]]; then\n'
        '   echo "List of devices attached\n'
        f'  printf "{SERIAL}\\t{state}\\n"\n'
        "   exit 0\n"
        "fi\n"
        "\n"
        'if [[ "$1 == "-s" && "$3" == "reconnect" ]]; then\n'
        '   echo "reconnecting $2"\n'
        "   exit 0\n"
        "fi\n"
        "\n"
        'if [[ "$1" == "kill-server" ]]; then\n'
        "   exit 0\n"
        "fi\n"
        "\n"
        "exit 1\n",
        encoding="utf-8",
    )

    adb.chmod(0o755)

    env = os.environ.copy()

    env["PATH"] = f"{bin_dir}:{env['PATH']}"

    return env


def make_fake_adb_without_device(
    tmp_path: Path,
) -> dict[str, str]:

    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()

    adb = bin_dir / "adb"

    adb.write_text(
        "#/usr/bin/env bash\n"
        'if [[ "$1" == "devices" ]]; then\n'
        '   echo "List of devices attached\n'
        "   exit 0\n"
        'fi\n'
        "exit 0\n",
        encoding="utf-8",
    )

    adb.chmod(0o755)

    env = os.environ.copy()

    env["PATH"] = f"{bin_dir}:{env['PATH']}"

    return env

def make_stateful_fake_adb(
    tmp_path: Path,
) -> tuple[dict[str, str], Path]:

    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()

    state_file = tmp_path / "adb-state"

    state_file.write_text(
        "offline",
        encoding="utf-8",
    )

    adb = bin_dir / "adb"

    adb.write_text(
        "#/usr/bin/env bash\n"
        f'STATE_FILE={state_file}\n'
        "\n"
        'if [[ "$1" == "devices" ]]; then\n'
        '   state="$(cat "$STATE_FILE")"\n'
        '   echo "List of devices attached"\n'
        f'  printf "{SERIAL}\\t%s\\n" "$state"\n'
        "   exit 0\n"
        "fi\n"
        "\n"
        'if [[ "$1" == "-s" && "$3" == "reconnect" ]]; then\n'
        '   echo "device" > "$STATE_FILE"\n'
        "   exit 0\n"
        "fi\n"
        "\n"
        "exit 0\n",
        encoding="utf-8",
    )

    adb.chmod(0o755)

    env = os.environ.copy()

    env["PATH"] = f"{bin_dir}:{env['PATH']}"

    return env, state_file

def run_bash(
    command: str,
    *,
    env: dict[str, str],
)-> subprocess.CompletedProcess[str]:

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

def test_device_state_device(
    tmp_path: Path,
):

    env = make_fake_adb(
        tmp_path,
        state="device",
    )

    result = run_bash(
        f'adb_device_state "{SERIAL}"',
        env=env,
    )

    assert result.returncode == 0
    
    assert result.stdout.strip() == "device"


def test_device_state_unauthorized(
    tmp_path: Path,
):

    env = make_fake_adb(
        tmp_path,
        state="unauthorized",
    )

    result = run_bash(
        f'adb_device_state "{SERIAL}"',
        env=env,
    )

    assert result.returncode == 0

    assert result.stdout.strip() == "unauthorized"

def test_device_state_offline(
    tmp_path: Path,
):

    env = make_fake_adb(
        tmp_path,
        state="offline",
    )

    result = run_bash(
        f'adb_device_state "{SERIAL}"',
        env=env,
    )

    assert result.returncode == 0

    assert result.stdout.strip() == "offline"

def test_device_state_ready(
    tmp_path: Path,
):

    env = make_fake_adb(
        tmp_path,
        state="device",
    )

    result = run_bash(
        f'adb_device_is_ready "{SERIAL}"',
        env=env,
    )

    assert result.returncode == 0

def test_unauthorized_not_ready(
    tmp_path: Path,
):


    env = make_fake_adb(
        tmp_path,
        state="unauthorized",
    )

    result = run_bash(
        f'adb_device_is_ready "{SERIAL}"',
        env=env,
    )

    assert result.returncode != 0

def test_offline_detected(
    tmp_path: Path,
):

    env = make_fake_adb(
        tmp_path,
        state="offline",
    )

    result = run_bash(
        f'adb_device_is_offline "{SERIAL}"',
        env=env,
    )

    assert result.returncode == 0

def test_unauthorized_detected(
    tmp_path: Path,
):

    env = make_fake_adb(
        tmp_path,
        state="unauthorized",
    )

    result = run_bash(
        f'adb_device_is_unauthorized "{SERIAL}"',
        env=env,
    )

    assert result.returncode == 0

def test_reconnect_device(
    tmp_path: Path,
):

    env = make_fake_adb(tmp_path)

    result = run_bash(
        f'adb_reconnect_device "{SERIAL}"',
        env=env,
    )

    assert result.returncode == 0

def test_restart_server(
    tmp_path: Path,
):

    env = make_fake_adb(tmp_path)

    result = run_bash(
        "adb_restart_server",
        env=env,
    )

    assert result.returncode == 0

def test_wait_for_ready_success(
    tmp_path: Path,
):

    env = make_fake_adb(
        tmp_path,
        state="device",
    )

    result = run_bash(
        f'wait_for_adb_ready "{SERIAL}" 1', 
    )

    assert result.returncode == 0

def test_wait_for_ready_timeout(
    tmp_path: Path,
):

    env = make_fake_adb(
        tmp_path,
        state="offline",
    )

    result = run_bash(
        f'wait_for_adb_ready "{SERIAL}" 1',
        env=env,
    )

    assert result.returncode != 0

def test_missing_devices(
    tmp_path: Path,
):

    env = make_fake_adb_without_device(
        tmp_path
    )

    result = run_bash(
        f'adb_device_exists "{SERIAL}"',
        env=env,
    )

    assert result.returncode != 0

def test_reconnect_changes_offline_to_device(
    tmp_path: Path,
):

    env, state_file = make_stateful_fake_adb(
        tmp_path
    )

    first = run_bash(
        f'adb_device_state "{SERIAL}"',
        env=env,
    )

    assert first.stdout.strip() == "offline"

    reconnect = run_bash(
        f'adb_reconnect_device "{SERIAL}"',
        env=env,
    )

    assert reconnect.returncode == 0

    second = run_bash(
        f'adb_device_state "{SERIAL}"',
        env=env,
    )

    assert second.stdout.strip() == "device"

    assert state_file.read_text(
            encoding="utf-8"
        ).strip() == "device"