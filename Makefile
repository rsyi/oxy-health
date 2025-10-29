# Generic Oxy Project Makefile
# This Makefile provides commands for testing and running Oxy agents, workflows, and SQL files
# Can be dropped into any Oxy project

.PHONY: help discover test-all validate clean show-base is-base

# Variables - can be overridden on command line
FILE ?=
PROMPT ?=
VARS ?=
DATABASE ?=

# Template base detection
TEMPLATE_BASE := $(shell [ -f .oxy-base ] && grep TEMPLATE_BASE .oxy-base | cut -d= -f2 || echo "")

# Autodiscovery
AGENTS := $(shell find . -name "*.agent.yml" 2>/dev/null)
WORKFLOWS := $(shell find . -name "*.workflow.yml" 2>/dev/null)
SQL_FILES := $(shell find . -name "*.sql" -not -path "*/.*" 2>/dev/null)

# Default target
help:
	@echo "Generic Oxy Project - Testing & Execution Commands"
	@echo "=================================================="
	@echo ""
	@echo "Discovery Commands:"
	@echo "  make discover          - List all Oxy files in project"
	@echo "  make validate          - Validate all Oxy configuration files"
	@echo ""
	@echo "Execution Commands (require FILE parameter):"
	@echo "  make run-agent FILE=<path> PROMPT=\"<question>\""
	@echo "  make run-workflow FILE=<path>"
	@echo "  make run-sql FILE=<path> [VARS=\"key=value key2=value2\"]"
	@echo ""
	@echo "Testing Commands:"
	@echo "  make test-agents       - Test all agent files"
	@echo "  make test-sql          - Test all SQL files"
	@echo "  make test-all          - Run all tests"
	@echo ""
	@echo "Template Commands:"
	@echo "  make show-base         - Show template base directory"
	@echo "  make is-base           - Check if this is the base template"
	@echo ""
	@echo "Utility Commands:"
	@echo "  make clean             - Clean up test artifacts"
	@echo ""
	@echo "Examples:"
	@echo "  make run-agent FILE=my-agent.agent.yml PROMPT=\"Analyze sales data\""
	@echo "  make run-sql FILE=queries/report.sql VARS=\"year=2024 region=west\""
	@echo "  make run-workflow FILE=data-pipeline.workflow.yml"

# Discovery
discover:
	@echo "Discovering Oxy files..."
	@echo ""
	@echo "Agent files (.agent.yml):"
	@$(foreach agent,$(AGENTS),echo "  - $(agent)";)
	@[ -z "$(AGENTS)" ] && echo "  (none found)" || true
	@echo ""
	@echo "Workflow files (.workflow.yml):"
	@$(foreach workflow,$(WORKFLOWS),echo "  - $(workflow)";)
	@[ -z "$(WORKFLOWS)" ] && echo "  (none found)" || true
	@echo ""
	@echo "SQL files (.sql):"
	@$(foreach sql,$(SQL_FILES),echo "  - $(sql)";)
	@[ -z "$(SQL_FILES)" ] && echo "  (none found)" || true

# Run commands
run-agent:
ifndef FILE
	@echo "Error: FILE parameter required"
	@echo "Usage: make run-agent FILE=path/to/agent.agent.yml PROMPT=\"your question\""
	@exit 1
endif
ifndef PROMPT
	@echo "Error: PROMPT parameter required for agent execution"
	@echo "Usage: make run-agent FILE=$(FILE) PROMPT=\"your question\""
	@exit 1
endif
	@echo "Running agent: $(FILE)"
	@echo "Prompt: $(PROMPT)"
	@oxy run $(FILE) "$(PROMPT)"

run-workflow:
ifndef FILE
	@echo "Error: FILE parameter required"
	@echo "Usage: make run-workflow FILE=path/to/workflow.workflow.yml"
	@exit 1
endif
	@echo "Running workflow: $(FILE)"
	@oxy run $(FILE)

