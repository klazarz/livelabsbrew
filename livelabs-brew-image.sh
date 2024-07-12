#!/bin/bash
# v1.0

#######################################################################################################################
###                                                                                                                 ###
### THIS SCRIPT INSTALLS 23ai free, ORDS, APEX, and Jupter Labs                                                     ###
###                                                                                                                 ###
### IT MUST BE EXECUTED JUST AFTER THE NEW VM IS PROVISIONED                                                        ###
### OR ON THE CLOUDINIT SECTION OF THE VM DEPLOYMENT                                                                ###
###                                                                                                                 ###
### RUN AS OPC                                                                                                      ###
### When finsihed login via noVNC                                                                                   ###
### http://<IP>/livelabs/vnc.html?password=LiveLabs.Rocks_99&resize=scale&quality=9&autoconnect=true&reconnect=true ###
### run in noVNC from terminal: $HOME/.livelabs/init_ll_windows.sh and jupyter-lab                                  ###
#######################################################################################################################

set -eEo pipefail

# sudo -s systemctl stop firewalld 
# sudo -s systemctl disable firewalld

sudo firewall-cmd --permanent --add-port=1521/tcp #Database
sudo firewall-cmd --permanent --add-port=8888/tcp #JupyterLabs
sudo firewall-cmd --permanent --add-port=8181/tcp #ORDS
sudo firewall-cmd --permanent --add-port=5000/tcp #Flask
#sudo firewall-cmd --permanent --add-port=5500/tcp #EM
sudo firewall-cmd --permanent --add-port=27017/tcp #Mongo
sudo firewall-cmd --reload


if [ -z "${BASH_VERSION}" -o "${BASH}" == "/bin/sh" ]
then
  >&2 echo "Script must be executed in BASH shell."
  exit 1
fi

v_this_script="$(basename -- "$0")"

[ "$(id -u -n)" != "opc" ] && >&2 echo "Must be executed as opc! Exiting..." && exit 1

# Set LC_CTYPE to avoid warnings when calling perl via sudo to oracle user
export LC_CTYPE=en_US.UTF-8

####
#### Internal functions to help usability
####

# Print error message to stderr
function echoError ()
{
   [ -z "$2" ] && (>&2 echo "$1") || (>&2 echoStatus "$1" "$2")
}

# Print status
function echoStatus ()
{
  local RED='\033[0;31m'
  local GREEN='\033[0;32m'
  local BOLD='\033[0;1m'
  local NC='\033[0m' # No Color
  local TYPE="$BOLD"
  [ "$2" == "GREEN-BOLD" ] && TYPE="$GREEN$BOLD"
  [ "$2" == "GREEN" ] && TYPE="$GREEN"
  [ "$2" == "BOLD" ] && TYPE="$BOLD"
  [ "$2" == "RED" ] && TYPE="$RED"
  printf "${TYPE}${1}${NC}\n"
}

# Print error and stop
function exitError ()
{
   local v_filename="${v_this_script%.*}.log"
   echoError "$1"
   ( set -o posix ; set ) > "${v_filename}"
   exit 1
}

# Print error and stop
function checkError ()
{
  # If 2 params given:
  # - If 1st is NULL, abort script printing 2nd.
  # If 3 params given:
  # - If 1st is NULL, abort script printing 3rd.
  # - If 2nd is not 0, abort script printing 3rd.
  local v_arg1 v_arg2 v_arg3
  v_arg1="$1"
  v_arg2="$2"
  v_arg3="$3"
  [ "$#" -ne 2 -a "$#" -ne 3 ] && exitError "checkError wrong usage."
  [ "$#" -eq 2 -a -z "${v_arg2}" ] && exitError "checkError wrong usage."
  [ "$#" -eq 3 -a -z "${v_arg3}" ] && exitError "checkError wrong usage."
  [ "$#" -eq 2 ] && [ -z "${v_arg1}" ] && echoError "${v_arg2}" "RED" && exit 1
  [ "$#" -eq 3 ] && [ -z "${v_arg1}" ] && echoError "${v_arg3}" "RED" && exit 1
  [ "$#" -eq 3 ] && [ "${v_arg2}" != "0" ] && echoError "${v_arg3}" "RED" && exit 1
  return 0
}

