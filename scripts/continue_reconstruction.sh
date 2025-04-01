#!/bin/bash

# Exit on error
set -e

# Ensure output directories exist
mkdir -p output/colmap
mkdir -p output/openmvs

# Create empty fused.ply to satisfy dependencies if it doesn't exist
if [ ! -f "output/colmap/dense/fused.ply" ]; then
    touch output/colmap/dense/fused.ply
fi

# Check COLMAP output structure
echo "Checking COLMAP output directory structure..."
find output/colmap -type d | sort

# Step 7: Convert COLMAP output to OpenMVS format
echo "Step 7: Converting COLMAP output to OpenMVS format..."
InterfaceCOLMAP \
    --working-folder output/colmap/dense \
    --input-file sparse \
    --output-file ../../output/openmvs/scene.mvs

# Step 8: Densify point cloud using OpenMVS (CPU-based)
echo "Step 8: Densifying point cloud using OpenMVS (CPU-based)..."
DensifyPointCloud \
    --input-file output/openmvs/scene.mvs \
    --output-file output/openmvs/scene_dense.mvs \
    --resolution-level 2 \
    --min-resolution 640 \
    --number-views-fuse 3 \
    --process-priority 1

# Step 9: Reconstruct mesh using OpenMVS
echo "Step 9: Reconstructing mesh using OpenMVS..."
ReconstructMesh \
    --input-file output/openmvs/scene_dense.mvs \
    --output-file output/openmvs/scene_mesh.mvs \
    --decimate 0.5

# Step 10: Refine mesh using OpenMVS
echo "Step 10: Refining mesh using OpenMVS..."
RefineMesh \
    --input-file output/openmvs/scene_mesh.mvs \
    --output-file output/openmvs/scene_mesh_refined.mvs \
    --resolution-level 2 \
    --max-face-area 16

# Step 11: Texture mesh using OpenMVS
echo "Step 11: Texturing mesh using OpenMVS..."
TextureMesh \
    --input-file output/openmvs/scene_mesh_refined.mvs \
    --output-file output/openmvs/scene_mesh_textured.mvs \
    --export-type obj

echo "Reconstruction complete! Output files are in the output directory."
echo "Final 3D model: output/openmvs/scene_mesh_textured.obj"