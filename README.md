# livelabsbrew

<last updates 2024-07-07>

```livelabs-brew.sh``` is the first init script.

## TL;DR
Execute as `opc` on an OCI compute instance with at least 100GB (the script will automatically extend the file system).
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/klazarz/livelabsbrew/main/livelabs-brew.sh)"
```


## What does it do?
It creates the following setup:
- 23ai free in a container
  - including Oracle sample data
- ORDS + APEX in a container (fully configured with the DB)
- Jupyter Lab including LSPs for several languages.
  - Allows running Flask apps (on port 5000)
  - sqlcl installed
- (optional) noVNC config (currently commented out lines 204-278)
- All containers autostart after server restart

## What is possible?
After running the script you can do the following:
- Connect to DB Actions / APEX via `server-ip:8181`
- Connect to Jupyter Lab via `server-ip:8888`
  - Start Flask apps from Jupyter Lab on port 5000 `server-ip:5000`
  - Connect to the database using `sqlcl` from Terminal in Jupyter Lab (Example: `sql hr/<password>@23aifree/freepdb1`)

## DB Users
All users/schemas are ORDS-enabled

Oracle Sample Data schemas:
- HR
- CO
- SH
  
Admin user with DBA role

# Installation
Execute as `opc` on an OCI compute instance with at least 100GB (the script will automatically extend the file system).

## Execute LiveLabs Brew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/klazarz/livelabsbrew/main/livelabs-brew.sh)"
```

Note: You need to restart the server after the script is finished to initialize the containers using `systemd`.
The script takes approximately 30-35 minutes to complete.
After restart of the server all containers are up in **under 3 minutes**.

## Installation Details

The script executes the following:

1. Installation of 23ai prerequisites (in VM)
2. `JDK 17` (in VM)
3. `sqlcl`  (in VM)
4. (optional) noVNC
5. Prerequisites to run containers (`podman`, etc.)
6. Container Jupyter Lab (container name: `jupol8`)
   1.  Python 3.12 and relevant libraries (see below for details))
   2.  `npm` and LSP for several programming languages
   3.  `sqlcl`
7. Container 23ai free (container name: `23aifree`)
8. Container ORDS + APEX (container name: `ords`)
9. Container network name: `oraclenet`

Base images used from Oracle Container Registry
- container-registry.oracle.com/database/ords:latest
- container-registry.oracle.com/os/oraclelinux:8
- container-registry.oracle.com/database/free:latest

## Connect

- Jupter Lab: ip:8888
- DB Actions and APEX: ip:8181

For APEX use the following login infos
- Workspace: internal
- User:      ADMIN
- Password:  `Welcome_1`

ORDS enabled users are: HR, CO, SH, and Admin. Password for all users is:



### Pre-installed Python Libraries
Following libraries are pre-installed

```
oracledb
sentence-transformers
oci
jupyterlab
pandas
setuptools
scipy
matplotlib
scikit-learn
langchain
langchain_community
numpy
onnxruntime
onnxruntime-extensions
onnx
prettytable
pyvis
torch
transformers
sentencepiece
spacy
ipython-sql
Flask
jupyterlab-lsp
jedi-language-server
```


# Server config
The script is tested on OCI compute instances using a shape with 2 OCPUs/32GB RAM and 180GB custom boot drive.


# ToDo's
[ ] Decide whether noVNC should be in there

[ ] Create a demo Jupyter notebook

[ ] Create a demo Flask app

[ ] Create a cheatsheet

[ ] Add True Cache setup

[ ] Clean up script

# Disclaimer
This is a test script. No support, no help, no nothing!