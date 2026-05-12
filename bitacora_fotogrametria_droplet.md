# Bitácora: Configuración de Estación de Fotogrametría
## Digital Ocean Droplet — Ubuntu 22.04 LTS

> **Propósito:** Servidor con escritorio remoto (GUI) para procesamiento fotogramétrico.
> **Registrar fecha, usuario y resultado en cada paso completado.**

################ ALTAMENTE RECOMENDADO: CREAR SCRIPT DE CONFIGURACIÓN EN BASH CON TODOS ESTOS COMANDOS #####################

---

## FASE 0 — Información del Servidor

| Campo | Valor |
|-------|-------|
| Proveedor | Digital Ocean |
| SO | Ubuntu 22.04 LTS |
| Droplet ID | _(registrar)_ |
| IP Pública | _(registrar)_ |
| Región | _(registrar)_ |
| Tamaño (vCPU / RAM / Disco) | _(registrar)_ |
| Fecha de creación | _(registrar)_ |
| Responsable | _(registrar)_ |

---

## FASE 1 — Acceso Inicial y Actualización del Sistema

### 1.1 Primer acceso como root

```bash
ssh root@137.184.121.221
```

### 1.2 Actualizar todos los paquetes

```bash
# Actualizar el software instalado
apt update && apt upgrade -y
# Aceptar por defecto, reiniciar (reboot)
# apt dist-upgrade -y
apt autoremove -y
```

- [ ] Completado — Fecha: __________ — Resultado: __________

### 1.3 Establecer nombre de host

```bash
hostnamectl set-hostname fotogrametria-01
# Editar /etc/hosts para reflejar el nuevo hostname
nano /etc/hosts
# Agregar: 127.0.1.1  fotogrametria-01
```

- [ ] Completado — Fecha: __________ — Resultado: __________

---

## FASE 2 — Seguridad del Servidor

### 2.1 Crear usuario administrador no-root

```bash
adduser geouser
usermod -aG sudo geouser
```

- [ ] Completado — Fecha: __________ — Usuario creado: __________

### 2.2 Copiar llaves SSH al nuevo usuario

```bash
# CREAR CLAVE DE USUARIO EN MÁQUINA LOCAL Y PASARLA A MÁQUINA REMOTA
rsync --archive --chown=geouser:geouser ~/.ssh /home/geouser
```

### 2.3 Probar acceso con el nuevo usuario (en terminal separada)

```bash
ssh geouser@137.184.121.221
sudo whoami   # Debe responder: root
```

- [ ] Acceso confirmado — Fecha: __________

### 2.4 Deshabilitar login de root por SSH

```bash
nano /etc/ssh/sshd_config
# Modificar o agregar:
#   PermitRootLogin no
#   PasswordAuthentication no
#   PubkeyAuthentication yes

systemctl restart sshd
```

- [ ] Completado — Fecha: __________

### 2.5 Configurar firewall (UFW)

```bash
ufw default deny incoming
ufw default allow outgoing

# SSH
ufw allow OpenSSH

# RDP / escritorio remoto (elegir uno según protocolo usado)
ufw allow 3389/tcp    # RDP (xrdp)
# ufw allow 5900/tcp  # VNC (alternativa)

# Puertos adicionales según necesidad
# ufw allow 8080/tcp  # WebODM u otros servicios web

ufw enable
ufw status verbose
```

- [ ] Completado — Fecha: __________ — Reglas activas: __________

### 2.6 Instalar Fail2Ban

```bash
apt install fail2ban -y
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
nano /etc/fail2ban/jail.local
# Verificar que [sshd] esté enabled = true

systemctl enable fail2ban
systemctl start fail2ban
systemctl status fail2ban
```

- [ ] Completado — Fecha: __________

### 2.7 Actualizaciones automáticas de seguridad

```bash
apt install unattended-upgrades -y
dpkg-reconfigure --priority=low unattended-upgrades
# Seleccionar "Yes"
```