v_step=1
function printStep ()
{
  echoStatus "Executing Step $v_step" "GREEN-BOLD"
  ((v_step++))
}

# Trap on error or ctrl-c
function trap_err ()
{
  echo "Error on line $1 of \"${v_this_script}\"."
  exit 1
}

trap 'trap_err $LINENO' ERR
trap 'exitError "Code Interrupted."' INT SIGINT SIGTERM



# Function to display a countdown timer
function countdown() {
  local SECONDS=$1
  local INTERVAL=1
  local CURRENT_SECONDS=$SECONDS

  while [ $CURRENT_SECONDS -gt 0 ]; do
    printf "\rTime remaining: %02d:%02d" $((CURRENT_SECONDS / 60)) $((CURRENT_SECONDS % 60))
    sleep $INTERVAL
    CURRENT_SECONDS=$((CURRENT_SECONDS - INTERVAL))
  done

  printf "\rTime remaining: 00:00\n"
}






###############
#### BEGIN ####
###############

echoStatus "Starting execution." "GREEN-BOLD"

# if egrep -q "SigIgn:\s.{15}[13579bdf]" /proc/$$/status
# then
#     echoStatus "Ignores SIGHUP (runing via nohup)"
#     echoStatus "Script will start in 10 seconds"
#     sleep 10
# else
#     echoError "This script may take some time. Please rerun it with the nohup option:" "RED"
#     echoError "nohup sh $0 &" "BOLD"
#     echoError "tail -f nohup.out" "BOLD"
#     exit 1
#     # nohup sh "$0" &
#     # tail -f nohup.out
#     # exit 0
# fi

####
#### Grow FS
####

printStep

echoStatus "Gods of file systems....increase size of this file system!!!"

sudo /usr/libexec/oci-growfs -y

# Deploying livelabs required scripts:
# https://oracle-livelabs.github.io/common/sample-livelabs-templates/create-labs/labs/workshops/livelabs/?lab=6-labs-setup-graphical-remote-desktop


####
#### Create oracle user env
####

sudo dnf -y install oracle-database-preinstall-23ai

####
#### Install sqlcl (native)
####

printStep


echoStatus "I'll start with installing sqlcl on the VM - because we will need it later"

sudo -u oracle mkdir -p /home/oracle/stage/

sudo dnf -y install java-17-openjdk

sudo dnf -y install sqlcl

# Clean empty UI folders
sudo -u oracle sh -c '
set -eo pipefail
cd /home/oracle
[ -d Videos ]    && rmdir Videos
[ -d Templates ] && rmdir Templates
[ -d Pictures ]  && rmdir Pictures
[ -d Music ]     && rmdir Music
[ -d Downloads ] && rmdir Downloads
[ -d Documents ] && rmdir Documents
[ -d Public ]    && rmdir Public
exit 0
'

####
#### Run setup-firstboot.sh
####



####
#### Install container stuff
####

printStep
echo Installing container stuff

sudo dnf -y module install container-tools:ol8

sudo loginctl enable-linger oracle

sudo -u oracle mkdir -p /home/oracle/oradata

sudo -u oracle mkdir -p /home/oracle/ords_secrets

sudo -u oracle mkdir -p /home/oracle/ords_config

sudo -u oracle mkdir -p /home/oracle/.config/systemd/oracle

sudo -u oracle chmod 777 /home/oracle/oradata

sudo -u oracle chmod 777 /home/oracle/ords_secrets

sudo -u oracle chmod 777 /home/oracle/ords_config

# Check if the network 'oraclenet' already exists
if ! sudo -u oracle bash -c "cd /home/oracle/;podman network inspect oraclenet > /dev/null 2>&1"; then
  # If the network does not exist, create it
  sudo -u oracle bash -c "cd /home/oracle/;podman network create oraclenet"
else
  echo "Network 'oraclenet' already exists."
