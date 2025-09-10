#!/bin/bash

echo "Retrieving database secrets from Vault..."
sleep 7

# Ждем готовности Vault
while ! curl -s http://vault:8201/v1/sys/health > /dev/null; do
  sleep 2
done

# Получаем секреты
export POSTGRES_PASSWORD=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" http://vault:8201/v1/foodgram/data/DB | jq -r '.data.data.POSTGRES_PASSWORD')
export POSTGRES_USER=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" http://vault:8201/v1/foodgram/data/DB | jq -r '.data.data.POSTGRES_USER')


echo "Retrieved user: $POSTGRES_USER"

# Запускаем с переменными окружения
exec env POSTGRES_USER="$POSTGRES_USER" POSTGRES_PASSWORD="$POSTGRES_PASSWORD" POSTGRES_DB=foodgram_db docker-entrypoint.sh postgres