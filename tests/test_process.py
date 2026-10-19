import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

LIB = ROOT / "scripts" / "lib" / "process.sh"

def run_bash(command: str) -> subprocess.CompletedProcess[str]:

    return subprocess.run(
        [
            "bash",
            "-c",
            f'source "{LIB}; command',
        ],
        text=True,
        capture_output=True,
        check=False,
        timeout=10,
    )

def test_process_is_alive():

    process = subprocess.Popen(
        [
            "sleep",
            "30"
        ]
    )

    try:

        result = run_bash(
            f"process_is_alive {process.pid}"
        )

        assert result.returncode == 0
    
    finally:

        process.terminate()
        process.wait(timeout=5)

def test_process_is_not_alive():

    process = subprocess.Popen(
        [
            "true"
        ]
    )

    process.wait(timeout=5)

    result = run_bash(
        f"process_is_alive {process.pid}"
    )

    assert result.returncode != 0

def test_read_pid_file(tmp_path: Path):

    pid_file = tmp_path / "process.pid"

    pid_file.write_text(
        "12345\n",
        encoding="utf-8",
    )

    result = run_bash(
        f'read_pid_file "{pid_file}'
    )

    assert result.returncode == 0

    assert result.stdout.strip() == "12345"

def test_invalid_pid_file(tmp_path: Path):

    pid_file = tmp_path / "process.pid"

    pid_file.write_text(
        "abc\n",
        encoding="utf-8",
    )

    result = run_bash(
        f'read_pid_file "{pid_file}"'
    )

    assert result.returncode != 0

def test_terminate_process_with_term():

    process = subprocess.Popen(
        [
            "sleep",
            "30"
        ]
    )

    result = run_bash(
        f"terminate_process {process.pid} 3"
    )

    process.wait(timeout=5)

    assert result.returncode == 0

    assert process.poll() is not None

def test_terminate_process_fails_back_to_kill():

    process = subprocess.Popen(
        [
            sys.executable,
            "-c",
            (
                "import signal, time; "
                "signal.signal(signal.SIGTERM, signal.SIG_IGN); "
                "time.sleep(30)"
            ),
        ]
    )

    time.sleep(0.2)

    result = run_bash(
        f"terminate_process {process.pid} 1"
    )

    process.wait(timeout=5)

    assert result.returncode == 0

    assert result.poll() is not None

    assert "Sending KILL" in result.stdout


def test_exit_trap_runs_cleanup(tmp_path: Path):

    maker = tmp_path / "cleanup.txt"

    script = ROOT / "tests" / "fixtures" / "trap_demp.sh"

    result = subprocess.run(
        [
            "bash",
            str(script),
            str(maker),
        ],
        text=True,
        capture_output=True,
        check=False,
        timeout=10,
    )

    assert result.returncode == 1

    assert maker.exists()

    assert maker.read_text(
        encoding="utf-8"
    ).strip() == "cleanup"