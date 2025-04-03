#!/bin/bash

# Exit on error
set -e

# Create output directories
mkdir -p output/colmap
mkdir -p output/colmap/sparse
mkdir -p output/colmap/dense

# Step 1: Feature extraction
echo "Step 1: 特征提取"
colmap feature_extractor \
    --database_path output/colmap/database.db \
    --image_path images \
    --ImageReader.camera_model SIMPLE_RADIAL \
    --SiftExtraction.use_gpu 1 \
    --SiftExtraction.gpu_index 0 \
    --SiftExtraction.max_num_features 16384 \
    --SiftExtraction.estimate_affine_shape 1

# Step 2: Feature matching
echo "Step 2: 特征匹配"
colmap exhaustive_matcher \
    --database_path output/colmap/database.db \
    --SiftMatching.use_gpu 1 \
    --SiftMatching.gpu_index 0 \
    --SiftMatching.guided_matching 1 \
    --SiftMatching.max_ratio 0.8 \
    --SiftMatching.max_distance 0.7 \
    --SiftMatching.cross_check 1

# Step 3: Sparse reconstruction
echo "Step 3: 稀疏重建"
colmap mapper \
    --database_path output/colmap/database.db \
    --image_path images \
    --output_path output/colmap/sparse \
    --Mapper.tri_ignore_two_view_tracks 0 \
    --Mapper.tri_min_angle 3 \
    --Mapper.ba_refine_focal_length 1 \
    --Mapper.ba_refine_extra_params 1 \
    --Mapper.min_num_matches 15

# Step 4: Image undistortion
echo "Step 4: 图像校正"
colmap image_undistorter \
    --image_path images \
    --input_path output/colmap/sparse/0 \
    --output_path output/colmap/dense \
    --output_type COLMAP \
    --max_image_size 3000

# Step 5: Dense reconstruction
echo "Step 5: 稠密重建"
colmap patch_match_stereo \
    --workspace_path output/colmap/dense \
    --workspace_format COLMAP \
    --PatchMatchStereo.gpu_index 0 \
    --PatchMatchStereo.depth_min 0.1 \
    --PatchMatchStereo.depth_max 100 \
    --PatchMatchStereo.window_radius 5 \
    --PatchMatchStereo.window_step 2 \
    --PatchMatchStereo.num_samples 15 \
    --PatchMatchStereo.num_iterations 5 \
    --PatchMatchStereo.geom_consistency 1

# Step 6: Stereo fusion
echo "Step 6: 立体融合"
colmap stereo_fusion \
    --workspace_path output/colmap/dense \
    --workspace_format COLMAP \
    --input_type geometric \
    --output_path output/colmap/dense/fused.ply \
    --StereoFusion.min_num_pixels 5 \
    --StereoFusion.max_num_pixels 10000 \
    --StereoFusion.max_reproj_error 2 \
    --StereoFusion.max_depth_error 0.01 \
    --StereoFusion.max_normal_error 10 \
    --StereoFusion.check_num_images 30

# Step 7: Meshing
echo "Step 7: 表面重建"
colmap poisson_mesher \
    --input_path output/colmap/dense/fused.ply \
    --output_path output/colmap/dense/meshed-poisson.ply \
    --PoissonMeshing.depth 10

# Step 8: Convert to text format for visualization
echo "Step 8: 转换为文本格式"
mkdir -p output/colmap/sparse/0/text
colmap model_converter \
    --input_path output/colmap/sparse/0 \
    --output_path output/colmap/sparse/0/text \
    --output_type TXT

echo "重建完成！"
echo "输出文件位置："
echo "- 稀疏重建结果：output/colmap/sparse/0"
echo "- 稠密点云：output/colmap/dense/fused.ply"
echo "- 重建网格：output/colmap/dense/meshed-poisson.ply"
echo "- 文本格式模型：output/colmap/sparse/0/text"