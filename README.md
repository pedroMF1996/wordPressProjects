# WordPress Projects

Este é um ambiente de desenvolvimento WordPress completo usando Docker, com suporte para desenvolvimento de temas e plugins personalizados.

## Estrutura do Projeto

```
wordPressProjects/
├── docker-compose.yml    # Configuração dos containers Docker
├── .env                  # Variáveis de ambiente
├── meu-tema/            # Diretório do tema personalizado
├── meu-plugin/          # Diretório do plugin personalizado
└── uploads/             # Diretório para uploads do WordPress
```

## Pré-requisitos

- Docker Desktop instalado e em execução
- Docker Compose instalado
- Git (opcional, para versionamento)

## Configuração Inicial

1. Crie um arquivo `.env` na raiz do projeto com as seguintes variáveis:

```env
WORDPRESS_PORT=8080
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wordpress
WORDPRESS_DB_PASSWORD=wordpress_password

MYSQL_ROOT_PASSWORD=somewordpress
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress
MYSQL_PASSWORD=wordpress_password
MYSQL_PORT=3306
MYSQL_MEMORY_LIMIT=1G
MYSQL_MEMORY_RESERVATION=500M

ADMINER_PORT=8888
```

2. Crie os diretórios necessários:

```powershell
mkdir meu-tema
mkdir meu-plugin
mkdir uploads
```

## Iniciando o Ambiente

1. Abra o terminal na pasta do projeto

2. Inicie os containers:
```powershell
docker-compose up -d
```

3. Aguarde alguns segundos até todos os serviços estarem prontos

## Acessando os Serviços

- WordPress: http://localhost:8080
- Adminer (gerenciador do banco de dados): http://localhost:8888
  - Sistema: MySQL
  - Servidor: mysql
  - Usuário: wordpress
  - Senha: wordpress_password
  - Banco de dados: wordpress

## Desenvolvimento

### Tema Personalizado
- Coloque os arquivos do seu tema na pasta `meu-tema/`
- O tema estará disponível para ativação no painel do WordPress

### Plugin Personalizado
- Coloque os arquivos do seu plugin na pasta `meu-plugin/`
- O plugin estará disponível para ativação no painel do WordPress

### Uploads
- Os arquivos enviados através do WordPress serão armazenados na pasta `uploads/`

## Comandos Úteis

### Iniciar os containers
```powershell
docker-compose up -d
```

### Parar os containers
```powershell
docker-compose down
```

### Ver logs dos containers
```powershell
docker-compose logs
```

### Reiniciar um serviço específico
```powershell
docker-compose restart wordpress
```

## Solução de Problemas

### Problemas de Permissão
Se encontrar problemas de permissão ao fazer upload de arquivos:
1. Verifique se a pasta `uploads/` existe na raiz do projeto
2. Reinicie os containers com `docker-compose down` seguido de `docker-compose up -d`

### Problemas de Conexão com o Banco de Dados
1. Verifique se as credenciais no arquivo `.env` estão corretas
2. Confirme se o container do MySQL está rodando: `docker-compose ps`
3. Verifique os logs do MySQL: `docker-compose logs mysql`

## Backup

### Banco de Dados
Para fazer backup do banco de dados:
```powershell
docker exec mysql-container mysqldump -u wordpress -pwordpress_password wordpress > backup.sql
```

### Arquivos
Os arquivos importantes já estão em seu sistema local nas pastas:
- `meu-tema/`
- `meu-plugin/`
- `uploads/`

## Segurança

- Altere todas as senhas no arquivo `.env` antes de usar em produção
- Nunca compartilhe seu arquivo `.env` com credenciais reais
- Mantenha o Docker e todas as imagens atualizadas
