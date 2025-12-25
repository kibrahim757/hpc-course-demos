#!/bin/bash

set -e

# Add q1 service to docker-compose.yml if not present
echo "Looking for the slurm-docker-cluster directory"
if [[ -n "$1" ]]; then
    CLUSTER_DIR="$1"
elif [[ -d "./slurm-docker-cluster" ]]; then
    CLUSTER_DIR="./slurm-docker-cluster"
elif [[ -d "../slurm-docker-cluster" ]]; then
    CLUSTER_DIR="../slurm-docker-cluster"
else
    # Search for it
    CLUSTER_DIR=$(find ~ -maxdepth 4 -type d -name "slurm-docker-cluster" 2>/dev/null | head -1)
fi

get_exec_container() {
    for container in slurmctld c1 c2 slurmdbd; do
        if docker exec $container true 2>/dev/null; then
            echo $container
            return 0
        fi
    done
    echo ""
    return 1
}

COMPOSE_FILE="$CLUSTER_DIR/docker-compose.yml"
if [[ ! -f "$COMPOSE_FILE" ]]; then
    echo "Error: Could not find docker-compose.yml"
    echo "Usage: $0 /path/to/slurm-docker-cluster"
    exit 1
fi
echo "Using cluster directory: $CLUSTER_DIR"
DOCKERFILE="$CLUSTER_DIR/Dockerfile"
SLURM_CONF="$CLUSTER_DIR/shared/spank-plugins/demo/qrmi/etc/slurm/slurm.conf"

# Update Dockerfile for PMIx/MPI Support
if grep -q "MY_PMIX_VERSION" "$DOCKERFILE"; then
    echo "PMIx build present in Dockerfile"
