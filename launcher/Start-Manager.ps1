$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$desktopProject = Join-Path $PSScriptRoot 'SoloRealm.Desktop\SoloRealm.Desktop.csproj'
$startupLog = Join-Path $PSScriptRoot 'logs\launcher-startup.log'
$desktopStdout = Join-Path $PSScriptRoot 'logs\desktop-launch.stdout.log'
$desktopStderr = Join-Path $PSScriptRoot 'logs\desktop-launch.stderr.log'

try {
    Set-Location -LiteralPath $root
    if (-not (Test-Path -LiteralPath $desktopProject)) {
        throw "Código-fonte do launcher gráfico não encontrado: $desktopProject"
    }

    $dotnet = Get-Command dotnet -ErrorAction Stop
    $sdks = @(& $dotnet.Source --list-sdks 2>$null)
    if ($LASTEXITCODE -ne 0 -or -not ($sdks | Where-Object { $_ -match '^\s*9\.' })) {
        throw 'O launcher gráfico precisa do SDK .NET 9. Instale o SDK e abra Abrir-SoloRealm.vbs novamente.'
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $desktopStdout) | Out-Null
    $projectArgument = '"{0}"' -f $desktopProject
    $process = Start-Process -FilePath $dotnet.Source `
        -ArgumentList @('run', '--project', $projectArgument, '--configuration', 'Release', '--no-launch-profile') `
        -WorkingDirectory $root -WindowStyle Hidden -PassThru -Wait `
        -RedirectStandardOutput $desktopStdout -RedirectStandardError $desktopStderr
    if ($process.ExitCode -ne 0) {
        throw "A compilação/inicialização do launcher gráfico falhou (código $($process.ExitCode)). Consulte $desktopStdout e $desktopStderr."
    }
} catch {
    $message = '{0} {1}{2}{3}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $_.Exception.Message, [Environment]::NewLine, $_.ScriptStackTrace
    try {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $startupLog) | Out-Null
        [IO.File]::AppendAllText($startupLog, $message + [Environment]::NewLine + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
    } catch { }

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        [Windows.Forms.MessageBox]::Show("O SoloRealm Control Center não conseguiu iniciar.`r`n`r`n$message`r`nLog: $startupLog", 'Falha ao abrir o SoloRealm', 'OK', 'Error') | Out-Null
    } catch {
        try {
            $shell = New-Object -ComObject WScript.Shell
            [void]$shell.Popup("Falha ao abrir o SoloRealm. Consulte o log:`r`n$startupLog", 0, 'Falha ao abrir o SoloRealm', 16)
        } catch { }
    }
    exit 1
}
