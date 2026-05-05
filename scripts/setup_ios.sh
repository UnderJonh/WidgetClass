#!/bin/bash
# iOS Setup Script for WidgetClass
# Run this on macOS to prepare the iOS build

set -e

echo "🚀 WidgetClass iOS Setup Script"
echo "================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ This script must be run on macOS${NC}"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Flutter found${NC}"

# Navigate to project root
cd "$(dirname "$0")"/../

echo -e "\n${YELLOW}1. Cleaning build artifacts...${NC}"
flutter clean
cd ios
rm -rf Pods
rm -f Podfile.lock
cd ..
echo -e "${GREEN}✅ Clean complete${NC}"

echo -e "\n${YELLOW}2. Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✅ Dependencies installed${NC}"

echo -e "\n${YELLOW}3. Installing iOS pods...${NC}"
cd ios
pod install --repo-update
cd ..
echo -e "${GREEN}✅ Pods installed${NC}"

echo -e "\n${GREEN}✅ iOS Setup Complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Open the project in Xcode:"
echo "   open ios/Runner.xcworkspace"
echo ""
echo "2. Follow the iOS Setup Guide:"
echo "   docs/ios_setup_guide.md"
echo ""
echo "3. Create Widget Extensions for ClassScheduleWidget and ActivitiesWidget"
echo ""
echo "4. Run:"
echo "   flutter run"
