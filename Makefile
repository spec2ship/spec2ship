# Spec2Ship - developer entrypoints
#
# The shipped plugin is markdown/YAML + a few bash helpers; there is no build.
# `make test` runs the hermetic script test suite (the same entrypoint CI uses).

.PHONY: test
test: ## Run the hermetic bash script test suite
	@bash tests/run-all.sh
