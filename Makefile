.PHONY: bootstrap doctor update clean inventory generate-brewfile validate

bootstrap:
	./bootstrap.sh

doctor:
	./doctor.sh

update:
	brew update
	brew upgrade
	brew cleanup

clean:
	brew cleanup

inventory:
	./scripts/inventory.sh

generate-brewfile:
	uv run python scripts/generate-brewfile.py

validate:
	uv run python scripts/validate-applications.py