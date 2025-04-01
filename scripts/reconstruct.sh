#!/bin/bash

# Exit on error
set -e

# Create output directories
mkdir -p output/colmap
mkdir -p output/openmvs

# Step 1: Run COLMAP feature extraction
echo "Step 1: COLMAP feature extraction..."
colmap feature_extractor \
    --database_path output/colmap/database.db \
    --image_path images \
    --ImageReader.camera_model SIMPLE_RADIAL \
    --SiftExtraction.use_gpu 0

# Step 2: Run COLMAP feature matching
echo "Step 2: COLMAP feature matching..."
colmap exhaustive_matcher \
    --database_path output/colmap/database.db \
    --SiftMatching.use_gpu 0

# Step 3: Run COLMAP sparse reconstruction
echo "Step 3: COLMAP sparse reconstruction..."
mkdir -p output/colmap/sparse
colmap mapper \
    --database_path output/colmap/database.db \
    --image_path images \
    --output_path output/colmap/sparse

# Step 4: Run COLMAP image undistorter
echo "Step 4: COLMAP image undistorter..."
mkdir -p output/colmap/dense
colmap image_undistorter \
    --image_path images \
    --input_path output/colmap/sparse/0 \
    --output_path output/colmap/dense \
    --output_type COLMAP

# Skip dense stereo and fusion which require CUDA
echo "Note: Skipping COLMAP dense stereo and fusion steps as they require CUDA."
echo "Using sparse reconstruction directly for OpenMVS."

# Create empty fused.ply to satisfy dependencies
touch output/colmap/dense/fused.ply

# Check COLMAP output structure
echo "Checking COLMAP output directory structure..."
find output/colmap -type d | sort

# Step 7: Convert COLMAP output to OpenMVS format
echo "Step 7: Converting COLMAP output to OpenMVS format..."
InterfaceCOLMAP \
    --working-folder output/colmap \
    --input-file output/colmap/sparse/0 \
    --output-file output/openmvs/scene.mvs

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