fi

#whenever you login as oracle, it automatically connects to the DB container
cat << 'EOF' | sudo -u oracle tee /home/oracle/.bash_profile > /dev/null
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi

podman exec -it 23ai /bin/bash

EOF



####
#### Install OL8 with Jupyterlab and bunch of libraries
####


echo
printStep
echo
echo Installing Jupyter Labs and a lot of awesomeness
### Install common libraries for Python
cat << 'EOF' | sudo -u oracle tee  /home/oracle/requirements.txt > /dev/null
appnope
asttokens
blinker
certifi
cffi
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
pillow
prettytable
pyvis
torch
transformers
sentencepiece
spacy
requests
ipython-sql
IProgress
Flask
jupyterlab-lsp
jedi-language-server

EOF


# #demo app for JupyterLab
# cat << 'EOF' | sudo -u oracle tee  /home/oracle/app.py > /dev/null
# from flask import Flask

# app = Flask(__name__)

# @app.route('/')
# def home():
#     return "Hello, World!"

# if __name__ == '__main__':
#     app.run(debug=True, host="0.0.0.0")
# EOF


# cat << 'EOF' | sudo -u oracle tee /home/oracle/bash_profile > /dev/null
# # .bash_profile

# # Get the aliases and functions
# if [ -f ~/.bashrc ]; then
#   . ~/.bashrc
# fi

# export PATH=$HOME/.opt/sqlcl/bin:$PATH


# # Aliases
# alias sql="/home/oracle/.opt/sqlcl/bin/sql"
# alias sqlplus="ssh host.containers.internal"
# alias l="ls -la"
# EOF



sudo -u oracle ssh-keygen -t rsa -f /home/oracle/.ssh/id_rsa -q -P ""
sudo -u oracle bash -c "cat /home/oracle/.ssh/id_rsa.pub >> /home/oracle/.ssh/authorized_keys"
sudo -u oracle cp /home/oracle/.ssh/id_rsa /home/oracle/

# cat << 'EOF' | sudo -u oracle tee /home/oracle/id_rsa.pub > /dev/null
# ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC5ekRF/HwtHZ4Lw/9xemtNN2vOwV3WgFNpRwbiH2qL3Pc0WH6L6MMIcYcey6gwmm8Tq4P2D5MXN53jf7i9v12oR4EYQhyd+s9hCawxmiHIWQmaclXlvCiTglTlE0IsIBVJAGvtNt6YPwvwps3oRWyV6aDokeE+M3jxDrL7PAJHH2xcPsrsuDwlT8zKcBVgZjvJlDiVCFWx45So0zOj7wOEWo5gDgepys+vN9G5QcQZoPP5YZGbZMdCtHWy568Xmn3f545CH0tGthFs1e02flPL0gm+QTffGlJwBovC4k9qaTGYtYfTePx6EBWvvTNEpVnJyDPkhbfFc9azsvhAOLUI+6Sj51/GQUf+KlyIx1lO3fFZMHiRB3v3T0jFTcZxSDJuRViAE2YRTMpFq7vpgKOHiHsl2fdRoU04Jtnzq+CmI2sc/MeKG2Z9drHg7VT5j0xaSr/Kh3nHFmfPz8ND5oCNU9TzDmoFJWiH532yLzlCkdUL927WW+mZHfvj1Z0p87s= 23aifree@livelabs
# EOF

# sudo -u oracle chmod 644 /home/oracle/id_rsa.pub


