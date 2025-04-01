#!/bin/bash

# Check if the reconstruction was successful
if [ -f "output/openmvs/scene_mesh_textured.obj" ]; then
    echo "=================================================="
    echo "Reconstruction completed successfully!"
    echo "=================================================="
    echo "Output files:"
    echo "- Sparse point cloud: output/colmap/sparse/0/points3D.bin"
    echo "- Dense point cloud: output/colmap/dense/fused.ply"
    echo "- MVS scene file: output/openmvs/scene.mvs"
    echo "- Dense MVS point cloud: output/openmvs/scene_dense.mvs"
    echo "- Mesh: output/openmvs/scene_mesh.mvs"
    echo "- Refined mesh: output/openmvs/scene_mesh_refined.mvs"
    echo "- Textured mesh (final result): output/openmvs/scene_mesh_textured.obj"
    echo "=================================================="
    
    # Get file sizes
    echo "File sizes:"
    du -h output/colmap/sparse/0/points3D.bin
    du -h output/colmap/dense/fused.ply
    du -h output/openmvs/scene.mvs
    du -h output/openmvs/scene_dense.mvs
    du -h output/openmvs/scene_mesh.mvs
    du -h output/openmvs/scene_mesh_refined.mvs
    du -h output/openmvs/scene_mesh_textured.obj
    echo "=================================================="
    
    # Count the number of vertices and faces in the final mesh
    if [ -f "output/openmvs/scene_mesh_textured.obj" ]; then
        echo "Mesh statistics:"
        echo "Vertices: $(grep -c "^v " output/openmvs/scene_mesh_textured.obj)"
        echo "Faces: $(grep -c "^f " output/openmvs/scene_mesh_textured.obj)"
    fi
else
    echo "Reconstruction failed! The final output file does not exist."
    echo "Check the logs for errors."
fi 