# Funções utilitárias para operações Docker
function Clear-DockerResources {
    param([string]$prefix)
    
    Write-InfoMessage "Limpando recursos Docker com prefixo: $prefix"
    
    # Remove containers
    $containers = docker ps -a --filter "name=$prefix" -q
    if ($containers) {
        docker rm -f $containers 2>&1 | Out-Null
    }
    
    # Remove volumes
    $volumes = docker volume ls --filter "name=$prefix" -q
    if ($volumes) {
        docker volume rm -f $volumes 2>&1 | Out-Null
    }
    
    # Remove networks
    $networks = docker network ls --filter "name=$prefix" -q
    if ($networks) {
        docker network rm $networks 2>&1 | Out-Null
    }
}

function Test-DockerService {
    Write-InfoMessage "Verificando serviço Docker..."
    
    try {
        $service = Get-Service -Name "docker" -ErrorAction Stop
        if ($service.Status -ne "Running") {
            Write-ErrorMessage "O serviço Docker não está em execução"
            return $false
        }
        return $true
    }
    catch {
        Write-ErrorMessage "O serviço Docker não foi encontrado"
        return $false
    }
}

Export-ModuleMember -Function Clear-DockerResources, Test-DockerService