# cat << 'EOF' | sudo -u oracle tee /home/oracle/id_rsa > /dev/null
# -----BEGIN OPENSSH PRIVATE KEY-----
# b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABlwAAAAdzc2gtcn
# NhAAAAAwEAAQAAAYEAuXpERfx8LR2eC8P/cXprTTdrzsFd1oBTaUcG4h9qi9z3NFh+i+jD
# CHGHHsuoMJpvE6uD9g+TFzed43+4vb9dqEeBGEIcnfrPYQmsMZohyFkJmnJV5bwok4JU5R
# NCLCAVSQBr7TbemD8L8KbN6EVslemg6JHhPjN48Q6y+zwCRx9sXD7K7Lg8JU/MynAVYGY7
# yZQ4lQhVseOUqNMzo+8DhFqOYA4HqcrPrzfRuUHEGaDz+WGRm2THQrR1suevF5p93+eOQh
# 9LRrYRbNXtNn5Ty9IJvkE33xpScAaLwuJPamkxmLWH03j8ehAVr70zRKVZycgz5IW3xXPW
# s7L4QDi1CPuko+dfxkFH/ipciMdZTt3xWTB4kQd7909IxU3GcUgybkVYgBNmEUzKRau76Y
# Cjh4h7Jdn3UaFNOCbZ86vgpiNrHPzHihtmfXax4O1U+Y9MWkq/yod5xxZnz8/DQ+aAjVPU
# 8w5qBSVoh+d9si85QpHVC/du1lvpmR3749WdKfO7AAAFkCsFwnorBcJ6AAAAB3NzaC1yc2
# EAAAGBALl6REX8fC0dngvD/3F6a003a87BXdaAU2lHBuIfaovc9zRYfovowwhxhx7LqDCa
# bxOrg/YPkxc3neN/uL2/XahHgRhCHJ36z2EJrDGaIchZCZpyVeW8KJOCVOUTQiwgFUkAa+
# 023pg/C/CmzehFbJXpoOiR4T4zePEOsvs8AkcfbFw+yuy4PCVPzMpwFWBmO8mUOJUIVbHj
# lKjTM6PvA4RajmAOB6nKz6830blBxBmg8/lhkZtkx0K0dbLnrxeafd/njkIfS0a2EWzV7T
# Z+U8vSCb5BN98aUnAGi8LiT2ppMZi1h9N4/HoQFa+9M0SlWcnIM+SFt8Vz1rOy+EA4tQj7
# pKPnX8ZBR/4qXIjHWU7d8VkweJEHe/dPSMVNxnFIMm5FWIATZhFMykWru+mAo4eIeyXZ91
# GhTTgm2fOr4KYjaxz8x4obZn12seDtVPmPTFpKv8qHeccWZ8/Pw0PmgI1T1PMOagUlaIfn
# fbIvOUKR1Qv3btZb6Zkd++PVnSnzuwAAAAMBAAEAAAGBAJREZfFgXU+fXmjfXAK1rrMCO5
# 8CumWvHX6J9bmrDXwSvlZM65QiFE5amn4GpUN9IJAjypBXcOjdX8ytm9uq706HIm5m4wNy
# rHZQyiK4qIrEikW5YmsMl48bX4vjckFdwEYkHSJ6e0RPGdddMDqdzKimIyfm/ZzAfsyMSI
# 1HMjbyqqeu1n6W5BWbjgTBxoTSFLcWUojoKcDTQVIXyy8f8LrLvQaSEJQteQoDYBZsuTsX
# jBBta31B+XucUH4ccL44k0pWSG1q2+k0xu4PlXr6jQZkjK9wjt/DZajGxTv6EA/uSWCRWQ
# ZWe9cmpyrZGyHkYodkVbPoQZuo7mtsv/15OnWYoe1HRhgwttx1RCjqhaB1gx7R77WVa1UB
# Zjq44IAZ2q6Hu5s+X2l/TZT1UZqXBfGxvCD4GtoFo7c052vMHwp3uoAOjQD66wBqXgWRUS
# gC1diR1iXXmVhUIpzbd0roXod80vbnReiOyQHgtdC8fwj3VUjXubirOv/RmiFIIb3+cQAA
# AMB0DdGc+wSCrd19NdKAqCxUa3YYVUKKEAolFoKL/FjgaxEWdDr+iqYWwed9JST6eOCopz
# SYLxyY1JyT05dRmiVPRXc6D/txRglanIbFkMkkPmr7d9D0d1mNb5WGRJlPOGKl2VOq2bFN
# +tQzBRffp9JgofAe5YhWaPV2cPnbV867jHVDOEAF06xa2IROcNuc7u87cLQ5t5gGop7xRP
# 4RGf19NNaagPRDVrmdvZOHsN+zv/Om84D4dqE9cgarjZmjFnoAAADBAPQs3Qv7wBq+0YTX
# lH5Ro4VWt7q56UyBbMgMA8ptlqvxuobOwu7PtJnFNNFHYcyrImqwatSHHmc+WViz4FZO4h
# arLSkNyux9hBj2KkBLaaKTcW6lX7Kop2zkYzNwWqOtoiZbLhuerAgz4SwGSGpvdfUUQGbr
# 2qZkGnPlpoHcq2J64+WMOWVg7BVUhrE7Tghbbwkqm+EEKiQVK2VOdLtpgExOs9Ldgxxci6
# 1lMJAysHoeSTGa3zOy7CuPKyQopVXzmQAAAMEAwnW0mWv61pXMDC48mYGwihp+WWhxLqvj
# kZsla567G+8xc83jkUPwNXZQKXZNVk1GfI8upa79gMYIWI/oia1ZRyOWGqmjUT75RlyrID
# 2DXQQrhjpIAGFHXzPVk1rT5Vw8sLCCRFABlGnXOpi6kj5e7+aKbokySAfN99u0b4AU1t7s
# 0/RocPzlVj87SafmEadudFMgrIkHA3tieilAO74CV1rHNI6QGKAK9uQriSYxaiUCRufkge
# kvkX2L9PO+jXZzAAAAE2tsYXphcnpAa2xhemFyei1tYWMBAgMEBQYH
# -----END OPENSSH PRIVATE KEY-----
# EOF




