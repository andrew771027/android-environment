.PHONY: \
	bootstrap \
	linux-tools \
	install-sdk \
	create-avd \
	kvm-check \
	headless-smoke \
	unit-test \
	emulator-start \
	emulator-wait \
	emulator-status \
	emulator-stop \
	emulator-reset \
	doctor \
	validate \
	devices \
	shell \
	test \
	clean

bootstrap:
	./scripts/bootstrap.sh

kvm-check:
	./scripts/check_kvm.sh

linux-tools:
	./scripts/install_cmdline_tools_linux.sh

headless-smoke:
	./scripts/run_headless_smoke.sh

install-sdk:
	./scripts/install_sdk.sh

create-avd:
	./scripts/create_avd.sh

emulator-start:
	./scripts/start_emulator.sh

emulator-wait:
	./scripts/wait_for_emulator.sh

emulator-status:
	./scripts/emulator_status.sh

emulator-stop:
	./scripts/stop_emulator.sh

emulator-reset:
	./scripts/reset_emulator.sh

doctor:
	./scripts/doctor.sh

validate:
	./scripts/validate_environment.sh

devices:
	adb devices

shell:
	adb shell

unit-test:
	python -m pytest -q -m "not integration" tests

# Alias kept for convenience.
test: unit-test

# Mock Emulator測試
# pytest -m "not integration"
# 真實Emulator測試
# pytest -m integration

clean:
	./scripts/cleanup.sh
