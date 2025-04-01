FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update package lists in a separate layer
RUN apt-get update

# Install basic build tools
RUN apt-get install -y \
    git \
    cmake \
    build-essential

# Install stable dependencies that rarely change
RUN apt-get install -y \
    libboost-all-dev \
    libeigen3-dev \
    libflann-dev \
    libfreeimage-dev \
    libmetis-dev \
    libsqlite3-dev \
    libglew-dev \
    libqt5opengl5-dev

# Install Google libraries
RUN apt-get install -y \
    libgoogle-glog-dev \
    libgflags-dev

# Install OpenCV and Ceres
RUN apt-get install -y \
    libopencv-dev \
    libceres-dev

# Install CGAL dependencies
RUN apt-get install -y \
    libgmp-dev \
    libmpfr-dev

# Install CGAL from source
RUN cd /opt && \
    git clone https://github.com/CGAL/cgal.git && \
    cd cgal && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j$(nproc) && \
    make install && \
    cd ../.. && \
    rm -rf cgal && \
    ldconfig && \
    echo "CGAL installation completed" && \
    ls -la /usr/local/include/CGAL

# Clean up in a separate layer
RUN rm -rf /var/lib/apt/lists/*

# Set up environment variables
ENV PATH="/usr/local/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"

# Create a working directory
WORKDIR /workspace

# Copy COLMAP installation script
COPY install_colmap.sh /opt/
RUN chmod +x /opt/install_colmap.sh

# Install COLMAP
RUN /opt/install_colmap.sh

# Copy OpenMVS installation script
COPY install_openmvs.sh /opt/
RUN chmod +x /opt/install_openmvs.sh

# Install OpenMVS (this layer will be rebuilt if install_openmvs.sh changes)
RUN /opt/install_openmvs.sh

# Create a script to check installation
COPY check_install.sh /opt/
RUN chmod +x /opt/check_install.sh 

