#!/bin/sh

REPO="https://api.github.com/repos/mizoil/mbzeguard/releases/latest"
DOWNLOAD_DIR="/tmp/mbzeguard"
COUNT=3

rm -rf "$DOWNLOAD_DIR"
mkdir -p "$DOWNLOAD_DIR"

msg() {
    printf "\033[32;1m%s\033[0m\n" "$1"
}

main() {
    check_system
    sing_box

    /usr/sbin/ntpd -q -p 194.190.168.1 -p 216.239.35.0 -p 216.239.35.4 -p 162.159.200.1 -p 162.159.200.123

    opkg update || { echo "opkg update failed"; exit 1; }

    if [ -f "/etc/init.d/mbzeguard" ]; then
        msg "MBzeGuard уже установлен. Обновление..."
    else
        msg "Установка MBzeGuard..."
    fi

    if command -v curl &> /dev/null; then
        check_response=$(curl -s "$REPO")

        if echo "$check_response" | grep -q 'API rate limit '; then
            msg "GitHub API лимит превышен. Подождите 5 минут."
            exit 1
        fi
    fi

    download_success=0
    while read -r url; do
        filename=$(basename "$url")
        filepath="$DOWNLOAD_DIR/$filename"

        attempt=0
        while [ $attempt -lt $COUNT ]; do
            msg "Скачивание $filename (попытка $((attempt+1)))..."
            if wget -q -O "$filepath" "$url"; then
                if [ -s "$filepath" ]; then
                    msg "$filename скачан успешно"
                    download_success=1
                    break
                fi
            fi
            msg "Ошибка при скачивании $filename. Повтор..."
            rm -f "$filepath"
            attempt=$((attempt+1))
        done

        if [ $attempt -eq $COUNT ]; then
            msg "Не удалось скачать $filename после $COUNT попыток"
        fi
    done < <(wget -qO- "$REPO" | grep -o 'https://[^"[:space:]]*\.ipk')

    if [ $download_success -eq 0 ]; then
        msg "Ни один .ipk файл не был успешно скачан"
        exit 1
    fi

    for pkg in mbzeguard luci-app-mbzeguard; do
        file=$(ls "$DOWNLOAD_DIR" | grep "^$pkg" | head -n 1)
        if [ -n "$file" ]; then
            msg "Установка $file"
            opkg install "$DOWNLOAD_DIR/$file"
            sleep 3
        fi
    done

    ru=$(ls "$DOWNLOAD_DIR" | grep "luci-i18n-mbzeguard-ru" | head -n 1)
    if [ -n "$ru" ]; then
        if opkg list-installed | grep -q luci-i18n-mbzeguard-ru; then
            msg "Обновление русской локализации..."
            opkg remove luci-i18n-mbzeguard*
            opkg install "$DOWNLOAD_DIR/$ru"
        else
            msg "Установить русский язык интерфейса? y/n"
            while true; do
                read -r -p '' RUS
                case $RUS in
                    y)
                        opkg remove luci-i18n-mbzeguard*
                        opkg install "$DOWNLOAD_DIR/$ru"
                        break
                        ;;
                    n)
                        break
                        ;;
                    *)
                        echo "Введите y или n"
                        ;;
                esac
            done
        fi
    fi

    find "$DOWNLOAD_DIR" -type f -name '*mbzeguard*' -exec rm {} \;
}

check_system() {
    MODEL=$(cat /tmp/sysinfo/model)
    msg "Модель роутера: $MODEL"

    openwrt_version=$(grep DISTRIB_RELEASE /etc/openwrt_release | cut -d"'" -f2 | cut -d'.' -f1)
    if [ "$openwrt_version" = "23" ]; then
        msg "OpenWrt 23.05 не поддерживается начиная с MBzeGuard 0.5.0"
        msg "Используйте версию 0.4.11 или установите вручную"
        msg "Подробнее: https://mbzeguard.net/docs/install/#установка-на-2305"
        exit 1
    fi

    AVAILABLE_SPACE=$(df /overlay | awk 'NR==2 {print $4}')
    REQUIRED_SPACE=15360

    if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
        msg "Ошибка: недостаточно места во флеш-памяти"
        msg "Доступно: $((AVAILABLE_SPACE/1024))MB"
        msg "Требуется: $((REQUIRED_SPACE/1024))MB"
        exit 1
    fi

    if ! nslookup google.com >/dev/null 2>&1; then
        msg "DNS не работает. Проверьте вручную."
        exit 1
    fi

    if opkg list-installed | grep -q https-dns-proxy; then
        msg "Обнаружен конфликтующий пакет: https-dns-proxy. Удалить?"

        while true; do
            read -r -p '' DNSPROXY
            case $DNSPROXY in
                yes|y|Y|yes)
                    opkg remove --force-depends luci-app-https-dns-proxy https-dns-proxy luci-i18n-https-dns-proxy*
                    break
                    ;;
                *)
                    msg "Отмена установки"
                    exit 1
                    ;;
            esac
        done
    fi
}

sing_box() {
    if ! opkg list-installed | grep -q "^sing-box"; then
        return
    fi

    sing_box_version=$(sing-box version | head -n 1 | awk '{print $3}')
    required_version="1.12.4"

    if [ "$(echo -e "$sing_box_version\n$required_version" | sort -V | head -n 1)" != "$required_version" ]; then
        msg "Версия sing-box $sing_box_version устарела (нужна $required_version)"
        msg "Удаление старой версии..."
        opkg remove sing-box
    fi
}

main
