#!/bin/bash

# Define colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Starting Automated Deployment ===${NC}"

# 1. Update Code
echo -e "${GREEN}1. Pulling latest code...${NC}"
git pull origin main
flutter pub get

# 2. Build Dev APK
echo -e "${GREEN}2. Building Dev APK (Testing)...${NC}"
flutter build apk --flavor dev -t lib/main_dev.dart --release

# 3. Build Prod APK
echo -e "${GREEN}3. Building Prod APK (Official)...${NC}"
flutter build apk --flavor prod -t lib/main_prod.dart --release

# 4. Prepare Deploy Folder
echo -e "${GREEN}4. Preparing Deploy Folder...${NC}"
mkdir -p deploy
cp build/app/outputs/flutter-apk/app-dev-release.apk deploy/
cp build/app/outputs/flutter-apk/app-prod-release.apk deploy/

# 5. Push to Git
echo -e "${GREEN}5. Pushing builds to Git...${NC}"
git add deploy/
git commit -m "Deploy: Automated build upload [$(date)]"
git push origin main

echo -e "${GREEN}=== Success! ===${NC}"
echo "You can now download the APKs from your GitHub repository folder: /deploy"
