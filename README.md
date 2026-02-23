# Outline Wiki in Docker

**Репозиторий:** [https://github.com/outline/outline](https://github.com/outline/outline)

**Описание:**

* Аутентификация пользователей через Keycloak.
* Маршрутизация запросов и SSL-терминация выполняется через Nginx.
* Стек полностью разворачивается через Docker Compose.

## Шаги для запуска

### 1. Генерация SSL-сертификатов

* Для wiki и Keycloak необходимо [сгенерировать SSL-сертификаты](./config/ca/README.md)
* Можно использовать скрипт `./config/ca/genSSL.sh`.
* Сгенерированные сертификаты положить в `./config/nginx/certs/`.

### 2. Настройка DNS или hosts

* Для локального запуска можно добавить имена в `/etc/hosts`:

```text
127.0.0.1 wiki.example.com
127.0.0.1 auth.example.com
```

* В продакшне нужно создать соответствующие DNS-записи.

### 3. Настройка переменных окружения

* Заполнить `.env` файлы для сервисов:

  * `./config/outline/.env`
  * `./config/keycloak/.env`
  * `./config/outline_db/.env`
  * `./config/keycloak_db/.env`

* Документация по настройке Outline: [Outline Guide](https://docs.getoutline.com/s/guide)

### 4. Настройка сетевых алиасов для Nginx

Если весь стек запускается на одной машине, Nginx должен резолвить домены внутри Docker:

```yaml
nginx:
  networks:
    nginx:
      aliases:
        - auth.example.com
        - wiki.example.com
```

### 5. Настройка конфигурации Nginx

* В конфиге Nginx указать доменные имена и пути к SSL-сертификатам.
* Пример сертификатов: `/config/certs/ssl.crt` и `/config/certs/ssl.key`.

### 6. Настройка Keycloak

* В realm provisioning файле `./config/keycloak/realm-export.json` указать домены (`redirectUris`, `webOrigins`).
* После запуска Keycloak выбрать realm `Wiki` и создать пользователя для Outline.

### 7. Запуск стека

```bash
docker compose up -d
```

* После запуска можно зайти на wiki: `https://wiki.example.com`.
