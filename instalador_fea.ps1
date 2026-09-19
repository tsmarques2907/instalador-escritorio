# Requires -RunAsAdministrator
[CmdletBinding()]
param()

$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) { $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition }
Set-Location $ScriptDir

# === SISTEMA DE LOGS (ESCOPO GLOBAL) ===
$global:logFile = Join-Path $ScriptDir "instalacao_log.txt"

function Write-Log {
    param (
        [string]$Message,
        [string]$Type = "INFO"
    )
    $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timeStamp] [$Type] $Message"
    
    switch ($Type) {
        "ERRO"    { Write-Host $Message -ForegroundColor Red }
        "AVISO"   { Write-Host $Message -ForegroundColor Yellow }
        "SUCESSO" { Write-Host $Message -ForegroundColor Green }
        default   { Write-Host $Message -ForegroundColor Cyan }
    }
    
    if ($global:logFile) {
        Add-Content -Path $global:logFile -Value $logEntry -ErrorAction SilentlyContinue
    }
}

# === FUNÇÃO AUXILIAR DE WALLPAPER ===
function Set-WallPaper {
    param ([string]$Path)
    $code = @'
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
'@
    Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue
    [Wallpaper]::SystemParametersInfo(20, 0, $Path, 3) | Out-Null
}

function Test-WingetPackage {
    param ([string]$Id)
    $check = winget list --id $Id --exact --accept-source-agreements 2>$null
    return ($check -match $Id)
}

# === SUB-ROTINAS DE INSTALAÇÃO ===
function Install-Wallpaper {
    Write-Log "`n=== [1/9] Aplicando Papel de Parede ===" "INFO"
    $wallpaperFile = Join-Path $ScriptDir "wallpaper-fea.png"
    $targetWallpaper = "C:\Windows\Web\Wallpaper\wallpaper_empresa.jpg"

    if (Test-Path $wallpaperFile) {
        Copy-Item -Path $wallpaperFile -Destination $targetWallpaper -Force
        Set-WallPaper -Path $targetWallpaper
        
        $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
        if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
        Set-ItemProperty -Path $regPath -Name "LockScreenImage" -Value $targetWallpaper -Force
        
        Write-Log "Papel de parede e tela de bloqueio configurados!" "SUCESSO"
    } else {
        Write-Log "[AVISO] Imagem de papel de parede nao encontrada." "AVISO"
    }
}

function Install-Chrome {
    Write-Log "`n=== [2/9] Instalando Google Chrome ===" "INFO"
    
    if (Test-WingetPackage -Id "Google.Chrome") {
        Write-Log "[JA INSTALADO] O Google Chrome ja esta instalado no sistema." "AVISO"
    } else {
        Write-Log "Baixando e instalando o Google Chrome..." "INFO"
        winget install --id Google.Chrome -e --silent --accept-package-agreements --accept-source-agreements
    }
    
    $loyTrustId = "foacbeippeghacocoooplemaihefjfdk"
    $chromeReg = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"
    if (-not (Test-Path $chromeReg)) { New-Item -Path $chromeReg -Force | Out-Null }
    Set-ItemProperty -Path $chromeReg -Name "1" -Value "$($loyTrustId);https://clients2.google.com/service/update2/crx" -Force
    
    cmd /c "assoc .htm=ChromeHTML" > $null
    cmd /c "assoc .html=ChromeHTML" > $null
    cmd /c "ftype ChromeHTML=`"C:\Program Files\Google\Chrome\Application\chrome.exe`" `-- `"%1`"" > $null

    Write-Log "Chrome configurado com sucesso!" "SUCESSO"
}

function Install-LoyTrustEdge {
    Write-Log "`n=== [3/9] Instalando Loy Trust no Edge ===" "INFO"
    
    $loyTrustId = "foacbeippeghacocoooplemaihefjfdk"
    $edgeReg = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist"
    $edgeSourcesReg = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallSources"
    
    if (-not (Test-Path $edgeReg)) { New-Item -Path $edgeReg -Force | Out-Null }
    if (-not (Test-Path $edgeSourcesReg)) { New-Item -Path $edgeSourcesReg -Force | Out-Null }

    Set-ItemProperty -Path $edgeSourcesReg -Name "1" -Value "https://clients2.google.com/service/update2/crx" -Force
    Set-ItemProperty -Path $edgeReg -Name "1" -Value "$($loyTrustId);https://clients2.google.com/service/update2/crx" -Force
    
    Write-Log "Extensao Loy Trust configurada no Microsoft Edge!" "SUCESSO"
}