- [ ] Completado — Fecha: __________

---

## FASE 3 — Entorno de Escritorio (GUI)

> Para esta estación se recomienda **XFCE4** (ligero, estable) con acceso via **xRDP**.
> Alternativa: MATE o LXQt para equipos con más RAM.

### 3.1 Instalar escritorio XFCE4

```bash
# Como geouser con sudo:
sudo apt install xfce4 xfce4-goodies -y
```

- [ ] Completado — Fecha: __________ — Tiempo aprox.: __________

### 3.2 Instalar xRDP (escritorio remoto)

```bash
sudo apt install xrdp -y
sudo systemctl enable xrdp
sudo systemctl start xrdp

# Configurar XFCE como sesión por defecto para xRDP
echo "xfce4-session" | sudo tee /etc/skel/.xsession
echo "xfce4-session" > ~/.xsession
sudo sed -i 's/^test -x/#test -x/' /etc/xrdp/startwm.sh

sudo systemctl restart xrdp
sudo systemctl status xrdp
```

- [ ] Completado — Fecha: __________

### 3.3 Agregar xrdp al grupo ssl-cert

```bash
sudo adduser xrdp ssl-cert
sudo systemctl restart xrdp
```

### 3.4 Probar conexión RDP desde cliente local

Usar **Remmina** (Linux), **Microsoft Remote Desktop** (Windows/Mac) o equivalente:

- Host: `137.184.121.221:3389`
- Usuario: `geouser`
- Contraseña: _(la definida en Fase 2.1)_

- Instalar Google Chrome

```
# 1. Descargar el paquete .deb oficial de Google
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb

# 2. Instalar
sudo apt install ./google-chrome-stable_current_amd64.deb -y

# 3. Verificar
google-chrome --version

# 4. Limpiar el instalador
rm google-chrome-stable_current_amd64.deb
```

- [ ] Conexión exitosa — Fecha: __________ — Cliente usado: __________

### Metashape

```
sudo apt install -y \
    libxcb-xinerama0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-randr0 \
    libxcb-render-util0 \
    libxcb-xkb1 \
    libxkbcommon-x11-0 \
    libxcb-cursor0 \
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    libglu1-mesa \
    libxi6 \
    libxrender1

echo $DISPLAY
# Debe mostrar algo como :10.0 o :0
# Si está vacía, definirla:
export DISPLAY=:10.0

```

### 3.5 (Opcional) Instalar gestor de pantalla ligero

```bash
sudo apt install lightdm -y
sudo dpkg-reconfigure lightdm
```

- [ ] Completado — Fecha: __________

---

## FASE 4 — Herramientas Base del Sistema

### 4.1 Paquetes esenciales

```bash
sudo apt install -y \
    git curl wget unzip p7zip-full \
    htop btop neofetch \
    build-essential cmake \
    python3-pip python3-venv python3-dev \
    gdal-bin libgdal-dev \
    proj-bin libproj-dev \
    libsqlite3-dev sqlite3 \
    ffmpeg \
    libreoffice \
    gedit nautilus
```

- [ ] Completado — Fecha: __________

### 4.2 QGIS

```bash
sudo apt install -y gnupg software-properties-common

# Agregar repositorio oficial QGIS
sudo wget -qO /etc/apt/keyrings/qgis-archive-keyring.gpg \
  https://download.qgis.org/downloads/qgis-archive-keyring.gpg

sudo nano /etc/apt/sources.list.d/qgis.sources
# Pegar el bloque correspondiente a Ubuntu 22.04 Jammy desde:
# https://qgis.org/en/site/forusers/alldownloads.html#debian-ubuntu

sudo apt update
sudo apt install qgis qgis-plugin-grass -y
```

- [ ] Completado — Fecha: __________ — Versión: __________

### 4.3 Python GIS / análisis

