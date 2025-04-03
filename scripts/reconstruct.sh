#!/bin/bash

# Exit on error
set -e

# Create output directories
mkdir -p output/colmap
mkdir -p output/openmvs

# Step 1: Run COLMAP feature extraction
echo "Step 1: 特征提取"
colmap feature_extractor \
    --database_path output/colmap/database.db \
    --image_path images \
    --ImageReader.camera_model SIMPLE_RADIAL \
    --SiftExtraction.use_gpu 0

# Step 2: Run COLMAP feature matching
echo "Step 2: 特征匹配"
colmap exhaustive_matcher \
    --database_path output/colmap/database.db \
    --SiftMatching.use_gpu 0

# Step 3: Run COLMAP sparse reconstruction
echo "Step 3: 稀疏重建"
mkdir -p output/colmap/sparse
colmap mapper \
    --database_path output/colmap/database.db \
    --image_path images \
    --output_path output/colmap/sparse

# Step 4: Run COLMAP image undistorter
echo "Step 4: 图像校正"
mkdir -p output/colmap/dense
colmap image_undistorter \
    --image_path images \
    --input_path output/colmap/sparse/0 \
    --output_path output/colmap/dense \
    --output_type COLMAP

# Skip dense stereo and fusion which require CUDA
echo "注意：跳过COLMAP稠密重建步骤，因为它需要CUDA"
echo "直接使用稀疏重建结果进行OpenMVS重建"

# Create empty fused.ply to satisfy dependencies
touch output/colmap/dense/fused.ply

# Check COLMAP output structure
echo "检查COLMAP输出目录结构..."
find output/colmap -type d | sort

# Convert COLMAP binary format to text format
echo "转换COLMAP二进制格式为文本格式..."
mkdir -p output/colmap/sparse/0/sparse
colmap model_converter \
    --input_path output/colmap/sparse/0 \
    --output_path output/colmap/sparse/0/sparse \
    --output_type TXT

# Step 5: Convert COLMAP output to OpenMVS format
echo "Step 5: 转换COLMAP模型为OpenMVS格式"
InterfaceCOLMAP \
    --working-folder output/colmap \
    --input-file sparse/0 \
    --output-file output/openmvs/scene.mvs

# Step 6: Densify point cloud
echo "Step 6: 稠密重建"
DensifyPointCloud \
    --input-file output/openmvs/scene.mvs \
    --output-file output/openmvs/scene_dense.mvs \
    --resolution-level 2 \
    --min-resolution 640 \
    --number-views-fuse 3 \
    --process-priority 1

# Step 7: Reconstruct mesh
echo "Step 7: 重建网格"
ReconstructMesh \
    --input-file output/openmvs/scene_dense.mvs \
    --output-file output/openmvs/scene_mesh.mvs \
    --decimate 0.5

# Step 8: Refine mesh
echo "Step 8: 网格优化"
RefineMesh \
    --input-file output/openmvs/scene_mesh.mvs \
    --output-file output/openmvs/scene_mesh_refined.mvs \
    --resolution-level 2 \
    --max-face-area 16

# Step 9: Texture mesh
echo "Step 9: 网格纹理化"
TextureMesh \
    --input-file output/openmvs/scene_mesh_refined.mvs \
    --output-file output/openmvs/scene_mesh_textured.mvs \
    --export-type obj

echo "重建完成！"
echo "输出文件位置："
echo "- 稀疏重建结果：output/colmap/sparse/0"
echo "- 稠密点云：output/openmvs/scene_dense.mvs"
echo "- 网格模型：output/openmvs/scene_mesh_refined.mvs"
echo "- 带纹理的模型：output/openmvs/scene_mesh_textured.obj" 