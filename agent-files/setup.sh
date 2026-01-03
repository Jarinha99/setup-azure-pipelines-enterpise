#!/bin/bash
# Before Run use
# chmod +x setup.sh
set -e

export AZP_TOKEN="seu-pat-token-aqui"
export AZP_URL="https://dev.azure.com/sua-organizacao"
export AZP_POOL="Linux-Docker-Pool"

if [ -z "$AZP_URL" ]; then
  echo "Error: AZP_URL não definida"
  exit 1
fi

if [ -z "$AZP_TOKEN" ]; then
  echo "Error: AZP_TOKEN não definida"
  exit 1
fi

if [ -z "$AZP_POOL" ]; then
  export AZP_POOL="Default"
fi

if [ -z "$AZP_AGENT_NAME" ]; then
  export AZP_AGENT_NAME="$(hostname)"
fi

echo "Instalando dependencias..."
export DEBIAN_FRONTEND=noninteractive
export AGENT_ALLOW_RUNASROOT=1

apt-get update && apt-get install -y ca-certificates curl jq git iputils-ping libcurl4 libicu70 libunwind8 netcat libssl3 wget unzip apt-transport-https software-properties-common && rm -rf /var/lib/apt/lists/*

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && apt-get update && apt-get install -y docker-ce-cli && rm -rf /var/lib/apt/lists/*

curl -sL https://aka.ms/InstallAzureCLIDeb | bash

curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs && rm -rf /var/lib/apt/lists/*

echo "Configurando agent..."
./config.sh --unattended --agent "$AZP_AGENT_NAME" --url "$AZP_URL" --auth pat --token "$AZP_TOKEN" --pool "$AZP_POOL" --work "_work" --replace --acceptTeeEula

unset AZP_TOKEN

# run ./run.sh now