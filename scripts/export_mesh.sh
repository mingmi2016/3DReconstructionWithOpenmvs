#!/bin/bash

# Exit on error
set -e

# Ensure output directories exist
mkdir -p output/colmap
mkdir -p output/mesh

# Show COLMAP sparse folder structure
echo "COLMAP sparse folder structure:"
find output/colmap/sparse -type f | sort

# Export sparse point cloud to PLY using COLMAP
echo "Exporting sparse point cloud to PLY..."
colmap model_converter \
    --input_path output/colmap/sparse/0 \
    --output_path output/mesh/sparse.ply \
    --output_type PLY

echo "Sparse point cloud exported to output/mesh/sparse.ply"
echo "You can view this file with MeshLab or similar software."

# If we have a dense reconstruction, export that too
if [ -f "output/colmap/dense/fused.ply" ]; then
    echo "Dense point cloud found, copying to output/mesh directory..."
    cp output/colmap/dense/fused.ply output/mesh/dense.ply
    echo "Dense point cloud copied to output/mesh/dense.ply"
fi

echo "Export complete. You can find the point clouds in the output/mesh directory." 