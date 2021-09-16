ifeq ($(SHELL), cmd)
	VERSION := $(shell git describe --exact-match --tags 2>nil)
	HOME := $(HOMEPATH)
else ifeq ($(SHELL), sh.exe)
	VERSION := $(shell git describe --exact-match --tags 2>nil)
	HOME := $(HOMEPATH)
else
	VERSION := $(shell git describe --exact-match --tags 2>/dev/null)
endif

PREFIX := /usr
BINDIR := $(PREFIX)/bin
ETCDIR := /etc
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
COMMIT := $(shell git rev-parse --short HEAD)
GOFILES ?= $(shell git ls-files '*.go')
GOFMT ?= $(shell gofmt -l -s $(filter-out plugins/parsers/influx/machine.go, $(GOFILES)))
BUILDFLAGS ?=
INSTALL := install
INSTALL_EXEC := $(INSTALL) -D --mode 755
INSTALL_DATA := $(INSTALL) -D --mode 0644

ifdef GOBIN
PATH := $(GOBIN):$(PATH)
else
PATH := $(subst :,/bin:,$(shell go env GOPATH))/bin:$(PATH)
endif

LDFLAGS := -X github.com/sunet/hsmca/pkg/meta.commit=$(COMMIT) -X github.com/sunet/hsmca/pkg/meta.branch=$(BRANCH)
ifdef VERSION
	LDFLAGS += -X github.com/sunet/hsmca/pkg/meta.version=$(VERSION)
endif

.PHONY: all
all:
	@$(MAKE) --no-print-directory hsmca docs/hsmca.1

.PHONY: hsmca
hsmca:
	go build $(GO_BUILD_FLAGS) -ldflags "$(LDFLAGS)" ./cmd/hsmca

docs/%.1: docs/%.ronn.1
	ronn -r $< > $@

.PHONY: go-install
go-install:
	go install -ldflags "-w -s $(LDFLAGS)" ./cmd/hsmca.go

.PHONY: install
install: hsmca
	$(INSTALL_EXEC) hsmca $(DESTDIR)$(BINDIR)


.PHONY: test
test:
	go test $(GO_BUILD_FLAGS) -cover -short ./...

.PHONY: testcover
testcover:
	go test $(GO_BUILD_FLAGS) -cover ./...

.PHONY: fmt
fmt:
	@gofmt -s -w $(filter-out plugins/parsers/influx/machine.go, $(GOFILES))

.PHONY: fmtcheck
fmtcheck:
	@if [ ! -z "$(GOFMT)" ]; then \
		echo "[ERROR] gofmt has found errors in the following files:"  ; \
		echo "$(GOFMT)" ; \
		echo "" ;\
		echo "Run make fmt to fix them." ; \
		exit 1 ;\
	fi

.PHONY: test-windows
test-windows:
	go test -short ./plugins/inputs/ping/...
	go test -short ./plugins/inputs/win_perf_counters/...
	go test -short ./plugins/inputs/win_services/...
	go test -short ./plugins/inputs/procstat/...
	go test -short ./plugins/inputs/ntpq/...

.PHONY: vet
vet:
	@echo 'go vet $$(go list ./... | grep -v ./plugins/parsers/influx)'
	@go vet $$(go list ./... | grep -v ./plugins/parsers/influx) ; if [ $$? -ne 0 ]; then \
		echo ""; \
		echo "go vet has found suspicious constructs. Please remediate any reported errors"; \
		echo "to fix them before submitting code for review."; \
		exit 1; \
	fi

.PHONY: check
check: fmtcheck vet

.PHONY: test-all
test-all: fmtcheck vet
	go test ./...

.PHONY: clean
clean:
	rm -f hsmca 
	rm -f hsmca.exe
	rm -f docs/hsmca.1

.PHONY: docker
docker:
	docker build -t "hsmca:$(COMMIT)" .
	docker tag hsmca:$(COMMIT) docker.sunet.se/hsmca:$(COMMIT)
	docker push docker.sunet.se/hsmca:$(COMMIT)

deb-source:
	go mod vendor
	dpkg-buildpackage -S -k$(DEBSIGN_KEYID)

deb-bin:
	go mod vendor
	dpkg-buildpackage -k$(DEBSIGN_KEYID)
