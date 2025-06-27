.PHONY: lint template test install uninstall clean validate diff

# Default environment
ENV ?= dev

# Namespace
NAMESPACE ?= koci

# Chart name
CHART_NAME ?= koci

# Values file
VALUES_FILE ?= values-$(ENV).yaml

# Lint the chart
lint:
	@echo "Linting chart for $(ENV) environment..."
	helm lint . -f $(VALUES_FILE)

# Template the chart
template:
	@echo "Templating chart for $(ENV) environment..."
	helm template $(CHART_NAME) . -f $(VALUES_FILE) --namespace $(NAMESPACE) > template-output.yaml
	@echo "Template output saved to template-output.yaml"

# Install the chart
install:
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

# Validate the chart
validate:
	@echo "Validating chart for $(ENV) environment..."
	helm template $(CHART_NAME) . -f $(VALUES_FILE) --namespace $(NAMESPACE) | kubectl apply --dry-run=client -f -

# Show diff between current and new deployment
diff:
	@echo "Showing diff for $(ENV) environment..."
	helm diff upgrade $(CHART_NAME) . -f $(VALUES_FILE) --namespace $(NAMESPACE)

# Run all checks
check: lint template validate
	@echo "All checks passed!"

# CI pipeline
ci: check
	@echo "CI pipeline completed successfully"

# Help command
help:
	@echo "Available commands:"
	@echo "  make lint ENV=dev       - Lint the chart for dev environment"
	@echo "  make template ENV=dev   - Template the chart for dev environment"
	@echo "  make install ENV=dev    - Install the chart for dev environment"
	@echo "  make test               - Test the installed chart"
	@echo "  make uninstall          - Uninstall the chart"
	@echo "  make clean              - Clean up generated files"
	@echo "  make validate ENV=dev   - Validate the chart for dev environment"
	@echo "  make diff ENV=dev       - Show diff between current and new deployment"
	@echo "  make check ENV=dev      - Run all checks for dev environment"
	@echo "  make ci ENV=dev         - Run CI pipeline for dev environment"
	@echo "  make help               - Show this help message" 