function Install-AnyDesk {
    Write-Log "`n=== [4/9] Instalando AnyDesk ===" "INFO"
    if (Test-WingetPackage -Id "AnyDeskSoftwareGmbH.AnyDesk") {
        Write-Log "[JA INSTALADO] O AnyDesk ja esta instalado." "AVISO"
        return
    }
    winget install --id AnyDeskSoftwareGmbH.AnyDesk -e --silent --accept-package-agreements --accept-source-agreements
    
    if ($LASTEXITCODE -ne 0) {
        Write-Log "[AVISO] Tentando instalar AnyDesk por busca alternativa..." "AVISO"
        winget install --name "AnyDesk" -e --silent --accept-package-agreements --accept-source-agreements
    }
}

function Install-GoogleDrive {
    Write-Log "`n=== [5/9] Instalando Google Drive ===" "INFO"
    if (Test-WingetPackage -Id "Google.GoogleDrive") {
        Write-Log "[JA INSTALADO] O Google Drive ja esta instalado." "AVISO"
        return
    }
    winget install --id Google.GoogleDrive -e --silent --accept-package-agreements --accept-source-agreements
}

function Install-Office {
    Write-Log "`n=== [6/9] Instalando Microsoft 365 (Office) ===" "INFO"
    
    if (Test-WingetPackage -Id "Microsoft.Office") {
        Write-Log "[JA INSTALADO] O Microsoft 365 ja esta instalado." "AVISO"
        return
    }

    Write-Log "Tentando instalar Microsoft 365 via Winget..." "INFO"
    winget install --id Microsoft.Office -e --silent --accept-package-agreements --accept-source-agreements

    if ($LASTEXITCODE -eq 0) {
        Write-Log "Microsoft 365 instalado com sucesso via Winget!" "SUCESSO"
    } else {
        Write-Log "[AVISO] Winget falhou. Tentando instalador Web do Office..." "AVISO"
        $officeSetupPath = Join-Path $env:TEMP "setup.exe"
        $officeUrl = "https://officecdn.microsoft.com/pr/wsus/setup.exe"
        
        $xmlPath = Join-Path $env:TEMP "configuration.xml"
        $xmlContent = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="Current">
    <Product ID="O365ProPlusRetail">
      <Language ID="pt-br" />
    </Product>
  </Add>
  <Display Level="None" AcceptEULA="TRUE" />
</Configuration>
"@
        Set-Content -Path $xmlPath -Value $xmlContent -Force

        try {
            Invoke-WebRequest -Uri $officeUrl -OutFile $officeSetupPath -UseBasicParsing
            Write-Log "Executando instalador do Office..." "INFO"
            Start-Process -FilePath $officeSetupPath -ArgumentList "/configure `"$xmlPath`"" -Wait
            Write-Log "Instalação do Office enviada ao sistema." "SUCESSO"
        }
        catch {
            Write-Log "[ERRO] Falha ao baixar ou instalar Microsoft 365: $_" "ERRO"
        }
        finally {
            Remove-Item $officeSetupPath -Force -ErrorAction SilentlyContinue
            Remove-Item $xmlPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Install-OpenVPN {
    Write-Log "`n=== [7/9] Instalando OpenVPN Connect ===" "INFO"
    if (Test-WingetPackage -Id "OpenVPNTechnologies.OpenVPNConnect") {
        Write-Log "[JA INSTALADO] O OpenVPN Connect ja esta instalado." "AVISO"
        return
    }
    winget install --id OpenVPNTechnologies.OpenVPNConnect -e --silent --accept-package-agreements --accept-source-agreements
}

function Install-Bitdefender {
    Write-Log "`n=== [8/9] Instalando Bitdefender do Pendrive ===" "INFO"
    
    if ((Get-Service -Name "*Bitdefender*" -ErrorAction SilentlyContinue) -or (Test-Path "C:\Program Files\Bitdefender")) {
        Write-Log "[JA INSTALADO] O Bitdefender ja esta instalado." "AVISO"
        return
    }

    $bitdefenderExe = Get-ChildItem -Path $ScriptDir -Recurse -File -ErrorAction SilentlyContinue | 
                      Where-Object { $_.Name -like "*bitdefender*.exe" } | 
                      Select-Object -ExpandProperty FullName -First 1

    if ($bitdefenderExe -and (Test-Path -LiteralPath $bitdefenderExe)) {
        Write-Log "Executável encontrado: $bitdefenderExe" "INFO"
        Start-Process -FilePath $bitdefenderExe -Verb RunAs
        Write-Log "Instalador do Bitdefender executado com sucesso." "SUCESSO"
    } else {
        Write-Log "[ERRO] O instalador do Bitdefender nao foi encontrado no pendrive (Diretório: $ScriptDir)!" "ERRO"
    }
}

function Update-Windows {
    Write-Log "`n=== [9/9] Verificando Atualizacoes do Windows ===" "INFO"
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
    }

    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction SilentlyContinue
        Install-Module PSWindowsUpdate -Force -Confirm:$false -Scope CurrentUser
    }

    Get-WindowsUpdate -AcceptAll -Install -AutoReboot:$false
    Write-Log "Processo do Windows Update finalizado." "SUCESSO"
}

