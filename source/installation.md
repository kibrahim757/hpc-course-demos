# Installation

This document describes how to setup development environment and the plugins developed in this project.


## Setup Local Development Environment

### Jump To:
- [Pre-requisites](#pre-requisites)
- [Creating Docker-based Slurm Cluster](#creating-docker-based-slurm-cluster)
- [Building and installing QRMI and SPANK Plugins](#building-and-installing-qrmi-and-spank-plugins)
- [Running examples of primitive job in Slurm Cluster](#running-examples-of-primitive-job-in-slurm-cluster)


### Pre-requisites

- [Podman](https://podman.io/getting-started/installation.html) or [Docker](https://docs.docker.com/get-docker/) installed. You can use [Rancher Desktop](https://rancherdesktop.io/) instead of installing Docker on your PC.


### Creating Docker-based Slurm Cluster

You can skip below steps if you already have Slurm Cluster for development.

Please refer to  the [documentation in our shared repo](https://github.com/qiskit-community/spank-plugins/blob/main/demo/qrmi/slurm-docker-cluster/INSTALL.md) for the latest Slurm Docker Cluster installation instructions.

##### Note 

4. Building [SPANK Plugin](../../../plugins/spank_qrmi/README.md)

```bash
[root@c1 /]# cd /shared/spank-plugins/plugins/spank_qrmi
[root@c1 /]# mkdir build
[root@c1 /]# cd build
[root@c1 /]# cmake ..
[root@c1 /]# make
```

> NOTE: you might need to run `git config --global --add safe.directory /shared/spank-plugins/plugins/spank_qrmi/build/deps/src/QRMI` if `make` is complaining about folder ownership

5. Creating qrmi_config.json

Refer [this example](https://github.com/qiskit-community/spank-plugins/blob/main/plugins/spank_qrmi/qrmi_config.json.example) and describe your environment. Then, create a file under /etc/slurm or other where slurm daemons can access.

Example:
```json
{
  "resources": [
    {
      "name": "ibm_brisbane", // or whatever backend name you have access to
      "type": "qiskit-runtime-service",
      "environment": {
        "QRMI_IBM_QRS_ENDPOINT": "https://quantum.cloud.ibm.com/api/v1",
        "QRMI_IBM_QRS_IAM_ENDPOINT": "https://iam.cloud.ibm.com",
        "QRMI_IBM_QRS_IAM_APIKEY": "<YOUR IAM APIKEY FOR THIS BACKEND>",
        "QRMI_IBM_QRS_SERVICE_CRN": "<YOUR IQP INSTANCE CRN>"
      }
    },
  ]
}
```


### Running examples of hybrid jobs

The examples in the [Slurm Docker Cluster Installation Document](https://github.com/qiskit-community/spank-plugins/blob/main/demo/qrmi/slurm-docker-cluster/INSTALL.md) show how to submit quantum only jobs using QRMI, next we will look into Quantum-Classical mixed workflows.

#### 1. Running `Hello, World!` and `Hello, Qiskit!`

```bash
sbatch /shared/chapters/ch2/hello_world/hello_world.sh
squeue
```

```bash
sbatch /shared/chapters/ch2/hello_qiskit/hello_qiskit.sh
squeue
```

#### 2. Running patterns workflow

```bash
MAPPING_JOB=$(sbatch --parsable mapping.sh)
OPTIMIZE_JOB=$(sbatch --parsable --dependency=afterok:$MAPPING_JOB optimization.sh)
EXECUTE_JOB=$(sbatch --parsable --dependency=afterok:$OPTIMIZE_JOB execution.sh)
squeue
```

#### 3. Running SQD

```bash
MAPPING_JOB=$(sbatch --parsable mapping.sh)
OPTIMIZE_JOB=$(sbatch --parsable --dependency=afterok:$MAPPING_JOB optimization.sh)
EXECUTE_JOB=$(sbatch --parsable --dependency=afterok:$OPTIMIZE_JOB execution.sh)
POSTPROCESSING_JOB=$(sbatch --parsable --dependency=afterok:$EXECUTE_JOB postprocessing.sh)
squeue
```

### Running serialized jobs using the qrmi_task_runner Slurm Cluster

It is possible to run JSON-serialized jobs directly using a commandline utility called qrmi_task runner.
See [the docs](https://github.com/qiskit-community/qrmi/blob/main/bin/task_runner/README.md) for that tool for details.

```bash
[root@login /]# sbatch /shared/spank-plugins/demo/qrmi/jobs/run_task.sh
```

#### Convenient commands to update devices or output locations:

```bash
find . -name "*.sh" -exec sed -i 's/^#SBATCH --qpu=.*/#SBATCH --qpu=ibm_torino/' {} +
find ~/hpc-course-demos -name "*.sh" -exec grep -l "#SBATCH --output=" {} \; -exec sed -i 's|#SBATCH --output=.*|#SBATCH --output=/shared/slurm-%j.out|g' {} \;
```