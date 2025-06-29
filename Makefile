.PHONY: lint template test install uninstall clean validate diff deps

# Default environment
ENV ?= dev

# Namespace
NAMESPACE ?= koci

# Chart name
CHART_NAME ?= koci

# Values file
VALUES_FILE ?= values-$(ENV).yaml

# Update dependencies
deps:
	@echo "Updating chart dependencies..."
	helm dependency update

# Lint the chart
lint: deps
	@echo "Linting chart for $(ENV) environment..."
	helm lint . -f $(VALUES_FILE)

# Template the chart
template: deps
	@echo "Templating chart for $(ENV) environment..."
	helm template $(CHART_NAME) . -f $(VALUES_FILE) --namespace $(NAMESPACE) > template-output.yaml
	@echo "Template output saved to template-output.yaml"

# Install the chart
install: deps
	@echo "Installing chart for $(ENV) environment..."
	helm upgrade --install $(CHART_NAME) . -f $(VALUES_FILE) --namespace $(NAMESPACE) --create-namespace

# Test the chart
test:
	@echo "Testing chart..."
	helm test $(CHART_NAME) --namespace $(NAMESPACE)

# Uninstall the chart
uninstall:
	@echo "Uninstalling chart..."
	helm uninstall $(CHART_NAME) --namespace $(NAMESPACE)

# Clean up generated files
clean:
	@echo "Cleaning up..."
	rm -f template-output.yaml
	rm -rf charts/*.tgz
	rm -f Chart.lock

# Validate the chart
validate: deps
	@echo "Validating chart for $(ENV) environment..."
	helm template $(CHART_NAME) . -f $(VALUES_FILE) --namespace $(NAMESPACE) | kubectl apply --dry-run=client -f -

# Show diff between current and new deployment
diff: deps
	@echo "Showing diff for $(ENV) environment..."
	helm diff upgrade $(CHART_NAME) . -f $(VALUES_FILE) --namespace $(NAMESPACE)

# Debug - show resolved values
debug: deps
	@echo "Showing resolved values for $(ENV) environment..."
	helm template $(CHART_NAME) . -f $(VALUES_FILE) --namespace $(NAMESPACE) --debug

# List what will be deployed
list: deps
	@echo "Components that will be deployed for $(ENV) environment:"
	@helm template $(CHART_NAME) . -f $(VALUES_FILE) --namespace $(NAMESPACE) | grep "^kind:" | sort | uniq -c
	@echo ""
	@echo "Services that will be created:"
	@helm template $(CHART_NAME) . -f $(VALUES_FILE) --namespace $(NAMESPACE) | grep -A5 "^kind: Service" | grep "name:" | sed 's/.*name: /  - /'

# Run all checks
check: lint template validate
	@echo "All checks passed!"

# CI pipeline
ci: deps check
	@echo "CI pipeline completed successfully"

# Setup - install required tools
setup:
	@echo "Installing required tools..."
	@command -v helm >/dev/null 2>&1 || { echo "Please install Helm first"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "Please install kubectl first"; exit 1; }
	@echo "Tools check passed!"

# Quick start for different environments
local: 
	$(MAKE) install ENV=local

dev:
	$(MAKE) install ENV=dev

staging:
	$(MAKE) install ENV=staging

# Help command
help:
	@echo "Infrastructure-only deployment commands:"
	@echo ""
	@echo "Setup:"
	@echo "  make setup              - Check required tools are installed"
	@echo "  make deps               - Update Helm chart dependencies"
	@echo ""
	@echo "Development:"
	@echo "  make lint ENV=dev       - Lint the chart for dev environment"
	@echo "  make template ENV=dev   - Template the chart for dev environment"
	@echo "  make validate ENV=dev   - Validate the chart for dev environment"
	@echo "  make debug ENV=dev      - Show resolved values and debug info"
	@echo "  make list ENV=dev       - List components that will be deployed"
	@echo ""
	@echo "Deployment:"
	@echo "  make local              - Deploy to local environment"
	@echo "  make dev                - Deploy to dev environment"
	@echo "  make staging            - Deploy to staging environment"
	@echo "  make install ENV=dev    - Install the chart for dev environment"
	@echo "  make test               - Test the installed chart"
	@echo "  make uninstall          - Uninstall the chart"
	@echo ""
	@echo "Utilities:"
	@echo "  make clean              - Clean up generated files"
	@echo "  make diff ENV=dev       - Show diff between current and new deployment"
	@echo "  make check ENV=dev      - Run all checks for dev environment"
	@echo "  make ci ENV=dev         - Run CI pipeline for dev environment"
	@echo ""
	@echo "Components deployed: MongoDB, Redis, RabbitMQ, Doppler"
	@echo "Disabled: main-api, auth-server, notification-service, MySQL"