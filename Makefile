.PHONY: bootstrap doctor update clean inventory

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