#!/usr/bin/env bash

# Get the secrets from vault
SECRET_1=$(vault kv get -format="json" -namespace=coder -mount=secrets vault-coder-demo | jq -r '.data.data.SECRET_1')
SECRET_2=$(vault kv get -format="json" -namespace=coder -mount=secrets vault-coder-demo | jq -r '.data.data.SECRET_2')

# Set the secrets in the environment
export SECRET_1=$SECRET_1
export SECRET_2=$SECRET_2

# Start the app
python3 app.py
