# Funções para gerenciamento de portas
function Test-PortRange {
    param(
        [int]$Port,
        [string]$PortType
    )
    
    # Validações básicas
    if ($Port -lt 1 -or $Port -gt 65535) {
        Write-ErrorMessage "Porta $Port fora do intervalo válido (1-65535)"
        return $false
    }
    
    # Verifica se a porta está na lista de reservadas
    $reservedPorts = @(80, 443, 3306, 5432, 6379, 27017)
    if ($reservedPorts -contains $Port) {
        Write-ErrorMessage "Porta $Port está reservada e não pode ser usada"
        return $false
    }
    
    # Verifica se a porta está em uso
    try {
        $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, $Port)
        $listener.Start()
        $listener.Stop()
        Write-SuccessMessage "Porta $Port está disponível"
        return $true
    }
    catch {
        Write-ErrorMessage "Porta $Port já está em uso"
        return $false
    }
}

function Get-NextAvailablePort {
    param(
        [int]$StartPort,
        [string]$PortType
    )
    
    $currentPort = $StartPort
    $maxAttempts = 100
    $attempts = 0
    
    while ($attempts -lt $maxAttempts) {
        if (Test-PortRange -Port $currentPort -PortType $PortType) {
            Write-SuccessMessage "Porta $currentPort disponível"
            return $currentPort
        }
        $currentPort++
        $attempts++
    }
    
    Write-ErrorMessage "Não foi possível encontrar uma porta disponível após $maxAttempts tentativas"
    return 0
}

Export-ModuleMember -Function Test-PortRange, Get-NextAvailablePort
