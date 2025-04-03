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

# First get PoseLib
echo "Cloning PoseLib..."
clone_with_retry https://github.com/PoseLib/PoseLib.git poselib
cd poselib
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j4
make install
cd ../..

echo "Cloning COLMAP repository..."
clone_with_retry https://github.com/colmap/colmap.git colmap
cd colmap

echo "Setting up build environment..."
mkdir -p build
cd build

echo "Configuring COLMAP..."
cmake .. -DCMAKE_BUILD_TYPE=Release \
        -DCUDA_ENABLED=ON \
        -DCUDA_ARCHITECTURES=86 \
        -DCMAKE_CUDA_ARCHITECTURES=86 \
        -DPoseLib_DIR=/usr/local/lib/cmake/PoseLib

echo "Building COLMAP..."
make -j4

echo "Installing COLMAP..."
make install

echo "Cleaning up..."
cd ../..
rm -rf colmap poselib

echo "COLMAP installation completed!" 