```bash
pip3 install --upgrade pip
pip3 install \
    numpy scipy pandas matplotlib \
    geopandas rasterio fiona shapely \
    pyproj open3d laspy[lazrs] \
    jupyter notebook
```

- [ ] Completado — Fecha: __________

---

## FASE 5 — Software de Fotogrametría

### 5.1 OpenDroneMap (ODM) — CLI

```bash
# Dependencias
sudo apt install -y docker.io docker-compose
sudo usermod -aG docker geouser
# (Cerrar sesión y volver a entrar para que el grupo tome efecto)

# Obtener imagen ODM
docker pull opendronemap/odm:latest

# Prueba básica
docker run -ti --rm opendronemap/odm --help
```

- [ ] Completado — Fecha: __________ — Versión ODM: __________

### 5.2 WebODM (interfaz web para ODM)

```bash
git clone https://github.com/OpenDroneMap/WebODM --config core.autocrlf=input --depth=1
cd WebODM
sudo ./webodm.sh start --detached

# Acceder en: http://<IP_PUBLICA>:8000
# (Asegurarse de abrir puerto 8000 en UFW si se requiere acceso externo)
```

- [ ] Completado — Fecha: __________ — URL: __________

### 5.3 MicMac (Photogrammetry Suite)

```bash
sudo apt install -y libimage-exiftool-perl imagemagick

# Clonar y compilar
git clone https://github.com/micmacIGN/micmac.git
cd micmac
mkdir build && cd build
cmake .. -DWITH_QT5=ON
make install -j$(nproc)

# Agregar al PATH
echo 'export PATH=$PATH:/ruta/a/micmac/bin' >> ~/.bashrc
source ~/.bashrc

# Verificar
mm3d --help
```

- [ ] Completado — Fecha: __________ — Versión: __________

### 5.4 COLMAP

```bash
sudo apt install -y \
    libboost-all-dev libeigen3-dev libfreeimage-dev \
    libflann-dev libgoogle-glog-dev libgflags-dev \
    libsqlite3-dev libglew-dev qtbase5-dev \
    libcgal-dev libceres-dev

git clone https://github.com/colmap/colmap.git
cd colmap
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
sudo make install

colmap --help
```

- [ ] Completado — Fecha: __________ — Versión: __________

### 5.5 CloudCompare (nube de puntos)

```bash
sudo snap install cloudcompare
# O desde PPA:
# sudo add-apt-repository ppa:cloudcompare/cloudcompare -y
# sudo apt update && sudo apt install cloudcompare -y
```

- [ ] Completado — Fecha: __________ — Versión: __________

### 5.6 Meshroom / AliceVision (opcional, requiere GPU NVIDIA)

```bash
# Solo si el droplet tiene GPU
# Descargar binario desde: https://github.com/alicevision/Meshroom/releases
wget https://github.com/alicevision/Meshroom/releases/download/vX.X.X/Meshroom-X.X.X-linux.tar.gz
tar -xzf Meshroom-*.tar.gz
cd Meshroom-*/
./Meshroom  # lanzar desde escritorio
```

> ⚠️ Meshroom requiere **CUDA** y GPU NVIDIA dedicada. Verificar si el droplet tiene GPU antes de instalar.

- [ ] Completado / Omitido — Motivo: __________

---

## FASE 6 — Almacenamiento y Datos

### 6.1 Estructura de directorios de proyectos

```bash
sudo mkdir -p /data/{proyectos,insumos,resultados,backups}
sudo chown -R geouser:geouser /data
chmod -R 755 /data

# Estructura sugerida por proyecto:
# /data/proyectos/
# └── YYYY-MM-nombre_proyecto/
#     ├── 01_imagenes/
#     ├── 02_procesamiento/
#     ├── 03_resultados/
#     │   ├── nube_puntos/
#     │   ├── mde/
#     │   └── orto/
#     └── 04_metadatos/
```

