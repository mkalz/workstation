.PHONY: bootstrap bootstrap-dry-run doctor update clean inventory generate-brewfile validate validate-applications validate-config validate-repository lint-shell check test

bootstrap:
	./bootstrap.sh

bootstrap-dry-run:
	./bootstrap.sh --dry-run

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

validate: validate-config validate-applications validate-repository

validate-applications:
	uv run python scripts/validate-applications.py

validate-config:
	uv run python scripts/validate-config.py

validate-repository:
	uv run python scripts/validate-repository.py

test:
	uv run python -m unittest discover -s tests

check: validate test

lint-shell:
	shellcheck bootstrap.sh doctor.sh install/*.sh scripts/*.sh