sudo -u oracle wget https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip -O /home/oracle/sqlcl-latest.zip


cat << 'EOF' | sudo -u oracle tee  /home/oracle/Dockerfile > /dev/null
FROM container-registry.oracle.com/os/oraclelinux:8
RUN dnf -y install git wget nodejs python3.12 python3.12-requests python3.12-pip java-17-openjdk python3.12-setuptools python3.12-wheel libffi-devel openssl openssl-devel tk-devel xz-devel zlib-devel bzip2-devel readline-devel libuuid-devel ncurses-devel libaio sudo oracle-database-preinstall-23ai
EXPOSE 8888
EXPOSE 5000
USER oracle
WORKDIR /home/oracle
RUN mkdir -p /home/oracle/.opt/
#RUN echo password:password | chpasswd
RUN python3.12 -m venv /home/oracle/.opt/pyenv
RUN source /home/oracle/.opt/pyenv/bin/activate
ENV PATH="/home/oracle/.local/bin:/home/oracle/.opt/pyenv/bin:/home/oracle/.opt/sqlcl/bin:$PATH"
COPY sqlcl-latest.zip /home/oracle/.opt/.
RUN unzip /home/oracle/.opt/sqlcl-latest.zip
RUN rm /home/oracle/.opt/sqlcl-latest.zip
COPY requirements.txt .
RUN mkdir -p /home/oracle/.ssh/
COPY --chown=oracle:oinstall id_rsa /home/oracle/.ssh/.
RUN chmod 700 /home/oracle/.ssh/
RUN pip3.12 install -r requirements.txt
RUN rm requirements.txt
RUN wget https://c4u04.objectstorage.us-ashburn-1.oci.customer-oci.com/p/EcTjWk2IuZPZeNnD_fYMcgUhdNDIDA6rt9gaFj_WZMiL7VvxPBNMY60837hu5hga/n/c4u04/b/livelabsfiles/o/labfiles/assets.zip
RUN unzip assets.zip -d /home/oracle/.
RUN npm install pyright typescript-language-server unified-language-server vscode-css-languageserver-bin vscode-html-languageserver-bin vscode-json-languageserver-bin yaml-language-server sql-language-server
CMD jupyter-lab --allow-root --ip 0.0.0.0 --port 8888 --no-browser --NotebookApp.token='' --NotebookApp.password=''
EOF

