# 3D Reconstruction Pipeline

这个dockerfile built的时候，有几个地方需要注意一下：
1，每一个RUN命令都是一层，执行‘docker-compose built'的时候，从修改的地方开始，之后每一行代码都会重新执行，而之前的会使用缓存。所以要把那些稳定的，耗时长的RUN命令放到前面。因为并不是built一次就成功了，重复下载会浪费大量的时间。。。

2，有很多种方式获得可执行程序？
  源码编译（这个一般从github上面）
  docker镜像（通过docker命令获取）。现在的经验是简单的（依赖少的）建议通过docker镜像（如果有点话），复杂的尽量还是通过源码编译的方式，因为有大量的依赖，使用docker镜像无法正常运行


This repository contains a Docker-based 3D reconstruction pipeline using COLMAP and OpenMVS.

## Setup

1. Clone this repository:
```bash
git clone <repository-url>
cd <repository-directory>
```

2. Build the Docker container:
```bash
docker-compose build
```

3. Start the Docker container:
```bash
docker-compose up -d
```

## Reconstruction

To perform 3D reconstruction from images:

1. Place your images in the `images/` directory.

2. Run the reconstruction script inside the Docker container:
```bash
docker-compose exec mvs bash -c "cd /workspace && ./scripts/reconstruct.sh"
```

3. Check the results:
```bash
docker-compose exec mvs bash -c "cd /workspace && ./scripts/check_results.sh"
```

## Output

The reconstruction pipeline produces the following outputs:

- **Sparse Reconstruction (COLMAP):**
  - `output/colmap/sparse/` - Sparse point cloud and camera poses

- **Dense Reconstruction (COLMAP):**
  - `output/colmap/dense/` - Dense point cloud
  - `output/colmap/dense/fused.ply` - Fused point cloud

- **Mesh Reconstruction (OpenMVS):**
  - `output/openmvs/scene.mvs` - Initial MVS scene
  - `output/openmvs/scene_dense.mvs` - Dense point cloud
  - `output/openmvs/scene_mesh.mvs` - Reconstructed mesh
  - `output/openmvs/scene_mesh_refined.mvs` - Refined mesh
  - `output/openmvs/scene_mesh_textured.obj` - Textured mesh (final output)

## Pipeline Steps

1. **COLMAP Feature Extraction:** Extract features from images
2. **COLMAP Feature Matching:** Match features between images
3. **COLMAP Sparse Reconstruction:** Create sparse point cloud and estimate camera poses
4. **COLMAP Dense Reconstruction:** Create dense point cloud
5. **OpenMVS Interface:** Convert COLMAP output to OpenMVS format
6. **OpenMVS Dense Point Cloud:** Densify the point cloud
7. **OpenMVS Mesh Reconstruction:** Create a mesh from the point cloud
8. **OpenMVS Mesh Refinement:** Refine the mesh
9. **OpenMVS Mesh Texturing:** Add texture to the mesh

## Viewing Results

The final textured mesh can be viewed with any 3D viewer that supports OBJ files, such as:
- [MeshLab](https://www.meshlab.net/)
- [Blender](https://www.blender.org/)

## Customization

You can customize the reconstruction parameters by editing the `scripts/reconstruct.sh` file. The most common parameters to adjust are:
- Resolution levels
- Mesh refinement parameters
- Texture quality

## 环境要求

- Docker
- Docker Compose

## 安装步骤

1. 构建Docker镜像：
```bash
docker-compose build
```

2. 启动容器：
```bash
docker-compose up -d
```

3. 进入容器：
```bash
docker-compose exec mvs bash
```

## 验证安装

在容器内运行以下命令来验证安装：

```bash
# 验证COLMAP安装
colmap --version

# 验证OpenMVS安装
DensifyPointCloud --version
```

## 使用说明

1. 将您的图像数据放在项目目录中
2. 进入容器后，您可以使用COLMAP进行特征提取和SfM重建
3. 使用OpenMVS进行密集重建和网格生成

## 目录结构

- `images/`: 存放输入图像
- `output/`: 存放重建结果
- `scripts/`: 存放处理脚本 