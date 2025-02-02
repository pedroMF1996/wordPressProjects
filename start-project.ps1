# Script para configurar ambiente WordPress com Docker
param(
    [string]$ProjectName = "",
    
    [Alias('h', '?')]
    [switch]$Help,
    
    [Alias('t')]
    [switch]$Test,
    
    [Alias('d')]
    [switch]$Debug
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Configuracao de encoding para UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# Definicao de portas reservadas
$script:RESERVED_PORTS = @{
    "HTTP" = 80
    "HTTPS" = 443
    "FTP" = 21
    "SSH" = 22
    "MySQL" = 3306
    "PostgreSQL" = 5432
    "Redis" = 6379
    "MongoDB" = 27017
    "Steam" = @(27015..27030)
    "Minecraft" = 25565
    "TeamSpeak" = @(9987, 10011, 30033)
    "Discord" = 50000
    "Skype" = @(50001..50003)
    "VNC" = 5900
    "RDP" = 3389
}

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

# Funcoes de teste de nome
function Test-NameConversion {
    Write-InfoMessage "Testando conversao de nomes..."
    
    $testCases = @(
        # Casos básicos
        @{ Input = "MeuProjeto"; Expected = "meu-projeto"; Description = "PascalCase simples" }
        @{ Input = "meuProjeto"; Expected = "meu-projeto"; Description = "camelCase simples" }
        @{ Input = "meu-projeto"; Expected = "meu-projeto"; Description = "kebab-case simples" }
        @{ Input = "MeuProjeto123"; Expected = "meu-projeto123"; Description = "Com numeros no final" }
        @{ Input = "123MeuProjeto"; Expected = "123-meu-projeto"; Description = "Com numeros no inicio" }
        
        # Casos especiais
        @{ Input = "MinhaLoja2023WordPress"; Expected = "minha-loja2023-word-press"; Description = "Nome composto com ano" }
        @{ Input = "TestePROJETO"; Expected = "teste-projeto"; Description = "Maiusculas no meio" }
        @{ Input = "ABC123xyz"; Expected = "abc123xyz"; Description = "Alternando maiusculas e numeros" }
        @{ Input = "ProjetoWP"; Expected = "projeto-wp"; Description = "Sigla no final" }
        @{ Input = "WPProjeto"; Expected = "wp-projeto"; Description = "Sigla no inicio" }
        
        # Casos de borda
        @{ Input = "a"; Expected = "a"; Description = "Nome muito curto" }
        @{ Input = "Ab"; Expected = "ab"; Description = "Nome curto PascalCase" }
        @{ Input = "MAIUSCULAS"; Expected = "maiusculas"; Description = "Tudo maiusculo" }
        @{ Input = "minusculas"; Expected = "minusculas"; Description = "Tudo minusculo" }
        @{ Input = "nome--com--hifens"; Expected = "nome-com-hifens"; Description = "Multiplos hifens" }
    )
    
    $allPassed = $true
    foreach ($test in $testCases) {
        Write-InfoMessage "`nTestando: $($test.Description)"
        try {
            $result = ConvertTo-KebabCase -Name $test.Input
            if ($result -ne $test.Expected) {
                Write-ErrorMessage "Falha na conversao: '$($test.Input)'"
                Write-ErrorMessage "  Esperado: '$($test.Expected)'"
                Write-ErrorMessage "  Obtido: '$result'"
                $allPassed = $false
            }
            else {
                Write-SuccessMessage "Conversao OK: '$($test.Input)' -> '$result'"
            }
        }
        catch {
            Write-ErrorMessage "Erro ao converter '$($test.Input)': $_"
            $allPassed = $false
        }
    }
    
    return $allPassed
}

function ConvertTo-KebabCase {
    param(
        [string]$Name
    )

    # Trata casos totalmente em maiúsculas
    if ($Name -cmatch '^[A-Z0-9]+$') {
        return $Name.ToLower()
    }

    # Lista de siglas comuns
    $commonAcronyms = @('WP', 'PHP', 'SQL', 'HTML', 'CSS', 'JS', 'PROJETO')
    
    # Primeiro, trata as siglas
    $result = $Name
    foreach ($acronym in $commonAcronyms) {
        if ($result -cmatch $acronym) {
            # Se a sigla está no início
            $result = $result -creplace "^$acronym", "${acronym}-"
            # Se a sigla está no fim
            $result = $result -creplace "$acronym$", "-${acronym}"
            # Se a sigla está no meio
            $result = $result -creplace "([a-z])$acronym([A-Z][a-z])", "`$1-${acronym}-`$2"
        }
    }
    
    # Remove hifens duplicados que podem ter sido criados
    $result = $result -replace '-+', '-'
    
    # Agora converte o resto para kebab-case
    $result = $result -creplace '(?<!^)(?<!-)(?=[A-Z][a-z])', '-'
    
    # Converte para minúsculas
    $result = $result.ToLower()
    
    # Limpa e normaliza o resultado final
    $result = $result -replace '[\W_-]+', '-'
    $result = $result.Trim('-')

    return $result
}

# Funcoes de teste
function Test-Environment {
    Write-InfoMessage "Verificando ambiente..."
    $allPassed = $true

    # Verifica se está rodando como administrador
    Write-InfoMessage "`nVerificando Administrador..."
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-WarningMessage "Script nao esta rodando como administrador"
        Write-WarningMessage "Alguns recursos podem nao funcionar corretamente"
        # Não falha o teste, apenas avisa
    }

    # Verifica versão do PowerShell
    Write-InfoMessage "`nVerificando PowerShell..."
    $psVersion = $PSVersionTable.PSVersion
    Write-InfoMessage "PowerShell $($psVersion.Major).$($psVersion.Minor).$($psVersion.Build).$($psVersion.Revision)"
    # Não falha o teste, apenas informa a versão

    # Verifica Docker
    Write-InfoMessage "`nVerificando Docker..."
    try {
        $dockerVersion = docker version --format '{{.Server.Version}}'
        if ($LASTEXITCODE -eq 0) {
            Write-InfoMessage "Docker instalado: Docker version $dockerVersion"
        }
        else {
            Write-ErrorMessage "Docker nao esta instalado ou nao esta rodando"
            $allPassed = $false
        }
    }
    catch {
        Write-ErrorMessage "Docker nao esta instalado, nao esta no PATH, ou nao esta rodando: $($_.Exception.Message)"
        $allPassed = $false
    }

    # Verifica Docker Compose
    Write-InfoMessage "Verificando Docker Compose..."
    try {
        $dockerComposeVersion = docker compose version
        if ($LASTEXITCODE -eq 0) {
            Write-InfoMessage "Docker Compose instalado: $dockerComposeVersion"
        }
        else {
            Write-ErrorMessage "Docker Compose nao esta instalado ou nao esta rodando"
            $allPassed = $false
        }
    }
    catch {
        Write-ErrorMessage "Docker Compose nao esta instalado, nao esta no PATH, ou nao esta rodando: $($_.Exception.Message)"
        $allPassed = $false
    }

    # Verifica arquivos necessários
    Write-InfoMessage "`nVerificando Arquivos..."
    $requiredFiles = @(
        "docker-compose.yml",
        ".env.development"
    )
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            Write-ErrorMessage "Arquivo $file nao encontrado"
            $allPassed = $false
        }
    }

    # Verifica conectividade com Docker Hub
    Write-InfoMessage "`nVerificando Rede..."
    try {
        # Tenta fazer um pull de uma imagem pequena para testar a conectividade
        $null = docker pull hello-world 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-InfoMessage "Conectividade com Docker Hub OK"
        }
        else {
            Write-ErrorMessage "Erro ao verificar conectividade com Docker Hub: Falha ao fazer pull da imagem de teste"
            $allPassed = $false
        }
    }
    catch {
        Write-ErrorMessage "Erro ao verificar conectividade com Docker Hub: $($_.Exception.Message)"
        # Não falha o teste, pois pode ser apenas um problema temporário de rede
    }

    if (-not $allPassed) {
        Write-ErrorMessage "`nForam encontrados problemas no ambiente"
    }

    return $allPassed
}