export ORAPOD="cd /home/oracle/"

sudo -u oracle bash -c "$ORAPOD; podman build --tag container-registry.oracle.com/os/oraclelinux:jupol8 -f /home/oracle/Dockerfile"

sudo -u oracle bash -c "$ORAPOD; podman run -d --network oraclenet --name jupol8 -p 8888:8888 -p 5000:5000 --rm container-registry.oracle.com/os/oraclelinux:jupol8"

sudo -u oracle bash -c "$ORAPOD; podman generate systemd --new --name jupol8 -f"

sudo -u oracle mkdir -p /home/oracle/.config/systemd/user/


sudo -u oracle mv /home/oracle/container-jupol8.service /home/oracle/.config/systemd/user/.

cat << 'EOF' | sudo -u oracle tee /home/oracle/jupsystemd.sh > /dev/null
#!/bin/bash
export XDG_RUNTIME_DIR="/run/user/$UID"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
systemctl --user daemon-reload
systemctl --user enable container-jupol8
EOF

sudo -u oracle chmod +x /home/oracle/jupsystemd.sh

sudo -u oracle sh -c "/home/oracle/jupsystemd.sh"

sudo rm -rf /home/oracle/.config/systemd/user/container-*

sudo rm -rf /home/oracle/jupsystemd.sh

sudo -u oracle bash -c "$ORAPOD; podman stop jupol8"


####
#### Set up container
####

printStep
echo Headliner: 23ai free + ORDS + APEX


# not needed but I left it uncommented for now
# cat << 'EOF' | sudo -u oracle tee /home/oracle/.bash_profile > /dev/null
# # .bash_profile
# # Get the aliases and functions
# if [ -f ~/.bashrc ]; then
#   . ~/.bashrc
# fi
# export XDG_RUNTIME_DIR="/run/user/$UID"
# export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
# alias s="podman exec -it 23aifree /bin/bash"
# EOF

export ORAPOD="cd /home/oracle/"

#create a container network
#sudo -u oracle bash -c "$ORAPOD; podman network rm oraclenet"
#sudo -u oracle bash -c "$ORAPOD; podman network create oraclenet"

#run the 23ai free container
sudo -u oracle bash -c "$ORAPOD; podman run --name 23aifree -d -p 1521:1521 -e ORACLE_PWD=Welcome23ai -e ENABLE_ARCHIVELOG=true -e ENABLE_FORCE_LOGGING=true -v /home/oracle/oradata/:/opt/oracle/oradata:Z --network=oraclenet container-registry.oracle.com/database/free:latest"


#Sleep timer
SLEEP_SECONDS=$((6 * 60)) # X minutes in seconds
echo "Waiting for initial DB setup to complete..."
countdown $SLEEP_SECONDS

#Initial start of ORDS container. It will automatically install ORDS and APEX. During the installation conn_string.txt will 
# be moved from ords_secrets to ords_config folder
# The installation takes about 5 minutes on VM with 2 OCPU: 
# check progress in another session: podman exec -it ords tail -f /tmp/install_container.log

#Create a connect string for ORDS
cat << 'EOF' | sudo -u oracle tee /home/oracle/ords_secrets/conn_string.txt > /dev/null
CONN_STRING=SYS/Welcome23ai@23aifree:1521/freepdb1
EOF

sudo -u oracle bash -c "$ORAPOD; podman run --rm -d --network oraclenet --name ords -v /home/oracle/ords_secrets/:/opt/oracle/variables:Z -v /home/oracle/ords_config/:/etc/ords/config/:Z -p 8181:8181 -p 27017:27017 container-registry.oracle.com/database/ords:latest"

#Sleep timer
SLEEP_SECONDS=$((9 * 60)) # X minutes in seconds
echo "Waiting for initial ORDS and APEX setup to complete..."
countdown $SLEEP_SECONDS


sudo -u oracle bash -c "$ORAPOD; podman stop ords"

sleep 10

# Remove the this directory which includes the settings.xml
sudo rm -rf /home/oracle/ords_config/global

