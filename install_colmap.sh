#!/bin/bash

set -e  # Exit on error

echo "Starting COLMAP installation..."

# Function to clone with retries
clone_with_retry() {
    local repo=$1
    local dir=$2
    local max_retries=3
    local retry=0
    
    while [ $retry -lt $max_retries ]; do
        echo "Cloning $repo (attempt $(($retry+1))/$max_retries)..."
        if git clone --depth 1 $repo $dir; then
            echo "Successfully cloned $repo"
            return 0
        else
            retry=$(($retry+1))
            if [ $retry -eq $max_retries ]; then
                echo "Failed to clone $repo after $max_retries attempts"
                return 1
            fi
            echo "Clone failed, retrying in 5 seconds..."
            sleep 5
        fi
    done
}

cd /opt
echo "Cloning COLMAP repository..."
clone_with_retry https://github.com/colmap/colmap.git colmap
cd colmap

echo "Setting up build environment..."
mkdir -p build
cd build

echo "Configuring COLMAP..."
cmake .. -DCMAKE_BUILD_TYPE=Release

echo "Building COLMAP..."
make -j$(nproc)

echo "Installing COLMAP..."
make install

echo "Cleaning up..."
cd ../..
rm -rf colmap 

echo "Verifying installation..."
if [ -f "/usr/local/bin/colmap" ]; then
    echo "COLMAP installation successful!"
    echo "COLMAP location: $(which colmap)"
else
    echo "Error: COLMAP executable not found after installation"
    exit 1
fi 