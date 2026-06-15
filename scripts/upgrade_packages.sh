#!/bin/bash

# Change to the packages directory
cd packages || exit 1

# Loop through each subdirectory
for dir in */; do
    # Check if it's a directory
    if [ -d "$dir" ]; then
        echo "Fetching packages in $dir..."
        # Navigate to the directory and run fvm flutter pub get
        (cd "$dir"  && fvm flutter pub upgrade --major-versions)
    fi
done

echo "All packages fetched."