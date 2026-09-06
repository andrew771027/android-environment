import subprocess

import pytest


@pytest.mark.integration
def test_configured_emulator_exists():

    result = subprocess.run(
        [
            "emulator",
            "-list-avds",
        ],
        text=True,
        capture_output=True,
        check=True,
    )

    assert "cookbook_pixel_api_36" in result.stdout


@pytest.mark.integration
def test_running_emulator_is_boot_completed():

    devices = subprocess.run(["adb", "devices"], text=True, capture_output=True, check=True)

    emulator_lines = [
        line
        for line in devices.stdout.splitlines()
        if line.startswith("emulator-") and line.endswith("device")
    ]

    assert emulator_lines

    serial = emulator_lines[0].split()[0]

    result = subprocess.run(
        ["adb", "-s", serial, "shell", "getprop", "sys.boot_completed"],
        text=True,
        capture_output=True,
        check=True,
    )

    assert result.stdout.strip() == "1"