function Test-Ports {
    Write-InfoMessage "Testando funcoes de porta..."
    
    $testPorts = @(
        # Portas privilegiadas
        @{ Port = 80; Expected = $false; Name = "HTTP padrao"; Description = "Porta privilegiada HTTP" }
        @{ Port = 443; Expected = $false; Name = "HTTPS padrao"; Description = "Porta privilegiada HTTPS" }
        @{ Port = 22; Expected = $false; Name = "SSH padrao"; Description = "Porta privilegiada SSH" }
        
        # Portas de servicos comuns
        @{ Port = 3306; Expected = $false; Name = "MySQL padrao"; Description = "Porta padrao MySQL" }
        @{ Port = 27017; Expected = $false; Name = "MongoDB padrao"; Description = "Porta padrao MongoDB" }
        @{ Port = 6379; Expected = $false; Name = "Redis padrao"; Description = "Porta padrao Redis" }
        
        # Portas de jogos
        @{ Port = 27015; Expected = $false; Name = "Steam"; Description = "Porta Steam" }
        @{ Port = 25565; Expected = $false; Name = "Minecraft"; Description = "Porta Minecraft" }
        
        # Portas invalidas
        @{ Port = 65536; Expected = $false; Name = "Porta invalida alta"; Description = "Acima do limite maximo" }
        @{ Port = 0; Expected = $false; Name = "Porta invalida baixa"; Description = "Abaixo do limite minimo" }
        @{ Port = -1; Expected = $false; Name = "Porta negativa"; Description = "Valor negativo invalido" }
        
        # Portas validas
        @{ Port = 8080; Expected = $true; Name = "HTTP alternativa"; Description = "Porta alternativa HTTP" }
        @{ Port = 8443; Expected = $true; Name = "HTTPS alternativa"; Description = "Porta alternativa HTTPS" }
        @{ Port = 9000; Expected = $true; Name = "Porta generica"; Description = "Porta nao reservada" }
    )
    
    $allPassed = $true
    foreach ($test in $testPorts) {
        Write-InfoMessage "`nTestando: $($test.Description)"
        try {
            $isReserved = Test-ReservedPort -Port $test.Port
            $isValid = Test-PortRange -Port $test.Port -PortType $test.Name
            
            Write-InfoMessage "Porta $($test.Port) ($($test.Name))"
            Write-InfoMessage "- Reservada: $isReserved"
            Write-InfoMessage "- Valida: $isValid"
            Write-InfoMessage "- Esperado: $($test.Expected)"
            
            if ($isValid -ne $test.Expected) {
                Write-ErrorMessage "Teste falhou para porta $($test.Port)"
                Write-ErrorMessage "  Motivo: Validacao retornou $isValid, esperado $($test.Expected)"
                $allPassed = $false
            }
        }
        catch {
            Write-ErrorMessage "Erro ao testar porta $($test.Port): $_"
            $allPassed = $false
        }
    }
    
    return $allPassed
}

