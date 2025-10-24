#!/bin/bash
set -e

echo "Iniciando instalação do Flutter + Android Studio..."

sudo apt update && sudo apt upgrade -y

sudo snap install flutter --classic

echo "Instalando dependências básicas..."
sudo apt install -y curl git xz-utils zip unzip openjdk-17-jdk

echo "Baixando Flutter SDK..."
cd /tmp
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz

echo "Extraindo Flutter para /opt/flutter..."
sudo tar -xf flutter_linux_3.24.5-stable.tar.xz -C /opt

if ! grep -q "/opt/flutter/bin" ~/.bashrc; then
  echo "export PATH=\"\$PATH:/opt/flutter/bin\"" >> ~/.bashrc
fi
source ~/.bashrc

echo "Verificando instalação do Flutter..."
flutter doctor

echo "⬇Baixando Android Studio..."
cd /tmp
wget https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2024.1.1.12/android-studio-2024.1.1.12-linux.tar.gz

echo "Instalando Android Studio..."
sudo tar -xzf android-studio-*-linux.tar.gz -C /opt/

# --- Criando atalho ---
sudo ln -sf /opt/android-studio/bin/studio.sh /usr/local/bin/android-studio

# --- Limpando temporários ---
rm -rf /tmp/flutter_linux_3.24.5-stable.tar.xz /tmp/android-studio-*-linux.tar.gz

echo "Instalação concluída!"

echo
echo "Para abrir o Android Studio, use o comando:"
echo "    android-studio &"
echo
echo "Depois de abrir, vá em:"
echo "    More Actions → SDK Manager → Instale o SDK e o AVD (emulador)."
echo
echo "Depois rode:"
echo "nano ~/.bashrc"
echo 
echo "Adicione dentro da pasta:"
echo " Troque USER por seu user:"
echo
echo "    export ANDROID_HOME=/home/USER/Android/Sdk"
echo "    export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
echo "    export PATH=$PATH:$ANDROID_HOME/platform-tools"
echo "    export PATH=$PATH:$ANDROID_HOME/emulator"
echo
echo "    source ~/.bashrc"
echo 
echo "    ls /home/USER/Android/Sdk/cmdline-tools""
echo
echo "    mkdir -p /home/USER/Android/Sdk/cmdline-tools"
echo "    cd /home/USER/Android/Sdk/cmdline-tools"
echo "    wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
echo "    unzip commandlinetools-linux-11076708_latest.zip"
echo "    mv cmdline-tools latest"
echo "    rm commandlinetools-linux-11076708_latest.zip"
echo
echo "    flutter doctor --android-licenses"
echo
echo "Aceite todos as licensas"
echo
echo "Rode o comando abaixo para ver se está ok:"
echo "    flutter doctor"
echo
echo "Se tudo estiver OK, você está pronto para desenvolver com Flutter!"
