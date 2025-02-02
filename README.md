# WordPress Docker Development Environment

Ambiente de desenvolvimento WordPress otimizado usando Docker, com suporte a múltiplos projetos, alocação dinâmica de portas e proteção contra conflitos com jogos e outras aplicações.

## 🚀 Início Rápido

1. Clone o repositório:
   ```powershell
   git clone <repository-url>
   cd wordPressProjects
   ```

2. Inicie um novo projeto:
   ```powershell
   # Usando o nome da pasta atual
   .\start-project.ps1

   # OU especificando um nome personalizado
   .\start-project.ps1 -ProjectName "meu-blog"
   ```

3. Acesse seu projeto:
   - WordPress: http://localhost:<porta> (mostrada ao final da execução)
   - Adminer: http://localhost:<porta> (mostrada ao final da execução)

## 🛡️ Proteção de Portas

O sistema inclui proteção inteligente contra conflitos de portas com:

### 🎮 Plataformas de Jogos
- Steam (incluindo Remote Play)
- Epic Games Store
- Battle.net
- Origin
- Ubisoft Connect
- GOG Galaxy
- Xbox Game Pass
- PlayStation Network
- Nintendo Switch Online

### 🎯 Jogos Populares
- Minecraft (Java e Bedrock)
- League of Legends
- Valorant
- Counter-Strike
- Dota 2
- Overwatch
- Fortnite

### 🔌 Serviços de Jogos
- Voice chat
- Matchmaking
- Servidores dedicados
- P2P networking
- Comunicação em tempo real

### 🖥️ Outros Serviços
- Bancos de dados (MySQL, PostgreSQL, MongoDB)
- Serviços web (HTTP, HTTPS)
- IDEs e ferramentas de desenvolvimento
- Serviços de sistema

## 🛠️ Estrutura do Projeto

```
wordPressProjects/
├── meu-tema/           # Seus temas personalizados
├── meu-plugin/         # Seus plugins personalizados
├── uploads/            # Arquivos de mídia do WordPress
├── .env.development    # Template para ambiente de desenvolvimento
├── .env.production     # Template para ambiente de produção
├── docker-compose.yml  # Configuração dos containers
└── start-project.ps1   # Script de inicialização
```

## 📋 Pré-requisitos

- Docker Desktop para Windows
- PowerShell 5.1 ou superior
- Git (opcional, para versionamento)

## 🔧 Configuração

### Arquivos de Ambiente

1. `.env.development`: Template para desenvolvimento local
   - Base para novos projetos
   - **NÃO EDITE** diretamente, é usado como template

2. `.env.production`: Template para produção
   - Use para deploy em produção
   - Ajuste senhas e configurações antes do uso

3. `.env`: Arquivo de configuração ativo
   - Gerado automaticamente pelo script
   - **NÃO EDITE** manualmente

### Script de Inicialização

O script `start-project.ps1` possui as seguintes opções:

```powershell
.\start-project.ps1 [-ProjectName <nome>] [-Help]

Parâmetros:
  -ProjectName   Nome do projeto (ex: meu-blog)
                Se omitido, usa o nome da pasta atual
  -Help         Mostra a ajuda
```

### 🔄 Sistema de Portas Dinâmicas

O sistema de alocação de portas:
1. Verifica portas em uso por jogos e aplicações
2. Identifica serviços que usam cada porta
3. Encontra automaticamente portas disponíveis
4. Evita conflitos com:
   - Portas de sistema (<1024)
   - Portas reservadas
   - Ranges dinâmicos de jogos
   - Serviços em execução

### Containers e Nomes

Cada projeto terá seus próprios containers com nomes únicos:
- `<projeto>-wordpress`: Servidor WordPress
- `<projeto>-mysql`: Banco de dados MySQL 8.0
- `<projeto>-adminer`: Interface do Adminer

## 📦 Volumes

Cada projeto mantém seus dados em volumes Docker separados:
- `<projeto>_wordpress-data`: Arquivos do WordPress
- `<projeto>_mysql_data`: Dados do MySQL
- `<projeto>_mysql_logs`: Logs do MySQL

## 🔐 Segurança

- Senhas padrão apenas para desenvolvimento
- Use `.env.production` com senhas fortes para produção
- Arquivos `.env` são ignorados pelo Git
- Proteção contra conflitos de porta
- Validação de nomes de projeto

## 🚀 Desenvolvimento

1. **Temas Personalizados**:
   - Coloque seus temas na pasta `meu-tema/`
   - Serão montados automaticamente em `wp-content/themes/`

2. **Plugins Personalizados**:
   - Coloque seus plugins na pasta `meu-plugin/`
   - Serão montados automaticamente em `wp-content/plugins/`

3. **Uploads**:
   - Arquivos de mídia são persistidos na pasta `uploads/`
   - Montados automaticamente em `wp-content/uploads/`

## 🐛 Depuração

O ambiente de desenvolvimento inclui:
- WordPress Debug Mode ativado
- Log de erros habilitado
- Display de erros ativado
- Mensagens detalhadas sobre portas em uso

## 📝 Logs

- Logs do WordPress: `wp-content/debug.log`
- Logs do MySQL: Volume `mysql_logs`
- Logs do Docker: `docker logs <container-name>`

## 🔄 Comandos Úteis

```powershell
# Ver status dos containers
docker ps

# Ver logs de um container
docker logs <projeto>-wordpress

# Parar todos os containers
docker-compose down

# Remover todos os dados
docker-compose down -v
```