function Test-FileOperations {
    Write-InfoMessage "Testando operacoes de arquivo..."
    
    $tests = @(
        @{
            Name = "Arquivo texto simples"
            Test = {
                $tempFile = Join-Path $env:TEMP "test-$(Get-Random).txt"
                $testContent = "Test content`n"
                
                # Teste de escrita
                $testContent | Out-File -FilePath $tempFile -NoNewline
                
                # Teste de leitura
                $content = Get-Content $tempFile -Raw
                if ($content -ne $testContent) {
                    throw "Conteudo nao confere. Esperado: '$testContent', Obtido: '$content'"
                }
                
                # Teste de remocao
                Remove-Item $tempFile
                if (Test-Path $tempFile) {
                    throw "Arquivo nao foi removido"
                }
                
                return $true
            }
        }
        @{
            Name = "Arquivo com caracteres especiais"
            Test = {
                $tempFile = Join-Path $env:TEMP "test-$(Get-Random).txt"
                $testContent = "Conteudo com acentuacao e caracteres especiais: a e i o u c a o"
                
                # Teste de escrita
                $testContent | Out-File -FilePath $tempFile -Encoding utf8
                
                # Teste de leitura
                $content = Get-Content $tempFile -Raw -Encoding utf8
                if ($content.Trim() -ne $testContent) {
                    throw "Conteudo com caracteres especiais nao confere"
                }
                
                # Teste de remocao
                Remove-Item $tempFile
                if (Test-Path $tempFile) {
                    throw "Arquivo com caracteres especiais nao foi removido"
                }
                
                return $true
            }
        }
        @{
            Name = "Arquivo grande"
            Test = {
                $tempFile = Join-Path $env:TEMP "test-large-$(Get-Random).txt"
                $testContent = "0123456789" * 1000  # 10KB de dados
                
                # Teste de escrita
                $testContent | Out-File -FilePath $tempFile
                
                # Verifica tamanho
                $fileInfo = Get-Item $tempFile
                if ($fileInfo.Length -lt 10000) {
                    throw "Arquivo grande nao foi escrito corretamente"
                }
                
                # Teste de remocao
                Remove-Item $tempFile
                if (Test-Path $tempFile) {
                    throw "Arquivo grande nao foi removido"
                }
                
                return $true
            }
        }
        @{
            Name = "Permissoes de arquivo"
            Test = {
                $tempFile = Join-Path $env:TEMP "test-perms-$(Get-Random).txt"
                "Test" | Out-File -FilePath $tempFile
                
                # Testa leitura
                $acl = Get-Acl $tempFile
                if (-not $acl) {
                    throw "Nao foi possivel ler as permissoes do arquivo"
                }
                
                # Testa escrita
                try {
                    $newAcl = New-Object System.Security.AccessControl.FileSecurity
                    $acl.SetAccessRuleProtection($true, $false)
                    Set-Acl -Path $tempFile -AclObject $newAcl
                }
                catch {
                    Write-WarningMessage "AVISO: Nao foi possivel modificar permissoes do arquivo"
                }
                
                # Limpa
                Remove-Item $tempFile
                return $true
            }
        }
    )
    
    $allPassed = $true
    foreach ($test in $tests) {
        Write-InfoMessage "`nTestando: $($test.Name)"
        try {
            $result = & $test.Test
            if (-not $result) {
                Write-ErrorMessage "Falha no teste: $($test.Name)"
                $allPassed = $false
            }
            else {
                Write-SuccessMessage "Teste passou: $($test.Name)"
            }
        }
        catch {
            Write-ErrorMessage "Erro no teste $($test.Name): $_"
            $allPassed = $false
        }
    }
    
    return $allPassed
}

