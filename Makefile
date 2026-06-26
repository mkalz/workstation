.PHONY: bootstrap doctor update clean

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