else
    echo "Adding PMIX / OpenMPI source build to Dockerfile"

    # Creating a backup of the original Dockerfile"
    cp "$DOCKERFILE" "$DOCKERFILE.bak.$(date +%Y%m%d_%H%M%S)"

    # Check if system MPI / Symlinks already present
    sed -i '/^       openmpi \\/d' "$DOCKERFILE"
    sed -i '/^       openmpi-devel \\/d' "$DOCKERFILE"
    sed -i '/ln -s \/usr\/lib64\/openmpi\/bin\/mpirun/d' "$DOCKERFILE"
    sed -i '/ln -s \/usr\/lib64\/openmpi\/bin\/mpiexec/d' "$DOCKERFILE"
    sed -i '/ln -s \/usr\/lib64\/openmpi\/bin\/orted/d' "$DOCKERFILE"
    sed -i '/echo "\/usr\/lib64\/openmpi\/lib"/d' "$DOCKERFILE"
    sed -i '/openmpi\.conf/d' "$DOCKERFILE"

    # Adding PMIx build dependencies
    if ! grep -q "libevent-devel" "$DOCKERFILE"; then
        sed -i '/lua-devel/a \       # PMIx and MPI build dependencies \\\n       libevent-devel \\\n       hwloc \\\n       hwloc-devel \\\n       hwloc-libs \\\n       autoconf \\\n       automake \\\n       libtool \\\n       flex \\\n       numactl \\\n       numactl-devel \\' "$DOCKERFILE"
        echo "PMIx duild dependencies added"
    fi

    # Inserting PMIx build before SLURM_TAG
    if ! grep -q "ARG PMIX_VERSION" "$DOCKERFILE"; then
        sed -i '/^ARG SLURM_TAG/i \
# Building and installing PMIx from source\
ARG MY_PMIX_VERSION=4.2.9\
\
RUN set -ex \\\
    \&\& cd /tmp \\\
    \&\& wget https://github.com/openpmix/openpmix/releases/download/v${MY_PMIX_VERSION}/pmix-${MY_PMIX_VERSION}.tar.gz \\\
    \&\& tar xzf pmix-${MY_PMIX_VERSION}.tar.gz \\\
    \&\& cd pmix-${MY_PMIX_VERSION} \\\
    \&\& ./configure \\\
        --prefix=/usr \\\
        --libdir=/usr/lib64 \\\
        --with-libevent \\\
        --with-hwloc \\\
    \&\& make -j$(nproc) \\\
    \&\& make install \\\
    \&\& ldconfig \\\
    \&\& cd / \\\
    \&\& rm -rf /tmp/pmix-${MY_PMIX_VERSION}*\
\
# Verify PMIx installation\
RUN pmix_info --version \&\& ls -la /usr/lib64/libpmix*\
' "$DOCKERFILE"
        echo "  Added PMIx build stage"
    fi
    
    # Modify Slurm configure to include --with-pmix
    if ! grep -q "\-\-with-pmix" "$DOCKERFILE"; then
        sed -i 's|--with-mysql_config=/usr/bin  --libdir=/usr/lib64|--with-mysql_config=/usr/bin --libdir=/usr/lib64 \\\n        --with-pmix=/usr \\\n        --with-hwloc|' "$DOCKERFILE"
        echo "  Modified Slurm build to include --with-pmix"
    fi
    
    # Add OpenMPI source build after Slurm build (before COPY slurm.conf)
    if ! grep -q "ARG OPENMPI_VERSION" "$DOCKERFILE"; then
        sed -i '/^COPY slurm.conf/i \
# Build OpenMPI from source with PMIx and Slurm support\
ARG OPENMPI_VERSION=4.1.6\
\
RUN set -ex \\\
    \&\& cd /tmp \\\
    \&\& wget https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-${OPENMPI_VERSION}.tar.gz \\\
    \&\& tar xzf openmpi-${OPENMPI_VERSION}.tar.gz \\\
    \&\& cd openmpi-${OPENMPI_VERSION} \\\
    \&\& ./configure \\\
        --prefix=/usr/local \\\
        --with-pmix=/usr \\\
        --with-slurm \\\
        --with-hwloc \\\
        --enable-mpi-cxx \\\
        --enable-mpi-fortran=no \\\
        --disable-getpwuid \\\
    \&\& make -j$(nproc) \\\
    \&\& make install \\\
    \&\& ldconfig \\\
    \&\& cd / \\\
    \&\& rm -rf /tmp/openmpi-${OPENMPI_VERSION}*\
\
# Configure OpenMPI library path and create symlinks\
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/openmpi-local.conf \&\& ldconfig\
RUN ln -sf /usr/local/bin/mpirun /usr/bin/mpirun \\\
    \&\& ln -sf /usr/local/bin/mpiexec /usr/bin/mpiexec \\\
    \&\& ln -sf /usr/local/bin/mpicc /usr/bin/mpicc \\\
    \&\& ln -sf /usr/local/bin/mpicxx /usr/bin/mpicxx\
\
# Set environment for all users\
RUN echo "export PATH=/usr/local/bin:\\$PATH" >> /etc/profile.d/openmpi.sh \\\
    \&\& echo "export LD_LIBRARY_PATH=/usr/local/lib:\\$LD_LIBRARY_PATH" >> /etc/profile.d/openmpi.sh \\\
    \&\& chmod +x /etc/profile.d/openmpi.sh\
RUN echo "export PATH=/usr/local/bin:\\$PATH" >> /etc/bashrc \\\
    \&\& echo "export LD_LIBRARY_PATH=/usr/local/lib:\\$LD_LIBRARY_PATH" >> /etc/bashrc\
\
# Verify OpenMPI has Slurm/PMIx support\
RUN /usr/local/bin/ompi_info | grep -E "(slurm|pmi)" | head -10 || true\
' "$DOCKERFILE"
        echo "  Added OpenMPI source build stage"
    fi
    
    NEEDS_REBUILD=true
    echo "Dockerfile modifications complete"
fi

# Updating the slurm.conf
# Add pmix as default if not alreaduy
if ! grep -q "^MpiDefault=" "$SLURM_CONF"; then
    echo "  Adding MpiDefault=pmix"
    sed -i '/^SwitchType=/a MpiDefault=pmix' "$SLURM_CONF"
elif ! grep -q "^MpiDefault=pmix" "$SLURM_CONF"; then
    echo "  Updating MpiDefault to pmix"
    sed -i 's/^MpiDefault=.*/MpiDefault=pmix/' "$SLURM_CONF"
else
    echo "  MpiDefault=pmix already set"
fi
sed -i '/^GresTypes=qpu/d' "$SLURM_CONF"
sed -i '/^NodeName=q1/d' "$SLURM_CONF"
sed -i '/^PartitionName=quantum/d' "$SLURM_CONF"
# Add qpu gres
echo "Adding gresType=qpu"
if grep -q "^SelectTypeParameters=" "$SLURM_CONF"; then
    sed -i '/^SelectTypeParameters=/a GresTypes=qpu' "$SLURM_CONF"
elif grep -q "^FastSchedule=" "$SLURM_CONF"; then
    sed -i '/^FastSchedule=/a GresTypes=qpu' "$SLURM_CONF"
else
    echo "GresTypes=qpu" >> "$SLURM_CONF"
