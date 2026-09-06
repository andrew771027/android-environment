.PHONY: \
	bootstrap \
	install-sdk \
	create-avd \
	emulator \
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

install-sdk:
	./scripts/install_sdk.sh

create-avd:
	./scripts/create_avd.sh

emulator:
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

test:
	pytest -v tests

	# Mock Emulator測試
	# pytest -m "not integration"
	# 真實Emulator測試
	# pytest -m integration

clean:
	./scripts/cleanup.sh
