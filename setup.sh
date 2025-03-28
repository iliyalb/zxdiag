#!/bin/bash

# Create vendor directory
mkdir -p vendor

# Download and extract raylib
cd vendor
git clone https://github.com/raysan5/raylib.git
cd raylib
git checkout 4.5.0
cd ..

# Download and extract raygui
git clone https://github.com/raysan5/raygui.git
cd raygui
git checkout 3.0
cd ../..

# Make the script executable
chmod +x setup.sh

echo "Dependencies have been set up successfully!" 