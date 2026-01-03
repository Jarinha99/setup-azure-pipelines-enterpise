#!/bin/bash

# 1. Criar diretório para o agent
mkdir ~/myagent && cd ~/myagent

# 2. Baixar o agent
curl -O https://download.agent.dev.azure.com/agent/4.266.2/vsts-agent-linux-x64-4.266.2.tar.gz

# 3. Extrair
tar -xzf vsts-agent-linux-x64-4.266.2.tar.gz

# After Run

# 1. Setup enviroments variables (AZP_URL / AZP_TOKEN)
# 2. run ./setup.sh

