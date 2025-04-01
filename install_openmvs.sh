#!/bin/bash

set -e  # Exit on error

echo "Starting OpenMVS installation..."

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
echo "Cloning VCG library..."
clone_with_retry https://github.com/cdcseacave/VCG.git VCG

echo "Cloning OpenMVS repository..."
clone_with_retry https://github.com/cdcseacave/openMVS.git openMVS
cd openMVS

# Create necessary directories and files
echo "Setting up build environment..."
mkdir -p build
mkdir -p build/Utils
touch build/Utils.cmake

echo "Configuring OpenMVS..."
cd build
export VCG_ROOT=/opt/VCG
cmake .. -DCMAKE_BUILD_TYPE=Release

echo "Building OpenMVS..."
make -j$(nproc)

echo "Installing OpenMVS..."
make install

echo "Cleaning up..."
cd ../..
rm -rf openMVS VCG

echo "Verifying installation..."
if [ -f "/usr/local/bin/OpenMVS/DensifyPointCloud" ]; then
    echo "OpenMVS installation successful!"
    echo "DensifyPointCloud location: /usr/local/bin/OpenMVS/DensifyPointCloud"
    
    # Create symlinks to /usr/local/bin for convenience
    echo "Creating symlinks in /usr/local/bin..."
    ln -sf /usr/local/bin/OpenMVS/DensifyPointCloud /usr/local/bin/
    ln -sf /usr/local/bin/OpenMVS/ReconstructMesh /usr/local/bin/
    ln -sf /usr/local/bin/OpenMVS/RefineMesh /usr/local/bin/
    ln -sf /usr/local/bin/OpenMVS/TextureMesh /usr/local/bin/
    ln -sf /usr/local/bin/OpenMVS/InterfaceCOLMAP /usr/local/bin/
else
    echo "Error: DensifyPointCloud not found after installation"
    exit 1
fi