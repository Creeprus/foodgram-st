#!/bin/sh

# Ждем пока Vault запустится
echo "Waiting for Vault to start..."
until curl -s -f http://vault:8201/v1/sys/health > /dev/null; do
  sleep 1
done

# Проверяем статус Vault
SEAL_STATUS=$(curl -s http://vault:8201/v1/sys/seal-status | jq -r '.sealed')
INIT_STATUS=$(curl -s http://vault:8201/v1/sys/init | jq -r '.initialized')

echo "Vault status - Sealed: $SEAL_STATUS, Initialized: $INIT_STATUS"

# Если Vault не инициализирован - инициализируем и сохраняем ключи
if [ "$INIT_STATUS" = "false" ]; then
  echo "Initializing Vault for the first time..."
  
  INIT_RESPONSE=$(curl -s -X PUT -d '{"secret_shares": 3, "secret_threshold": 2}' http://vault:8201/v1/sys/init)
  
  # Извлекаем ключи и root token
  UNSEAL_KEY_1=$(echo $INIT_RESPONSE | jq -r '.keys[0]')
  UNSEAL_KEY_2=$(echo $INIT_RESPONSE | jq -r '.keys[1]') 
  UNSEAL_KEY_3=$(echo $INIT_RESPONSE | jq -r '.keys[2]')
  ROOT_TOKEN=$(echo $INIT_RESPONSE | jq -r '.root_token')
  
  # Сохраняем ключи в файл внутри контейнера (для последующих запусков)
  echo "UNSEAL_KEY_1=$UNSEAL_KEY_1" > /vault/unseal_keys.env
  echo "UNSEAL_KEY_2=$UNSEAL_KEY_2" >> /vault/unseal_keys.env
  echo "UNSEAL_KEY_3=$UNSEAL_KEY_3" >> /vault/unseal_keys.env
  echo "VAULT_ROOT_TOKEN=$ROOT_TOKEN" >> /vault/unseal_keys.env
  
  echo "=================================================="
  echo "✅ Vault initialized! Keys saved internally."
  echo "=================================================="
  
  # Используем ключи для unseal
  curl -X PUT -d "{\"key\": \"$UNSEAL_KEY_1\"}" http://vault:8201/v1/sys/unseal
  curl -X PUT -d "{\"key\": \"$UNSEAL_KEY_2\"}" http://vault:8201/v1/sys/unseal
  
else
  # Vault уже инициализирован - читаем ключи из файла
  echo "Vault already initialized, loading keys from file..."
  
  if [ -f /vault/unseal_keys.env ]; then
    . /vault/unseal_keys.env
    echo "Loaded unseal keys from file"
  else
    echo "❌ No unseal keys file found!"
    exit 1
  fi
  
  # Используем ключи для unseal
  curl -X PUT -d "{\"key\": \"$UNSEAL_KEY_1\"}" http://vault:8201/v1/sys/unseal
  curl -X PUT -d "{\"key\": \"$UNSEAL_KEY_2\"}" http://vault:8201/v1/sys/unseal
fi

# Проверяем результат
sleep 2
FINAL_STATUS=$(curl -s http://vault:8201/v1/sys/seal-status | jq -r '.sealed')
if [ "$FINAL_STATUS" = "false" ]; then
  echo "✅ Vault successfully unsealed!"
else
  echo "❌ Vault is still sealed! Trying third key..."
  curl -X PUT -d "{\"key\": \"$UNSEAL_KEY_3\"}" http://vault:8201/v1/sys/unseal
  sleep 2
  FINAL_STATUS=$(curl -s http://vault:8201/v1/sys/seal-status | jq -r '.sealed')
  if [ "$FINAL_STATUS" = "false" ]; then
    echo "✅ Vault unsealed with third key!"
  else
    echo "❌ Still sealed after all keys attempt"
    exit 1
  fi
fi