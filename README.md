# 🇬🇧 README (English)

## Automatic sing-box Route Synchronization from MikroTik Address‑List

This script automatically retrieves IP addresses and subnets from the MikroTik Firewall Address‑List (`list=proxy`) and updates Linux routing rules, directing them through the `singbox0` interface. It enables sing-box to act as a centralized proxy gateway for Telegram, YouTube, Instagram, Facebook, CDN networks, and any other services added to the MikroTik list.

### What is sing-box?

**sing-box** is a modern, high‑performance, modular proxy framework supporting Shadowsocks, VLESS, Trojan, Hysteria, WireGuard, and more. Project: https://github.com/SagerNet/sing-box

This script is intended for setups where sing-box runs in **TUN mode** and specific subnets must be routed through the tunnel.

## Features

- Fetches address list from MikroTik via SSH
- Extracts only IPv4 and IPv4/subnet entries
- Filters out local networks
- Updates routes using `ip route replace`
- Detailed logging
- SSH error handling
- Cron‑based automation

## Installation

### Required packages

```
apt update
apt install sshpass -y
```

### Install the script

Save as:

```
/root/singbox-route-sync.sh

```

Make executable:

```
chmod +x /root/singbox-route-sync.sh

```

## MikroTik router configuration

Create a read‑only user:

```
/user add name=route-sync group=read password=YOUR_PASSWORD
/ip service enable ssh
```

Add addresses:

```
/ip firewall address-list add list=proxy address=149.154.160.0/20
...
```
Or use the RouterOS script below, just add/replace the required domains.
```lua
:local proxyListName "proxy"
:local proxyCommentText "Google"
:local domains {
    "google.com"
    "youtube.com"
    "mail.google.com"
}

:foreach domain in=$domains do={
    :local resolved [:resolve $domain]
    :if ([:len $resolved] > 0) do={
        # Check if IP address in list
        :local exists [/ip firewall address-list find list=$proxyListName address=$resolved]
        :if ([:len $exists] = 0) do={
            /ip firewall address-list add list=$proxyListName address=$resolved comment="$proxyCommentText"
            :log info "Added: $domain -> $resolved"
        } else={
            :log info "Skipped: $domain -> $resolved (already exists)"
        }
    } else={
        :log warning "Failed to resolve: $domain"
    }
}

:log info "Domains processing completed"
```
- `proxyListName` - address list name
- `proxyCommentText` - Comments

## Cron automation

```
crontab -e

```

Add:

```
*/30 * * * * /root/singbox-route-sync.sh >> /var/log/singbox-route-sync.log 2>&1

```

Every 30 minutes

## Logs

```
/var/log/singbox-route-sync.log

```

---
## Configuring MikroTik to forward traffic into sing-box

To make MikroTik router forward selected subnets to the Linux server running sing-box, two steps are required:

- create a **mangle rule** that marks traffic belonging to the `proxy` address‑list;
- create a static route that forwards marked traffic to the Linux server.

This ensures that only the intended subnets are routed through the tunnel.

## Mangle rule

Open:

```
/ip firewall mangle

```

Add:

```
/ip firewall mangle add chain=prerouting src-address=your_singbox_server_ip action=accept

```

```
add chain=prerouting src-address-list=proxy action=mark-routing new-routing-mark=singbox passthrough=no

```

**What this rule does**

- Checks whether the source IP belongs to the `proxy` address‑list.
- If yes, assigns a routing mark `singbox`.
- This mark is used by the static route below.

## Static route

Create a route that forwards marked traffic to the Linux server:

```
/ip route add dst-address=0.0.0.0/0 gateway=your_singbox_server_ip routing-mark=singbox

```

Where:

- `your_singbox_server_ip` is the IP of your Linux server running sing-box.
- `routing-mark=singbox` matches the mangle rule.

**What this route does**

- Any traffic marked as `singbox` is forwarded to the Linux server.
- The server then routes it through the `singbox0` interface into the tunnel.
- Return traffic flows normally, ensuring proper bidirectional connectivity.
---

## Enabling IP forwarding

Linux server must be allowed to forward packets between interfaces (Router → singbox0).

Check:

```
sysctl net.ipv4.ip_forward
```

Enable if needed:

```
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
```

## Minimal firewall example

```
table inet filter {
    chain input { type filter hook input priority filter; policy accept; }
    chain forward { type filter hook forward priority filter; policy accept; }
    chain output { type filter hook output priority filter; policy accept; }
}

table ip nat {
}
```
### Why is this necessary?

- The MikroTik router sends traffic to the server.
- The server must be able to forward it to the 'singbox0' interface.
- Without forwarding, packets simply die at the input.
---

# 🇷🇺 README (Russian)

## Автоматическая синхронизация маршрутов sing-box с MikroTik Address‑List

Этот скрипт автоматически получает список IP‑адресов и подсетей из MikroTik Firewall Address‑List (`list=proxy`) и обновляет маршруты в Linux‑системе, направляя их через интерфейс `singbox0`. Это позволяет использовать **sing-box** как централизованный прокси‑шлюз для Telegram, YouTube, Instagram, Facebook, CDN‑сетей и любых других сервисов, добавленных в список MikroTik.

