PYTHON ?= python
PIP_VERSION ?= 26.0.1
PYTHON_SERIES ?= $(strip $(shell cat .python-version))
PIP_BOOTSTRAP = $(PYTHON) -m pip install --upgrade "pip==$(PIP_VERSION)"

.PHONY: help clean check-python pin-pip install install-dev install-test install-hook 
install-hooks bootstrap-dev lint format typecheck test ci reset-precommit reinstall 
reinstall-dev

help:
	@echo "Available targets:"
	@echo "  clean         Remove build, cache, and temporary artifacts"
	@echo "  check-python  Verify that \$(PYTHON) is Python \$(PYTHON_SERIES).x"
	@echo "  pin-pip       Upgrade pip to the pinned version"
	@echo "  install       Clean and install the package in standard mode"
	@echo "  install-dev   Clean and install the package in editable mode with all dev depende
	@echo "  install-test  Install the test dependency set used by CI"
	@echo "  install-hook  Install the hook dependency set used by CI"
	@echo "  install-hooks Install pre-commit git hooks locally"
	@echo "  bootstrap-dev Install dev dependencies and git hooks (run this first)"
	@echo "  lint          Run ruff lint checks"
	@echo "  format        Run ruff format"
	@echo "  typecheck     Run basedpyright"
	@echo "  test          Run pytest"
	@echo "  ci            Run lint + typecheck + test, mirroring CI"
	@echo "  reset-precommit Fully refresh pre-commit hooks and cached environments"
	@echo "  reinstall     Alias for install"
	@echo "  reinstall-dev Alias for install-dev"

clean:
	rm -rf \
			build \
			dist \
			*.egg-info \
			src/*.egg-info \
			.pytest_cache \
			.mypy_cache \
			.ruff_cache \
			.tmp

check-python:
	@$(PYTHON) -c 'import sys; expected = "$(PYTHON_SERIES)"; actual =
f"{sys.version_info.major}.{sys.version_info.minor}"; version =
f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"; sys.exit(0 if
actual == expected else f"Python {expected}.x is required. Current interpreter: {version}.")'

pin-pip:
	$(PIP_BOOTSTRAP)

install: check-python clean
	$(PIP_BOOTSTRAP)
	$(PYTHON) -m pip install .

install-dev: check-python clean
	$(PIP_BOOTSTRAP)
	$(PYTHON) -m pip install -e .[dev]

install-test: check-python
	$(PIP_BOOTSTRAP)
	$(PYTHON) -m pip install -e .[test]

install-hook: check-python
	$(PIP_BOOTSTRAP)
	$(PYTHON) -m pip install -e .[hook]

install-hooks: install-hook
	$(PYTHON) -m pre_commit install
	$(PYTHON) -m pre_commit install --hook-type pre-push

bootstrap-dev: install-dev install-hooks

lint:
	$(PYTHON) -m ruff check src tests

format:
	$(PYTHON) -m ruff format src tests

typecheck:
	$(PYTHON) -m basedpyright

test:
	$(PYTHON) -m pytest tests

ci: lint typecheck test

reset-precommit:
	$(PYTHON) -m pre_commit uninstall
	$(PYTHON) -m pre_commit clean
	$(PYTHON) -m pre_commit gc
	$(MAKE) install-hooks

reinstall: install
reinstall-dev: install-dev