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

# Create gres.conf file (General Resource Configuration file)
echo "Creating General Resource Configuration file gres.conf"
docker exec slurmctld bash -c 'cat > /etc/slurm/gres.conf << EOF
# GRES Configuration for Quantum Queue
NodeName=q1 Name=qpu Count=1
EOF'

# Update the slurm.conf files 
echo "Updating slurm.conf files"
SLURM_CONF="$CLUSTER_DIR/shared/spank-plugins/demo/qrmi/etc/slurm/slurm.conf"
# Edit local file (remove then add for idempotency)
sed -i '/^GresTypes=qpu/d' "$SLURM_CONF"
sed -i '/^NodeName=q1/d' "$SLURM_CONF"
sed -i '/^PartitionName=quantum/d' "$SLURM_CONF"

echo "  Adding GresTypes=qpu"
sed -i '/^FastSchedule=1/a GresTypes=qpu' "$SLURM_CONF"

echo "  Adding NodeName=q1"
sed -i '/^NodeName=c\[1-2\]/a NodeName=q1 CPUs=1 RealMemory=1000 CoresPerSocket=1 Gres=qpu:1 State=UNKNOWN' "$SLURM_CONF"

echo "  Updating partition defaults"
sed -i 's/Default=yes/Default=NO/' "$SLURM_CONF"

echo "  Adding PartitionName=quantum"
echo "PartitionName=quantum Default=YES Nodes=q1 MaxTime=INFINITE State=UP" >> "$SLURM_CONF"

# Verify local changes
echo "  Verifying configuration:"
grep -E "NodeName=q1|GresTypes=qpu|PartitionName=quantum" "$SLURM_CONF"

# Copy to container
echo "  Copying to container..."
docker cp "$SLURM_CONF" c1:/etc/slurm/slurm.conf

# Validate
COMPOSE_FILE="$CLUSTER_DIR/docker-compose.yml"
if [[ ! -f "$COMPOSE_FILE" ]]; then
    echo "Error: Could not find docker-compose.yml"
    echo "Usage: $0 /path/to/slurm-docker-cluster"
    exit 1
fi
echo "Using cluster directory: $CLUSTER_DIR"

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

# Reconfigure Slurm
echo "Updating slurm"
docker exec slurmctld scontrol reconfigure

# Verify
echo "Verifying changes"
docker exec slurmctld sinfo
docker exec slurmctld scontrol show node q1

echo "Done"
