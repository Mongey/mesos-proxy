# Metadata about this makefile and position
MKFILE_PATH := $(lastword $(MAKEFILE_LIST))
CURRENT_DIR := $(dir $(realpath $(MKFILE_PATH)))
CURRENT_DIR := $(CURRENT_DIR:/=)

# Get the project metadata
GOVERSION := 1.8.1
VERSION := 0.0.1
PROJECT := $(shell echo $(CURRENT_DIR) | rev | cut -d'/' -f1,3 | rev)
NAME := $(notdir $(PROJECT))
EXTERNAL_TOOLS =
DOCKER_ACCOUNT := mongey
DOCKER_IMAGE := ${DOCKER_ACCOUNT}/${NAME}
GIT_COMMIT=$(shell git rev-parse HEAD)
GIT_DIRTY=$(shell test -n "$(git status --porcelain)" && echo "+CHANGES" || true)
DOCKER_TAG=${DOCKER_IMAGE}:${GIT_COMMIT}${GIT_DIRTY}
# Current system information (this is the invoking system)
ME_OS = $(shell go env GOOS)
ME_ARCH = $(shell go env GOARCH)

# Default os-arch combination to build
XC_OS ?= linux
XC_ARCH ?= amd64

# GPG Signing key (blank by default, means no GPG signing)
GPG_KEY ?=

# List of tests to run
TEST = ./...
# List all our actual files, excluding vendor
GOFILES = $(shell go list $(TEST) | grep -v /vendor/)

# bin builds the project by invoking the compile script inside of a Docker
# container. Invokers can override the target OS or architecture using
# environment variables.
bin:
	@echo "==> Building ${PROJECT}..."
	@docker run \
		--rm \
		--env="VERSION=${VERSION}" \
		--env="PROJECT=${PROJECT}" \
		--env="OWNER=${OWNER}" \
		--env="NAME=${NAME}" \
		--env="XC_OS=${XC_OS}" \
		--env="XC_ARCH=${XC_ARCH}" \
		--env="XC_EXCLUDE=${XC_EXCLUDE}" \
		--env="DIST=${DIST}" \
		--workdir="/go/src/${PROJECT}" \
		--volume="${CURRENT_DIR}:/go/src/${PROJECT}" \
		"golang:${GOVERSION}" /bin/sh -c "scripts/compile.sh"

docker: bin
	@echo "==> Building ${DOCKER_TAG}"
	@docker build -t "${DOCKER_TAG}" .

docker-release: docker
	@echo "==> Releasing ${DOCKER_TAG}"
	@docker push ${DOCKER_TAG}

# deps gets all the dependencies for this repository and vendors them.
deps:
	@echo "==> Updating dependencies..."
	@echo "--> Installing dependency manager..."
	@go get -u github.com/kardianos/govendor
	@govendor init
	@echo "--> Installing all dependencies..."
	@govendor fetch -v +outside

# dev builds the project for the current system as defined by go env.
dev:
	@env \
		XC_OS="${ME_OS}" \
		XC_ARCH="${ME_ARCH}" \
		$(MAKE) -f "${MKFILE_PATH}" bin
	@echo "--> Moving into PATH"
	@cp "${CURRENT_DIR}/pkg/${ME_OS}_${ME_ARCH}/${NAME}" "${CURRENT_DIR}/bin/"
	@cp "${CURRENT_DIR}/pkg/${ME_OS}_${ME_ARCH}/${NAME}" "${GOPATH}/bin/"

# test runs the test suite
test:
	@echo "==> Testing ${PROJECT}..."
	@go test -timeout=60s -parallel=10 ${GOFILES} ${TESTARGS}

# test-race runs the race checker
test-race:
	@echo "==> Testing ${PROJECT} (race)..."
	@go test -timeout=60s -race ${GOFILES} ${TESTARGS}

.PHONY: bin deps dev test test-race
