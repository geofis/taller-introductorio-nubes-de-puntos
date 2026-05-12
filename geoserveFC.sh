#!/bin/bash
set -e

# =========================
# CONFIG
# =========================

HOSTNAME="fotogrametria-01"
USER="geouser"
PASS="GeoPass123"

SSH_PORT=10000

log(){ echo "[+] $1"; }

# =========================
# FASE 1: SISTEMA BASE
# =========================
apt update && apt upgrade -y
apt autoremove -y
hostnamectl set-hostname $HOSTNAME


apt install -y sshpass

# sshpass -p 'PASSWORD' scp \
# -o StrictHostKeyChecking=no \
# -o UserKnownHostsFile=/dev/null \
# icm-f@10.0.0.222:E:\Compartido3\GEOVM\metashape_2_3_1_amd64.tar.gz .
# tar -xvzf metashape_2_3_1_amd64.tar.gz

# cd metashape

# chmod +x metashape.sh


# =========================
# FASE 2: USUARIO + SSH + SEGURIDAD
# =========================

id "$USER" &>/dev/null || adduser --disabled-password --gecos "" $USER
echo "$USER:$PASS" | chpasswd
usermod -aG sudo $USER

apt install -y openssh-server ufw fail2ban unattended-upgrades

log "Configurando SSH en puerto $SSH_PORT"

# Cambiar puerto SSH
sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
sed -i "s/Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config

# Hardening SSH
sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

systemctl restart ssh

# FIREWALL
ufw default deny incoming
ufw default allow outgoing

ufw allow $SSH_PORT/tcp
ufw allow 3389/tcp
ufw allow 8000/tcp

ufw --force enable

systemctl enable fail2ban

# =========================
# FASE 3: GUI
# =========================

apt install -y xfce4 xfce4-goodies xrdp lightdm firefox

echo "xfce4-session" > /home/$USER/.xsession
chown $USER:$USER /home/$USER/.xsession

systemctl enable xrdp
adduser xrdp ssl-cert

# =========================
# FASE 4: TOOLS + GIS
# =========================

apt install -y \
 build-essential ninja-build git cmake pkg-config \
 python3-pip python3-venv python3-dev \
 gdal-bin libgdal-dev proj-bin libproj-dev \
 libsqlite3-dev sqlite3 \
 ffmpeg htop btop curl wget unzip \
 libboost-all-dev libeigen3-dev

# QGIS
apt install -y gnupg software-properties-common
wget -qO /etc/apt/keyrings/qgis.gpg https://download.qgis.org/downloads/qgis-archive-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/qgis.gpg] https://qgis.org/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/qgis.list
apt update
apt install -y qgis qgis-plugin-grass

# Python GIS
pip3 install numpy scipy pandas matplotlib geopandas rasterio shapely pyproj open3d laspy jupyter

# =========================
# FASE 5: DOCKER + ODM
# =========================

apt install -y docker.io docker-compose
usermod -aG docker $USER

docker pull opendronemap/odm

git clone https://github.com/OpenDroneMap/WebODM
cd WebODM
./webodm.sh start --detached
cd ..

# =========================
# FASE 6: CMAKE MODERNO
# =========================

apt remove -y cmake || true

CMAKE_VERSION=3.28.3
wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh
chmod +x cmake-${CMAKE_VERSION}-linux-x86_64.sh
./cmake-${CMAKE_VERSION}-linux-x86_64.sh --skip-license --prefix=/usr/local

# =========================
# FASE 7: DEPENDENCIAS COLMAP
# =========================

apt install -y \
 libgoogle-glog-dev libgflags-dev libceres-dev \
 libjpeg-dev libpng-dev libtiff-dev \
 libopenexr-dev openexr \
 libopencv-dev \
 libopenimageio-dev openimageio-tools \
 libmetis-dev \
 libfreeimage-dev libflann-dev \
 libglew-dev libgl1-mesa-dev \
 qtbase5-dev qttools5-dev libqt5svg5-dev \
 libcgal-dev

# =========================
# FASE 8: COLMAP
# =========================

git clone https://github.com/colmap/colmap.git
cd colmap
mkdir build && cd build

cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release
ninja
ninja install
cd ../..

# =========================
# FASE 9: MICMAC
# =========================

apt install -y imagemagick libimage-exiftool-perl

git clone https://github.com/micmacIGN/micmac.git
cd micmac
mkdir build && cd build
cmake .. -DWITH_QT5=ON
make -j$(nproc)
make install
cd ../..

# =========================
# FASE 10: CLOUDCOMPARE
# =========================

snap install cloudcompare

# =========================
# FASE 11: DATA STRUCTURE
# =========================

mkdir -p /data/{proyectos,insumos,resultados,backups}
chown -R $USER:$USER /data

# =========================
# FINAL
# =========================

echo "==========================="
echo "✔ SISTEMA LISTO"
echo "SSH PORT: $SSH_PORT"
echo "USER: $USER"
echo "PASS: $PASS"
echo "==========================="
