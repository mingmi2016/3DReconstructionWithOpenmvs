#!/bin/bash

set -e  # Exit on error

echo "Starting OpenMVS installation..."

# Set up CUDA environment variables
export PATH="/usr/local/cuda/bin:${PATH}"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"
export CUDA_HOME=/usr/local/cuda
export CUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda
export OpenMVS_USE_CUDA=ON
export CUDA_ARCHITECTURES=86

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

# Set up environment variables
export VCG_DIR=/opt/VCG
export VCG_ROOT=/opt/VCG
export CGAL_DIR=/usr/lib/cmake/CGAL

# Configure with CMake
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DOpenMVS_USE_CUDA=ON \
    -DVCG_ROOT=/opt/VCG \
    -DVCG_DIR=/opt/VCG \
    -DCGAL_DIR=/usr/lib/cmake/CGAL \
    -DCMAKE_PREFIX_PATH="/usr;/usr/local" \
    -DCMAKE_MODULE_PATH="/opt/VCG;/usr/share/cmake/CGAL" \
    -DCMAKE_CXX_FLAGS="-I/usr/include -I/usr/local/include -I/usr/local/cuda/include" \
    -DCMAKE_CUDA_FLAGS="--expt-relaxed-constexpr" \
    -DBOOST_ROOT=/usr \
    -DBoost_NO_SYSTEM_PATHS=OFF \
    -DCMAKE_CUDA_ARCHITECTURES=86 \
    -DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda \
    -DCUDA_ENABLED=ON \
    -DCUDA_HOST_COMPILER=/usr/bin/g++ \
    -DCMAKE_CUDA_COMPILER=/usr/local/cuda/bin/nvcc

echo "Building OpenMVS..."
make -j4

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