# === LOOP DO MENU ===
do {
    Clear-Host
    $host.UI.RawUI.WindowTitle = "MENU DE INSTALACAO - T.I. - Fragata e Antunes Advogados"
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "             MENU DE INSTALACAO DE SOFTWARES       " -ForegroundColor Yellow
    Write-Host "===================================================" -ForegroundColor Yellow
    Write-Host "[1] Aplicar Papel de Parede (Fragata e Antunes)"
    Write-Host "[2] Instalar Chrome + Extensao + Definir Padrao"
    Write-Host "[3] Instalar e Fixar Loy Trust no Microsoft Edge"
    Write-Host "[4] Instalar AnyDesk"
    Write-Host "[5] Instalar Google Drive"
    Write-Host "[6] Instalar Microsoft 365 (Office)"
    Write-Host "[7] Instalar OpenVPN Connect"
    Write-Host "[8] Instalar Bitdefender (Administrador)"
    Write-Host "[9] Executar Windows Update"
    Write-Host "---------------------------------------------------"
    Write-Host "[A] INSTALAR TUDO AUTOMATICAMENTE" -ForegroundColor Green
    Write-Host "[0] Sair" -ForegroundColor Red
    Write-Host "===================================================" -ForegroundColor Yellow
    
    $opcao = Read-Host "Digite a opcao desejada e pressione Enter"

    switch ($opcao.ToUpper()) {
        '1' { Install-Wallpaper; Read-Host "`nPressione Enter para voltar ao menu..." }
        '2' { Install-Chrome; Read-Host "`nPressione Enter para voltar ao menu..." }
        '3' { Install-LoyTrustEdge; Read-Host "`nPressione Enter para voltar ao menu..." }
        '4' { Install-AnyDesk; Read-Host "`nPressione Enter para voltar ao menu..." }
        '5' { Install-GoogleDrive; Read-Host "`nPressione Enter para voltar ao menu..." }
        '6' { Install-Office; Read-Host "`nPressione Enter para voltar ao menu..." }
        '7' { Install-OpenVPN; Read-Host "`nPressione Enter para voltar ao menu..." }
        '8' { Install-Bitdefender; Read-Host "`nPressione Enter para voltar ao menu..." }
        '9' { Update-Windows; Read-Host "`nPressione Enter para voltar ao menu..." }
        'A' {
            Write-Log "--- INICIANDO ROTINA COMPLETA DE INSTALACAO ---" "INFO"
            Install-Wallpaper
            Install-Chrome
            Install-LoyTrustEdge
            Install-AnyDesk
            Install-GoogleDrive
            Install-Office
            Install-OpenVPN
            Install-Bitdefender
            Update-Windows
            Write-Log "--- ROTINA COMPLETA FINALIZADA ---" "SUCESSO"
            Read-Host "`nPressione Enter para voltar ao menu..."
        }
        '0' { 
            Write-Host "`nSaindo..." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
            Stop-Process -Id $PID -Force
        }
        default { Write-Host "`nOpcao invalida! Tente novamente." -ForegroundColor Red; Start-Sleep -Seconds 2 }
    }
} while ($true)