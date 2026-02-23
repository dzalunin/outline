
# Генерация своего корневого сертификата, SSL-сертификатов для keycloak и wiki

## 1. Создать Root CA

```bash
openssl genrsa -out RCA.key 4096

openssl req -x509 -new -nodes -key RCA.key -sha256 -days 3650 \
  -out RCA.crt \
  -subj "/C=RU/O=Example/CN=Example-Root-CA"
```

## 2. Создать серверный ключ

```bash
openssl genrsa -out ssl.key 4096
```

## 3. Создать конфиг SAN (Subject Alternative Names)

Файл `server.cnf`:

```ini
[req]
distinguished_name=req_distinguished_name
req_extensions=req_ext
prompt=no

[req_distinguished_name]
C=RU
ST=Moscow
L=Moscow
O=Example
CN=wiki.example.com

[req_ext]
subjectAltName=@alt_names

[alt_names]
DNS.1=auth.example.com
DNS.2=wiki.example.com
```

## 4. Создать CSR (Certificate Signing Request)

```bash
openssl req -new -key ssl.key -out ssl.csr -config server.cnf
```

## 5. Подписать серверный сертификат Root CA

```bash
openssl x509 -req -in ssl.csr \
  -CA RCA.crt -CAkey RCA.key -CAcreateserial \
  -out ssl.crt -days 825 -sha256 \
  -extensions req_ext -extfile server.cnf
```

# Генерация скриптом `genSSL.sh`

Запуск скрипта:

```bash
./genSSL.sh
```

Пример интерактивного ввода:

```
SSL-GENERATOR 00:23:15.60 INFO  ==> Starting interactive SSL generation
CA Country (RU): 
SSL-GENERATOR 00:23:16.89 WARN  ==> Value cannot be empty. Please try again.
CA Country (RU): RU
CA Organization (Example): 
SSL-GENERATOR 00:23:25.99 WARN  ==> Value cannot be empty. Please try again.
CA Organization (Example): Example LLC
CA Common Name (Example-Root-CA): Example-RCA
Server Country (RU): RU
Server State (Moscow): Moscow
Server Locality (Moscow): Moscow
Server Organization (Example LLC): Example LLC
Server Common Name (wiki.example.com): wiki.example.com
SAN domains (comma separated): wiki.example.com,auth.example.com
SSL-GENERATOR 00:24:38.39 INFO  ==> Generating Root CA key
SSL-GENERATOR 00:24:42.79 INFO  ==> Generating Root CA certificate
SSL-GENERATOR 00:24:42.81 INFO  ==> Generating server private key
SSL-GENERATOR 00:24:44.00 INFO  ==> Creating SAN config
SSL-GENERATOR 00:24:44.02 INFO  ==> Generating CSR
SSL-GENERATOR 00:24:44.05 INFO  ==> Signing server certificate
SSL-GENERATOR 00:24:44.11 INFO  ==> Building full chain
SSL-GENERATOR 00:24:44.13 INFO  ==> Certificates successfully generated:
SSL-GENERATOR 00:24:44.13 INFO  ==>   RCA.key
SSL-GENERATOR 00:24:44.13 INFO  ==>   RCA.crt
SSL-GENERATOR 00:24:44.14 INFO  ==>   ssl.key
SSL-GENERATOR 00:24:44.14 INFO  ==>   ssl.crt (includes Root CA)
```

## Результат

После работы скрипта в директории будут:

* `RCA.key` — приватный ключ Root CA
* `RCA.crt` — сертификат Root CA
* `ssl.key` — приватный ключ сервера
* `ssl.crt` — сертификат сервера с включенным Root CA (full chain)
