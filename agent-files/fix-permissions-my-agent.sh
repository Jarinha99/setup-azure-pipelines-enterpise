# Mandatory to work on GCP VM

# 1. Verificar dono dos arquivos
ls -la ~/myagent/_diag

# Se mostrar 'root' como dono, esse é o problema!
# Exemplo: drwxr-xr-x 2 root root ...

# 2. Corrigir ownership de TODO o diretório myagent
sudo chown -R $USER:$USER ~/myagent

# 3. Garantir permissões de escrita
chmod -R u+w ~/myagent

# 4. Verificar que está correto agora
ls -la ~/myagent/_diag
# Deve mostrar seu usuário: drwxr-xr-x 2 gjara_dev gjara_dev ...

# 5. Tentar rodar novamente
./run.sh