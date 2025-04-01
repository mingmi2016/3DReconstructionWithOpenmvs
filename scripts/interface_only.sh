#!/bin/bash

# Exit on error
set -e

# Ensure output directories exist
mkdir -p output/colmap
mkdir -p output/openmvs

# Show COLMAP sparse folder structure
echo "COLMAP sparse folder structure:"
find output/colmap/sparse -type f | sort

# Create a clean temp directory
echo "Creating temporary directory with the correct structure..."
rm -rf temp_colmap
mkdir -p temp_colmap
mkdir -p temp_colmap/sparse

# Convert COLMAP binary model to text format
echo "Converting COLMAP binary files to text format..."
colmap model_converter \
    --input_path output/colmap/sparse/0 \
    --output_path temp_colmap/sparse \
    --output_type TXT

# Copy images
echo "Copying images to the temporary directory..."
cp -r images temp_colmap/

# Check the temp directory structure
echo "Temporary directory structure:"
find temp_colmap -type f | head -20

# Converting COLMAP to OpenMVS
echo "Converting COLMAP output to OpenMVS format..."
cd temp_colmap
InterfaceCOLMAP \
    --working-folder . \
    --input-file sparse \
    --output-file ../output/openmvs/scene.mvs
cd ..

echo "Conversion complete. Check output/openmvs/scene.mvs"

# If successful, continue with OpenMVS pipeline
if [ -f "output/openmvs/scene.mvs" ]; then
    echo "Starting OpenMVS pipeline..."
    
    # Densify point cloud
    echo "Step 1: Densifying point cloud..."
    DensifyPointCloud \
        --input-file output/openmvs/scene.mvs \
        --output-file output/openmvs/scene_dense.mvs \
        --resolution-level 2 \
        --min-resolution 640 \
        --number-views-fuse 3 \
        --process-priority 1
    
    # Reconstruct mesh
    echo "Step 2: Reconstructing mesh..."
    ReconstructMesh \
        --input-file output/openmvs/scene_dense.mvs \
        --output-file output/openmvs/scene_mesh.mvs \
        --decimate 0.5
    
    # Refine mesh
    echo "Step 3: Refining mesh..."
    RefineMesh \
        --input-file output/openmvs/scene_mesh.mvs \
        --output-file output/openmvs/scene_mesh_refined.mvs \
        --resolution-level 2 \
        --max-face-area 16
    
    # Texture mesh
    echo "Step 4: Texturing mesh..."
    TextureMesh \
        --input-file output/openmvs/scene_mesh_refined.mvs \
        --output-file output/openmvs/scene_mesh_textured.mvs \
        --export-type obj
    
    echo "OpenMVS pipeline complete. Final 3D model: output/openmvs/scene_mesh_textured.obj"
fi 