# Recreate the directory
sudo -u oracle mkdir -p /home/oracle/ords_config/global

# and make it writeable for everyone
sudo -u oracle chmod 777 /home/oracle/ords_config/global

# add an updated settings.xml to the directory. This enables mongo API
cat << 'EOF' | sudo -u oracle tee /home/oracle/ords_config/global/settings.xml > /dev/null
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE properties SYSTEM "http://java.sun.com/dtd/properties.dtd">
<properties>
<comment>Saved on Sun Jun 09 09:09:02 UTC 2024</comment>
<entry key="database.api.enabled">true</entry>
<entry key="db.invalidPoolTimeout">5s</entry>
<entry key="debug.printDebugToScreen">true</entry>
<entry key="mongo.enabled">true</entry>
</properties>
EOF


# Restart the ORDS container
sudo -u oracle bash -c "$ORAPOD; podman run -d --rm --network oraclenet --name ords  -v /home/oracle/ords_config/:/etc/ords/config/:Z -p 8181:8181 -p 27017:27017 container-registry.oracle.com/database/ords:latest"



####
#### load Oracle sample data
####

#The init.sql to enable all users for ORDS
cat << 'EOF' | sudo -u oracle tee /home/oracle/init.sql > /dev/null
BEGIN
 ords_admin.enable_schema(
  p_enabled => TRUE,
  p_schema => 'hr',
  p_url_mapping_type => 'BASE_PATH',
  p_url_mapping_pattern => 'hr',
  p_auto_rest_auth => NULL
 );
 commit;
END;
/

BEGIN
 ords_admin.enable_schema(
  p_enabled => TRUE,
  p_schema => 'sh',
  p_url_mapping_type => 'BASE_PATH',
  p_url_mapping_pattern => 'sh',
  p_auto_rest_auth => NULL
 );
 commit;
END;
/

BEGIN
 ords_admin.enable_schema(
  p_enabled => TRUE,
  p_schema => 'co',
  p_url_mapping_type => 'BASE_PATH',
  p_url_mapping_pattern => 'co',
  p_auto_rest_auth => NULL
 );
 commit;
END;
/

GRANT SODA_APP TO hr;

GRANT SODA_APP TO co;

GRANT SODA_APP TO sh;


CREATE USER admin IDENTIFIED BY Welcome23ai;

GRANT DBA TO admin;


BEGIN
 ords_admin.enable_schema(
  p_enabled => TRUE,
  p_schema => 'admin',
  p_url_mapping_type => 'BASE_PATH',
  p_url_mapping_pattern => 'admin',
  p_auto_rest_auth => NULL
 );
 commit;
END;
/

exit;
EOF

sudo -u oracle mkdir -p /home/oracle/tmp

sudo -u oracle wget https://github.com/oracle-samples/db-sample-schemas/archive/refs/tags/v23.3.zip -O /home/oracle/tmp/v23.3.zip

sudo unzip -o /home/oracle/tmp/v23.3.zip -d /home/oracle/tmp/

#Remove accept and add positional substitution variables
sudo sh -c "cd /home/oracle/tmp/db-sample-schemas-23.3/human_resources && sed -i '/ACCEPT/d' hr_install.sql && sed -i 's/pass/1/g' hr_install.sql && sed -i 's/tbs/2/g' hr_install.sql && sed -i 's/overwrite_schema/3/g' hr_install.sql"

sudo sh -c "cd /home/oracle/tmp/db-sample-schemas-23.3/sales_history && sed -i '/ACCEPT/d' sh_install.sql && sed -i 's/pass/1/g' sh_install.sql && sed -i 's/tbs/2/g' sh_install.sql && sed -i 's/overwrite_schema/3/g' sh_install.sql"

sudo sh -c "cd /home/oracle/tmp/db-sample-schemas-23.3/customer_orders && sed -i '/ACCEPT/d' co_install.sql && sed -i 's/pass/1/g' co_install.sql && sed -i 's/tbs/2/g' co_install.sql && sed -i 's/overwrite_schema/3/g' co_install.sql"