function Test-DockerOperations {
    Write-InfoMessage "Testando operacoes do Docker..."
    
    $tests = @(
        @{
            Name = "Rede Docker"
            Test = {
                $networkName = "test-network-$(Get-Random)"
                
                # Criar rede
                docker network create $networkName
                if ($LASTEXITCODE -ne 0) {
                    throw "Falha ao criar rede"
                }
                Write-InfoMessage "Rede de teste criada: $networkName"
                
                # Listar rede
                $network = docker network ls --filter name=$networkName --format "{{.Name}}"
                if ($network -ne $networkName) {
                    throw "Rede nao encontrada apos criacao"
                }
                
                # Remover rede
                docker network rm $networkName
                if ($LASTEXITCODE -ne 0) {
                    throw "Falha ao remover rede"
                }
                Write-InfoMessage "Rede de teste removida"
                
                return $true
            }
        }
        @{
            Name = "Imagem Docker"
            Test = {
                # Testa pull de imagem
                Write-InfoMessage "Testando pull de imagem..."
                docker pull hello-world:latest
                if ($LASTEXITCODE -ne 0) {
                    throw "Falha ao baixar imagem hello-world"
                }
                
                # Verifica se a imagem existe
                $image = docker images hello-world:latest --format "{{.Repository}}"
                if (-not $image) {
                    throw "Imagem nao encontrada apos download"
                }
                
                return $true
            }
        }
        @{
            Name = "Container Docker"
            Test = {
                # Testa execucao de container
                Write-InfoMessage "Testando execucao de container..."
                $output = docker run --rm hello-world
                if ($LASTEXITCODE -ne 0) {
                    throw "Falha ao executar container: $output"
                }
                
                # Testa criacao de container com nome personalizado
                $containerName = "test-container-$(Get-Random)"
                docker run --name $containerName -d hello-world
                if ($LASTEXITCODE -ne 0) {
                    throw "Falha ao criar container com nome personalizado"
                }
                
                # Remove o container
                docker rm -f $containerName
                if ($LASTEXITCODE -ne 0) {
                    throw "Falha ao remover container"
                }
                
                return $true
            }
        }
        @{
            Name = "Volume Docker"
            Test = {
                $volumeName = "test-volume-$(Get-Random)"
                
                # Criar volume
                docker volume create $volumeName
                if ($LASTEXITCODE -ne 0) {
                    throw "Falha ao criar volume"
                }
                Write-InfoMessage "Volume de teste criado: $volumeName"
                
                # Listar volume
                $volume = docker volume ls --filter name=$volumeName --format "{{.Name}}"
                if ($volume -ne $volumeName) {
                    throw "Volume nao encontrado apos criacao"
                }
                
                # Remover volume
                docker volume rm $volumeName
                if ($LASTEXITCODE -ne 0) {
                    throw "Falha ao remover volume"
                }
                Write-InfoMessage "Volume de teste removido"
                
                return $true
            }
        }
    )
    
    $allPassed = $true
    foreach ($test in $tests) {
        Write-InfoMessage "`nTestando: $($test.Name)"
        try {
            $result = & $test.Test
            if (-not $result) {
                Write-ErrorMessage "Falha no teste: $($test.Name)"
                $allPassed = $false
            }
            else {
                Write-SuccessMessage "Teste passou: $($test.Name)"
            }
        }
        catch {
            Write-ErrorMessage "Erro no teste $($test.Name): $_"
            $allPassed = $false
        }
    }
    
    return $allPassed
}

