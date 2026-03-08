#!/bin/bash
# Auto-install TeamSpeak 3 via Docker in one command

set -e

echo "=== TeamSpeak 3 Auto Installer ==="

# Проверка запуска от root (sudo)
if [ "$EUID" -ne 0 ]; then
  echo "Пожалуйста, запустите с sudo или как root."
  exit 1
fi

# 1. Установка Docker, если нет
if ! command -v docker &> /dev/null; then
    echo "Docker не найден. Устанавливаем..."
    apt update
    apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
        | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io
    systemctl enable docker
    systemctl start docker
else
    echo "Docker уже установлен."
fi

# 2. Создаем папку данных в домашней директории
TS_VOLUME="$HOME/teamspeak_data"
mkdir -p $TS_VOLUME
echo "Данные TeamSpeak будут храниться в: $TS_VOLUME"

# 3. Проверка контейнера
CONTAINER_NAME="teamspeak"
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "Существующий контейнер найден, удаляем..."
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
fi

# 4. Запуск TeamSpeak через Docker
docker run -d \
  --name=$CONTAINER_NAME \
  -p 9987:9987/udp \
  -p 10011:10011 \
  -p 30033:30033 \
  -v $TS_VOLUME:/var/ts3server \
  --restart unless-stopped \
  teamspeak

echo "=== TeamSpeak 3 установлен и запущен! ==="
echo "Проверить контейнер: docker ps"
echo "Порты для подключения:"
echo "  Клиенты: 9987 UDP"
echo "  Query (админ): 10011 TCP"
echo "  Файлы: 30033 TCP"
