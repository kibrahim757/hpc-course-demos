# Installation

This document provides guidance on setting up an environment for the HPC course exercises. Let’s start by preparing the necessary information first..


# Jump To:
- [Pre-requisites](#pre-requisites)
- [Creating Docker-based Slurm Cluster](#creating-docker-based-slurm-cluster)
- [Building and installing QRMI and SPANK Plugins](#building-and-installing-qrmi-and-spank-plugins)
- [Modify configurations for this course](#configure-slurmconf-and-qrmi_configjson)
- [Copy course files and install Course Requirements](#copy-and-install-requirements)

# Pre-requisites

## Docker Environment
The exercises will be conducted using Docker, which includes a Slurm cluster set up on your local computer.

Docker is an open platform for packaging, distributing, and running applications in lightweight, portable containers. It streamlines development workflows by isolating applications with their dependencies, ensuring consistent behavior across environments—from local laptops to cloud servers.

At its core, Docker Engine manages containers using OS-level virtualization on Linux and lightweight VMs on macOS and Windows.
To use Docker on your desktop, you need to install one of the following:

- [Docker Desktop](https://docs.docker.com/get-docker/) or [Rancher Desktop](https://rancherdesktop.io/) 
- Alternatively, [Podman](https://podman.io/getting-started/installation.html)

## IBM Cloud Credentials for QPU access

You will need valid IBM Cloud credentials to access the Quantum Processing Unit (QPU). Make sure your account is set up and ready before starting the exercises.

Please refer to the [Set up your IBM Cloud account](https://quantum.cloud.ibm.com/docs/en/guides/cloud-setup) guide to create and configure your account.
After completing the setup, save your access credentials by following the instructions in [Save your login credentials](https://quantum.cloud.ibm.com/docs/en/guides/save-credentials) at a text note. You will need an `API key` and `CRNs(Compute Resource Names)` to access to the QPUs.


## Prepare SSH connection to the Github

To clone a repository from GitHub using the `git clone` command, you may need to [generate an SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) and [add it to your GitHub account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account).

# Creating Docker-based Slurm Cluster

You can skip below steps if you already have Slurm Cluster for development.

Please refer to  the [documentation in spank plugin repo](https://github.com/qiskit-community/spank-plugins/blob/main/demo/qrmi/slurm-docker-cluster/INSTALL.md) for the latest Slurm Docker Cluster installation instructions.

It is recommended to clone the repo into the following directory:

```
hpc-course-demo/source
```

If you successfully created the Slurm cluster, you should see six containers running on your machine. You can verify this by checking your terminal or viewing your containers in tools like Docker, Rancher Desktop, or Podman.

![launching containers](../media/images/launch_containers.png)

Please follow the installation guide to install the QRMI and Spank plugins. 

After installing the QRMI and Spank plugins, your next step is to creater a quantum partition in slurm, copy the provided scripts into the shared slurm directory, and update critical configuration files.

<details>
<summary>
If you experience gosu failures during the docker compose build process try this:

</summary>
In the Dockerfile found in 

```bash
/slurm-docker-cluster/ 
```
Replace lines 57-65:
```bash
RUN set -ex \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -rf "${GNUPGHOME}" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true
```

with 
```bash
RUN set -ex \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64" \
    && echo "bbc4136d03ab138b1ad66fa4fc051bafc6cc7ffae632b069a53657279a450de3  /usr/local/bin/gosu" | sha256sum -c - \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true
```
</details>

## Copy script files into the shared directory so all containers have access

while In the ```/slurm-docker-cluster``` directory pass the following command into your terminal. Note that this assumes that the slurm-docker-cluster directory is present in the ```/source``` directory of this repo, if needed modify the command to point to the ```/chapters``` directory found in the source folder of this repo.

```bash
cp -r ../chapters ./shared
```
# Configure slurm.conf and qrmi_config.json

## How to edit files in the container

There are two main ways to edit configuration files inside a container:

### 1. Edit directly inside the container using an editor

First connect to the container (for example `c` or `login` container)

```bash
docker exec -it <container_name> bash
```

Open the file with [vi editor](https://www.redhat.com/en/blog/introduction-vi-editor)(or another editor):

```bash
vi /path/to/filename.txt
```

Once finished editing, press `ESC` and type `:wq` to save and quit editor.

### 2. Edit Locally and Copy Back to the Container

If you prefer to use your local editor, follow these steps:

First, copy the file from the container to your local machine:

```bash
docker cp <container_name>:/path/to/file /local/path
```
Next, edit the file locally using your preferred editor (e.g., VS Code, nano, etc)

Then, copy the updated file back into the container:

```bash
docker cp /local/path <container_name>:/path/to/file
```

In the following section, we will introduce how to use vi editor to edit both config files.

> Note: you can also utilize `shared` folder to share files and folders between containers and local machine. 

## Edit slurm.conf

Next, you need to update the slurm.conf file to adjust the CPUs setting so it matches your local machine’s physical CPU count:


```bash
((pyenv) ) [root@c1 /]# vi /etc/slurm/slurm.conf
```

Navigate to line 93 (or search for NodeName), then press i to enter insert mode. Update the CPUs value to 1 or another appropriate number that reflects your machine’s actual CPU cores.
For example, change:

```
NodeName=c[1-2] CPUs=6 RealMemory=1000 State=UNKNOWN
```

To:

```
NodeName=c[1-2] CPUs=1 RealMemory=1000 State=UNKNOWN
```

save and exit by typing `Esc` and `:wq`, then apply the changes by running:

```bash
systemctl restart slurmd
scontrol reconfigure
scontrol update NodeName=c[1-2] State=RESUME
```

If this doesn't work try this command from outside of your container:
```bash
docker restart c1 c2
docker exec slurmctld scontrol reconfigure
```
If everything is set correctly, you should see the following output when you run `sinfo` inside the container:

```bash
docker exec -it c1 bash
```

``` bash
[root@c1 chapters]# sinfo
[root@login /]# sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
normal       up 5-00:00:00      2   idle c[1-2]
quantum*     up   infinite      1   idle q1
```

## Edit qrmi_config.json

Use the following command to edit `qrmi_config.json`:


```bash
((pyenv) ) [root@c1 /]# vi /etc/slrum/qrmi_config.json
```

Next, edit the file by pressing `i` to enter insert mode in vi. Add the quantum backends you can access using your `IAM APIKEY` and `CRN`. Refer to [this guide](https://quantum.cloud.ibm.com/docs/en/guides/save-credentials#find-your-access-credentials) to learn how to find your access credentials. Below is an example of adding three QPUs available with your Open Plan:

Example:
```
{
  "resources": [
    {
      "name": "ibm_fez",
      "type": "qiskit-runtime-service",
      "environment": {
        "QRMI_IBM_QRS_ENDPOINT": "https://quantum.cloud.ibm.com/api/v1",
        "QRMI_IBM_QRS_IAM_ENDPOINT": "https://iam.cloud.ibm.com",
        "QRMI_IBM_QRS_IAM_APIKEY": "<YOUR IAM APIKEY FOR THIS BACKEND>",
        "QRMI_IBM_QRS_SERVICE_CRN": "<YOUR IQP INSTANCE CRN>",
        "QRMI_IBM_QRS_SESSION_MODE": "batch"

      }
    },
    {
      "name": "ibm_marrakesh",
      "type": "qiskit-runtime-service",
      "environment": {
        "QRMI_IBM_QRS_ENDPOINT": "https://quantum.cloud.ibm.com/api/v1",
        "QRMI_IBM_QRS_IAM_ENDPOINT": "https://iam.cloud.ibm.com",
        "QRMI_IBM_QRS_IAM_APIKEY": "<YOUR IAM APIKEY FOR THIS BACKEND>",
        "QRMI_IBM_QRS_SERVICE_CRN": "<YOUR IQP INSTANCE CRN>",
        "QRMI_IBM_QRS_SESSION_MODE": "batch"
      }
    },
    {
      "name": "ibm_torino",
      "type": "qiskit-runtime-service",
      "environment": {
        "QRMI_IBM_QRS_ENDPOINT": "https://quantum.cloud.ibm.com/api/v1",
        "QRMI_IBM_QRS_IAM_ENDPOINT": "https://iam.cloud.ibm.com",
        "QRMI_IBM_QRS_IAM_APIKEY": "<YOUR IAM APIKEY FOR THIS BACKEND>",
        "QRMI_IBM_QRS_SERVICE_CRN": "<YOUR IQP INSTANCE CRN>",
        "QRMI_IBM_QRS_SESSION_MODE": "batch"
      }
    }
  ]
}
```

> Note: If you are using a premium plan and can enable session mode, you may remove `"QRMI_IBM_QRS_SESSION_MODE": "batch"` from the configuration file.

After you finish editing the file in vi, press `ESC` to exit insert mode then type `:wq` and press Enter to save and close the file.
# Add a quantum partition to Slurm and build the q1 Container

Navigate to the folder on your local machine that contains the slurm-docker-container repo from the step above.

For example:
```bash
cd hpc-course-demos/source
```
Then execute the following command from your terminal:
```bash
./q1_container.sh
```
<details>
<summary>
Example Output:</summary>

```
--- Slurm MPI Support ---
MPI plugin types are...
        none
        cray_shasta
        pmix
        pmi2
specific pmix plugin versions available: pmix_v4

--- OpenMPI PMIx/Slurm Support ---
  Configure command line: '--prefix=/usr/local' '--with-pmix=/usr' '--with-slurm' '--with-hwloc' '--enable-mpi-cxx' '--enable-mpi-fortran=no' '--disable-getpwuid'
                MCA pmix: isolated (MCA v2.1.0, API v2.0.0, Component v4.1.6)
                MCA pmix: flux (MCA v2.1.0, API v2.0.0, Component v4.1.6)
                MCA pmix: ext3x (MCA v2.1.0, API v2.0.0, Component v4.1.6)
                 MCA ess: slurm (MCA v2.1.0, API v3.0.0, Component v4.1.6)

--- Cluster Status ---
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
normal       up 5-00:00:00      2   idle c[1-2]
quantum*     up   infinite      1   idle q1

--- Quantum Node Status ---
NodeName=q1 Arch=x86_64 CoresPerSocket=1 
   CPUAlloc=0 CPUEfctv=1 CPUTot=1 CPULoad=1.84
   AvailableFeatures=(null)
   ActiveFeatures=(null)
   Gres=qpu:1
   NodeAddr=q1 NodeHostName=q1 Version=25.05.3
   OS=Linux 6.6.87.2-microsoft-standard-WSL2 #1 SMP PREEMPT_DYNAMIC Thu Jun  5 18:30:46 UTC 2025 
   RealMemory=1000 AllocMem=0 FreeMem=3219 Sockets=1 Boards=1
   State=IDLE ThreadsPerCore=1 TmpDisk=0 Weight=1 Owner=N/A MCS_label=N/A
   Partitions=quantum 
   BootTime=2025-12-23T17:51:25 SlurmdStartTime=2025-12-25T13:49:25
   LastBusyTime=2025-12-25T13:49:25 ResumeAfterTime=None
   CfgTRES=cpu=1,mem=1000M,billing=1
   AllocTRES=
   CurrentWatts=0 AveWatts=0


--- SPANK Plugin Check ---
QRMI SPANK plugin loaded (--qpu option available)

Done!
```
</details>

## Copy and install requirements

You’re almost there! Open a terminal on your local machine and navigate to the directory you used to set up the containers. Run the following commands to clone the course materials:

Next, log in to the c1 container:

```bash
docker exec -it c1 bash
```

Inside the container, activate the virtual environment:

```bash
[root@c1 /]# source /shared/pyenv/bin/activate
```

Then navigate to the chapters folder and install the requirements:

``` bash
((pyenv) ) [root@c1 chapters]# cd /shared/chapters
((pyenv) ) [root@c1 chapters]# pip install -r requirements.txt
```
Now you are all set. Follow the course notebooks and videos to begin your Quantum Centric Super Computing journey!

# Convenient Linux commands to update devices or output locations:
To update the --qpu flag in all your scripts run:
```bash
find . -name "*.sh" -exec sed -i 's/^#SBATCH --qpu=.*/#SBATCH --qpu=ibm_torino/' {} +
```
To change the output location of all slurm .out files update the ```|#SBATCH --output=slurm-%j.out|g' {} \;``` part of this command with the output path and file name you would like. 
```bash
find ~/hpc-course-demos -name "*.sh" -exec grep -l "#SBATCH --output=" {} \; -exec sed -i 's|#SBATCH --output=.*|#SBATCH --output=slurm-%j.out|g' {} \;
```