# Executa todos os testes
function Start-Tests {
    $testResults = @()
    
    # Testes de ambiente
    try {
        $testResults += @{
            Name = "Ambiente"
            Passed = Test-Environment
            Error = $null
        }
    }
    catch {
        $testResults += @{
            Name = "Ambiente"
            Passed = $false
            Error = $_.Exception.Message
        }
    }
    
    # Testes de nomes
    try {
        $testResults += @{
            Name = "Nomes"
            Passed = Test-NameConversion
            Error = $null
        }
    }
    catch {
        $testResults += @{
            Name = "Nomes"
            Passed = $false
            Error = $_.Exception.Message
        }
    }
    
    # Testes de portas
    try {
        $testResults += @{
            Name = "Portas"
            Passed = Test-Ports
            Error = $null
        }
    }
    catch {
        $testResults += @{
            Name = "Portas"
            Passed = $false
            Error = $_.Exception.Message
        }
    }
    
    # Testes do Docker
    try {
        $testResults += @{
            Name = "Docker"
            Passed = Test-DockerOperations
            Error = $null
        }
    }
    catch {
        $testResults += @{
            Name = "Docker"
            Passed = $false
            Error = $_.Exception.Message
        }
    }
    
    # Testes de arquivo
    try {
        $testResults += @{
            Name = "Arquivos"
            Passed = Test-FileOperations
            Error = $null
        }
    }
    catch {
        $testResults += @{
            Name = "Arquivos"
            Passed = $false
            Error = $_.Exception.Message
        }
    }
    
    # Exibe resultados
    Write-Host "`nResultados dos testes:"
    Write-Host "====================="
    foreach ($result in $testResults) {
        $status = if ($result.Passed) { "PASSOU" } else { "FALHOU" }
        $color = if ($result.Passed) { "Green" } else { "Red" }
        
        Write-Host "$($result.Name): " -NoNewline
        Write-Host $status -ForegroundColor $color
        
        if (-not $result.Passed -and $null -ne $result.Error) {
            Write-Host "  Erro: $($result.Error)" -ForegroundColor Red
        }
    }
    
    # Verifica se todos os testes passaram
    $allPassed = $testResults | Where-Object { -not $_.Passed } | Measure-Object | Select-Object -ExpandProperty Count
    return $allPassed -eq 0
}

