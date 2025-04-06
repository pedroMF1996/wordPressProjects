# Função centralizada de logging
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Error', 'Warning')]
        [string]$Level = 'Info'
    )
    
    $colors = @{
        Info = 'Cyan'
        Success = 'Green'
        Error = 'Red'
        Warning = 'Yellow'
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

function Write-InfoMessage { param([string]$Message) Write-Log -Message $Message -Level 'Info' }
function Write-SuccessMessage { param([string]$Message) Write-Log -Message $Message -Level 'Success' }
function Write-ErrorMessage { param([string]$Message) Write-Log -Message $Message -Level 'Error' }
function Write-WarningMessage { param([string]$Message) Write-Log -Message $Message -Level 'Warning' }

Export-ModuleMember -Function Write-Log, Write-InfoMessage, Write-SuccessMessage, Write-ErrorMessage, Write-WarningMessage
