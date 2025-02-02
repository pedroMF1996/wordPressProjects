[CmdletBinding()]
param(
    [string]$ProjectName = "",
    [switch]$Help
)

# Configuracao de encoding para UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# Funcoes de mensagem
function Write-InfoMessage {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Cyan
}

function Write-SuccessMessage {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

function Write-WarningMessage {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Yellow
}

# Mostra ajuda se solicitado
if ($Help) {
    Write-Host @"
Uso: .\start-project.ps1 [-ProjectName <nome>] [-Help]

Parametros:
    -ProjectName   Nome do projeto WordPress (ex: meu-blog, loja-virtual)
                  Se nao especificado, usa o nome da pasta atual
    -Help         Mostra esta mensagem de ajuda

Exemplo:
    .\start-project.ps1 -ProjectName "meu-blog"
"@
    exit 0
}

# Funcao para validar o nome do projeto
function Test-ProjectName {
    param([string]$Name)
    
    if ($Name -match '[^a-z0-9\-]') {
        Write-ErrorMessage "ERRO: Nome do projeto '$Name' invalido."
        Write-ErrorMessage "Use apenas letras minusculas, numeros e hifens."
        Write-ErrorMessage "Exemplo: meu-blog, loja-virtual"
        return $false
    }
    return $true
}

# Funcao para verificar se o Docker esta rodando
function Test-DockerRunning {
    try {
        $null = docker info 2>&1
        return $true
    }
    catch {
        Write-ErrorMessage "ERRO: Docker nao esta rodando!"
        Write-ErrorMessage "Por favor, inicie o Docker Desktop e tente novamente."
        return $false
    }
}

# Funcao para verificar portas em uso
function Test-PortInUse {
    param([int]$Port)
    
    try {
        $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $Port)
        $listener.Start()
        $listener.Stop()
        return $false
    }
    catch {
        return $true
    }
}

# Lista de portas comumente usadas por outros softwares
$RESERVED_PORTS = @{
    # Plataformas de Jogos
    'Steam' = @(
        (27015..27050),  # Jogos Source e servidores
        (27014..27015),  # Steam download
        (27036..27037),  # Steam Remote Play
        4380,            # Steam cliente
        (3478..3479),    # Steam P2P
        (4379..4380),    # Steam amigos
        (7680..7681)     # Steam HTTP
    )
    'Epic Games' = @(
        5222,            # Epic Games Store
        (5795..5847),    # Fortnite
        (5848..5850),    # Epic Online Services
        (9000..9100)     # Epic Games geral
    )
    'Battle.net' = @(
        1119,            # Battle.net
        1120,            # Battle.net
        3724,            # Cliente Battle.net
        4000,            # Cliente Battle.net
        6012,            # Cliente Battle.net
        (6112..6119)     # Battle.net jogos
    )
    'Origin' = @(
        3216,            # Origin cliente
        (9960..9969),    # Origin cliente
        8080,            # Origin web helper
        (1024..1124)     # Origin jogos
    )
    'Ubisoft Connect' = @(
        12345,           # Ubisoft Connect
        14000,           # Ubisoft Connect
        14008,           # Ubisoft Connect
        (14020..14025)   # Ubisoft jogos
    )
    'GOG Galaxy' = @(
        6688,            # GOG Galaxy cliente
        (27015..27030),  # GOG Galaxy multiplayer
        (6121..6125)     # GOG Galaxy network
    )
    'Xbox Game Pass' = @(
        3074,            # Xbox Live
        3544,            # Xbox Live
        (500..550),      # Xbox networking
        (3075..3076),    # Xbox multiplayer
        (3070..3080)     # Xbox Game Pass
    )
    'PlayStation Network' = @(
        (3478..3480),    # PSN
        3658,            # PSN
        1935,            # PSN streaming
        5223             # PSN notifications
    )
    'Nintendo Switch Online' = @(
        (45000..45999),  # Nintendo Switch Online
        (50000..50999),  # Nintendo jogos online
        57120            # Nintendo eShop
    )

    # Jogos populares
    'Minecraft' = @(
        25565,           # Java Edition
        (19132..19133)   # Bedrock Edition
    )
    'League of Legends' = @(
        2099,            # Cliente
        (5222..5223),    # Comunicação
        (8393..8400),    # Jogo
        8088,            # Chat
        (5000..5500)     # Riot Client
    )
    'Valorant' = @(
        (7081..7082),    # Cliente
        8088,            # Chat
        (8393..8400),    # Jogo
        (49152..65535)   # Range dinâmico
    )
    'Counter-Strike' = @(
        (27015..27030),  # Servidores
        (27000..27100),  # Steam datagram
        (27014..27050)   # Matchmaking
    )
    'Dota 2' = @(
        (27015..27030),  # Servidores
        (27014..27050),  # Matchmaking
        (28015..28020)   # Fonte 2
    )
    'Overwatch' = @(
        (27015..27030),  # Blizzard
        1119,            # Battle.net
        3724,            # Matchmaking
        (5060..5062)     # Voice chat
    )
    'Fortnite' = @(
        (5222..5223),    # Epic Online Services
        (5795..5847),    # Fortnite
        (9000..9100)     # Epic Games
    )

    # Outros serviços
    'PostgreSQL' = 5432
    'MongoDB' = 27017
    'Redis' = 6379
    'Elasticsearch' = 9200
    'HTTP' = 80
    'HTTPS' = 443
    'FTP' = @(20, 21)
    'SSH' = 22
    'SMTP' = 25
    'DNS' = 53
    'Remote Desktop' = 3389
    'VS Code Debug' = @(5555, 9229)
    'Node.js Default' = 3000
    'React Default' = 3000
    'Vue.js Default' = 8080
    'Angular Default' = 4200
    'Spring Boot' = 8080
    'Jenkins' = 8080
    'Tomcat' = 8080
    'Skype' = @(50000..50019)
    'Discord RPC' = @(6463..6472)
    'Printer Services' = 631
    'Windows File Sharing' = @(135, 139, 445)
}