- [ ] Completado — Fecha: __________

### 6.2 Montaje de volumen adicional (si aplica)

```bash
# Identificar disco
lsblk
# Formatear (solo primera vez)
sudo mkfs.ext4 /dev/sda   # ajustar dispositivo
# Montar
sudo mount /dev/sda /data
# Hacer permanente en /etc/fstab
echo '/dev/sda /data ext4 defaults 0 2' | sudo tee -a /etc/fstab
```

- [ ] Completado / N/A — Fecha: __________

### 6.3 Integración con Spaces / S3 (respaldo en nube)

```bash
sudo apt install s3cmd -y
s3cmd --configure
# Ingresar Access Key y Secret Key de Digital Ocean Spaces
# Endpoint: nyc3.digitaloceanspaces.com (o la región correspondiente)

# Ejemplo de sincronización
s3cmd sync /data/resultados/ s3://nombre-bucket/resultados/
```

- [ ] Configurado — Fecha: __________ — Bucket: __________

---

## FASE 7 — Monitoreo y Mantenimiento

### 7.1 Instalar herramientas de monitoreo

```bash
sudo apt install -y htop btop iotop ncdu
# Monitor de GPU (si aplica)
# sudo apt install -y nvtop
```

### 7.2 Configurar logrotate para logs de proyectos

```bash
sudo nano /etc/logrotate.d/fotogrametria
# Contenido sugerido:
# /data/proyectos/**/logs/*.log {
#     weekly
#     rotate 4
#     compress
#     missingok
#     notifempty
# }
```

### 7.3 Script de respaldo periódico (cron)

```bash
crontab -e
# Agregar (respaldo semanal los domingos a las 2am):
# 0 2 * * 0 s3cmd sync /data/resultados/ s3://nombre-bucket/resultados/ >> /var/log/backup_geo.log 2>&1
```

- [ ] Configurado — Fecha: __________

### 7.4 Snapshot del Droplet

> Desde el panel de Digital Ocean → Droplet → Snapshots → "Take snapshot"
> Hacerlo **antes** de instalar software pesado y **después** de terminar la configuración base.

- [ ] Snapshot inicial tomado — Fecha: __________
- [ ] Snapshot post-configuración tomado — Fecha: __________

---

## FASE 8 — Verificación Final

| Componente | Estado | Versión | Notas |
|------------|--------|---------|-------|
| Ubuntu actualizado | ☐ | 22.04 | |
| Usuario geouser | ☐ | | |
| SSH root deshabilitado | ☐ | | |
| UFW activo | ☐ | | |
| Fail2Ban | ☐ | | |
| Escritorio XFCE4 | ☐ | | |
| xRDP funcional | ☐ | | |
| QGIS | ☐ | | |
| Docker / ODM | ☐ | | |
| WebODM | ☐ | | |
| COLMAP | ☐ | | |
| CloudCompare | ☐ | | |
| MicMac | ☐ | | |
| Estructura /data | ☐ | | |
| Respaldo S3 | ☐ | | |
| Snapshot Droplet | ☐ | | |

---

## Registro de Cambios

| Fecha | Fase | Acción realizada | Usuario | Resultado |
|-------|------|-----------------|---------|-----------|
| | | | | |
| | | | | |
| | | | | |

---

## Referencias

- [Digital Ocean — Initial Server Setup Ubuntu 22.04](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-22-04)
- [OpenDroneMap Docs](https://docs.opendronemap.org/)
- [WebODM GitHub](https://github.com/OpenDroneMap/WebODM)
- [COLMAP Docs](https://colmap.github.io/)
- [QGIS Download](https://qgis.org/en/site/forusers/alldownloads.html)
- [CloudCompare](https://www.danielgm.net/cc/)
- [MicMac GitHub](https://github.com/micmacIGN/micmac)

---

*Bitácora generada para uso interno. Actualizar con cada intervención al servidor.*
