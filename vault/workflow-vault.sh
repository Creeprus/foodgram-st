
export VAULT_ADDR='http://0.0.0.0:8201'
export VAULT_SKIP_VERIFY='true'

vault server -config /vault_data/vault-config.hcl &

sleep 5
chmod +x /vault_data/unseal.sh 
./vault_data/unseal.sh 

wait
