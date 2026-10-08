import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

LIB = ROOT / "scripts" / "lib" / "build_tools.sh"


def run_bash(
    command: str,
) -> subprocess.CompletedProcess[str]:

    return subprocess.run(
        [
            "bash",
            "-c",
            f'source "{LIB}"; {command}',
        ],
        text=True,
        capture_output=True,
        check=False,
        timeout=10,
    )


def create_fake_build_tools(
    tmp_path: Path,
    version: str = "36.0.0",
) -> Path:

    build_tools = tmp_path / "build-tools" / version

    build_tools.mkdir(parents=True)

    return build_tools


def create_executable(
    path: Path,
) -> None:

    path.write_text(
        "#!/usr/bin/env bash\n" "exit 0\n",
        encoding="utf-8",
    )

    path.chmod(0o755)


def test_build_tools_package_name():

    result = run_bash('build_tools_package_name "36.0.0"')

    assert result.returncode == 0

    assert result.stdout.strip() == "build-tools;36.0.0"


def test_build_tools_directory(tmp_path: Path):

    result = run_bash(f'build_tools_directory "{tmp_path}" "36.0.0"')

    expected = tmp_path / "build-tools" / "36.0.0"

    assert result.returncode == 0

    assert result.stdout.strip() == str(expected)


def test_build_tools_installed(tmp_path: Path):

    create_fake_build_tools(tmp_path)

    result = run_bash(f'build_tools_installed "{tmp_path}" "36.0.0"')

    assert result.returncode == 0


def test_build_tools_missing(tmp_path: Path):

    result = run_bash(f'build_tools_installed "{tmp_path}" "36.0.0"')

    assert result.returncode != 0


def test_required_build_tools_binaries_exist(
    tmp_path: Path,
):

    directory = create_fake_build_tools(tmp_path)

    create_executable(directory / "aapt2")
    create_executable(directory / "apksigner")
    create_executable(directory / "zipalign")

    result = run_bash(f'build_tools_has_required_binaries "{tmp_path}" "36.0.0"')

    assert result.returncode == 0


def test_missing_required_build_tools_binary(tmp_path: Path):

    directory = create_fake_build_tools(tmp_path)

    create_executable(directory / "aapt2")
    create_executable(directory / "apksigner")

    # zipalign intentionally missing

    result = run_bash(f'build_tools_has_required_binaries "{tmp_path}" "36.0.0"')

    assert result.returncode != 0
