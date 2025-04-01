#!/bin/bash

echo "Checking COLMAP installation..."
if command -v colmap &> /dev/null; then
    echo "COLMAP is installed:"
    colmap --version
else
    echo "COLMAP is not installed"
    echo "Installing COLMAP..."
    /opt/install_colmap.sh
fi

echo -e "\nChecking OpenMVS installation..."
if command -v DensifyPointCloud &> /dev/null; then
    echo "OpenMVS is installed:"
    DensifyPointCloud --version
else
    echo "OpenMVS is not installed"
    echo "Installing OpenMVS..."
    /opt/install_openmvs.sh
fi 