param(
    [Parameter(Mandatory=$true)][string]$ClientPath,
    [int]$ParallelJobs = 1
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\Common.ps1"

$client = (Resolve-Path -LiteralPath $ClientPath).Path
if (-not (Test-Path (Join-Path $client 'Wow.exe')) -or -not (Test-Path (Join-Path $client 'Data'))) {
    throw 'ClientPath precisa ser um cliente WotLK instalado, com Wow.exe e Data.'
}

function Invoke-KitScript([string]$Name,[string[]]$Arguments=@()) {
    $script = Join-Path $PSScriptRoot $Name
    Write-Section "Executando $Name"
    & $script @Arguments
    $scriptSucceeded = $?
    if (-not $scriptSucceeded) { throw "$Name falhou." }
}

Invoke-KitScript '00-verificar-pre-requisitos.ps1'
Invoke-KitScript '01-baixar-fontes.ps1'
Invoke-KitScript -Name '02-compilar-servidor.ps1' -Arguments @('-ParallelJobs', [string]$ParallelJobs)
Invoke-KitScript '10-configurar-mysql.ps1'
Invoke-KitScript -Name '03-extrair-dados.ps1' -Arguments @('-ClientPath', $client)
Invoke-KitScript '04-configurar-servidor.ps1'
Invoke-KitScript '11-importar-bancos.ps1'
Invoke-KitScript -Name '13-configurar-reino.ps1'
Invoke-KitScript -Name '05-instalar-addons.ps1' -Arguments @('-ClientPath', $client)
Invoke-KitScript '09-validar-perfil.ps1'

Write-Host ''
Write-Host 'Instalação concluída. Leia docs/03-configurar-e-jogar.md para cadastrar sua conta e iniciar o reino.' -ForegroundColor Green