# Funcoes de validacao
function Test-ProjectName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    # Verificar se o nome esta vazio
    if ([string]::IsNullOrWhiteSpace($Name)) {
        Write-ErrorMessage "ERRO: Nome do projeto nao pode ser vazio"
        return $false
    }
    
    # Verificar comprimento minimo e maximo
    if ($Name.Length -lt 2) {
        Write-ErrorMessage "ERRO: Nome do projeto '$Name' muito curto (minimo 2 caracteres)"
        return $false
    }
    if ($Name.Length -gt 50) {
        Write-ErrorMessage "ERRO: Nome do projeto '$Name' muito longo (maximo 50 caracteres)"
        return $false
    }
    
    # Verificar caracteres invalidos
    if ($Name -notmatch '^[a-zA-Z0-9-]+$') {
        Write-ErrorMessage "ERRO: Nome do projeto '$Name' contem caracteres invalidos"
        Write-ErrorMessage "Use apenas:"
        Write-ErrorMessage "- Letras (a-z, A-Z)"
        Write-ErrorMessage "- Numeros (0-9)"
        Write-ErrorMessage "- Hifens (-)"
        Write-ErrorMessage "Exemplos validos: meu-blog, loja-virtual, loja-virtual2"
        return $false
    }
    
    # Verificar se comeca ou termina com hifen
    if ($Name -match '^-|-$') {
        Write-ErrorMessage "ERRO: Nome do projeto '$Name' nao pode comecar ou terminar com hifen"
        return $false
    }
    
    # Verificar hifens consecutivos
    if ($Name -match '--') {
        Write-ErrorMessage "ERRO: Nome do projeto '$Name' nao pode conter hifens consecutivos"
        return $false
    }
    
    # Verificar palavras reservadas do Docker
    $reservedWords = @('default', 'host', 'none', 'all', 'bridge', 'container', 'daemon', 'network', 'service', 'volume')
    if ($reservedWords -contains $Name.ToLower()) {
        Write-ErrorMessage "ERRO: Nome do projeto '$Name' e uma palavra reservada do Docker"
        Write-ErrorMessage "Nao use: $($reservedWords -join ', ')"
        return $false
    }
    
    return $true
}

function Test-DockerName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    # Regex para nomes validos do Docker
    # Permite apenas lowercase, numeros e um unico hifen entre caracteres
    return $Name -match '^[a-z0-9]+(?:-[a-z0-9]+)*$'
}

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
    
    # Verifica se a porta esta reservada
    if (Test-ReservedPort -Port $Port) {
        Write-InfoMessage "Porta $Port esta reservada para outro servico"
        return $false
    }
    
    # Verifica se a porta esta em uso
    if (Test-PortInUse -Port $Port) {
        Write-InfoMessage "Porta $Port ja esta em uso"
        return $false
    }
    
    return $true
}

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

function Test-PortIsPrivileged {
    param (
        [int]$Port,
        [string]$ServiceName = ""
    )
    
    if ($Port -lt 1024) {
        Write-ErrorMessage "ERRO: Porta $Port para $ServiceName e uma porta privilegiada"
        return $true
    }
    return $false
}

