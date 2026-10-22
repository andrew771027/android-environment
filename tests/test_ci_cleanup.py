import os
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]


@pytest.mark.parametrize(
    "launch, workflow_rc, cleanup_rc, expected",
    [
        (False, 1, 0, 1),
        (True, 1, 0, 1),
        (True, 0, 0, 0),
        (True, 0, 7, 7),
        (True, 3, 7, 3),
    ],
)
def test_ci_cleans_only_this_run(tmp_path, launch, workflow_rc, cleanup_rc, expected):
    scripts = tmp_path / "scripts"

    scripts.mkdir()

    shutil.copy(ROOT / "scripts/ci_headless_smoke.sh", scripts)

    marker = tmp_path / "stopped"

    start = scripts / "headless_start.sh"

    start.write_text(
        "#!/bin/bash\n"
        + ('echo 12345 > "$HEADLESS_PID_FILE"\n' if launch else "")
        + f"exit {workflow_rc}\n"
    )

    stop = scripts / "headless_stop.sh"

    stop.write_text(
        "#!/bin/bash\n"
        '[[ "$1" == --owned ]] || exit 99\n'
        '[[ "$(cat "$HEADLESS_PID_FILE")" == 12345 ]] || exit 98\n'
        f'touch "{marker}"\nexit {cleanup_rc}\n'
    )

    smoke = scripts / "smoke_test.sh"

    smoke.write_text("#!/bin/bash\nexit 0\n")

    for script in (start, stop, smoke):
        script.chmod(0o755)

    env = dict(os.environ, TMPDIR=str(tmp_path))

    result = subprocess.run(
        ["bash", str(scripts / "ci_headless_smoke.sh")],
        env=env,
        capture_output=True,
        text=True,
        timeout=10,
    )

    assert result.returncode == expected
    assert marker.exists() == launch
    assert f"Cleanup exit code: {cleanup_rc if launch else 0}" in result.stdout


def test_owned_stop_rejects_unrelated_process(tmp_path):
    pid_file = tmp_path / "emulator.pid"

    with subprocess.Popen(["sleep", "30"]) as process:
        try:
            pid_file.write_text(f"{process.pid}\n")
            result = subprocess.run(
                ["bash", str(ROOT / "scripts/headless_stop.sh"), "--owned"],
                env=dict(os.environ, HEADLESS_PID_FILE=str(pid_file)),
                capture_output=True,
                text=True,
                timeout=10,
            )

            assert result.returncode == 1
            assert "Refusing to terminate unidentified PID" in result.stderr
            assert process.poll() is None

        finally:
            process.terminate()
            process.wait(timeout=5)


def test_owned_stop_works_without_adb(tmp_path):
    emulator = tmp_path / "emulator"
    emulator.write_text(
        '#!/bin/bash\ntrap "exit 0" TERM\nwhile :; do sleep 0.1; done\n'
    )
    emulator.chmod(0o755)
    pid_file = tmp_path / "emulator.pid"
    process = subprocess.Popen(
        [str(emulator), "-avd", "cookbook_pixel_api_36", "-port", "5554"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        pid_file.write_text(f"{process.pid}\n")
        result = subprocess.run(
            ["bash", str(ROOT / "scripts/headless_stop.sh"), "--owned"],
            env=dict(os.environ, HEADLESS_PID_FILE=str(pid_file)),
            capture_output=True,
            text=True,
            timeout=15,
        )
        assert result.returncode == 0, result.stderr
        process.wait(timeout=5)
        assert not pid_file.exists()
    finally:
        if process.poll() is None:
            process.kill()
        process.wait(timeout=5)