# Funcao para verificar se uma porta esta na lista de reservadas
function Test-ReservedPort {
    param([int]$Port)
    
    foreach ($service in $RESERVED_PORTS.Keys) {
        $reservedPorts = $RESERVED_PORTS[$service]
        
        # Se for um array de ranges, expanda cada range
        if ($reservedPorts -is [array]) {
            foreach ($portRange in $reservedPorts) {
                if ($portRange -is [array]) {
                    # Se é um range (ex: 27015..27030)
                    $start = $portRange[0]
                    $end = $portRange[-1]
                    if ($Port -ge $start -and $Port -le $end) {
                        Write-InfoMessage "Porta $Port e usada por $service (range $start-$end)"
                        return $true
                    }
                } else {
                    # Se é uma porta unica
                    if ($Port -eq $portRange) {
                        Write-InfoMessage "Porta $Port e usada por $service"
                        return $true
                    }
                }
            }
        } else {
            # Se é uma unica porta
            if ($Port -eq $reservedPorts) {
                Write-InfoMessage "Porta $Port e usada por $service"
                return $true
            }
        }
    }
    return $false
}

# Funcao para encontrar proxima porta disponivel
function Get-NextAvailablePort {
    param(
        [int]$StartPort,
        [string]$PortType
    )
    
    $currentPort = $StartPort
    $maxAttempts = 100  # Evita loop infinito
    $attempts = 0
    
    while ($attempts -lt $maxAttempts) {
        # Verifica se a porta esta na lista de reservadas
        if (Test-ReservedPort -Port $currentPort) {
            Write-InfoMessage "Porta $currentPort esta reservada, tentando proxima..."
            $currentPort++
            $attempts++
            continue
        }
        
        # Verifica se a porta esta em uso
        if (Test-PortInUse -Port $currentPort) {
            Write-InfoMessage "Porta $currentPort esta em uso, tentando proxima..."
            $currentPort++
            $attempts++
            continue
        }
        
        # Porta disponivel encontrada
        Write-SuccessMessage "Porta $currentPort disponivel para $PortType"
        return $currentPort
    }
    
    throw "Nao foi possivel encontrar uma porta disponivel apos $maxAttempts tentativas"
}