function Test-PortIsReserved {
    param (
        [int]$Port,
        [string]$ServiceName = ""
    )

    # Lista de portas reservadas
    $reservedPorts = @{
        80 = "HTTP"
        443 = "HTTPS"
        22 = "SSH"
        3306 = "MySQL"
        5432 = "PostgreSQL"
        27017 = "MongoDB"
        6379 = "Redis"
        27015 = "Steam"
        25565 = "Minecraft"
    }

    # Verifica se a porta está na lista de reservadas
    if ($reservedPorts.ContainsKey($Port)) {
        Write-InfoMessage "Porta $Port e usada por $($reservedPorts[$Port])"
        Write-ErrorMessage "Porta $Port esta reservada para outro servico"
        return $true
    }

    return $false
}

function Test-PortIsValid {
    param (
        [int]$Port,
        [string]$ServiceName = ""
    )

    # Verifica se a porta está dentro do intervalo válido
    if ($Port -lt 1 -or $Port -gt 65535) {
        Write-ErrorMessage "ERRO: Porta $Port para $ServiceName e invalida (minimo 1, maximo 65535)"
        return $false
    }

    # Verifica se é uma porta privilegiada
    if (Test-PortIsPrivileged -Port $Port -ServiceName $ServiceName) {
        return $false
    }

    # Verifica se é uma porta reservada
    if (Test-PortIsReserved -Port $Port -ServiceName $ServiceName) {
        return $false
    }

    return $true
}

# Funcoes de conversao
function Convert-ToDockerName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    try {
        # Converte PascalCase para kebab-case
        # Ex: MinhaLoja -> minha-loja
        $kebabCase = ConvertTo-KebabCase -Name $Name
        
        # Valida o resultado final
        if (-not (Test-DockerName -Name $kebabCase)) {
            throw "Nome convertido '$kebabCase' invalido para o Docker"
        }
        
        return $kebabCase
    }
    catch {
        Write-ErrorMessage "ERRO ao converter nome do projeto: $_"
        throw
    }
}

# Funcoes de porta
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

# Mostra ajuda
function Show-Help {
    Write-Host @"
Uso: .\start-project.ps1 [-ProjectName <nome>] [-Help] [-Debug] [-Test]

Parametros:
    -ProjectName   Nome do projeto WordPress (ex: meu-blog, loja-virtual)
                  Se omitido, usa o nome da pasta atual
    -Help, -h, -?  Mostra esta mensagem de ajuda
    -Debug, -d     Executa testes de conversao de nomes
    -Test, -t      Executa todos os testes do sistema

Exemplos:
    .\start-project.ps1 -ProjectName "meu-blog"
    .\start-project.ps1 -Test
    .\start-project.ps1 -Debug
    .\start-project.ps1 -h
"@
    exit 0
}

# Executa modo apropriado
if ($Help) { Show-Help }
if ($Test) { 
    $testsPassed = Start-Tests
    if (-not $testsPassed) {
        throw "Alguns testes falharam. Verifique os resultados acima."
    }
    exit 0 
}
if ($Debug) {
    Write-InfoMessage "Executando testes de conversao de nomes..."
    if (-not (Test-NameConversion)) {
        throw "Testes de conversao de nomes falharam!"
    }
    Write-SuccessMessage "Todos os testes de nome passaram!"
    exit 0
}

# Validacao inicial do ambiente
if (-not (Test-Environment)) {
    throw "Falha na validacao do ambiente"
}

# Validar nome do projeto
if ([string]::IsNullOrEmpty($ProjectName)) {
    $ProjectName = Split-Path -Leaf (Get-Location)
}

if (-not (Test-ProjectName -Name $ProjectName)) {
    exit 1
}

# Converte o nome do projeto para formato Docker-friendly
$DockerProjectName = Convert-ToDockerName -Name $ProjectName
Write-InfoMessage "Nome do projeto para Docker: $DockerProjectName"

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
    $envContent = $envContent.Replace("COMPOSE_PROJECT_NAME=default", "COMPOSE_PROJECT_NAME=$DockerProjectName")
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
        
        $mysqlStatus = docker inspect -f '{{.State.Health.Status}}' "$DockerProjectName-mysql" 2>&1
        $wpStatus = docker ps -q -f name="$DockerProjectName-wordpress" 2>&1
        
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
