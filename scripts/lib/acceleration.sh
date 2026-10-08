#!/usr/bin/env bash

# Android Environment v0.4.2
# 
# Cross-platform Android Emulator acceleration helpers.

check_emulator_exists(){

    command -v emulator >/dev/null 2>&1

}

check_macos_acceleration(){

    check_emulator_exists || retrun 1

    emulator -accel-check >/dev/null 2>&1
}