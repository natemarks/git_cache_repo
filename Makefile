.PHONY: lint 
.DEFAULT_GOAL := help


help: ## Show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'


lint: ## Run static code checks
	@echo Run static code checks
	shellcheck *.sh