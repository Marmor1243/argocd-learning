SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c

# -------- Config --------
NS            ?= argocd
SVC           ?= argocd-server

CTX_INSPECTOR ?= kind-kube-inspector
CTX_TEST      ?= kind-argocd-test

# lokale Ports (damit beide parallel gehen können)
INSPECTOR_LOCAL_PORT ?= 8080
TEST_LOCAL_PORT      ?= 8081

# Service Ports (wie in deinem Walkthrough)
INSPECTOR_REMOTE_PORT ?= 443
TEST_REMOTE_PORT      ?= 80

PID_DIR      ?= ./.pids
PF_PID_INS   := $(PID_DIR)/pf-argocd-inspector.pid
PF_PID_TEST  := $(PID_DIR)/pf-argocd-test.pid

.PHONY: help
help:
	@echo "Targets:"
	@echo "  make status          - zeigt aktuellen kubectl context"
	@echo "  make ctx-inspector   - switch zu $(CTX_INSPECTOR)"
	@echo "  make ctx-test        - switch zu $(CTX_TEST)"
	@echo "  make pf-inspector    - port-forward ArgoCD im Inspector-Cluster auf :$(INSPECTOR_LOCAL_PORT)"
	@echo "  make pf-test         - port-forward ArgoCD im Test-Cluster auf :$(TEST_LOCAL_PORT)"
	@echo "  make pw-inspector    - Admin-Passwort (Inspector-Cluster)"
	@echo "  make pw-test         - Admin-Passwort (Test-Cluster)"
	@echo "  make open-inspector  - URL ausgeben (+ Browser öffnen, falls xdg-open vorhanden)"
	@echo "  make open-test       - URL ausgeben (+ Browser öffnen, falls xdg-open vorhanden)"
	@echo "  make stop            - stoppt beide port-forwards"
	@echo ""
	@echo "Hinweis:"
	@echo "  Inspector URL: https://localhost:$(INSPECTOR_LOCAL_PORT)"
	@echo "  Test URL:      http://localhost:$(TEST_LOCAL_PORT) (falls dein Service wirklich :80 ist)"

$(PID_DIR):
	@mkdir -p $(PID_DIR)

.PHONY: status
status:
	@echo "Current context: $$(kubectl config current-context)"

.PHONY: ctx-inspector
ctx-inspector:
	@kubectl config use-context $(CTX_INSPECTOR)
	@$(MAKE) status

.PHONY: ctx-test
ctx-test:
	@kubectl config use-context $(CTX_TEST)
	@$(MAKE) status

# ---------- Passwort ----------
# Geheimnis liegt im jeweiligen Cluster, deshalb context explizit setzen per --context
.PHONY: pw-inspector
pw-inspector:
	@kubectl --context $(CTX_INSPECTOR) -n $(NS) get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

.PHONY: pw-test
pw-test:
	@kubectl --context $(CTX_TEST) -n $(NS) get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# ---------- Port-forward ----------
.PHONY: pf-inspector
pf-inspector: $(PID_DIR)
	@echo "[pf-inspector] $(CTX_INSPECTOR): svc/$(SVC) -n $(NS) -> localhost:$(INSPECTOR_LOCAL_PORT)"
	@if [ -f "$(PF_PID_INS)" ] && kill -0 $$(cat "$(PF_PID_INS)") 2>/dev/null; then \
		echo "  läuft bereits (PID $$(cat $(PF_PID_INS)))"; \
	else \
		kubectl --context $(CTX_INSPECTOR) -n $(NS) port-forward svc/$(SVC) $(INSPECTOR_LOCAL_PORT):$(INSPECTOR_REMOTE_PORT) >/tmp/pf-argocd-inspector.log 2>&1 & \
		echo $$! > $(PF_PID_INS); \
		echo "  gestartet (PID $$(cat $(PF_PID_INS)))"; \
	fi
	@echo "  URL: https://localhost:$(INSPECTOR_LOCAL_PORT)"

