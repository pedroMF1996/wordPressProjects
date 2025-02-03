param(
    [string]$ProjectName = "",
    [switch]$Help,
    [switch]$Test,
    [switch]$Debug
)

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

    $tests = @(
        # Testes básicos
        @{ Input = "MeuProjeto"; Expected = "meu-projeto"; Description = "PascalCase simples" }
        @{ Input = "meuProjeto"; Expected = "meu-projeto"; Description = "camelCase simples" }
        @{ Input = "meu-projeto"; Expected = "meu-projeto"; Description = "kebab-case simples" }
        @{ Input = "MeuProjeto123"; Expected = "meu-projeto-123"; Description = "Com numeros no final" }
        @{ Input = "123MeuProjeto"; Expected = "123-meu-projeto"; Description = "Com numeros no inicio" }
        @{ Input = "MinhaLoja2023WordPress"; Expected = "minha-loja-2023-wordpress"; Description = "Nome composto com ano" }
        
        # Testes de maiúsculas
        @{ Input = "TestePROJETO"; Expected = "teste-projeto"; Description = "Maiusculas no meio" }
        @{ Input = "ABC123xyz"; Expected = "abc-123-xyz"; Description = "Alternando maiusculas e numeros" }
        @{ Input = "MAIUSCULAS"; Expected = "maiusculas"; Description = "Tudo maiusculo" }
        @{ Input = "minusculas"; Expected = "minusculas"; Description = "Tudo minusculo" }
        
        # Testes de siglas
        @{ Input = "ProjetoWP"; Expected = "projeto-wp"; Description = "Sigla no final" }
        @{ Input = "WPProjeto"; Expected = "wp-projeto"; Description = "Sigla no inicio" }
        @{ Input = "MeuProjetoWPAPI"; Expected = "meu-projeto-wp-api"; Description = "Multiplas siglas" }
        
        # Testes de comprimento
        @{ Input = "a"; Expected = "a"; Description = "Nome muito curto" }
        @{ Input = "Ab"; Expected = "ab"; Description = "Nome curto PascalCase" }
        @{ Input = "a" * 50; Expected = ("a-" * 50).Trim('-'); Description = "Nome no limite maximo" }
        
        # Testes de hifens
        @{ Input = "nome--com--hifens"; Expected = "nome-com-hifens"; Description = "Multiplos hifens" }
        @{ Input = "-nome-com-hifen-"; Expected = "nome-com-hifen"; Description = "Hifens nas extremidades" }
        @{ Input = "nome - com - espacos"; Expected = "nome-com-espacos"; Description = "Hifens com espacos" }
        
        # Testes de caracteres especiais (devem ser removidos)
        @{ Input = "nome@com#caracteres"; Expected = "nome-com-caracteres"; Description = "Caracteres especiais" }
        @{ Input = "nome_com_underscore"; Expected = "nome-com-underscore"; Description = "Underscores" }
        @{ Input = "nome.com.pontos"; Expected = "nome-com-pontos"; Description = "Pontos" }
        
        # Testes de casos complexos
        @{ Input = "MeuProjeto2023WPv2API"; Expected = "meu-projeto-2023-wp-v2-api"; Description = "Caso complexo 1" }
        @{ Input = "API_REST_v2.0"; Expected = "api-rest-v2-0"; Description = "Caso complexo 2" }
        @{ Input = "meu.projeto-WP_2023"; Expected = "meu-projeto-wp-2023"; Description = "Caso complexo 3" }
        @{ Input = "MINHA_LOJA_WP_2023"; Expected = "minha-loja-wp-2023"; Description = "Caso complexo 4" }
        @{ Input = "wp-API-v2.0-BETA"; Expected = "wp-api-v2-0-beta"; Description = "Caso complexo 5" }
        @{ Input = "RESTfulAPI"; Expected = "restful-api"; Description = "Palavra com sufixo" }
    )

    $allPassed = $true
    foreach ($test in $tests) {
        Write-InfoMessage "`nTestando: $($test.Description)"
        try {
            $result = Convert-ToDockerName -Name $test.Input
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

function Convert-ToDockerName {
    param([string]$Name)
    
    # 0. Pré-processamento para casos especiais
    if ($Name -match '^(.)\1+$') {
        return ($Name.ToCharArray() -join '-').ToLower()
    }
    
    # 1. Lista de siglas conhecidas (ordenada da mais longa para a mais curta)
    $knownAcronyms = @(
        'WordPress', 'RESTful', 'REST', 'BETA', 'API', 'SQL', 'HTTP', 'FTP', 'SSH', 
        'XML', 'HTML', 'CSS', 'PHP', 'URL', 'URI', 'JWT', 'WP'
    ) | Sort-Object { $_.Length } -Descending
    
    # 2. Função para encontrar siglas em uma palavra
    function Find-Siglas {
        param([string]$Word)
        
        $results = @()
        $currentPos = 0
        
        while ($currentPos -lt $Word.Length) {
            $found = $false
            foreach ($acronym in $knownAcronyms) {
                if ($currentPos + $acronym.Length -le $Word.Length) {
                    $substring = $Word.Substring($currentPos, $acronym.Length)
                    if ($substring -ceq $acronym) {
                        # Se for uma palavra completa (WordPress, RESTful), tratar como palavra
                        if ($acronym -in @('WordPress', 'RESTful')) {
                            $results += @{
                                Start = $currentPos
                                Length = $acronym.Length
                                Value = $acronym
                                IsWord = $true
                            }
                        }
                        else {
                            $results += @{
                                Start = $currentPos
                                Length = $acronym.Length
                                Value = $acronym
                                IsWord = $false
                            }
                        }
                        $currentPos += $acronym.Length
                        $found = $true
                        break
                    }
                }
            }
            if (-not $found) {
                $currentPos++
            }
        }
        
        return $results
    }
    
    # 3. Função para processar uma palavra
    function Process-Word {
        param([string]$Word)
        
        # Se for uma versão
        if ($Word -match '^v\d') {
            return $Word.ToLower()
        }
        
        # Se for um número
        if ($Word -match '^\d+$') {
            return $Word
        }
        
        # Encontrar todas as siglas na palavra
        $siglas = Find-Siglas -Word $Word
        
        if ($siglas.Count -eq 0) {
            # Se não houver siglas, processar normalmente
            $result = @()
            $currentWord = ""
            
            for ($i = 0; $i -lt $Word.Length; $i++) {
                $char = $Word[$i]
                $nextChar = if ($i -lt $Word.Length - 1) { $Word[$i + 1] } else { $null }
                
                if (($char -cmatch '[a-z]' -and $nextChar -cmatch '[A-Z]') -or
                    ($char -cmatch '[A-Z]' -and $nextChar -cmatch '[A-Z]' -and $i -lt $Word.Length - 2 -and $Word[$i + 2] -cmatch '[a-z]') -or
                    ($char -match '[a-zA-Z]' -and $nextChar -match '\d') -or
                    ($char -match '\d' -and $nextChar -match '[a-zA-Z]')) {
                    $currentWord += $char
                    if ($currentWord) {
                        $result += $currentWord.ToLower()
                        $currentWord = ""
                    }
                }
                else {
                    $currentWord += $char
                }
            }
            
            if ($currentWord) {
                $result += $currentWord.ToLower()
            }
            
            return $result -join '-'
        }
        else {
            # Se houver siglas, dividir a palavra em partes
            $parts = @()
            $lastEnd = 0
            
            foreach ($sigla in $siglas) {
                # Adicionar parte antes da sigla
                if ($sigla.Start -gt $lastEnd) {
                    $beforeSigla = $Word.Substring($lastEnd, $sigla.Start - $lastEnd)
                    if ($beforeSigla) {
                        $parts += (Process-Word -Word $beforeSigla)
                    }
                }
                
                # Adicionar a sigla ou palavra
                if ($sigla.IsWord) {
                    $parts += $sigla.Value.ToLower()
                }
                else {
                    $parts += $sigla.Value.ToLower()
                }
                $lastEnd = $sigla.Start + $sigla.Length
            }
            
            # Adicionar parte final após última sigla
            if ($lastEnd -lt $Word.Length) {
                $afterLastSigla = $Word.Substring($lastEnd)
                if ($afterLastSigla) {
                    $parts += (Process-Word -Word $afterLastSigla)
                }
            }
            
            return $parts -join '-'
        }
    }
    
    # 4. Dividir em palavras por caracteres especiais
    $words = $Name -split '[^a-zA-Z0-9]' | Where-Object { $_ }
    
    # 5. Processar cada palavra
    $processedWords = @()
    foreach ($word in $words) {
        if ($word) {
            $processed = Process-Word -Word $word
            if ($processed) {
                $processedWords += $processed
            }
        }
    }
    
    # 6. Juntar com hífen
    $dockerName = ($processedWords -join '-').Trim('-')
    
    # 7. Remover hífens duplicados
    $dockerName = $dockerName -replace '-+', '-'
    
    # 8. Garantir que o nome não exceda o limite
    if ($dockerName.Length -gt 50) {
        Write-WarningMessage "Nome do projeto muito longo, será truncado para 50 caracteres"
        $dockerName = $dockerName.Substring(0, 50).TrimEnd('-')
    }
    
    return $dockerName
}

function Validate-Port {
    param(
        [int]$Port,
        [string]$ServiceName
    )
    
    # Uma porta é válida se está no intervalo válido (1-65535)
    $valid = ($Port -ge 1 -and $Port -le 65535)
    
    # Verificar se é uma porta reservada
    $reserved = $false
    
    # Verificar se é uma porta privilegiada (1-1024)
    $isPrivileged = $Port -le 1024
    
    # Se for uma porta privilegiada HTTP/HTTPS (80, 443), é inválida
    if ($isPrivileged -and $ServiceName -in @('HTTP', 'HTTPS') -and $Port -in @(80, 443)) {
        Write-ErrorMessage "Porta $Port para $ServiceName padrao e uma porta privilegiada"
        return @{
            Reserved = $true
            Valid = $false
        }
    }
    
    # Se a porta está na lista de portas reservadas para o serviço específico
    if ($script:RESERVED_PORTS.ContainsKey($ServiceName)) {
        $ports = $script:RESERVED_PORTS[$ServiceName]
        if ($Port -in $ports) {
            Write-InfoMessage "Porta $Port e usada por $ServiceName"
            $reserved = $true
            # Se for uma porta alternativa (8080, 8443), é válida
            if ($Port -in @(8080, 8443)) {
                $valid = $true
            }
        }
    }
    
    # Se a porta está na lista de portas reservadas para qualquer outro serviço
    foreach ($service in $script:RESERVED_PORTS.Keys) {
        if ($service -ne $ServiceName) {
            $ports = $script:RESERVED_PORTS[$service]
            if ($Port -in $ports) {
                Write-InfoMessage "Porta $Port e usada por $service"
                Write-InfoMessage "Porta $Port esta reservada para outro servico"
                $reserved = $true
                $valid = $false
                break
            }
        }
    }
    
    return @{
        Reserved = $reserved
        Valid = $valid
    }
}

# Definir portas reservadas globalmente
$script:RESERVED_PORTS = @{
    'HTTP' = @(80, 8080)
    'HTTPS' = @(443, 8443)
    'MySQL' = @(3306)
    'PostgreSQL' = @(5432)
    'Redis' = @(6379)
    'MongoDB' = @(27017)
}

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
        # Portas essenciais
        @{ Port = 80; Expected = $false; Name = "HTTP padrao"; Description = "Porta privilegiada HTTP" }
        @{ Port = 443; Expected = $false; Name = "HTTPS padrao"; Description = "Porta privilegiada HTTPS" }
        @{ Port = 3306; Expected = $false; Name = "MySQL padrao"; Description = "Porta padrao MySQL" }
        
        # Portas alternativas
        @{ Port = 8080; Expected = $true; Name = "HTTP alternativa"; Description = "Porta alternativa HTTP" }
        @{ Port = 8443; Expected = $true; Name = "HTTPS alternativa"; Description = "Porta alternativa HTTPS" }
        @{ Port = 9000; Expected = $true; Name = "Genérica"; Description = "Porta nao reservada" }
    )
    
    $allPassed = $true
    foreach ($test in $testPorts) {
        Write-InfoMessage "`nTestando: $($test.Description)"
        try {
            $result = Validate-Port -Port $test.Port -ServiceName $(if ($test.Name -match "HTTP|HTTPS") { $test.Name.Split(" ")[0] } else { $test.Name })
            
            Write-InfoMessage "Porta $($test.Port) ($($test.Name))"
            Write-InfoMessage "- Reservada: $($result.Reserved)"
            Write-InfoMessage "- Valida: $($result.Valid)"
            Write-InfoMessage "- Esperado: $($test.Expected)"
            
            if ($result.Valid -ne $test.Expected) {
                Write-ErrorMessage "Teste falhou para porta $($test.Port)"
                Write-ErrorMessage "  Motivo: Validacao retornou $($result.Valid), esperado $($test.Expected)"
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
                $testContent = "Conteudo de teste"
                
                try {
                    # Teste de escrita
                    $testContent | Out-File -FilePath $tempFile -Encoding utf8 -ErrorAction Stop
                    
                    # Teste de leitura
                    $content = Get-Content -Path $tempFile -Raw -ErrorAction Stop
                    if ($content.Trim() -ne $testContent) {
                        throw "Conteudo nao confere. Esperado: '$testContent', Obtido: '$content'"
                    }
                    
                    # Teste de exclusão
                    Remove-Item -Path $tempFile -Force -ErrorAction Stop
                    if (Test-Path $tempFile) {
                        throw "Arquivo nao foi removido"
                    }
                }
                catch {
                    throw "Erro em operacao de arquivo: $_"
                }
                finally {
                    # Limpeza
                    if (Test-Path $tempFile) {
                        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
        @{
            Name = "Arquivo com caracteres especiais"
            Test = {
                $tempFile = Join-Path $env:TEMP "test-$(Get-Random).txt"
                $testContent = "Conteudo com acentuacao e caracteres especiais: a e i o u c a o"
                
                try {
                    # Teste de escrita
                    $testContent | Out-File -FilePath $tempFile -Encoding utf8 -ErrorAction Stop
                    
                    # Teste de leitura
                    $content = Get-Content -Path $tempFile -Raw -ErrorAction Stop
                    if ($content.Trim() -ne $testContent) {
                        throw "Conteudo com caracteres especiais nao confere"
                    }
                    
                    # Teste de exclusão
                    Remove-Item -Path $tempFile -Force -ErrorAction Stop
                    if (Test-Path $tempFile) {
                        throw "Arquivo com caracteres especiais nao foi removido"
                    }
                }
                catch {
                    throw "Erro em operacao de arquivo com caracteres especiais: $_"
                }
                finally {
                    # Limpeza
                    if (Test-Path $tempFile) {
                        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
        @{
            Name = "Arquivo grande"
            Test = {
                $tempFile = Join-Path $env:TEMP "test-large-$(Get-Random).txt"
                $testContent = "X" * 1MB # Arquivo de 1MB
                
                try {
                    # Teste de escrita
                    $testContent | Out-File -FilePath $tempFile -Encoding utf8 -ErrorAction Stop
                    
                    # Verifica tamanho
                    $fileInfo = Get-Item $tempFile -ErrorAction Stop
                    if ($fileInfo.Length -lt 1MB) {
                        throw "Arquivo grande nao foi escrito corretamente"
                    }
                    
                    # Teste de exclusão
                    Remove-Item -Path $tempFile -Force -ErrorAction Stop
                    if (Test-Path $tempFile) {
                        throw "Arquivo grande nao foi removido"
                    }
                }
                catch {
                    throw "Erro em operacao de arquivo grande: $_"
                }
                finally {
                    # Limpeza
                    if (Test-Path $tempFile) {
                        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
        @{
            Name = "Permissoes de arquivo"
            Test = {
                $tempFile = Join-Path $env:TEMP "test-perms-$(Get-Random).txt"
                
                try {
                    # Cria arquivo
                    "Test" | Out-File -FilePath $tempFile -Encoding utf8 -ErrorAction Stop
                    
                    # Testa permissões
                    $acl = Get-Acl -Path $tempFile -ErrorAction Stop
                    if (-not $acl) {
                        throw "Nao foi possivel ler as permissoes do arquivo"
                    }
                    
                    # Tenta modificar permissões
                    try {
                        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                            $currentUser,
                            "Read",
                            "Allow"
                        )
                        $acl.AddAccessRule($accessRule)
                        Set-Acl -Path $tempFile -AclObject $acl -ErrorAction Stop
                    }
                    catch {
                        Write-WarningMessage "Nao foi possivel modificar permissoes do arquivo"
                    }
                    
                    # Remove arquivo
                    Remove-Item -Path $tempFile -Force -ErrorAction Stop
                }
                catch {
                    throw "Erro em operacao de permissoes: $_"
                }
                finally {
                    # Limpeza
                    if (Test-Path $tempFile) {
                        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
        @{
            Name = "Arquivo somente leitura"
            Test = {
                $tempFile = Join-Path $env:TEMP "test-readonly-$(Get-Random).txt"
                
                try {
                    # Cria arquivo
                    "Test" | Out-File -FilePath $tempFile -Encoding utf8 -ErrorAction Stop
                    
                    # Torna somente leitura
                    Set-ItemProperty -Path $tempFile -Name IsReadOnly -Value $true -ErrorAction Stop
                    
                    # Tenta modificar (deve falhar)
                    $modified = $false
                    try {
                        "New content" | Out-File -FilePath $tempFile -Encoding utf8 -ErrorAction Stop
                        $modified = $true
                    }
                    catch {
                        # Esperado falhar
                    }
                    
                    if ($modified) {
                        throw "Arquivo somente leitura foi modificado"
                    }
                    
                    # Remove proteção e arquivo
                    Set-ItemProperty -Path $tempFile -Name IsReadOnly -Value $false -ErrorAction Stop
                    Remove-Item -Path $tempFile -Force -ErrorAction Stop
                }
                catch {
                    throw "Erro em operacao de arquivo somente leitura: $_"
                }
                finally {
                    # Limpeza
                    if (Test-Path $tempFile) {
                        Set-ItemProperty -Path $tempFile -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
                        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
        @{
            Name = "Arquivo em uso"
            Test = {
                $tempFile = Join-Path $env:TEMP "test-inuse-$(Get-Random).txt"
                $fileStream = $null
                
                try {
                    # Cria arquivo
                    "Test" | Out-File -FilePath $tempFile -Encoding utf8 -ErrorAction Stop
                    
                    # Abre arquivo para manter bloqueado
                    $fileStream = [System.IO.File]::Open($tempFile, 'Open', 'Read', 'None')
                    
                    # Tenta modificar (deve falhar)
                    $modified = $false
                    try {
                        "New content" | Out-File -FilePath $tempFile -Encoding utf8 -ErrorAction Stop
                        $modified = $true
                    }
                    catch {
                        # Esperado falhar
                    }
                    
                    if ($modified) {
                        throw "Arquivo em uso foi modificado"
                    }
                }
                catch {
                    throw "Erro em operacao de arquivo em uso: $_"
                }
                finally {
                    # Limpeza
                    if ($fileStream) {
                        $fileStream.Close()
                        $fileStream.Dispose()
                    }
                    if (Test-Path $tempFile) {
                        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
                    }
                }
            }
        }
        @{
            Name = "Caminhos invalidos"
            Test = {
                $invalidPaths = @(
                    "C:\invalid\path\file.txt",
                    "\\invalid\share\file.txt",
                    "C:\COM1", # Nome reservado
                    "C:\file.txt:stream" # ADS não suportado
                )
                
                foreach ($path in $invalidPaths) {
                    try {
                        # Tenta criar arquivo
                        "Test" | Out-File -FilePath $path -Encoding utf8 -ErrorAction Stop
                        throw "Arquivo criado em caminho invalido: $path"
                    }
                    catch {
                        # Esperado falhar
                    }
                }
            }
        }
    )

    $allPassed = $true
    foreach ($test in $tests) {
        Write-InfoMessage "`nTestando: $($test.Name)"
        try {
            & $test.Test
            Write-SuccessMessage "Teste passou: $($test.Name)"
        }
        catch {
            Write-ErrorMessage "Falha no teste: $($test.Name)"
            Write-ErrorMessage $_.Exception.Message
            $allPassed = $false
        }
    }

    return $allPassed
}

function Test-DockerOperations {
    Write-InfoMessage "Testando operacoes do Docker..."
    $allPassed = $true

    # Função auxiliar para limpar recursos Docker
    function Clear-DockerResources {
        param(
            [string]$prefix
        )
        
        Write-InfoMessage "Limpando recursos Docker com prefixo: $prefix"
        
        # Remove containers
        $containers = docker ps -a --format "{{.Names}}" 2>&1
        foreach ($container in $containers) {
            if ($container -eq $prefix) {
                docker rm -f $container 2>&1 | Out-Null
            }
        }
        
        # Remove redes
        $networks = docker network ls --filter name=$prefix --format "{{.Name}}" 2>&1
        foreach ($network in $networks) {
            docker network rm $network 2>&1 | Out-Null
        }
        
        # Remove volumes
        $volumes = docker volume ls --filter name=$prefix --format "{{.Name}}" 2>&1
        foreach ($volume in $volumes) {
            docker volume rm -f $volume 2>&1 | Out-Null
        }
    }

    # Verifica se o Docker está rodando antes de executar os testes
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

    # Prefixo único para todos os recursos deste teste
    $testPrefix = "test-$(Get-Random)"
    
    try {
        # Limpa recursos antigos que possam ter ficado de testes anteriores
        Clear-DockerResources -prefix "test-"

        $tests = @(
            @{
                Name = "Imagem Docker"
                Test = {
                    Write-InfoMessage "Testando pull de imagem..."
                    
                    # Remove imagem se existir
                    docker rmi hello-world:latest -f 2>&1 | Out-Null
                    
                    # Testa pull
                    $pullOutput = docker pull hello-world:latest 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-InfoMessage "Imagem baixada com sucesso"
                    }
                    else {
                        throw "Falha ao baixar imagem hello-world: $pullOutput"
                    }
                    
                    # Verifica se existe
                    $image = docker images hello-world:latest --format "{{.Repository}}" 2>&1
                    if (-not $image) {
                        throw "Imagem nao encontrada apos download"
                    }
                }
            }
            @{
                Name = "Rede Docker"
                Test = {
                    $networkName = "${testPrefix}-network"
                    
                    # Cria rede
                    $createOutput = docker network create $networkName 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-InfoMessage "Rede de teste criada: $networkName"
                    }
                    else {
                        throw "Falha ao criar rede: $createOutput"
                    }
                    
                    # Verifica se existe
                    $network = docker network ls --filter name=$networkName --format "{{.Name}}" 2>&1
                    if (-not $network) {
                        throw "Rede nao encontrada apos criacao"
                    }
                    
                    # Remove rede
                    $rmOutput = docker network rm $networkName 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-InfoMessage "Rede de teste removida"
                    }
                    else {
                        throw "Falha ao remover rede: $rmOutput"
                    }
                }
            }
            @{
                Name = "Container Docker"
                Test = {
                    $containerName = "${testPrefix}-container"
                    
                    # Executa container
                    $runOutput = docker run --name $containerName hello-world 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-InfoMessage "Container de teste executado"
                    }
                    else {
                        throw "Falha ao executar container: $runOutput"
                    }
                    
                    # Verifica se existe
                    $container = docker ps -a --filter name=$containerName --format "{{.Names}}" 2>&1
                    if (-not $container) {
                        throw "Container nao encontrado apos criacao"
                    }
                    
                    # Remove container
                    $rmOutput = docker rm -f $containerName 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-InfoMessage "Container de teste removido"
                    }
                    else {
                        throw "Falha ao remover container: $rmOutput"
                    }
                }
            }
            @{
                Name = "Volume Docker"
                Test = {
                    $volumeName = "${testPrefix}-volume"
                    Write-InfoMessage "Volume de teste criado: $volumeName"
                    
                    # Cria volume
                    $createOutput = docker volume create $volumeName 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-InfoMessage "Volume de teste criado"
                    }
                    else {
                        throw "Falha ao criar volume: $createOutput"
                    }
                    
                    # Verifica se existe
                    $volume = docker volume ls --filter name=$volumeName --format "{{.Name}}" 2>&1
                    if (-not $volume) {
                        throw "Volume nao encontrado apos criacao"
                    }
                    
                    # Testa uso do volume
                    $runOutput = docker run --rm -v ${volumeName}:/data hello-world 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-InfoMessage "Volume de teste utilizado com sucesso"
                    }
                    else {
                        throw "Falha ao usar volume em container: $runOutput"
                    }
                    
                    # Remove volume
                    $rmOutput = docker volume rm $volumeName 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-InfoMessage "Volume de teste removido"
                    }
                    else {
                        throw "Falha ao remover volume: $rmOutput"
                    }
                }
            }
            @{
                Name = "Limites de Recursos"
                Test = {
                    $containerName = "${testPrefix}-limits"
                    
                    # Testa limites de memória
                    $memOutput = docker run --name $containerName --memory=10m hello-world 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-InfoMessage "Limite de memoria definido com sucesso"
                    }
                    else {
                        throw "Falha ao definir limite de memoria: $memOutput"
                    }
                    
                    # Remove container
                    docker rm -f $containerName 2>&1 | Out-Null
                    
                    # Testa limites de CPU
                    $cpuOutput = docker run --name $containerName --cpus=0.5 hello-world 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-InfoMessage "Limite de CPU definido com sucesso"
                    }
                    else {
                        throw "Falha ao definir limite de CPU: $cpuOutput"
                    }
                    
                    # Remove container
                    docker rm -f $containerName 2>&1 | Out-Null
                }
            }
        )

        foreach ($test in $tests) {
            Write-InfoMessage "`nTestando: $($test.Name)"
            try {
                & $test.Test
                Write-SuccessMessage "Teste passou: $($test.Name)"
            }
            catch {
                Write-ErrorMessage "Falha no teste: $($test.Name)"
                Write-ErrorMessage $_.Exception.Message
                $allPassed = $false
            }
            finally {
                # Limpa recursos após cada teste
                Clear-DockerResources -prefix $testPrefix
            }
        }
    }
    finally {
        # Limpa todos os recursos de teste no final
        Clear-DockerResources -prefix "test-"
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
    
    # Verifica se a porta esta na lista de reservadas
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
try {
    $dockerVersion = docker version --format '{{.Server.Version}}'
    if ($LASTEXITCODE -eq 0) {
        Write-InfoMessage "Docker instalado: Docker version $dockerVersion"
    }
    else {
        exit 1
    }
}
catch {
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
