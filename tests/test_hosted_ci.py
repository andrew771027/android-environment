import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

LIB = ROOT / "scripts" / "lib" / "hosted_ci.sh"

def run_bash(
    command: str,
    *,
    env: dict[str, str] | None = None,
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

def test_linux_x86_64_is_supported():

    result = run_bash(
        'hosted_ci_supported_platform "linux" "x86_64"'
    )

    assert result.returncode == 0

def test_macos_is_not_hosted_linux_target():

    result = run_bash(
        'hosted_ci_supported_platform "darwin" "x86_64"'
    )

    assert result.returncode != 0

def test_linux_arm64_is_not_v046_target():

    result = run_bash(
        'hosted_ci_supported_platform "linux" "arm64"'
    )

    assert result.returncode != 0

def test_android_home_has_priority(tmp_path: Path):

    env = os.environ.copy()

    env["ANDROID_HOME"] = str(tmp_path / "android-home")
    env["ANDROID_SDK_ROOT"] = str(tmp_path / "sdk-root")

    result = run_bash(
        "hosted_ci_android_home",
        env=env,
    )

    assert result.returncode == 0
    assert result.stdout.strip() == env["ANDROID_HOME"]

def test_android_sdk_root_is_fallback(tmp_path: Path):

    env = os.environ.copy()

    env.pop("ANDROID_HOME", None)

    env["ANDROID_SDK_ROOT"] = str(tmp_path / "sdk-root")

    result = run_bash(
        "hosted_ci_android_home",
        env=env,
    )

    assert result.returncode == 0
    assert result.stdout.strip() == env["ANDROID_SDK_ROOT"]


def test_android_home_missing():

    env = os.environ.copy()

    env.pop("ANDROID_HOME", None)
    env.pop("ANDROID_SDK_ROOT", None)

    result = run_bash(
        "hosted_ci_android_home",
        env=env,
    )

    assert result.returncode != 0

def test_kvm_device_accessible(tmp_path: Path):

    fake_kvm = tmp_path / "kvm"

    fake_kvm.write_text(
        "",
        encoding="utf-8",
    )

    fake_kvm.chmod(0o600)

    result = run_bash(
        f"hosted_ci_kvm_accessible '{fake_kvm}'"
    )

    assert result.returncode == 0

def test_kvm_device_missing(tmp_path: Path):

    fake_kvm = tmp_path / "missing-kvm"

    result = run_bash(
        f'hosted_ci_kvm_accessible "{fake_kvm}"'
    )

    assert result.returncode != 0