fi
sed -i '/^NodeName=c\[1-2\]/a NodeName=q1 CPUs=1 RealMemory=1000 CoresPerSocket=1 Gres=qpu:1 State=UNKNOWN' "$SLURM_CONF"
sed -i 's/Default=yes/Default=NO/' "$SLURM_CONF"
echo "  Adding PartitionName=quantum to the end of the slurm.conf file."
echo "PartitionName=quantum Default=YES Nodes=q1 MaxTime=INFINITE State=UP" >> "$SLURM_CONF"

echo "Verifying Configuration"
grep -E "MpiDefault|NodeName=q1|GresTypes=qpu|PartitionName=quantum" "$SLURM_CONF"

# Rebuild if changes were made or mpirun not in PATH
if [[ "$NEEDS_REBUILD" == "true" ]] || ! docker exec c1 which mpirun 2>/dev/null | grep -q "/usr/local/bin/mpirun"; then
    echo "Rebuilding Docker image..."
    (cd "$CLUSTER_DIR" && docker compose build --no-cache)
    
    echo "Restarting containers with new image..."
    (cd "$CLUSTER_DIR" && docker compose down)
    (cd "$CLUSTER_DIR" && docker compose up -d)
    echo "Waiting for services to start"
    sleep 30
else
    echo "Checking container status..."
    if ! docker exec c1 true 2>/dev/null; then
        echo "Starting containers..."
        (cd "$CLUSTER_DIR" && docker compose up -d)
        sleep 10
    fi
fi

# Create gres.conf file (General Resource Configuration file)
echo ""
echo "Creating General Resource Configuration file gres.conf"
docker exec slurmctld bash -c 'cat > /etc/slurm/gres.conf << EOF
# GRES Configuration for Quantum Queue
NodeName=q1 Name=qpu Count=1
EOF'
# Copy updated slurm.conf to containers
echo ""
echo "Copying slurm.conf to containers..."
docker cp "$SLURM_CONF" slurmctld:/etc/slurm/slurm.conf
docker cp "$SLURM_CONF" c1:/etc/slurm/slurm.conf
docker cp "$SLURM_CONF" c2:/etc/slurm/slurm.conf

echo "Adding Quantum Node to Cluster"
echo

echo "Updating docker-compose.yml file if needed"


if ! grep -q "container_name: q1" "$COMPOSE_FILE"; then
    echo "Adding q1 service to docker-compose.yml..."
    
    # Insert q1 service before 'volumes:'
    sed -i '/^volumes:/i \
  q1:\
    image: slurm-docker-cluster:${IMAGE_TAG}\
    command: ["slurmd"]\
    hostname: q1\
    container_name: q1\
    volumes:\
    - etc_munge:/etc/munge\
    - etc_slurm:/etc/slurm\
    - slurm_jobdir:/data\
    - var_log_q1:/var/log/slurm\
    - ./shared:/shared\
    expose:\
      - "6818"\
    depends_on:\
      - slurmctld\
    networks:\
      - slurm-network\
' "$COMPOSE_FILE"

    # Add var_log_q1 volume
    sed -i '/^  var_log_c2:/a \  var_log_q1:' "$COMPOSE_FILE"
else
    echo "q1 service already exists"
fi

# Start the q1 container
echo "Starting q1 container"
(cd "$CLUSTER_DIR" && docker compose up -d q1)
sleep 5

echo "Verifying changes"

# Copy slurm.conf to q1
docker cp "$SLURM_CONF" q1:/etc/slurm/slurm.conf 2>/dev/null || true

# Reconfigure Slurm
echo "Reconfiguring Slurm..."
docker exec slurmctld scontrol reconfigure


echo "--- Slurm MPI Support ---"
docker exec c1 srun --mpi=list 2>&1 || echo "(srun --mpi=list not available yet)"

echo ""
echo "--- OpenMPI PMIx/Slurm Support ---"
docker exec c1 /usr/local/bin/ompi_info 2>/dev/null | grep -E "(slurm|pmi)" | head -5 || echo "(ompi_info check skipped)"

echo ""
echo "--- Cluster Status ---"
docker exec slurmctld sinfo

echo ""
echo "--- Quantum Node Status ---"
docker exec slurmctld scontrol show node q1

echo ""
echo "--- SPANK Plugin Check ---"
if docker exec c1 sbatch --help 2>&1 | grep -q "qpu"; then
    echo "QRMI SPANK plugin loaded (--qpu option available)"
else
    echo "QRMI SPANK plugin not loaded (build it with the instructions in INSTALL.md)"
fi

echo ""
echo "Done!"
echo ""