.PHONY: pf-test
pf-test: $(PID_DIR)
	@echo "[pf-test] $(CTX_TEST): svc/$(SVC) -n $(NS) -> localhost:$(TEST_LOCAL_PORT)"
	@if [ -f "$(PF_PID_TEST)" ] && kill -0 $$(cat "$(PF_PID_TEST)") 2>/dev/null; then \
		echo "  läuft bereits (PID $$(cat $(PF_PID_TEST)))"; \
	else \
		kubectl --context $(CTX_TEST) -n $(NS) port-forward svc/$(SVC) $(TEST_LOCAL_PORT):$(TEST_REMOTE_PORT) >/tmp/pf-argocd-test.log 2>&1 & \
		echo $$! > $(PF_PID_TEST); \
		echo "  gestartet (PID $$(cat $(PF_PID_TEST)))"; \
	fi
	@echo "  URL: http://localhost:$(TEST_LOCAL_PORT)"

.PHONY: stop
stop:
	@echo "[stop] Stoppe port-forwards..."
	@if [ -f "$(PF_PID_INS)" ]; then \
		PID=$$(cat "$(PF_PID_INS)"); \
		if kill -0 $$PID 2>/dev/null; then kill $$PID || true; fi; \
		rm -f "$(PF_PID_INS)"; \
		echo "  inspector stopped"; \
	else \
		echo "  inspector PID file nicht gefunden"; \
	fi
	@if [ -f "$(PF_PID_TEST)" ]; then \
		PID=$$(cat "$(PF_PID_TEST)"); \
		if kill -0 $$PID 2>/dev/null; then kill $$PID || true; fi; \
		rm -f "$(PF_PID_TEST)"; \
		echo "  test stopped"; \
	else \
		echo "  test PID file nicht gefunden"; \
	fi

# ---------- Open ----------
.PHONY: open-inspector
open-inspector:
	@echo "https://localhost:$(INSPECTOR_LOCAL_PORT)"
	@if command -v xdg-open >/dev/null 2>&1; then xdg-open "https://localhost:$(INSPECTOR_LOCAL_PORT)" >/dev/null 2>&1 || true; fi

.PHONY: open-test
open-test:
	@echo "http://localhost:$(TEST_LOCAL_PORT)"
	@if command -v xdg-open >/dev/null 2>&1; then xdg-open "http://localhost:$(TEST_LOCAL_PORT)" >/dev/null 2>&1 || true; fi

# -------- High Level Demo Targets --------

.PHONY: up-ins
up-ins:
	@echo "=== ArgoCD Inspector (großes Setup) ==="
	@$(MAKE) ctx-inspector
	@$(MAKE) pf-inspector
	@echo ""
	@echo "Admin Passwort:"
	@$(MAKE) pw-inspector
	@echo ""
	@$(MAKE) open-inspector

.PHONY: up-test
up-test:
	@echo "=== ArgoCD Test (minimales Setup) ==="
	@$(MAKE) ctx-test
	@$(MAKE) pf-test
	@echo ""
	@echo "Admin Passwort:"
	@$(MAKE) pw-test
	@echo ""
	@$(MAKE) open-test


.PHONY: down-ins
down-ins:
	@echo "Stopping Inspector port-forward..."
	@if [ -f "$(PF_PID_INS)" ]; then \
		PID=$$(cat "$(PF_PID_INS)"); \
		if kill -0 $$PID 2>/dev/null; then kill $$PID || true; fi; \
		rm -f "$(PF_PID_INS)"; \
		echo "Inspector stopped."; \
	else \
		echo "Inspector not running."; \
	fi

.PHONY: down-test
down-test:
	@echo "Stopping Test port-forward..."
	@if [ -f "$(PF_PID_TEST)" ]; then \
		PID=$$(cat "$(PF_PID_TEST)"); \
		if kill -0 $$PID 2>/dev/null; then kill $$PID || true; fi; \
		rm -f "$(PF_PID_TEST)"; \
		echo "Test stopped."; \
	else \
		echo "Test not running."; \
	fi
