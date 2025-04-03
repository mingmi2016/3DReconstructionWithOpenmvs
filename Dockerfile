FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Add retry mechanism for apt-get and set mirror
RUN echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries && \
    sed -i 's/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list

# First layer: Install all stable system dependencies
RUN apt-get update && apt-get install -y \
    git \
    cmake \
    build-essential \
    wget \
    libboost-all-dev \
    libeigen3-dev \
    libflann-dev \
    libfreeimage-dev \
    libmetis-dev \
    libsqlite3-dev \
    libglew-dev \
    libqt5opengl5-dev \
    libgoogle-glog-dev \
    libgflags-dev \
    libopencv-dev \
    libceres-dev \
    libgmp-dev \
    libmpfr-dev \
    && rm -rf /var/lib/apt/lists/*

# Set up basic environment variables
ENV PATH="/usr/local/bin:/usr/local/cuda/bin:${PATH}" \
    LD_LIBRARY_PATH="/usr/local/lib:/usr/local/cuda/lib64:${LD_LIBRARY_PATH}" \
    CUDA_ARCHITECTURES="86" \
    CUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda \
    OpenMVS_USE_CUDA=ON \
    CMAKE_CUDA_ARCHITECTURES=86

# Create working directory early
WORKDIR /workspace

# Copy COLMAP and check installation scripts
COPY install_colmap.sh check_install.sh /opt/
RUN chmod +x /opt/install_colmap.sh /opt/check_install.sh

# Install CGAL from source
RUN cd /opt && \
    git clone https://github.com/CGAL/cgal.git && \
    cd cgal && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DCGAL_HEADER_ONLY=ON \
          -DCMAKE_CXX_FLAGS="-O3 -DNDEBUG" \
          -DCMAKE_INSTALL_PREFIX=/usr \
          -DWITH_CGAL_Qt5=OFF \
          -DWITH_CGAL_ImageIO=ON \
          -DWITH_CGAL_Core=ON \
          .. && \
    make -j4 && \
    make install && \
    ldconfig && \
    cd ../.. && \
    rm -rf cgal && \
    echo "CGAL installation completed"

# Fourth layer: Configure and install COLMAP
RUN sed -i 's/cmake \.\./cmake .. -DCMAKE_BUILD_TYPE=Release -DCUDA_ENABLED=ON -DCUDA_ARCHITECTURES=86 -DCMAKE_CUDA_ARCHITECTURES=86/' /opt/install_colmap.sh && \
    sed -i 's/make -j/make -j4/' /opt/install_colmap.sh && \
    /opt/install_colmap.sh

# Final layer: Copy and install OpenMVS
COPY install_openmvs.sh /opt/
RUN chmod +x /opt/install_openmvs.sh && \
    /opt/install_openmvs.sh

