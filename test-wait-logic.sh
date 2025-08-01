#!/bin/bash

# Test script for wait-for-main-build logic
# This script helps you test the workflow waiting logic on your fork

set -e

REPO_OWNER="ezhang6811"  # Your fork owner
REPO_NAME="aws-otel-js-instrumentation"
WORKFLOW_FILE="test-wait-for-main-build.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -r, --ref REF        Git ref to test against (default: current branch)"
    echo "  -t, --timeout MIN    Timeout in minutes (default: 10)"
    echo "  -d, --dry-run        Show what would be done without executing"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                           # Test current branch with 10min timeout"
    echo "  $0 -r main -t 5             # Test main branch with 5min timeout"
    echo "  $0 --ref feature-branch      # Test specific branch"
    echo "  $0 --dry-run                 # Preview the command"
}

# Default values
REF=""
TIMEOUT="10"
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--ref)
            REF="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
done

# Get current branch if no ref specified
if [ -z "$REF" ]; then
    REF=$(git branch --show-current)
    if [ -z "$REF" ]; then
        REF=$(git rev-parse --abbrev-ref HEAD)
    fi
fi

echo -e "${YELLOW}Testing wait-for-main-build logic...${NC}"
echo "Repository: $REPO_OWNER/$REPO_NAME"
echo "Ref: $REF"
echo "Timeout: ${TIMEOUT} minutes"
echo ""

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: GitHub CLI (gh) is not installed.${NC}"
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${RED}Error: Not authenticated with GitHub CLI.${NC}"
    echo "Please run: gh auth login"
    exit 1
fi

# Build the command
CMD="gh workflow run $WORKFLOW_FILE --repo $REPO_OWNER/$REPO_NAME"

if [ -n "$REF" ]; then
    CMD="$CMD --ref $REF"
fi

CMD="$CMD --field test_ref=$REF --field wait_timeout=$TIMEOUT"

if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}Dry run - would execute:${NC}"
    echo "$CMD"
    exit 0
fi

echo -e "${YELLOW}Triggering test workflow...${NC}"
echo "Command: $CMD"
echo ""

# Execute the command
if $CMD; then
    echo ""
    echo -e "${GREEN}✅ Test workflow triggered successfully!${NC}"
    echo ""
    echo "To monitor the workflow:"
    echo "  gh run list --repo $REPO_OWNER/$REPO_NAME --workflow=$WORKFLOW_FILE"
    echo ""
    echo "To view logs of the latest run:"
    echo "  gh run view --repo $REPO_OWNER/$REPO_NAME --log"
    echo ""
    echo "Or visit: https://github.com/$REPO_OWNER/$REPO_NAME/actions"
else
    echo -e "${RED}❌ Failed to trigger test workflow${NC}"
    exit 1
fi