run-sql:
ifndef FILE
	@echo "Error: FILE parameter required"
	@echo "Usage: make run-sql FILE=path/to/query.sql [VARS=\"key=value\"]"
	@exit 1
endif
	@echo "Running SQL: $(FILE)"
ifdef VARS
	@echo "With variables: $(VARS)"
	@oxy run $(FILE) $(addprefix -v ,$(VARS))
else
	@oxy run $(FILE)
endif

# Testing
test-agents:
	@echo "Testing all agent files..."
	@if [ -z "$(AGENTS)" ]; then \
		echo "No agent files found to test"; \
	else \
		for agent in $(AGENTS); do \
			echo ""; \
			echo "Testing: $$agent"; \
			echo "Note: Agents require a PROMPT to execute. Skipping execution test."; \
		done; \
	fi

test-sql:
	@echo "Testing all SQL files..."
	@if [ -z "$(SQL_FILES)" ]; then \
		echo "No SQL files found to test"; \
	else \
		for sql in $(SQL_FILES); do \
			echo ""; \
			echo "Testing: $$sql"; \
			oxy run $$sql --dry-run || oxy run $$sql; \
		done; \
	fi

test-workflows:
	@echo "Testing all workflow files..."
	@if [ -z "$(WORKFLOWS)" ]; then \
		echo "No workflow files found to test"; \
	else \
		for workflow in $(WORKFLOWS); do \
			echo ""; \
			echo "Testing: $$workflow"; \
			oxy run $$workflow; \
		done; \
	fi

test-all: test-sql test-workflows
	@echo ""
	@echo "======================================================"
	@echo "All tests completed"
	@echo "======================================================"
	@echo ""
	@echo "Note: Agent files were not tested (require prompts)"
	@echo "To test agents, use:"
	@echo "  make run-agent FILE=<agent-file> PROMPT=\"<question>\""

# Validation
validate:
	@echo "Validating Oxy configuration..."
	@echo ""
	@echo "Checking for oxy CLI:"
	@which oxy > /dev/null && echo "  ✓ oxy command found" || (echo "  ✗ oxy not found. Install from https://github.com/oxy-hq/oxy" && exit 1)
	@echo ""
	@echo "Running oxy validate:"
	@oxy validate || echo "Validation warnings/errors found (see above)"
	@echo ""
	@echo "Project structure:"
	@test -n "$(AGENTS)" && echo "  ✓ Found $(words $(AGENTS)) agent file(s)" || echo "  ⚠ No agent files found"
	@test -n "$(WORKFLOWS)" && echo "  ✓ Found $(words $(WORKFLOWS)) workflow file(s)" || echo "  ⚠ No workflow files found"
	@test -n "$(SQL_FILES)" && echo "  ✓ Found $(words $(SQL_FILES)) SQL file(s)" || echo "  ⚠ No SQL files found"

# Template management
show-base:
	@if [ -f .oxy-base ]; then \
		echo "This is a derived project."; \
		echo ""; \
		echo "Template base directory:"; \
		echo "  $(TEMPLATE_BASE)"; \
		echo ""; \
		echo "To update template documentation:"; \
		echo "  cd $(TEMPLATE_BASE)"; \
	else \
		echo "This appears to be the base template directory."; \
		echo ""; \
		echo "Current location:"; \
		echo "  $(shell pwd)"; \
		echo ""; \
		echo "To create a new project from this template:"; \
		echo "  ./setup-oxy-project.sh /path/to/new/project"; \
	fi

is-base:
	@if [ -f .oxy-base ]; then \
		echo "✗ This is a derived project (has .oxy-base file)"; \
		echo "  Base template: $(TEMPLATE_BASE)"; \
		exit 1; \
	else \
		echo "✓ This is the base template directory"; \
		exit 0; \
	fi

# Clean up
clean:
	@echo "Cleaning up test artifacts..."
	@find . -name "*.log" -type f -delete 2>/dev/null || true
	@find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "✓ Clean complete"
