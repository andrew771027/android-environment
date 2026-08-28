.PHONY: bootstrap install-sdk create-avd emulator doctor devices shell clean

bootstrap:
	./scripts/bootstrap.sh

install-sdk:
	./scripts/install_sdk.sh

create-avd:
	./scripts/create_avd.sh

emulator:
	./scripts/start_emulator.sh

doctor:
	./scripts/doctor.sh

validate:
	./scripts/validate_environment.sh

devices:
	adb devices

shell:
	adb shell

clean:
	./scripts/cleanup.sh
