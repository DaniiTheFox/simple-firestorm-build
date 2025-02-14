#!/bin/bash

set -e

REPO_URL="https://github.com/FirestormViewer/phoenix-firestorm"
BUILD_DIR="$HOME/build-firestorm"
INSTALL_DIR="/opt/firestorm-viewer"

# Dependencias
DEPENDENCIES=(
  "apr"
  "apr-util"
  "dbus-glib"
  "gconf"
  "glu"
  "gtk2"
  "libgl"
  "libidn"
  "libjpeg-turbo"
  "libpng"
  "libxml2"
  "libxss"
  "mesa"
  "nss"
  "openal"
  "sdl"
  "vlc"
  "zlib"
  "cmake"
  "gcc"
  "make"
  "python-pip"
  "git"
  "boost"
  "xz"
)

# Instalar dependencias (para Arch Linux)
sudo pacman -Sy --needed "${DEPENDENCIES[@]}"

# Clonar el repositorio si no existe
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
if [ ! -d "firestorm/.git" ]; then
  git clone "$REPO_URL" firestorm
else
  echo "Repositorio ya clonado, omitiendo..."
fi
cd firestorm

git pull --rebase || echo "No se pudo actualizar el repositorio, revisa manualmente."

# Crear entorno virtual y configurar
python3 -m venv .venv
source .venv/bin/activate
pip install --break-system-packages --upgrade pip
pip install --break-system-packages autobuild llbase

export CXXFLAGS="$CXXFLAGS -Wno-error"
export CFLAGS="$CFLAGS -Wno-error"

export LL_BUILD="$PWD"

# Descargar build-variables si no existe
# Descargar build-variables si no existe
VARIABLES_DIR="$BUILD_DIR/firestorm/fs-build-variables"
if [ ! -d "$VARIABLES_DIR" ]; then
  git clone https://github.com/FirestormViewer/fs-build-variables.git "$VARIABLES_DIR"
else
  echo "build-variables ya clonado, actualizando..."
  cd "$VARIABLES_DIR" && git pull --rebase || echo "No se pudo actualizar build-variables."
fi

#cd "$VARIABLES_DIR" && git pull --rebase || echo "No se pudo actualizar build-variables."

export AUTOBUILD_VARIABLES_FILE="$VARIABLES_DIR/variables"

#export AUTOBUILD_VARIABLES_FILE="$(realpath "$VARIABLES_DIR/variables")"

#autobuild configure -A 64 -c Release -- -DLL_TESTS:BOOL=FALSE -DOPENAL=on
#autobuild configure -A 64 -c Release -- -DLL_TESTS:BOOL=FALSE -DOPENAL=on -DFMOD=OFF
autobuild configure -A 64 -c ReleaseFS_open -- -DLL_TESTS:BOOL=FALSE -DOPENAL=on -DFMODEX=FALSE -DFMOD=OFF

# Compilar
#mkdir -p build-linux-x86_64
cd ..
cd build-linux-x86_64
pwd
make -j4

# Instalar
sudo mkdir -p "$INSTALL_DIR"
sudo cp -r newview/packaged/* "$INSTALL_DIR"

# Crear acceso directo
sudo tee /usr/share/applications/firestorm-viewer.desktop > /dev/null <<EOL
[Desktop Entry]
Name=Firestorm Viewer
Exec=$INSTALL_DIR/firestorm
Icon=$INSTALL_DIR/icons/firestorm.png
Type=Application
Categories=Game;
EOL

sudo ln -sf "$INSTALL_DIR/firestorm" /usr/bin/firestorm-viewer

echo "InstalaciÃ³n completa. Ejecuta 'firestorm-viewer' para iniciar."