### Что такое sing-box?

**sing-box** — это современный, высокопроизводительный, модульный сетевой прокси‑фреймворк, поддерживающий Shadowsocks, VLESS, Trojan, Hysteria, WireGuard и другие протоколы. Проект: https://github.com/SagerNet/sing-box

Скрипт предназначен для тех, кто использует sing-box в режиме **TUN‑интерфейса**, чтобы направлять определённые подсети через туннель.

## Возможности

- Получение списка адресов с MikroTik по SSH
- Фильтрация только IPv4 и IPv4/маска
- Исключение локальных сетей
- Обновление маршрутов через `ip route replace`
- Подробное логирование
- Защита от ошибок SSH
- Автоматический запуск через cron

## Установка

### Требуемые пакеты

```
apt update
apt install sshpass -y
```

### Установка скрипта

Сохраните файл:

```
/root/singbox-route-sync.sh

```

Сделайте исполняемым:

```
chmod +x /root/singbox-route-sync.sh

```

## Настройка MikroTik

Создайте пользователя:

```
/user add name=route-sync group=read password=YOUR_PASSWORD
/ip service enable ssh
```

Добавьте адреса:

```
/ip firewall address-list add list=proxy address=149.154.160.0/20
...
```

Или используйте скрипт для RouterOS ниже, только добавьте/замените необходимые домены.

```lua
:local proxyListName "proxy"
:local proxyCommentText "Google"
:local domains {
    "google.com"
    "youtube.com"
    "mail.google.com"
}

:foreach domain in=$domains do={
    :local resolved [:resolve $domain]
    :if ([:len $resolved] > 0) do={
        # Check if IP address in list
        :local exists [/ip firewall address-list find list=$proxyListName address=$resolved]
        :if ([:len $exists] = 0) do={
            /ip firewall address-list add list=$proxyListName address=$resolved comment="$proxyCommentText"
            :log info "Added: $domain -> $resolved"
        } else={
            :log info "Skipped: $domain -> $resolved (already exists)"
        }
    } else={
        :log warning "Failed to resolve: $domain"
    }
}

:log info "Domains processing completed"
```

- `proxyListName` - имя списка
- `proxyCommentText` - комментарий


## Автозапуск через cron

```
crontab -e

```

Добавить:

```
*/30 * * * * /root/singbox-route-sync.sh >> /var/log/singbox-route-sync.log 2>&1

```

Каждые 30 минут

## Логи

```
/var/log/singbox-route-sync.log

```

---
## Маркировка трафика в MikroTik (Mangle)

Чтобы роутер MikroTik отправлял нужные подсети в сторону Linux‑сервера с sing-box, необходимо создать правило в **mangle**, которое будет маркировать трафик, соответствующий address‑list `proxy`.

Откройте:

```
/ip firewall mangle

```

Добавьте правило:

```
/ip firewall mangle add chain=prerouting src-address=your_singbox_server_ip action=accept

```

```
add chain=prerouting src-address-list=proxy action=mark-routing new-routing-mark=singbox passthrough=no

```

### Что делает это правило

- Проверяет, принадлежит ли IP‑адрес списку `proxy`.
- Если да — помечает пакет маршрутизируемой меткой `singbox`.
- Эта метка используется в следующем шаге — статическом маршруте.

## Статический маршрут

Теперь создайте маршрут, который будет отправлять помеченный трафик на сервер с sing-box:

```
/ip route add dst-address=0.0.0.0/0 gateway=your_singbox_server_ip routing-mark=singbox

```

Где:

- `your_singbox_server_ip` — IP‑адрес Linux‑сервера, где работает sing-box.
- `routing-mark=singbox` — метка, установленная правилом mangle.

**Что делает этот маршрут**

- Любой трафик, помеченный как `singbox`, отправляется на Linux‑сервер.
- Сервер, в свою очередь, направляет его через интерфейс `singbox0` в туннель.
- Обратный трафик возвращается по обычному маршруту, что обеспечивает корректную двустороннюю связь.

## Итоговая схема работы

- Роутер MikroTik получает пакет.
- Проверяет, есть ли IP в списке `proxy`.
- Если да — mangle ставит метку `singbox`.
- Маршрут с этой меткой отправляет пакет на Linux‑сервер.
- Скрипт на сервере обновляет маршруты и направляет трафик через sing-box.
- Ответ приходит обратно по стандартному маршруту.

---
## Включение IP‑forwarding

Linux должен уметь пересылать пакеты между интерфейсами (MikroTik → singbox0). Это обязательный шаг.

Проверка:

```
sysctl net.ipv4.ip_forward
```

Если значение `0`, включите:

```
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
```

## Минимальная настройка Firewall

```
table inet filter {
    chain input { type filter hook input priority filter; policy accept; }
    chain forward { type filter hook forward priority filter; policy accept; }
    chain output { type filter hook output priority filter; policy accept; }
}

table ip nat {
}
```

### Зачем это нужно

- Роутер MikroTik отправляет трафик на сервер.
- Сервер должен уметь пересылать его в интерфейс `singbox0`.
- Без forwarding пакеты просто «умирают» на входе.
