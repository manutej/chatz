#!/bin/bash

# Chatz Test Runner Script
# This script runs the full test suite with coverage

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Chatz Test Suite Runner${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed!${NC}"
    echo ""
    echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo -e "${GREEN}✅ Flutter found: $(flutter --version | head -1)${NC}"
echo ""

# Check if we're in the project directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: pubspec.yaml not found!${NC}"
    echo "Please run this script from the project root directory."
    exit 1
fi

# Step 1: Get dependencies
echo -e "${YELLOW}📦 Installing dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Step 2: Static analysis
echo -e "${YELLOW}🔍 Running static analysis...${NC}"
if flutter analyze; then
    echo -e "${GREEN}✅ Static analysis passed${NC}"
else
    echo -e "${RED}❌ Static analysis failed${NC}"
    exit 1
fi
echo ""

# Step 3: Format check
echo -e "${YELLOW}📝 Checking code formatting...${NC}"
if flutter format --set-exit-if-changed .; then
    echo -e "${GREEN}✅ Code is properly formatted${NC}"
else
    echo -e "${YELLOW}⚠️  Code formatting issues found${NC}"
    echo "Run 'flutter format .' to fix formatting"
fi
echo ""

# Step 4: Run tests
echo -e "${YELLOW}🧪 Running tests...${NC}"
if flutter test; then
    echo -e "${GREEN}✅ All tests passed${NC}"
else
    echo -e "${RED}❌ Tests failed${NC}"
    exit 1
fi
echo ""

# Step 5: Generate coverage
echo -e "${YELLOW}📊 Generating coverage report...${NC}"
flutter test --coverage
echo -e "${GREEN}✅ Coverage generated${NC}"
echo ""

# Step 6: Show coverage summary (if lcov is installed)
if command -v lcov &> /dev/null; then
    echo -e "${YELLOW}📈 Coverage summary:${NC}"
    lcov --summary coverage/lcov.info
    echo ""

    # Generate HTML report
    echo -e "${YELLOW}🌐 Generating HTML coverage report...${NC}"
    genhtml coverage/lcov.info -o coverage/html --quiet
    echo -e "${GREEN}✅ HTML report generated at coverage/html/index.html${NC}"
    echo ""

    # Ask to open report
    read -p "Open coverage report in browser? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open coverage/html/index.html
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            xdg-open coverage/html/index.html
        else
            echo "Please open coverage/html/index.html manually"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  lcov not found. Install it to view coverage report:${NC}"
    echo "  macOS:   brew install lcov"
    echo "  Ubuntu:  sudo apt-get install lcov"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ All checks passed successfully!${NC}"
echo -e "${BLUE}========================================${NC}"
