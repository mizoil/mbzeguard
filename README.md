⚠️ Это альфа-версия MBzeGuard. Возможны баги. Обсуждение в Telegram
🚀 Установка MBzeGuard

MBzeGuard — это система маршрутизации доменов с поддержкой туннелей и кастомных списков.

Поддержка: OpenWrt 23.05 и новее
Архитектура: все
Требуется: dnsmasq-full, curl, jq, nftables, coreutils-base64
📦 Установка из релиза

Обнови списки:

```
opkg update
```

Установи ipk-пакеты (в нужном порядке):

```
opkg install mbzeguard_*.ipk
opkg install luci-app-mbzeguard_*.ipk
opkg install luci-i18n-mbzeguard-ru_*.ipk  # при необходимости
```

⚙️ Автоматическая установка

```
sh <(wget -O - https://raw.githubusercontent.com/mizoil/mbzeguard/refs/heads/main/install.sh)
```

Скрипт сам установит необходимые зависимости

Предложит выбрать туннель: WG / AmneziaWG / Proxy

Всё автоматически настроит

🔄 Обновление

Повтори команду установки:

```
sh <(wget -O - https://raw.githubusercontent.com/mizoil/mbzeguard/refs/heads/main/install.sh)
```

❌ Удаление

```
opkg remove luci-app-mbzeguard mbzeguard
opkg remove luci-i18n-mbzeguard-ru  # если был установлен
```

📁 Конфигурация

    Файл: /etc/config/mbzeguard

    Веб-интерфейс: VPN → MBzeGuard
