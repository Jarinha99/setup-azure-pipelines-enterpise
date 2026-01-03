# Plano de Implementação Azure DevOps - CI/CD

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Pré-requisitos](#pré-requisitos)
3. [Fase 1: Configuração Inicial do Azure DevOps](#fase-1-configuração-inicial-do-azure-devops)
4. [Fase 2: Estrutura de Repositórios](#fase-2-estrutura-de-repositórios)
5. [Fase 3: Configuração de Agents](#fase-3-configuração-de-agents)
6. [Fase 4: Criação de Templates CI/CD](#fase-4-criação-de-templates-cicd)
7. [Fase 5: Implementação de Pipelines](#fase-5-implementação-de-pipelines)
8. [Fase 6: Segurança e Governança](#fase-6-segurança-e-governança)
9. [Fase 7: Monitoramento e Otimização](#fase-7-monitoramento-e-otimização)
10. [Cronograma Estimado](#cronograma-estimado)
11. [Boas Práticas](#boas-práticas)

---

## 🚨 Quick Actions - Problemas Comuns

**Se você está aqui porque encontrou um erro:**

| Erro | Onde ir |
|------|---------|
| "No subscriptions found" | → [Seção 1.4.1](#141-verificar-e-configurar-azure-cli) |
| "has no configured federated identity credentials" | → [Seção 1.4.4](#144-configurar-service-connection-no-azure-devops) |
| "No hosted parallelism has been purchased" | → [Seção 1.4.5](#145-testar-service-connection) |
| "Insufficient privileges" | → [Troubleshooting 1.4.6](#-troubleshooting-comum-geral) |
| "SkuNotAvailable" ou "VM size not available" | → [Seção 3.3.1 - Troubleshooting SKU](#opção-b-vm-linux-no-azure-recomendado-para-produção) |
| Preciso de agents agora | → [Fase 3](#fase-3-configuração-de-agents) |
| Como usar os templates? | → [Fase 4](#fase-4-criação-de-templates-cicd) |

---

## Visão Geral

Este documento descreve o plano completo para implementação do Azure DevOps com templates de CI/CD reutilizáveis, incluindo configuração de infraestrutura, agents, pipelines e boas práticas de DevOps.

### Objetivos
- ✅ Estabelecer ambiente Azure DevOps organizado
- ✅ Criar templates CI/CD reutilizáveis e padronizados
- ✅ Configurar agents auto-escaláveis
- ✅ Implementar pipelines seguros e eficientes
- ✅ Estabelecer governança e boas práticas

---

## Pré-requisitos

### ⚠️ AVISO IMPORTANTE - Paralelismo de Pipelines

**Organizações novas do Azure DevOps** não têm paralelismo gratuito para Microsoft-hosted agents. Você precisará:
- **Opção 1**: Solicitar grant gratuito (formulário) - leva 2-3 dias a 2 semanas
- **Opção 2**: Configurar self-hosted agents (gratuito e ilimitado) - recomendado
- **Opção 3**: Comprar paralelismo ($40/mês por job)

💡 Este documento já contempla self-hosted agents na **Fase 3**, que é a solução mais robusta e recomendada. Você pode adiantar essa fase se quiser testar pipelines imediatamente.

Mais detalhes sobre este problema e soluções: veja seção **1.4.5**.

---

### Contas e Acessos Necessários

- [ ] Conta Azure ativa com permissões de:
  - Criação de recursos
  - Gestão de identidades (Service Principals)
  - Acesso ao Azure DevOps
- [ ] Organização Azure DevOps criada
- [ ] Licenças Azure DevOps apropriadas
- [ ] Acesso administrativo ao Azure DevOps

### Ferramentas Necessárias

- [ ] Azure CLI (`az`) instalado
- [ ] Git instalado e configurado
- [ ] Editor de código (VS Code recomendado)
- [ ] Azure DevOps CLI extension
- [ ] Docker (para agents containerizados)
- [ ] Terraform ou Bicep (opcional, para IaC)

### Conhecimentos Técnicos

- Conhecimento básico de Git e controle de versão
- Familiaridade com YAML
- Conceitos de CI/CD
- Noções de Azure (recursos, networking, segurança)
- Conhecimento da stack tecnológica do projeto (.NET, Node.js, etc.)

---

## Fase 1: Configuração Inicial do Azure DevOps

### 1.1 Criação da Organização

**Duração estimada:** 30 minutos

1. **Acessar Azure DevOps**
   ```
   https://dev.azure.com
   ```

2. **Criar nova organização**
   - Nome da organização: `sua-empresa-devops`
   - Região: escolher mais próxima (ex: Brazil South)
   - URL final: `https://dev.azure.com/sua-empresa-devops`

3. **Configurações iniciais**
   - Definir políticas de segurança
   - Configurar autenticação (Azure AD)
   - Habilitar terceiros se necessário

### 1.2 Criação do Projeto

1. **Criar projeto principal**
   - Nome: `Templates-CICD` (projeto para templates)
   - Visibilidade: Private
   - Controle de versão: Git
   - Work item process: Agile ou Scrum

2. **Criar projetos de aplicação**
   - Nome: `Nome-Aplicacao`
   - Mesmas configurações de visibilidade

### 1.3 Estrutura de Equipes

1. **Definir equipes**
   - DevOps Team (administradores)
   - Development Team
   - QA Team
   - Operations Team

2. **Configurar permissões**
   - Grupos de segurança por função
   - Políticas de branch
   - Permissões de pipeline

### 1.4 Configuração de Service Connections

#### 1.4.1 Verificar e Configurar Azure CLI

**Passo 1: Verificar login**
```bash
# Verificar se está autenticado
az account show

# Se não estiver autenticado, fazer login
az login

# Se estiver usando autenticação multi-fator ou corporativa
az login --use-device-code
```

**Passo 2: Listar subscriptions disponíveis**
```bash
# Listar todas as subscriptions
az account list --output table

# Verificar subscription atual
az account show --query "{Name:name, ID:id, TenantID:tenantId}" --output table
```

**Passo 3: Definir subscription correta (se necessário)**
```bash
# Se você tem múltiplas subscriptions, definir a correta
az account set --subscription "Nome-da-Subscription"
# ou
az account set --subscription "subscription-id"

# Verificar se foi definida corretamente
az account show --query name
```

#### 1.4.2 Criar Service Principal para Azure DevOps

**Opção 1: Service Principal com escopo na Subscription (recomendado para início)**

```bash
# 1. Obter o ID da subscription
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"

# 2. Criar Service Principal
az ad sp create-for-rbac --name "azure-devops-sp" --role Contributor --scopes /subscriptions/$SUBSCRIPTION_ID --output json

# Salvar o output! Você precisará de:
# - appId (Client ID)
# - password (Client Secret)
# - tenant (Tenant ID)
```

**Opção 2: Service Principal com escopo em Resource Group específico**

```bash
# 1. Criar Resource Group primeiro (se ainda não existe)
az group create --name rg-devops-resources --location brazilsouth

# 2. Criar Service Principal com escopo limitado
az ad sp create-for-rbac --name "azure-devops-sp-rg" --role Contributor --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-devops-resources --output json
```

**Output esperado:**
```json
{
  "appId": "12345678-1234-1234-1234-123456789012",
  "displayName": "azure-devops-sp",
  "password": "super-secret-password-here",
  "tenant": "87654321-4321-4321-4321-210987654321"
}
```

⚠️ **IMPORTANTE**: Copie e salve essas credenciais imediatamente em local seguro! O `password` não pode ser recuperado depois.

#### 1.4.3 Verificar Service Principal Criado

```bash
# Listar Service Principals
az ad sp list --display-name "azure-devops-sp" --output table

# Verificar role assignments
az role assignment list --assignee "appId-do-service-principal" --output table
```

#### 1.4.4 Configurar Service Connection no Azure DevOps

⚡ **QUICK FIX para o erro "has no configured federated identity credentials":**

Se você chegou aqui por causa deste erro, a solução rápida é:
1. Na tela de criar Service Connection, onde pede **"Authentication method"**
2. Escolha **"Service principal (manual)"** (NÃO escolha "Workload Identity")
3. Preencha com appId e password que você salvou no passo 1.4.2
4. Siga a **OPÇÃO A** abaixo

---

Existem **duas formas** de autenticação. A forma tradicional (com secret) é mais simples e funciona sempre.

---

##### **OPÇÃO A: Service Principal Manual (Tradicional - RECOMENDADO para início)**

Esta é a opção mais simples e sempre funciona. Use o Service Principal criado anteriormente.

**Passo 1: Acessar Service Connections**
- Project Settings → Service connections
- New service connection
- Azure Resource Manager
- Next

**Passo 2: Escolher método de autenticação**
- ⚠️ **IMPORTANTE**: Selecione **"Service principal (manual)"**
- Next

**Passo 3: Preencher informações**

Na tela de configuração, preencha:

```
Environment: Azure Cloud
Scope Level: Subscription

Subscription Id: [cole o subscription-id obtido anteriormente]
Subscription Name: [nome da sua subscription]

Service Principal Id: [appId do output do passo 1.4.2]
Credential: Service Principal Key
Service Principal Key: [password do output do passo 1.4.2]
Tenant ID: [tenant do output do passo 1.4.2]

Service connection name: Azure-DevOps-Connection
Description: Service connection for Azure DevOps pipelines
Security: Grant access permission to all pipelines
```

**Exemplo com valores:**
```
Subscription Id: 12345678-1234-1234-1234-123456789012
Subscription Name: Visual Studio Enterprise

Service Principal Id: 87654321-4321-4321-4321-210987654321
Service Principal Key: abcd1234EFGH5678ijkl9012MNOP3456qrst
Tenant ID: 11111111-2222-3333-4444-555555555555

Service connection name: Azure-DevOps-Connection
```

**Passo 4: Verificar e Salvar**
- Clique em **"Verify"**
- Deve aparecer "Verification Succeeded" ✅
- Clique em **"Verify and save"**

Se ainda der erro, veja a seção de Troubleshooting abaixo.

---

##### **OPÇÃO B: Workload Identity Federation (Moderna - Mais segura)**

Este método não usa secrets, é mais seguro, mas requer configuração adicional. Use se sua organização exige este tipo de autenticação.

**Passo 1: Obter informações do Azure DevOps**

```bash
# Obter Organization ID
# Vá para: https://dev.azure.com/sua-org/_settings/organizationOverview
# Copie o Organization ID (formato: UUID)

# Exemplo:
ORG_ID="a1b2c3d4-e5f6-7890-abcd-ef1234567890"
PROJECT_NAME="Templates-CICD"
```

**Passo 2: Configurar Federated Credentials no Service Principal**

```bash
# Variáveis necessárias
APP_ID="seu-appId-aqui"  # Do passo 1.4.2
ORG_NAME="sua-empresa-devops"
ORG_ID="seu-organization-id"  # Veja passo 1 acima
PROJECT_NAME="Templates-CICD"

# Criar credencial federada
az ad app federated-credential create --id $APP_ID --parameters "{\"name\":\"AzureDevOpsConnection\",\"issuer\":\"https://vstoken.dev.azure.com/$ORG_ID\",\"subject\":\"sc://$ORG_NAME/$PROJECT_NAME/Azure-DevOps-Connection\",\"description\":\"Azure DevOps Service Connection\",\"audiences\":[\"api://AzureADTokenExchange\"]}"
```

**Passo 3: Configurar no Azure DevOps**

- Project Settings → Service connections
- New service connection → Azure Resource Manager
- Next
- **Workload Identity federation (manual)**
- Next
- Preencher:
  ```
  Subscription Id: [seu-subscription-id]
  Subscription Name: [nome da subscription]
  Service Principal Id: [appId]
  Tenant ID: [tenant-id]
  Service connection name: Azure-DevOps-Connection
  ```
- Verify and save

---

#### 🔧 Troubleshooting - Service Connection

**Erro: "has no configured federated identity credentials"**

✅ **SOLUÇÃO**: Você está tentando usar Workload Identity mas o SP não está configurado para isso.

**Correção rápida:**
1. Volte na tela de configuração
2. No passo "Authentication method", escolha **"Service principal (manual)"** ao invés de "Workload Identity federation"
3. Use a **OPÇÃO A** acima
4. Preencha com appId e password (secret) que você salvou

**Se quiser usar Workload Identity:**
- Siga a **OPÇÃO B** para configurar o federated credential primeiro

---

**Erro: "Verification Failed - Failed to obtain the JWT"**

```bash
# 1. Verificar se as credenciais estão corretas
az login --service-principal --username "seu-appId" --password "seu-password" --tenant "seu-tenant-id"

# Se o login funcionar, as credenciais estão corretas

# 2. Verificar permissões na subscription
az role assignment list --assignee "seu-appId" --output table

# Deve mostrar role "Contributor" na subscription
```

---

**Erro: "The service principal does not exist"**

```bash
# Verificar se o SP existe
az ad sp show --id "seu-appId"

# Se não existir, criar novamente:
az ad sp create-for-rbac --name "azure-devops-sp" --role Contributor --scopes /subscriptions/$(az account show --query id -o tsv)
```

---

**Erro: "Insufficient privileges to complete the operation"**

```bash
# O Service Principal precisa ter permissão de Contributor
# Verificar role assignments:
az role assignment list --assignee "seu-appId" --output table

# Se não tiver, adicionar:
az role assignment create --assignee "seu-appId" --role Contributor --scope /subscriptions/$(az account show --query id -o tsv)
```

---

**Erro: "Could not find a valid subscription"**

```bash
# 1. Verificar o Subscription ID
az account show --query id

# 2. Copie o ID exato (sem espaços, sem quebras de linha)

# 3. Use esse ID no campo "Subscription Id" do Azure DevOps
```

**Via Azure DevOps CLI (Alternativa):**

```bash
# Instalar extensão do Azure DevOps
az extension add --name azure-devops

# Configurar organização default
az devops configure --defaults organization=https://dev.azure.com/sua-empresa-devops

# Criar service endpoint
az devops service-endpoint azurerm create --azure-rm-service-principal-id "appId-aqui" --azure-rm-subscription-id "$SUBSCRIPTION_ID" --azure-rm-subscription-name "Nome-Subscription" --azure-rm-tenant-id "tenant-id-aqui" --name "Azure-DevOps-Connection" --project "Templates-CICD"
```

#### 1.4.5 Testar Service Connection

⚠️ **IMPORTANTE - Problema de Paralelismo**: Se você criou uma nova organização Azure DevOps, provavelmente receberá o erro abaixo ao tentar executar qualquer pipeline com Microsoft-hosted agents. Veja as soluções após o erro.

---

**Criar pipeline de teste simples:**

```yaml
# test-service-connection.yml
trigger: none

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: AzureCLI@2
    displayName: 'Test Azure Connection'
    inputs:
      azureSubscription: 'Azure-DevOps-Connection'
      scriptType: 'bash'
      scriptLocation: 'inlineScript'
      inlineScript: |
        echo "Testing Azure connection..."
        az account show
        az group list --output table
```

---

### 🚨 Erro Comum: "No hosted parallelism has been purchased or granted"

**Mensagem completa do erro:**
```
##[error]No hosted parallelism has been purchased or granted. 
To request a free parallelism grant, please fill out the following form 
https://aka.ms/azpipelines-parallelism-request
```

**Por que isso acontece?**
- Organizações novas do Azure DevOps não têm paralelismo gratuito para Microsoft-hosted agents
- Isso é uma política da Microsoft desde 2021 para evitar abuso
- Você precisa solicitar acesso gratuito OU usar self-hosted agents

---

### ✅ Soluções para o Problema de Paralelismo

#### **SOLUÇÃO 1: Solicitar Grant Gratuito (Recomendado para testes)**

1. **Preencher o formulário da Microsoft**
   - Acesse: https://aka.ms/azpipelines-parallelism-request
   - Preencha todas as informações solicitadas
   - Seja específico sobre o uso (desenvolvimento, CI/CD, etc.)

2. **Informações a fornecer:**
   ```
   Nome da Organização: sua-empresa-devops
   Link da Organização: https://dev.azure.com/sua-empresa-devops
   
   Justificativa: 
   "Estamos configurando pipelines CI/CD para desenvolvimento de 
   aplicações .NET/Node.js. Precisamos de paralelismo para executar 
   builds, testes e deployments automatizados."
   
   Uso esperado: Desenvolvimento interno, CI/CD
   ```

3. **Tempo de resposta:**
   - ⏱️ Pode levar de **2-3 dias úteis até 2 semanas**
   - Você receberá email quando for aprovado
   - Enquanto isso, use as outras soluções abaixo

4. **O que você ganhará:**
   - 1 job paralelo gratuito de Microsoft-hosted agents
   - 1800 minutos/mês grátis
   - Suficiente para desenvolvimento e testes

---

#### **SOLUÇÃO 2: Usar Self-Hosted Agents (Recomendado para produção)**

Esta é a solução mais robusta e já está planejada no seu documento (Fase 3).

**Opção 2A: Configurar Self-Hosted Agent agora (adiantar Fase 3)**

Se você quer testar imediatamente, pode adiantar a configuração dos agents:

1. **Ir direto para a Fase 3** do documento
2. Configurar pelo menos 1 agent Docker
3. Voltar aqui e modificar o pipeline de teste:

```yaml
# test-service-connection.yml (com self-hosted agent)
trigger: none

pool:
  name: 'Linux-Docker-Pool'  # Seu pool de self-hosted agents

steps:
  - task: AzureCLI@2
    displayName: 'Test Azure Connection'
    inputs:
      azureSubscription: 'Azure-DevOps-Connection'
      scriptType: 'bash'
      scriptLocation: 'inlineScript'
      inlineScript: |
        echo "Testing Azure connection..."
        az account show
        az group list --output table
```

**Opção 2B: Configurar agent mínimo rapidamente**

Se quiser apenas um agent simples para teste agora:

```bash
# Em uma máquina Linux (pode ser seu próprio computador)

# 1. Baixar agent
mkdir azp-agent && cd azp-agent
wget https://vstsagentpackage.azureedge.net/agent/3.236.1/vsts-agent-linux-x64-3.236.1.tar.gz
tar zxvf vsts-agent-linux-x64-3.236.1.tar.gz

# 2. Configurar
./config.sh

# Responda as perguntas:
# Server URL: https://dev.azure.com/sua-empresa-devops
# Authentication type: PAT
# Personal Access Token: [seu PAT criado em 1.3.2]
# Agent pool: Default (ou criar novo pool "Test-Pool")
# Agent name: test-agent
# Work folder: _work

# 3. Instalar como serviço (opcional)
sudo ./svc.sh install
sudo ./svc.sh start

# OU executar diretamente
./run.sh
```

Depois use `pool: 'Default'` (ou nome do pool escolhido) no pipeline.

---

#### **SOLUÇÃO 3: Comprar Paralelismo (Para empresas)**

Se sua empresa pode pagar:

1. **Acessar configurações de billing**
   - Organization Settings → Billing
   - Parallel jobs → Change

2. **Comprar Microsoft-hosted parallelism**
   - Microsoft-hosted CI/CD: $40/mês por job paralelo
   - Inclui 1800 minutos grátis + $0.008 por minuto adicional

3. **Benefícios:**
   - Sem espera de aprovação
   - Múltiplos jobs paralelos
   - Ideal para empresas com muitas pipelines

---

#### **SOLUÇÃO 4: Pular Teste por Enquanto (Temporário)**

Se você quer apenas continuar com a configuração:

1. **Aceite que este teste específico não vai funcionar agora**
2. **Continue com a Fase 2** do documento
3. **Configure os self-hosted agents na Fase 3**
4. **Volte para testar depois** com agents próprios

A Service Connection está criada e vai funcionar quando você tiver agents disponíveis.

---

### Verificar Status de Paralelismo

**Via Interface:**
```
Organization Settings → Billing → Parallel jobs
```

Você verá algo como:
```
Microsoft-hosted CI/CD
  Parallelism: 0 of 0 (none purchased)
  
Self-hosted CI/CD  
  Parallelism: Unlimited (free)
```

**Via Azure DevOps CLI:**
```bash
# Verificar parallel jobs disponíveis
az devops configure --defaults organization=https://dev.azure.com/sua-empresa-devops

# Listar agents pools
az pipelines pool list --output table

# Ver detalhes de um pool
az pipelines pool show --id 1  # Default pool
```

---

### Recomendação

🎯 **Para este projeto, recomendo:**

1. **Curto prazo (agora):**
   - Solicitar o grant gratuito no formulário
   - Continuar com Fase 2 (estrutura de repositórios)
   - Configurar self-hosted agents na Fase 3

2. **Médio prazo:**
   - Usar self-hosted agents para tudo (Fase 3)
   - Self-hosted tem vantagens: sem limite de tempo, cache persistente, ferramentas customizadas
   - Quando o grant for aprovado, usar Microsoft-hosted apenas para validações rápidas de PRs

3. **Longo prazo:**
   - Estratégia híbrida:
     - Microsoft-hosted: validações rápidas, PRs, testes unitários
     - Self-hosted: builds completos, deploys, testes de integração

---

### Alternativa: Testar Service Connection Manualmente

Enquanto não tem agents, você pode testar a connection manualmente:

```bash
# Fazer login com o Service Principal
az login --service-principal --username "seu-appId" --password "seu-password" --tenant "seu-tenant-id"

# Testar acesso à subscription
az account show

# Listar resource groups
az group list --output table

# Testar criação de recurso (teste apenas)
az group create --name rg-test-connection --location brazilsouth

# Limpar
az group delete --name rg-test-connection --yes --no-wait
```

Se esses comandos funcionarem, sua Service Connection está configurada corretamente! ✅

#### 1.4.6 Outras Service Connections Comuns

**Docker Registry (Azure Container Registry):**

```bash
# Criar ACR
az acr create --resource-group rg-devops-resources --name suaempresaacr --sku Basic

# No Azure DevOps:
# - New service connection → Docker Registry
# - Registry type: Azure Container Registry
# - Selecionar a subscription e ACR criado
```

**Kubernetes (AKS):**

```bash
# Obter credenciais do cluster
az aks get-credentials --resource-group rg-k8s --name aks-cluster-name

# No Azure DevOps:
# - New service connection → Kubernetes
# - Authentication method: Service Account
# - Usar o kubeconfig ou criar service account
```

**SonarQube:**

```bash
# No Azure DevOps:
# - New service connection → SonarQube
# - Server URL: https://seu-sonarqube.com
# - Token: gerar no SonarQube (My Account → Security → Generate Token)
```

**NPM / NuGet Artifacts:**

```bash
# No Azure DevOps:
# - New service connection → npm / NuGet
# - Registry URL: feed URL
# - Personal Access Token com escopo Packaging (Read & Write)
```

---

#### 🔧 Troubleshooting Comum (Geral)

💡 **Nota**: Problemas específicos de Service Connection foram movidos para a seção 1.4.4 acima.

---

**Problema: "No subscriptions found"**

```bash
# Solução 1: Verificar se tem subscriptions
az account list --output table

# Se não aparecer nenhuma, pode ser:
# 1. Não tem subscription associada à conta
# 2. Precisa criar uma subscription trial
# 3. Precisa de permissões na subscription

# Solução 2: Verificar tenant correto
az account show --query tenantId

# Solução 3: Limpar cache e fazer login novamente
az account clear
az login
```

**Se você não tem nenhuma subscription:**
1. Acesse: https://portal.azure.com
2. Vá em "Subscriptions" no menu
3. Clique em "+ Add" para criar uma nova subscription
4. Ou solicite acesso a uma subscription existente ao administrador

---

**Problema: "Insufficient privileges to complete the operation"**

```bash
# Para criar Service Principals, você precisa de:
# - Owner ou User Access Administrator na subscription, OU
# - Application Administrator no Azure AD

# Verificar suas permissões atuais:
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv) --output table

# Solicitar ao administrador:
# Opção 1: Permissão de "Owner" na subscription
# Opção 2: "Contributor" + "User Access Administrator" na subscription
# Opção 3: "Application Administrator" no Azure AD (nível tenant)
```

---

**Problema: "Service Principal already exists with name 'azure-devops-sp'"**

```bash
# Opção 1: Listar e resetar credenciais do existente
az ad sp list --display-name "azure-devops-sp" --output table

# Resetar o password (secret) do SP existente
az ad sp credential reset --id "appId-do-sp-existente" --query "{appId:appId, password:password, tenant:tenant}" --output json

# Use essas novas credenciais no Azure DevOps

# Opção 2: Criar com nome diferente
az ad sp create-for-rbac --name "azure-devops-sp-$(date +%Y%m%d)" --role Contributor --scopes /subscriptions/$(az account show --query id -o tsv)

# Opção 3: Deletar o antigo e criar novo (cuidado se está em uso!)
# Liste primeiro para confirmar o appId
az ad sp list --display-name "azure-devops-sp" --query "[].{Name:displayName, AppId:appId}" -o table

# Delete (só se tiver certeza!)
az ad sp delete --id "appId-aqui"

# Crie novamente
az ad sp create-for-rbac --name "azure-devops-sp" ...
```

---

**Problema: "AADSTS700016: Application with identifier not found"**

```bash
# O Service Principal foi deletado ou nunca existiu
# Solução: Criar um novo

az ad sp create-for-rbac --name "azure-devops-sp-new" --role Contributor --scopes /subscriptions/$(az account show --query id -o tsv)
```

---

**Problema: Azure CLI não reconhece comandos `az ad`**

```bash
# Pode ser versão antiga do Azure CLI
# Verificar versão
az --version

# Atualizar Azure CLI
# Windows:
# Baixe o installer: https://aka.ms/installazurecliwindows

# macOS:
brew update && brew upgrade azure-cli

# Linux:
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Após atualizar, verificar:
az --version  # Deve ser 2.40.0 ou superior
```

---

**Problema: "Principal does not exist in the directory"**

```bash
# Pode levar alguns minutos para o Service Principal propagar no Azure AD
# Aguarde 2-5 minutos e tente novamente

# Verificar se o SP existe:
az ad sp show --id "seu-appId"

# Se não existir após 5 minutos, criar novamente
```

---

**Problema: Permissões funcionam via CLI mas não no Azure DevOps**

```bash
# Às vezes a propagação de permissões leva tempo
# 1. Aguarde 5 minutos
# 2. Tente "Verify" novamente no Azure DevOps
# 3. Se não funcionar, verifique:

# Se o Service Principal tem role assignment na subscription:
az role assignment list --assignee "seu-appId" --all --output table

# Se necessário, adicionar explicitamente:
az role assignment create --assignee "seu-appId" --role Contributor --scope /subscriptions/$(az account show --query id -o tsv)
```

---

## Fase 2: Estrutura de Repositórios

### 2.1 Repositório de Templates

**Estrutura proposta:**

```
templates-cicd/
├── README.md
├── pipelines/
│   ├── templates/
│   │   ├── jobs/
│   │   │   ├── build-job.yml
│   │   │   ├── test-job.yml
│   │   │   ├── security-scan-job.yml
│   │   │   └── deploy-job.yml
│   │   ├── stages/
│   │   │   ├── build-stage.yml
│   │   │   ├── test-stage.yml
│   │   │   └── deploy-stage.yml
│   │   └── steps/
│   │       ├── install-dependencies.yml
│   │       ├── run-tests.yml
│   │       ├── build-container.yml
│   │       └── deploy-azure.yml
│   └── examples/
│       ├── dotnet-api-pipeline.yml
│       ├── nodejs-app-pipeline.yml
│       └── react-spa-pipeline.yml
├── scripts/
│   ├── setup/
│   ├── build/
│   ├── test/
│   └── deploy/
├── agents/
│   ├── docker/
│   │   ├── Dockerfile
│   │   └── docker-compose.yml
│   └── kubernetes/
│       ├── deployment.yml
│       └── service.yml
└── docs/
    ├── setup-guide.md
    ├── template-usage.md
    └── best-practices.md
```

### 2.2 Inicializar Repositório

```bash
# Clonar repositório vazio
git clone https://dev.azure.com/sua-empresa-devops/Templates-CICD/_git/templates-cicd

cd templates-cicd

# Criar estrutura de diretórios
mkdir -p pipelines/{templates/{jobs,stages,steps},examples}
mkdir -p scripts/{setup,build,test,deploy}
mkdir -p agents/{docker,kubernetes}
mkdir -p docs

# Criar README inicial
cat > README.md << 'EOF'
# Templates CI/CD - Azure DevOps

Repositório centralizado de templates YAML reutilizáveis para pipelines CI/CD.

## Estrutura
- `pipelines/templates/` - Templates reutilizáveis
- `pipelines/examples/` - Exemplos de uso
- `scripts/` - Scripts auxiliares
- `agents/` - Configuração de build agents
- `docs/` - Documentação

## Como usar
Veja a documentação em `docs/template-usage.md`
EOF

# Commit inicial
git add .
git commit -m "Initial repository structure"
git push origin main
```

### 2.3 Configuração de Branch Policies

1. **Branch protection para `main`**
   - Branches → main → Branch policies
   - ✅ Require a minimum number of reviewers: 2
   - ✅ Check for linked work items
   - ✅ Check for comment resolution
   - ✅ Build validation

2. **Branch naming convention**
   - `feature/*` - novas funcionalidades
   - `bugfix/*` - correções
   - `hotfix/*` - correções urgentes
   - `release/*` - preparação de releases

---

## Fase 3: Configuração de Agents

⭐ **FASE CRÍTICA**: Esta fase é especialmente importante porque:
1. **Organizações novas não têm paralelismo gratuito** para Microsoft-hosted agents
2. **Self-hosted agents são gratuitos e ilimitados**
3. **Mais controle**: cache persistente, ferramentas customizadas, sem restrições de tempo
4. **Melhor performance**: para projetos maiores

💡 **Recomendação**: Se você está enfrentando o erro "No hosted parallelism" na Fase 1, considere fazer esta Fase 3 imediatamente após a Fase 2.

---

### 🚀 Quick Reference - Escolha de SKU para VMs

**Se você vai criar uma VM para hospedar agents, use estas SKUs:**

| Cenário | SKU Recomendada | Comando |
|---------|-----------------|---------|
| 💰 **Economia (teste/dev)** | Standard_B2s | `--size Standard_B2s` |
| ⭐ **Melhor custo-benefício (RECOMENDADO)** | Standard_B2ms | `--size Standard_B2ms` |
| 🚀 **Alta performance** | Standard_D2s_v5 | `--size Standard_D2s_v5` |

**Verificar disponibilidade antes de criar:**
```bash
az vm list-skus --location brazilsouth --size Standard_B2ms --output table
```

Se a SKU não estiver disponível, veja o troubleshooting na **Seção 3.3.1**.

---

### 3.1 Decisão: Self-hosted vs Microsoft-hosted

**Microsoft-hosted Agents:**
- ✅ Fácil configuração
- ✅ Sem manutenção
- ❌ Tempo limitado
- ❌ Custo por minuto

**Self-hosted Agents:**
- ✅ Controle total
- ✅ Cache persistente
- ✅ Softwares customizados
- ❌ Requer manutenção

**Recomendação:** Híbrido - Microsoft-hosted para validações rápidas, Self-hosted para builds/deploys complexos

### 3.2 Configuração de Agent Pools

1. **Criar Agent Pool**
   - Organization Settings → Agent pools
   - Add pool → New → Self-hosted
   - Nome: `Linux-Docker-Pool`
   - Grant access to all pipelines: ✅

2. **Gerar Personal Access Token (PAT)**
   - User Settings → Personal Access Tokens
   - New Token
   - Scopes: Agent Pools (Read & manage), Deployment Groups (Read & manage)
   - Salvar token em local seguro

### 3.3 Escolha Sua Abordagem

Existem duas formas principais de configurar self-hosted agents no Azure:

| Abordagem | Complexidade | Setup | Quando Usar |
|-----------|--------------|-------|-------------|
| **🎯 Agent Direto na VM** | ⭐ Simples | 10 min | **90% dos casos** - até 50 builds/dia |
| **🐳 Agents com Docker** | ⭐⭐⭐ Complexo | 1-2h | Múltiplos agents/VM, ambiente reproduzível |
| **☁️ Azure Container Instances** | ⭐⭐ Médio | 30 min | Auto-scale, sem gerenciar VMs |

**Recomendação:** Comece com **Agent Direto na VM** (seção 3.4). É simples, funciona perfeitamente, e você sempre pode migrar para Docker depois se precisar.

---

### 3.4 Opção Principal: Agent Direto na VM ⭐

Esta é a forma **mais simples e direta** de ter self-hosted agents. Uma VM = Um agent rodando direto no sistema.

#### 3.4.1 Criar VM no Azure

```bash
# 1. Criar Resource Group
az group create --name rg-devops-agents --location brazilsouth

# 2. Criar VM Linux
az vm create \
  --resource-group rg-devops-agents \
  --name vm-agent-01 \
  --image Ubuntu2204 \
  --size Standard_B2ms \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard

# 3. Obter IP público
VM_IP=$(az vm show --resource-group rg-devops-agents --name vm-agent-01 --show-details --query publicIps --output tsv)
echo "VM IP: $VM_IP"

# 4. Conectar na VM
ssh azureuser@$VM_IP
```

**💡 Sobre o tamanho Standard_B2ms:**
- 2 vCPUs, 8GB RAM
- ~R$ 120-150/mês
- Suficiente para maioria dos projetos

**Alternativas de SKU:**
- `Standard_B2s`: Mais barato (~R$ 80-100/mês), 4GB RAM
- `Standard_D2s_v5`: Mais performance (~R$ 180-220/mês)

---

#### 3.4.2 Instalar Dependências na VM

```bash
# Dentro da VM (via SSH)

# 1. Atualizar sistema
sudo apt update && sudo apt upgrade -y

# 2. Instalar ferramentas básicas
sudo apt install -y curl wget git jq

# 3. Instalar .NET SDK (se precisar)
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt update
sudo apt install -y dotnet-sdk-8.0

# 4. Instalar Node.js (se precisar)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# 5. Instalar Docker (se pipelines usam Docker)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker azureuser
rm get-docker.sh

# Relogar para aplicar grupo docker
exit
ssh azureuser@$VM_IP
```

---

#### 3.4.3 Instalar e Configurar o Agent

```bash
# 1. Criar diretório para o agent
mkdir ~/myagent && cd ~/myagent

# 2. Baixar o agent
curl -O https://download.agent.dev.azure.com/agent/4.266.2/vsts-agent-linux-x64-4.266.2.tar.gz

# 3. Extrair
tar -xzf vsts-agent-linux-x64-4.266.2.tar.gz

# 4. Configurar o agent (interativo)
./config.sh

# O script vai pedir:
# - Server URL: https://dev.azure.com/sua-organizacao
# - Authentication type: PAT
# - Personal access token: [cole seu PAT da seção 3.2]
# - Agent pool: Linux-Docker-Pool (ou nome que você criou)
# - Agent name: vm-agent-01 (ou deixe o padrão)
# - Work folder: _work (deixe padrão)
# - Run as service: Y (recomendado)

# 5. Se escolheu rodar como service, instalar:
sudo ./svc.sh install azureuser

# 6. Iniciar o service
sudo ./svc.sh start

# 7. Verificar status
sudo ./svc.sh status
```

**Pronto! Seu agent está rodando.** ✅

---

#### 3.4.4 Verificar no Azure DevOps

1. Vá para **Azure DevOps** → **Organization Settings** → **Agent pools**
2. Clique no pool que você criou (ex: `Linux-Docker-Pool`)
3. Aba **Agents**
4. Você deve ver: **vm-agent-01** com status **Online** 🟢

---

#### 3.4.5 Testar com Pipeline Simples

Crie um arquivo `azure-pipelines.yml` em qualquer repo:

```yaml
trigger:
  - main

pool:
  name: Linux-Docker-Pool

steps:
  - script: |
      echo "Hello from self-hosted agent!"
      hostname
      whoami
      dotnet --version
      node --version
    displayName: 'Test Agent'
```

Faça commit e push. A pipeline deve rodar no seu agent! 🎉

---

#### 3.4.6 Adicionar Mais Agents (Escalar)

Para adicionar mais capacidade, simplesmente:

```bash
# Criar mais VMs
az vm create \
  --resource-group rg-devops-agents \
  --name vm-agent-02 \
  --image Ubuntu2204 \
  --size Standard_B2ms \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard

# Conectar e repetir os passos 3.4.2 e 3.4.3
```

Simples assim! Cada VM = mais 1 agent no pool.

---

#### 3.4.7 Troubleshooting

**Problema: Agent não aparece como Online**

```bash
# Verificar logs do service
sudo ./svc.sh status
journalctl -u vsts.agent.* -f

# Verificar se agent está rodando
ps aux | grep Agent.Listener

# Restartar service
sudo ./svc.sh stop
sudo ./svc.sh start
```

**Problema: PAT token expirou**

```bash
# Gerar novo PAT no Azure DevOps
# Reconfigurar agent
cd ~/myagent
./config.sh remove  # Remove configuração antiga
./config.sh         # Configura novamente com novo PAT
sudo ./svc.sh install azureuser
sudo ./svc.sh start
```

**Problema: DNS não resolve (VM Azure)**

```bash
# Configurar DNS manualmente
sudo rm /etc/resolv.conf
sudo bash -c 'echo "nameserver 168.63.129.16" > /etc/resolv.conf'
sudo bash -c 'echo "nameserver 8.8.8.8" >> /etc/resolv.conf'
sudo chattr +i /etc/resolv.conf

# Testar
nslookup dev.azure.com
```

---

### 3.5 Opção Avançada: Agents com Docker 🐳

Use esta abordagem **apenas se**:
- ✅ Precisa rodar 3+ agents na mesma VM (densidade)
- ✅ Quer ambiente completamente reproduzível
- ✅ Já tem experiência com Docker
- ✅ Precisa isolamento forte entre agents

**Se você não tem esses requisitos, use a Opção Principal (3.4).**

---

#### 3.5.1 Por Que Docker?

**Vantagens:**
- 1 VM pode rodar 5+ agents (densidade)
- Ambiente idêntico sempre (Dockerfile)
- Fácil escalar horizontalmente (docker-compose scale)
- Isolamento entre agents

**Desvantagens:**
- Configuração mais complexa
- Overhead de performance (~10-15%)
- Troubleshooting mais difícil
- Requer expertise em Docker

---

#### 3.5.2 Preparar VM com Docker

```bash
# 1. Criar VM (igual seção 3.4.1)
az vm create \
  --resource-group rg-devops-agents \
  --name vm-docker-agents \
  --image Ubuntu2204 \
  --size Standard_B2ms \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard

# 2. Conectar
VM_IP=$(az vm show --resource-group rg-devops-agents --name vm-docker-agents --show-details --query publicIps --output tsv)
ssh azureuser@$VM_IP

# 3. Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker azureuser

# 4. Instalar docker-compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 5. Relogar
exit
ssh azureuser@$VM_IP

# 6. Criar diretório
mkdir ~/azure-devops-agents
cd ~/azure-devops-agents
```

---

#### 3.5.3 Criar Arquivos de Configuração

**1. Criar Dockerfile:**

```bash
cat > Dockerfile << 'EOF'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV AGENT_ALLOW_RUNASROOT=1

# Instalar dependências
RUN apt-get update && apt-get install -y \
    ca-certificates curl jq git wget unzip \
    libicu70 libssl3 && \
    rm -rf /var/lib/apt/lists/*

# Instalar .NET 8
RUN wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb && \
    dpkg -i packages-microsoft-prod.deb && \
    rm packages-microsoft-prod.deb && \
    apt-get update && \
    apt-get install -y dotnet-sdk-8.0 && \
    rm -rf /var/lib/apt/lists/*

# Instalar Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /azp

COPY start.sh /azp/start.sh
RUN chmod +x /azp/start.sh

RUN useradd -m azureagent
USER azureagent

ENTRYPOINT ["/azp/start.sh"]
EOF
```

**2. Criar start.sh:**

```bash
cat > start.sh << 'EOF'
#!/bin/bash
set -e

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

# Baixar agent
echo "Baixando Azure Pipelines Agent..."
curl -LsS https://vstsagentpackage.azureedge.net/agent/4.266.2/vsts-agent-linux-x64-4.266.2.tar.gz | tar -xz

# Configurar
echo "Configurando agent..."
./config.sh \
  --unattended \
  --agent "$AZP_AGENT_NAME" \
  --url "$AZP_URL" \
  --auth pat \
  --token "$AZP_TOKEN" \
  --pool "$AZP_POOL" \
  --work "_work" \
  --replace \
  --acceptTeeEula

unset AZP_TOKEN

# Executar
echo "Iniciando agent..."
./run.sh
EOF

chmod +x start.sh
```

**3. Criar docker-compose.yml:**

```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  agent-1:
    build: .
    container_name: azp-agent-1
    environment:
      - AZP_URL=https://dev.azure.com/SUA-ORGANIZACAO
      - AZP_TOKEN=${AZP_TOKEN}
      - AZP_POOL=Linux-Docker-Pool
      - AZP_AGENT_NAME=docker-agent-1
    restart: unless-stopped

  agent-2:
    build: .
    container_name: azp-agent-2
    environment:
      - AZP_URL=https://dev.azure.com/SUA-ORGANIZACAO
      - AZP_TOKEN=${AZP_TOKEN}
      - AZP_POOL=Linux-Docker-Pool
      - AZP_AGENT_NAME=docker-agent-2
    restart: unless-stopped
EOF
```

**4. Editar docker-compose.yml com seus dados:**

```bash
# Substitua SUA-ORGANIZACAO pela sua organização
nano docker-compose.yml
```

---

#### 3.5.4 Deploy dos Agents

```bash
# 1. Definir PAT token
export AZP_TOKEN="seu-pat-token-aqui"

# 2. Build das imagens
docker-compose build

# 3. Iniciar agents
docker-compose up -d

# 4. Ver logs
docker-compose logs -f

# Deve mostrar:
# azp-agent-1  | Baixando Azure Pipelines Agent...
# azp-agent-1  | Configurando agent...
# azp-agent-1  | Listening for Jobs
```

---

#### 3.5.5 Gerenciar Agents Docker

```bash
# Ver status
docker-compose ps

# Parar agents
docker-compose down

# Reiniciar agents
docker-compose restart

# Ver logs de um agent específico
docker-compose logs -f agent-1

# Escalar (adicionar mais agents)
docker-compose up -d --scale agent-1=5

# Rebuild após mudanças
docker-compose down
docker-compose build
docker-compose up -d
```

---

### 3.6 Opção Serverless: Azure Container Instances ☁️

Para cenários de auto-scale ou quando não quer gerenciar VMs.

**Quando usar:**
- Builds esporádicos/imprevisíveis
- Auto-scale sob demanda
- Não quer manutenção de VM

**Setup rápido:**

```bash
# 1. Criar ACI com agent
az container create \
  --resource-group rg-devops-agents \
  --name aci-agent-01 \
  --image mcr.microsoft.com/azure-pipelines/vsts-agent:ubuntu-22.04 \
  --environment-variables \
    AZP_URL=https://dev.azure.com/SUA-ORG \
    AZP_TOKEN=SEU-PAT-TOKEN \
    AZP_POOL=Linux-Docker-Pool \
    AZP_AGENT_NAME=aci-agent-01 \
  --cpu 2 \
  --memory 4 \
  --restart-policy Always

# 2. Verificar status
az container show \
  --resource-group rg-devops-agents \
  --name aci-agent-01 \
  --query instanceView.state
```

**Custo:** ~R$ 100-150/mês por container (24/7)

**Nota:** Para produção, considere usar ARM templates para escalar múltiplos containers facilmente.

---

### 3.7 Comparativo: Qual Escolher?

| Critério | Agent Direto VM | Docker na VM | ACI |
|----------|----------------|--------------|-----|
| **Complexidade** | ⭐ Simples | ⭐⭐⭐ Complexo | ⭐⭐ Médio |
| **Setup** | 10 minutos | 1-2 horas | 30 minutos |
| **Custo/mês** | R$ 120-150 (1 VM, 1 agent) | R$ 120-150 (1 VM, 3-5 agents) | R$ 100-150 por container |
| **Manutenção** | Baixa | Média-Alta | Mínima |
| **Densidade** | 1 agent/VM | 3-5 agents/VM | 1 agent/container |
| **Performance** | 100% | ~85-90% | 100% |
| **Escala** | +1 VM = +1 agent | +1 container = +1 agent | Fácil (ARM) |
| **Melhor para** | **90% dos casos** | Múltiplos agents, densidade | Auto-scale, sem VM |

**Recomendação por cenário:**

```
Time pequeno (2-5 devs, até 20 builds/dia)
→ 1 VM com Agent Direto (3.4)
   Custo: ~R$ 120/mês

Time médio (5-15 devs, até 50 builds/dia)
→ 2 VMs com Agent Direto (3.4)
   Custo: ~R$ 240-280/mês

Time grande (15+ devs, 50+ builds/dia)
→ Opção 1: 1 VM com 5 Docker Agents (3.5)
   Custo: ~R$ 140/mês
→ Opção 2: 3 VMs com Agent Direto (3.4)
   Custo: ~R$ 360-450/mês
   Mais simples, menos pontos de falha

Builds imprevisíveis/esporádicos
→ ACI (3.6)
   Custo: Paga só quando usa
```

---

### 3.8 Estratégia de Pools Recomendada

Depois de configurar seus agents, organize-os em pools:

| Pool Name | Tipo | Agentes | Uso |
|-----------|------|---------|-----|
| `Default` | Microsoft-hosted | N/A | PRs, testes rápidos |
| `Linux-Pool` | Self-hosted (VM) | 1-2 | Builds main/develop |
| `Linux-Heavy` | Self-hosted (VM) | 1 | Builds pesados |
| `Deploy-Prod` | Self-hosted (VM) | 1-2 | Deploy produção |

**Exemplo de uso em pipelines:**

```yaml
# Build rápido em PR
trigger:
  branches:
    include:
      - feature/*

pool:
  vmImage: 'ubuntu-latest'  # Microsoft-hosted

steps:
  - script: npm test

---
# Build principal
trigger:
  branches:
    include:
      - main
      - develop

pool:
  name: Linux-Pool  # Self-hosted

steps:
  - script: |
      dotnet build
      dotnet test
      dotnet publish
```

---

### 3.9 Próximos Passos

Você agora tem agents configurados! 🎉

**Checklist:**
- [ ] Agents aparecem como Online no Azure DevOps
- [ ] Testou pipeline simples
- [ ] Configurou PAT token para não expirar logo
- [ ] Documentou as credenciais/configurações

**Próximo:**
- **Fase 4:** Criar templates de CI/CD reutilizáveis
- **Fase 5:** Implementar estratégia de branching
- **Fase 6:** Configurar aprovações e gates

---

## Fase 4: Criação de Templates CI/CD

### 4.1 Estrutura de Templates

**Hierarquia:**
- **Steps** - Passos individuais reutilizáveis
- **Jobs** - Conjuntos de steps relacionados
- **Stages** - Agrupamento lógico de jobs

### 4.2 Template Base - Steps

**Install Dependencies (.NET):**

```yaml
# pipelines/templates/steps/install-dependencies-dotnet.yml
parameters:
  - name: dotnetVersion
    type: string
    default: '8.0.x'

steps:
  - task: UseDotNet@2
    displayName: 'Install .NET SDK'
    inputs:
      version: ${{ parameters.dotnetVersion }}
      includePreviewVersions: false

  - task: DotNetCoreCLI@2
    displayName: 'Restore NuGet packages'
    inputs:
      command: 'restore'
      projects: '**/*.csproj'
      feedsToUse: 'select'
```

**Run Tests (.NET):**

```yaml
# pipelines/templates/steps/run-tests-dotnet.yml
parameters:
  - name: testProjects
    type: string
    default: '**/*Tests.csproj'
  - name: configuration
    type: string
    default: 'Release'

steps:
  - task: DotNetCoreCLI@2
    displayName: 'Run Unit Tests'
    inputs:
      command: 'test'
      projects: '${{ parameters.testProjects }}'
      arguments: '--configuration ${{ parameters.configuration }} --collect:"XPlat Code Coverage" --logger trx'
      publishTestResults: true

  - task: PublishCodeCoverageResults@1
    displayName: 'Publish Code Coverage'
    inputs:
      codeCoverageTool: 'Cobertura'
      summaryFileLocation: '$(Agent.TempDirectory)/**/coverage.cobertura.xml'
```

**Build Docker Image:**

```yaml
# pipelines/templates/steps/build-docker-image.yml
parameters:
  - name: dockerfilePath
    type: string
    default: 'Dockerfile'
  - name: imageName
    type: string
  - name: imageTag
    type: string
    default: '$(Build.BuildId)'
  - name: containerRegistry
    type: string

steps:
  - task: Docker@2
    displayName: 'Build Docker Image'
    inputs:
      command: 'build'
      repository: '${{ parameters.imageName }}'
      dockerfile: '${{ parameters.dockerfilePath }}'
      tags: |
        ${{ parameters.imageTag }}
        latest

  - task: Docker@2
    displayName: 'Push Docker Image'
    inputs:
      command: 'push'
      repository: '${{ parameters.imageName }}'
      containerRegistry: '${{ parameters.containerRegistry }}'
      tags: |
        ${{ parameters.imageTag }}
        latest
```

### 4.3 Template Base - Jobs

**Build Job:**

```yaml
# pipelines/templates/jobs/build-job.yml
parameters:
  - name: jobName
    type: string
    default: 'Build'
  - name: pool
    type: string
    default: 'Linux-Docker-Pool'
  - name: dotnetVersion
    type: string
    default: '8.0.x'
  - name: buildConfiguration
    type: string
    default: 'Release'

jobs:
  - job: ${{ parameters.jobName }}
    displayName: 'Build Application'
    pool:
      name: ${{ parameters.pool }}
    
    steps:
      - checkout: self
        clean: true
        fetchDepth: 0

      - template: ../steps/install-dependencies-dotnet.yml
        parameters:
          dotnetVersion: ${{ parameters.dotnetVersion }}

      - task: DotNetCoreCLI@2
        displayName: 'Build Solution'
        inputs:
          command: 'build'
          projects: '**/*.csproj'
          arguments: '--configuration ${{ parameters.buildConfiguration }} --no-restore'

      - task: DotNetCoreCLI@2
        displayName: 'Publish Application'
        inputs:
          command: 'publish'
          publishWebProjects: true
          arguments: '--configuration ${{ parameters.buildConfiguration }} --output $(Build.ArtifactStagingDirectory)'
          zipAfterPublish: true

      - task: PublishBuildArtifacts@1
        displayName: 'Publish Artifacts'
        inputs:
          PathtoPublish: '$(Build.ArtifactStagingDirectory)'
          ArtifactName: 'drop'
          publishLocation: 'Container'
```

**Test Job:**

```yaml
# pipelines/templates/jobs/test-job.yml
parameters:
  - name: jobName
    type: string
    default: 'Test'
  - name: pool
    type: string
    default: 'Linux-Docker-Pool'
  - name: dependsOn
    type: object
    default: []

jobs:
  - job: ${{ parameters.jobName }}
    displayName: 'Run Tests'
    pool:
      name: ${{ parameters.pool }}
    dependsOn: ${{ parameters.dependsOn }}
    
    steps:
      - checkout: self
        clean: true

      - template: ../steps/install-dependencies-dotnet.yml

      - template: ../steps/run-tests-dotnet.yml
        parameters:
          testProjects: '**/*Tests.csproj'
          configuration: 'Release'

      - task: PublishTestResults@2
        displayName: 'Publish Test Results'
        condition: succeededOrFailed()
        inputs:
          testResultsFormat: 'VSTest'
          testResultsFiles: '**/*.trx'
          mergeTestResults: true
          failTaskOnFailedTests: true
```

**Security Scan Job:**

```yaml
# pipelines/templates/jobs/security-scan-job.yml
parameters:
  - name: jobName
    type: string
    default: 'SecurityScan'
  - name: pool
    type: string
    default: 'Linux-Docker-Pool'

jobs:
  - job: ${{ parameters.jobName }}
    displayName: 'Security Scanning'
    pool:
      name: ${{ parameters.pool }}
    
    steps:
      - checkout: self
        clean: true

      # OWASP Dependency Check
      - task: dependency-check-build-task@6
        displayName: 'OWASP Dependency Check'
        inputs:
          projectName: '$(Build.DefinitionName)'
          scanPath: '$(Build.SourcesDirectory)'
          format: 'HTML,JSON'
          suppressionPath: '$(Build.SourcesDirectory)/dependency-check-suppressions.xml'
        continueOnError: true

      # SonarQube Analysis
      - task: SonarQubePrepare@5
        displayName: 'Prepare SonarQube'
        inputs:
          SonarQube: 'SonarQubeConnection'
          scannerMode: 'MSBuild'
          projectKey: '$(Build.DefinitionName)'
          projectName: '$(Build.DefinitionName)'

      - task: DotNetCoreCLI@2
        displayName: 'Build for Analysis'
        inputs:
          command: 'build'

      - task: SonarQubeAnalyze@5
        displayName: 'Run SonarQube Analysis'

      - task: SonarQubePublish@5
        displayName: 'Publish Quality Gate'
        inputs:
          pollingTimeoutSec: '300'
```

### 4.4 Template Base - Stages

**Build Stage:**

```yaml
# pipelines/templates/stages/build-stage.yml
parameters:
  - name: stageName
    type: string
    default: 'Build'
  - name: pool
    type: string
    default: 'Linux-Docker-Pool'
  - name: runTests
    type: boolean
    default: true
  - name: runSecurityScan
    type: boolean
    default: true

stages:
  - stage: ${{ parameters.stageName }}
    displayName: 'Build & Test'
    jobs:
      - template: ../jobs/build-job.yml
        parameters:
          jobName: 'Build'
          pool: ${{ parameters.pool }}

      - ${{ if eq(parameters.runTests, true) }}:
        - template: ../jobs/test-job.yml
          parameters:
            jobName: 'Test'
            pool: ${{ parameters.pool }}
            dependsOn: ['Build']

      - ${{ if eq(parameters.runSecurityScan, true) }}:
        - template: ../jobs/security-scan-job.yml
          parameters:
            jobName: 'SecurityScan'
            pool: ${{ parameters.pool }}
```

**Deploy Stage:**

```yaml
# pipelines/templates/stages/deploy-stage.yml
parameters:
  - name: stageName
    type: string
  - name: environment
    type: string
  - name: pool
    type: string
    default: 'Deploy-Pool'
  - name: serviceConnection
    type: string
  - name: resourceGroup
    type: string
  - name: appServiceName
    type: string
  - name: dependsOn
    type: object
    default: []

stages:
  - stage: ${{ parameters.stageName }}
    displayName: 'Deploy to ${{ parameters.environment }}'
    dependsOn: ${{ parameters.dependsOn }}
    jobs:
      - deployment: Deploy
        displayName: 'Deploy Application'
        pool:
          name: ${{ parameters.pool }}
        environment: ${{ parameters.environment }}
        strategy:
          runOnce:
            deploy:
              steps:
                - download: current
                  artifact: drop

                - task: AzureWebApp@1
                  displayName: 'Deploy to Azure App Service'
                  inputs:
                    azureSubscription: '${{ parameters.serviceConnection }}'
                    appType: 'webAppLinux'
                    appName: '${{ parameters.appServiceName }}'
                    package: '$(Pipeline.Workspace)/drop/**/*.zip'
                    runtimeStack: 'DOTNETCORE|8.0'

                - task: AzureAppServiceManage@0
                  displayName: 'Restart App Service'
                  inputs:
                    azureSubscription: '${{ parameters.serviceConnection }}'
                    Action: 'Restart Azure App Service'
                    WebAppName: '${{ parameters.appServiceName }}'
```

### 4.5 Pipeline Completo - Exemplo

```yaml
# pipelines/examples/dotnet-api-pipeline.yml
trigger:
  branches:
    include:
      - main
      - develop
      - release/*
  paths:
    exclude:
      - docs/*
      - README.md

pr:
  branches:
    include:
      - main
      - develop
  paths:
    exclude:
      - docs/*

variables:
  - name: buildConfiguration
    value: 'Release'
  - name: dotnetVersion
    value: '8.0.x'

resources:
  repositories:
    - repository: templates
      type: git
      name: Templates-CICD/templates-cicd
      ref: refs/heads/main

stages:
  # Build & Test
  - template: pipelines/templates/stages/build-stage.yml@templates
    parameters:
      stageName: 'Build'
      pool: 'Linux-Docker-Pool'
      runTests: true
      runSecurityScan: true

  # Deploy DEV
  - template: pipelines/templates/stages/deploy-stage.yml@templates
    parameters:
      stageName: 'DeployDev'
      environment: 'Development'
      serviceConnection: 'Azure-Dev'
      resourceGroup: 'rg-app-dev'
      appServiceName: 'app-api-dev'
      dependsOn: ['Build']

  # Deploy QA
  - template: pipelines/templates/stages/deploy-stage.yml@templates
    parameters:
      stageName: 'DeployQA'
      environment: 'QA'
      serviceConnection: 'Azure-QA'
      resourceGroup: 'rg-app-qa'
      appServiceName: 'app-api-qa'
      dependsOn: ['DeployDev']

  # Deploy Production (manual approval)
  - template: pipelines/templates/stages/deploy-stage.yml@templates
    parameters:
      stageName: 'DeployProduction'
      environment: 'Production'
      serviceConnection: 'Azure-Prod'
      resourceGroup: 'rg-app-prod'
      appServiceName: 'app-api-prod'
      dependsOn: ['DeployQA']
```

---

## Fase 5: Implementação de Pipelines

### 5.1 Configuração de Environments

1. **Criar Environments**
   - Pipelines → Environments → New Environment
   - Criar: Development, QA, Production

2. **Configurar Approvals & Checks (Production)**
   - Environment → Production → Approvals and checks
   - Add check → Approvals
   - Approvers: DevOps Lead, Product Owner
   - Timeout: 30 dias

3. **Branch Control**
   - Add check → Branch control
   - Allowed branches: `refs/heads/main`, `refs/heads/release/*`

### 5.2 Configuração de Variable Groups

```bash
# Via Azure DevOps CLI

# Development
az pipelines variable-group create --name "Dev-Variables" --variables AppServiceName="app-api-dev" ResourceGroup="rg-app-dev" Environment="Development"

# QA
az pipelines variable-group create --name "QA-Variables" --variables AppServiceName="app-api-qa" ResourceGroup="rg-app-qa" Environment="QA"

# Production
az pipelines variable-group create --name "Prod-Variables" --variables AppServiceName="app-api-prod" ResourceGroup="rg-app-prod" Environment="Production"
```

### 5.3 Criar Pipeline no Projeto

1. **Via Interface**
   - Pipelines → New Pipeline
   - Azure Repos Git
   - Select repository
   - Existing Azure Pipelines YAML file
   - Select: `/azure-pipelines.yml`

2. **Variables da Pipeline**
   - Edit pipeline → Variables
   - Link variable groups criados
   - Add secrets se necessário

### 5.4 Primeira Execução

1. **Validar pipeline**
   - Run pipeline
   - Review logs de cada stage
   - Verificar artifacts gerados

2. **Troubleshooting comum**
   - Agent não disponível → Verificar pool
   - Permissões → Verificar service connection
   - Tests falhando → Verificar ambiente

---

## Fase 6: Segurança e Governança

### 6.1 Secrets Management

**Azure Key Vault Integration:**

```yaml
# Pipeline com Key Vault
variables:
  - group: 'Prod-Variables'
  - name: keyVaultName
    value: 'kv-app-prod'

steps:
  - task: AzureKeyVault@2
    displayName: 'Get Secrets from Key Vault'
    inputs:
      azureSubscription: 'Azure-Prod'
      KeyVaultName: '$(keyVaultName)'
      SecretsFilter: '*'
      RunAsPreJob: true

  - script: |
      echo "Using secret from Key Vault"
      # Secret está disponível como variável de ambiente
    displayName: 'Use Secret'
    env:
      DATABASE_PASSWORD: $(DatabasePassword)
```

### 6.2 Branch Policies

```yaml
# Adicionar Build Validation
# Repos → Branches → main → Branch Policies

Build validation:
  - Build pipeline: CI Pipeline
  - Path filter: /**
  - Trigger: Automatic
  - Policy requirement: Required
  - Build expiration: 12 hours
```

### 6.3 Pipeline Permissions

1. **Repository permissions**
   - Settings → Repositories → Security
   - Limitar quem pode criar/editar pipelines

2. **Pipeline permissions**
   - Pipelines → ... → Security
   - Definir quem pode executar, editar, visualizar

3. **Service Connection permissions**
   - Project Settings → Service connections
   - Desabilitar "Grant access to all pipelines"
   - Autorizar pipelines específicas

### 6.4 Audit & Compliance

1. **Ativar logs de auditoria**
   - Organization Settings → Auditing
   - Stream logs para Log Analytics

2. **Retention policies**
   - Project Settings → Retention
   - Builds: 30 dias (ajustar conforme necessário)
   - Releases: 90 dias
   - Test results: 30 dias

---

## Fase 7: Monitoramento e Otimização

### 7.1 Analytics & Reporting

1. **Pipeline Analytics**
   - Pipelines → Analytics
   - Monitorar:
     - Pass rate
     - Duration
     - Failure trends

2. **Test Analytics**
   - Test Plans → Analytics
   - Test pass rate
   - Flaky tests
   - Coverage trends

### 7.2 Otimizações

**Cache de dependências:**

```yaml
# Exemplo de cache para NuGet
steps:
  - task: Cache@2
    displayName: 'Cache NuGet packages'
    inputs:
      key: 'nuget | "$(Agent.OS)" | **/packages.lock.json'
      path: '$(UserProfile)\.nuget\packages'
      restoreKeys: |
        nuget | "$(Agent.OS)"

  - task: DotNetCoreCLI@2
    displayName: 'Restore'
    inputs:
      command: 'restore'
```

**Parallel jobs:**

```yaml
jobs:
  - job: Test_Unit
    displayName: 'Unit Tests'
    steps:
      - template: test-steps.yml
  
  - job: Test_Integration
    displayName: 'Integration Tests'
    steps:
      - template: integration-test-steps.yml
```

### 7.3 Alerts & Notifications

**Service Hooks:**

1. **Slack Integration**
   - Project Settings → Service hooks
   - New subscription → Slack
   - Trigger: Build completed
   - Filter: Only failed builds

2. **Email Notifications**
   - User Settings → Notifications
   - Configure por pipeline
   - Build failed, tests failed, etc.

---

## Cronograma Estimado

### Timeline Padrão

| Fase | Duração | Dependências |
|------|---------|--------------|
| **Fase 1**: Setup Azure DevOps | 1-2 dias | Contas e acessos |
| **Fase 2**: Estrutura de Repos | 1 dia | Fase 1 |
| **Fase 3**: Configuração Agents | 2-3 dias | Fase 1, infraestrutura |
| **Fase 4**: Criação Templates | 3-5 dias | Fase 2 |
| **Fase 5**: Implementação Pipelines | 2-3 dias | Fases 3 e 4 |
| **Fase 6**: Segurança | 2 dias | Fase 5 |
| **Fase 7**: Monitoramento | 1-2 dias | Fase 5 |
| **Buffer/Testes** | 2-3 dias | Todas |
| **TOTAL** | **14-21 dias** | - |

---

### ⚡ Timeline Acelerado (com self-hosted agents primeiro)

**Recomendado se você não tem paralelismo de Microsoft-hosted agents:**

| Fase | Duração | Notas |
|------|---------|-------|
| **Fase 1**: Setup Azure DevOps | 1-2 dias | Incluindo solicitar grant gratuito |
| **Fase 2**: Estrutura de Repos | 1 dia | Pode fazer em paralelo com Fase 3 |
| **Fase 3**: Configuração Agents | 2-3 dias | **PRIORIDADE** - Faz logo após Fase 1 |
| **Fase 4**: Criação Templates | 3-5 dias | Já pode testar com self-hosted agents |
| **Fase 5**: Implementação Pipelines | 2-3 dias | Usando self-hosted agents |
| **Fase 6**: Segurança | 2 dias | - |
| **Fase 7**: Monitoramento | 1-2 dias | - |
| Grant gratuito aprovado | 2-14 dias | **Em paralelo**, não bloqueia projeto |
| **TOTAL** | **14-21 dias** | Grant não afeta timeline! |

---

### 📝 Notas Importantes sobre o Cronograma

**1. Paralelismo Microsoft-hosted:**
- ⏱️ Grant gratuito pode levar 2-3 dias a 2 semanas
- 💡 **NÃO espere o grant**: configure self-hosted agents (Fase 3 primeiro)
- ✅ Grant aprovado = bônus adicional, não é bloqueante

**2. Flexibilidade de Ordem:**
- Fase 3 pode ser feita **imediatamente após Fase 1**
- Fases 2 e 3 podem ser **executadas em paralelo** por pessoas diferentes
- Fase 4 só precisa de Fase 2 (estrutura de repos)
- Fase 5 precisa de Fases 3 e 4

**3. Ordem Recomendada para Novos Projetos:**
```
Fase 1 → Fase 2 + Fase 3 (paralelo) → Fase 4 → Fase 5 → Fase 6 → Fase 7
        ↓
    Solicitar grant (não bloqueia)
```

**4. Marcos Críticos:**
- ✅ Dia 3-4: Self-hosted agents funcionando
- ✅ Dia 5-6: Estrutura de templates pronta
- ✅ Dia 8-10: Primeira pipeline funcionando
- ✅ Dia 14-21: Implementação completa

---

### 🚀 Quick Start (Mínimo Viável)

Se você quer começar a usar CI/CD o mais rápido possível:

**Dia 1:**
- Criar organização Azure DevOps
- Criar projeto
- Solicitar grant gratuito (formulário)
- Criar service connection

**Dia 2-3:**
- Configurar 1 self-hosted agent (Docker básico)
- Criar estrutura mínima de repositório

**Dia 4-5:**
- Criar 2-3 templates básicos (build, test, deploy)
- Primeira pipeline funcionando

**Dia 6+:**
- Incrementar templates
- Adicionar segurança
- Expandir para mais projetos

**Resultado:** Pipeline básica funcionando em **5 dias**, sem depender de Microsoft-hosted agents.

---

## Boas Práticas

### Pipeline Design

✅ **DRY (Don't Repeat Yourself)**
- Use templates para código comum
- Parametrize tudo que pode variar
- Centralize configurações em variable groups

✅ **Fail Fast**
- Execute testes rápidos primeiro
- Valide sintaxe antes de build completo
- Use pre-deployment checks

✅ **Incremental Builds**
- Use path filters em triggers
- Implemente caching agressivo
- Compile apenas o que mudou

✅ **Security First**
- Nunca commit secrets no código
- Use Azure Key Vault
- Rotate credentials regularmente
- Principle of least privilege

✅ **Observable**
- Logs detalhados mas organizados
- Métricas de pipeline
- Alertas para falhas
- Dashboards de status

### Templates Best Practices

✅ **Versionamento**
- Use tags/branches específicas: `@templates#v1.0`
- Documente breaking changes
- Mantenha changelog

✅ **Documentação**
- Documente cada parâmetro
- Forneça exemplos de uso
- README em cada template

✅ **Testes**
- Teste templates em projeto sandbox
- Valide com diferentes parâmetros
- CI para o repositório de templates

### Agent Management

✅ **Escalabilidade**
- Monitore fila de builds
- Auto-scale em horários de pico
- Use Azure Container Instances/AKS

✅ **Manutenção**
- Atualize imagens regularmente
- Monitore uso de recursos
- Clean up de workspace

✅ **Segurança**
- Minimize ferramentas instaladas
- Use imagens base verificadas
- Isole agents por sensitivity

### Deployment Practices

✅ **Blue-Green / Canary**
- Minimize downtime
- Rollback rápido
- Teste em produção com tráfego limitado

✅ **Infrastructure as Code**
- Trate infra como código
- Versione arquivos Terraform/Bicep
- Pipeline para infraestrutura

✅ **Database Migrations**
- Sempre backward compatible
- Rollback strategy
- Teste em ambientes inferiores

---

## Recursos Adicionais

### Documentação Oficial
- [Azure DevOps Documentation](https://docs.microsoft.com/azure/devops/)
- [YAML Schema Reference](https://docs.microsoft.com/azure/devops/pipelines/yaml-schema)
- [Azure Pipelines Tasks](https://docs.microsoft.com/azure/devops/pipelines/tasks/)

### Ferramentas Úteis
- [Azure DevOps CLI](https://docs.microsoft.com/cli/azure/devops)
- [VS Code Azure Pipelines Extension](https://marketplace.visualstudio.com/items?itemName=ms-azure-devops.azure-pipelines)
- [Pipeline Decorators](https://docs.microsoft.com/azure/devops/extend/develop/add-pipeline-decorator)

### Comunidade
- [Azure DevOps Blog](https://devblogs.microsoft.com/devops/)
- [Stack Overflow - Azure DevOps](https://stackoverflow.com/questions/tagged/azure-devops)
- [GitHub - Azure Pipelines YAML samples](https://github.com/microsoft/azure-pipelines-yaml)

---

## Checklist Final

Antes de considerar a implementação completa:

- [ ] Organização Azure DevOps configurada
- [ ] Projetos criados com permissões adequadas
- [ ] Service connections funcionando
- [ ] **Paralelismo resolvido (grant aprovado OU self-hosted agents configurados)**
- [ ] Agent pools configurados e operacionais (pelo menos 1 agent online)
- [ ] Repositório de templates estruturado
- [ ] Templates base criados e documentados
- [ ] Pipelines de exemplo funcionando
- [ ] Environments criados com approvals
- [ ] Variable groups configurados
- [ ] Segredos em Key Vault
- [ ] Branch policies aplicadas
- [ ] Monitoramento e alertas ativos
- [ ] Documentação completa
- [ ] Equipe treinada

### Validação Mínima para "Go Live"

O mínimo necessário para começar a usar em desenvolvimento:

- [x] Organização e projeto criados
- [x] Service connection Azure funcionando
- [x] **Pelo menos 1 self-hosted agent online** (crítico!)
- [x] Repositório de templates básico
- [x] 3 templates funcionando (build, test, deploy)
- [x] 1 pipeline end-to-end funcionando
- [x] Variable groups para ambientes
- [ ] Environments com approvals (pode vir depois)
- [ ] Segurança completa (pode vir depois)
- [ ] Monitoramento (pode vir depois)

---

**Versão:** 1.0  
**Última atualização:** Janeiro 2026  
**Mantido por:** DevOps Team