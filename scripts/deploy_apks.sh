#!/bin/bash

# Define colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Starting Automated Deployment ===${NC}"

# 1. Update Code
echo -e "${GREEN}1. Pulling latest code...${NC}"
git pull origin main
flutter pub get

# 2. Clean previous builds
echo -e "${GREEN}2. Cleaning previous application artifacts...${NC}"
rm -rf deploy/*
mkdir -p deploy

# 3. Build Prod APK ONLY
echo -e "${GREEN}3. Building Production APK (Official)...${NC}"
flutter build apk --flavor prod -t lib/main_prod.dart --release

# 4. Copy to Deploy Folder
echo -e "${GREEN}4. Copying and Renaming...${NC}"
cp build/app/outputs/flutter-apk/app-prod-release.apk deploy/Guardian_App_Latest.apk

# 5. Push to Git (Single File)
echo -e "${GREEN}5. Pushing single build to Git...${NC}"
git add deploy/Guardian_App_Latest.apk
git commit -m "Deploy: Updated Production APK [$(date)]"
git push origin main

echo -e "${GREEN}=== Success! ===${NC}"
echo "You can now download the APKs from your GitHub repository folder: /deploy"
