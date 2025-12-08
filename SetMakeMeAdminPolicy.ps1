<# 
    Make Me Admin policy setup for current user (AIP plus - Stiftung Jugendsozialwerk)
#>

# --- Ensure the script runs elevated ---
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Elevation required. Restarting this script as Administrator..." -ForegroundColor Yellow
    $psi = @{
        FilePath = "powershell.exe"
        ArgumentList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        Verb = "RunAs"
    }
    Start-Process @psi
    exit
}

# --- Resolve current user in DOMAIN\username format ---
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Host "Using current user: $currentUser" -ForegroundColor Cyan

# --- Registry path ---
$regPath = 'HKLM:\SOFTWARE\Policies\Sinclair Community College\Make Me Admin'

# Create the path if it doesn't exist
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

# --- Set values ---

# Allowed Entities (REG_MULTI_SZ)
# Here we replace it with the current user.
$newAllowed = @($currentUser)
New-ItemProperty -Path $regPath -Name 'Allowed Entities' -Value $newAllowed -PropertyType MultiString -Force | Out-Null

# Remote Allowed Entities (REG_MULTI_SZ) — mirror local allowed entities
New-ItemProperty -Path $regPath -Name 'Remote Allowed Entities' -Value $newAllowed -PropertyType MultiString -Force | Out-Null

# Remove Admin Rights On Logout (DWORD: 1)
New-ItemProperty -Path $regPath -Name 'Remove Admin Rights On Logout' -Value 1 -PropertyType DWord -Force | Out-Null

# Log Elevated Processes (DWORD: 1)
New-ItemProperty -Path $regPath -Name 'Log Elevated Processes' -Value 1 -PropertyType DWord -Force | Out-Null

# Prompt For Reason (DWORD: 2)
New-ItemProperty -Path $regPath -Name 'Prompt For Reason' -Value 2 -PropertyType DWord -Force | Out-Null

# Canned Reasons (REG_MULTI_SZ)
$cannedReasons = @(
    'Software installation',
    'System update or configuration',
    'Driver or hardware issue'
)
New-ItemProperty -Path $regPath -Name 'Canned Reasons' -Value $cannedReasons -PropertyType MultiString -Force | Out-Null

Write-Host "Registry configuration completed successfully." -ForegroundColor Green
