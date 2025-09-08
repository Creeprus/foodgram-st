
# Надо подождать сервак
sleep 20
# Проверяем статус
VAULT_STATUS=$(vault status -format=json)
INIT_STATUS=$(echo "$VAULT_STATUS" | grep -o '"initialized":[^,]*' | cut -d: -f2 | tr -d ' "')
SEAL_STATUS=$(echo "$VAULT_STATUS" | grep -o '"sealed":[^,]*' | cut -d: -f2 | tr -d ' "')

echo "Vault status - Initialized: $INIT_STATUS, Sealed: $SEAL_STATUS"

# Если не инициализирован - инициализируем
if [ "$INIT_STATUS" = "false" ]; then
  echo "Initializing Vault..."
  
  # Инициализируем и сохраняем вывод
  INIT_OUTPUT=$(vault operator init -format=json)
  
  # Извлекаем ключи простыми методами
  KEY1=$(echo "$INIT_OUTPUT" | grep -o '"unseal_keys_b64":\[[^]]*\]' | cut -d'"' -f4 | cut -d',' -f1 | tr -d '[]"')
  KEY2=$(echo "$INIT_OUTPUT" | grep -o '"unseal_keys_b64":\[[^]]*\]' | cut -d'"' -f4 | cut -d',' -f2 | tr -d '[]"')
  KEY3=$(echo "$INIT_OUTPUT" | grep -o '"unseal_keys_b64":\[[^]]*\]' | cut -d'"' -f4 | cut -d',' -f3 | tr -d '[]"')
  ROOT_TOKEN=$(echo "$INIT_OUTPUT" | grep -o '"root_token":"[^"]*"' | cut -d'"' -f4)
  
  echo "Keys generated"
  
  # Unseal
  vault operator unseal $KEY1
  vault operator unseal $KEY2
  
else
  # Если уже инициализирован но sealed - пробуем unseal
  echo "Vault already initialized, checking seal status..."
  
  if [ "$SEAL_STATUS" = "true" ]; then
    echo "Trying to unseal..."
   vault operator unseal 825ed0780a3af0f7adc5f5c12bfbd381706bdbcff4a711865b021a34acd04c03
  fi
fi

# Проверяем результат
sleep 2
FINAL_STATUS=$(vault status -format=json | grep -o '"sealed":[^,]*' | cut -d: -f2 | tr -d ' "')
if [ "$FINAL_STATUS" = "false" ]; then
  echo "✅ Vault successfully unsealed!"
else
  echo "❌ Vault is still sealed"
fi