#Load data
sudo sh -c "cd /home/oracle/tmp/db-sample-schemas-23.3/human_resources/ && sql system/Welcome23ai@localhost:1521/freepdb1 @hr_install.sql Welcome23ai USERS YES"

sudo sh -c "cd /home/oracle/tmp/db-sample-schemas-23.3/sales_history/  && sql system/Welcome23ai@localhost:1521/freepdb1 @sh_install.sql Welcome23ai USERS YES"

sudo sh -c "cd /home/oracle/tmp/db-sample-schemas-23.3/customer_orders/  && sql system/Welcome23ai@localhost:1521/freepdb1 @co_install.sql Welcome23ai USERS YES"


#Enable ORDS
sudo -u oracle sh -c "sql system/Welcome23ai@localhost:1521/freepdb1 @/home/oracle/init.sql"

sudo rm -rf /home/oracle/tmp




#below part is deprecated but still works...need to look into this: https://mo8it.com/blog/quadlet/
# Quadlets do not work in OL8, needs to be tested in OL9
sudo -u oracle mkdir -p /home/oracle/.config/systemd/user/

sudo -u oracle bash -c "$ORAPOD; podman generate systemd --new --name 23aifree -f"

sudo -u oracle mv /home/oracle/container-23aifree.service /home/oracle/.config/systemd/user/.

sudo -u oracle bash -c "$ORAPOD; podman generate systemd --new --name ords -f"

sudo -u oracle mv /home/oracle/container-ords.service /home/oracle/.config/systemd/user/.

# sudo -u oracle bash -c "export XDG_RUNTIME_DIR="/run/user/$UID; DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus; systemctl --user daemon-reload"

# sudo -u oracle bash -c "export XDG_RUNTIME_DIR="/run/user/$UID; DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus; systemctl --user enable container-23aifree"


cat << 'EOF' | sudo -u oracle tee /home/oracle/system23ai.sh > /dev/null
#!/bin/bash
export XDG_RUNTIME_DIR="/run/user/$UID"
export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
systemctl --user daemon-reload
systemctl --user enable container-23aifree
systemctl --user enable container-ords.service
EOF

sudo -u oracle chmod +x /home/oracle/system23ai.sh

sudo -u oracle sh -c "/home/oracle/system23ai.sh"

sudo rm -rf /home/oracle/.config/systemd/user/container-*

sudo rm -rf /home/oracle/system23ai.sh

sudo -u oracle bash -c "$ORAPOD; podman stop ords"

sudo -u oracle bash -c "$ORAPOD; podman stop 23aifree"

sudo -u oracle bash -c "$ORAPOD; podman rm 23aifree"

echo ""

IP_ADDRESS=$(hostname -I | awk '{print $1}')




echo "SCRIPT EXECUTED SUCCESSFULLY"

sudo rm -rf /home/oracle/23dock.tar
sudo rm -rf /home/oracle/bash_profile
sudo rm -rf /home/oracle/Dockerfile
sudo rm -rf /home/oracle/requirements.txt
sudo rm -rf /home/oracle/sqlcl-latest.zip
sudo rm -rf /home/oracle/stage
sudo rm -rf /home/oracle/ords_secrets
sudo rm -rf /home/oracle/app.py
sudo rm -rf /home/oracle/dba.sh
sudo rm -rf /home/oracle/id_rsa
sudo rm -rf /home/oracle/init.sql


echo DONE! Reboot the server.
echo --------------------------
echo Jupter Lab: ip:8888
echo DB Actions and APEX: ip:8181
echo --------------------------
echo For APEX use the following login infos
echo - Workspace: internal
echo - User:      ADMIN
echo - Password:  Welcome_1
echo --------------------------
echo ORDS enabled users are: HR, CO, SH, and Admin. Password for all users is: Welcome23ai
echo --------------------------

#Sleep timer
SLEEP_SECONDS=$((30)) #  seconds
echo "The server will reboot in..."
countdown $SLEEP_SECONDS
sudo reboot now

exit 0

########################################################
#### THE END
########################################################
