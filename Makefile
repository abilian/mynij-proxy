
# The package name
PKG=FIXME


.PHONY:
all: test lint


#
# Run
#
.PHONY:
run:
	gunicorn -b localhost:3000 \
		--pid server.pid \
		--keyfile ssl/httpd.key \
		--certfile ssl/httpd.crt \
		-k uvicorn.workers.UvicornWorker \
		-w 4 \
		mynij_proxy:app


#
# Setup
#
.PHONY:
develop: install-deps activate-pre-commit configure-git

install-deps:
	@echo "--> Installing dependencies"
	pip install -U pip setuptools wheel
	poetry install

.PHONY:
activate-pre-commit:
	@echo "--> Activating pre-commit hook"
	pre-commit install

.PHONY:
configure-git:
	@echo "--> Configuring git"
	git config branch.autosetuprebase always


#
# testing & checking
#
.PHONY:
test-all: test

.PHONY:
test:
	@echo "--> Running Python tests"
	pytest --ff -x -p no:randomly
	@echo ""

.PHONY:
test-randomly:
	@echo "--> Running Python tests in random order"
	pytest
	@echo ""

.PHONY:
test-with-coverage:
	@echo "--> Running Python tests"
	pytest --cov $(PKG)
	@echo ""

.PHONY:
test-with-typeguard:
	@echo "--> Running Python tests with typeguard"
	pytest --typeguard-packages=${PKG}
	@echo ""


#
# Various Checkers
#
.PHONY:
lint: lint-py lint-mypy lint-bandit

.PHONY:
lint-ci: lint

.PHONY:
lint-py:
	@echo "--> Linting Python files /w flake8"
	flake8 src tests
	@echo ""

.PHONY:
lint-mypy:
	@echo "--> Typechecking Python files w/ mypy"
	mypy src tests
	@echo ""

.PHONY:
lint-bandit:
	@echo "--> Security audit w/ Bandit"
	bandit -q src/*.py
	@echo ""


#
# Formatting
#
.PHONY:
format: format-py

.PHONY:
format-py:
	docformatter -i -r src tests
	black src tests
	isort src tests


#
# Everything else
#
.PHONY:
install:
	poetry install

.PHONY:
doc: doc-html doc-pdf

.PHONY:
doc-html:
	sphinx-build -W -b html docs/ docs/_build/html

.PHONY:
doc-pdf:
	sphinx-build -W -b latex docs/ docs/_build/latex
	make -C docs/_build/latex all-pdf

.PHONY:
clean:
	rm -f **/*.pyc
	find . -type d -empty -delete
	rm -rf *.egg-info *.egg .coverage .eggs .cache .mypy_cache .pyre \
		.pytest_cache .pytest .DS_Store  docs/_build docs/cache docs/tmp \
		dist build pip-wheel-metadata junit-*.xml htmlcov coverage.xml

.PHONY:
tidy: clean
	rm -rf .tox

.PHONY:
update-deps:
	pip install -U pip setuptools wheel
	poetry update
	dephell deps convert --from=pyproject.toml --to=setup.py
	black setup.py

.PHONY:
publish: clean
	git push --tags
	poetry build
	twine upload dist/*

.PHONY:
push:
	rsync -e ssh -avz ./ pilaf:git/minij-proxy/

.PHONY:
fetch-results:
	rsync -e ssh -avz pilaf:git/minij-proxy/results.csv results/

