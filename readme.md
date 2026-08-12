# Android Environment

Reproducible Android workstation environment for Android Cookbook.

## Goals

Provide a local Android environment for learning:

- Android SDK
- ADB
- Fastboot
- Android Emulator
- Android Virtual Device
- Android command-line tools

Physical Pixel devices are optional.

## Supported Hosts

- macOS Apple Silicon
- macOS Intel
- Linux x86_64

## Android Baseline

- Android 16
- API Level 36
- Google APIs system image

## Setup

```bash
make bootstrap
make install-sdk
make create-avd
make emulator
make doctor