# Funcao para validar intervalo de portas
function Test-PortRange {
    param(
        [int]$Port,
        [string]$PortType
    )
    
    # Portas abaixo de 1024 sao privilegiadas
    if ($Port -lt 1024) {
        Write-ErrorMessage "ERRO: Porta $Port para $PortType e uma porta privilegiada"
        return $false
    }
    
    # Portas validas vao ate 65535
    if ($Port -gt 65535) {
        Write-ErrorMessage "ERRO: Porta $Port para $PortType e invalida (maximo e 65535)"
        return $false
    }
    
    return $true
}

Write-InfoMessage "=== Iniciando configuracao do projeto WordPress ==="

# Validar nome do projeto
if ([string]::IsNullOrEmpty($ProjectName)) {
    $ProjectName = Split-Path -Leaf (Get-Location)
}

if (-not (Test-ProjectName -Name $ProjectName)) {
    exit 1
}

# Verificar se o Docker esta rodando
Write-InfoMessage "Verificando status do Docker"
if (-not (Test-DockerRunning)) {
    exit 1
}

# Procurar portas disponiveis com validacao melhorada
Write-InfoMessage "Procurando portas disponiveis..."

# WordPress - tenta a partir da porta 8000
$wpPort = Get-NextAvailablePort -StartPort 8000 -PortType "WordPress"
if (-not (Test-PortRange -Port $wpPort -PortType "WordPress")) {
    exit 1
}

# MySQL - tenta a partir da porta 3306
$mysqlPort = Get-NextAvailablePort -StartPort 3306 -PortType "MySQL"
if (-not (Test-PortRange -Port $mysqlPort -PortType "MySQL")) {
    exit 1
}

# Adminer - tenta a partir da porta 8080
$adminerPort = Get-NextAvailablePort -StartPort 8080 -PortType "Adminer"
if (-not (Test-PortRange -Port $adminerPort -PortType "Adminer")) {
    exit 1
}

Write-InfoMessage "Portas selecionadas:"
Write-InfoMessage "WordPress: $wpPort"
Write-InfoMessage "MySQL: $mysqlPort"
Write-InfoMessage "Adminer: $adminerPort"

try {
    # Remover containers antigos se existirem
    Write-InfoMessage "Removendo containers antigos se existirem..."
    docker-compose down 2>&1 | Out-Null

    # Criar arquivo .env a partir do template
    Write-InfoMessage "Configurando variaveis de ambiente..."
    $envContent = Get-Content .env.development -Raw
    $envContent = $envContent.Replace("COMPOSE_PROJECT_NAME=default", "COMPOSE_PROJECT_NAME=$ProjectName")
    $envContent = $envContent.Replace("WORDPRESS_PORT=8000", "WORDPRESS_PORT=$wpPort")
    $envContent = $envContent.Replace("MYSQL_PORT=3306", "MYSQL_PORT=$mysqlPort")
    $envContent = $envContent.Replace("ADMINER_PORT=8080", "ADMINER_PORT=$adminerPort")
    $envContent | Set-Content .env -Force

    # Iniciar containers
    Write-InfoMessage "Iniciando containers Docker..."
    docker-compose up -d

    # Aguardar containers estarem saudaveis
    Write-InfoMessage "Aguardando containers iniciarem..."
    $maxAttempts = 30
    $attempts = 0
    $allHealthy = $false

    while (-not $allHealthy -and $attempts -lt $maxAttempts) {
        $attempts++
        Start-Sleep -Seconds 1
        
        $mysqlStatus = docker inspect -f '{{.State.Health.Status}}' "$ProjectName-mysql" 2>&1
        $wpStatus = docker ps -q -f name="$ProjectName-wordpress" 2>&1
        
        if ($mysqlStatus -eq "healthy" -and $wpStatus) {
            $allHealthy = $true
        }
    }

    if (-not $allHealthy) {
        throw "Timeout aguardando containers iniciarem"
    }

    Write-SuccessMessage "=== Configuracao concluida com sucesso! ==="
    Write-Host "Acesse seu projeto em http://localhost:$wpPort"
    Write-Host "Adminer disponivel em http://localhost:$adminerPort"
    Write-Host "MySQL disponivel na porta $mysqlPort"
}
catch {
    Write-ErrorMessage "ERRO: Falha ao configurar o projeto:"
    Write-ErrorMessage $_.Exception.Message
    Write-ErrorMessage "Tentando limpar recursos..."
    docker-compose down 2>&1 | Out-Null
    exit 1
}
