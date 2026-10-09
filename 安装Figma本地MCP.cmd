@echo off
setlocal EnableExtensions
chcp 65001 >nul
title Install Figma Desktop MCP for Codex

set "INSTALLER_FILE=%~f0"
set "PAYLOAD_FILE=%TEMP%\figma-desktop-mcp-install-%RANDOM%-%RANDOM%.ps1"

echo.
echo ============================================================
echo   Figma Desktop MCP - Codex Installer
echo ============================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { $content = [System.IO.File]::ReadAllText($env:INSTALLER_FILE); $marker = ':__POWERSHELL_PAYLOAD__'; $index = $content.LastIndexOf($marker); if ($index -lt 0) { throw 'Installer payload marker was not found.' }; $payload = $content.Substring($index + $marker.Length).TrimStart([char]13, [char]10); [System.IO.File]::WriteAllText($env:PAYLOAD_FILE, $payload, [System.Text.Encoding]::Unicode) }"
if not errorlevel 1 goto payload_ready
set "INSTALL_EXIT_CODE=%ERRORLEVEL%"
echo.
echo Could not extract the installer payload. Exit code: %INSTALL_EXIT_CODE%
echo This window will stay open so you can read the error above.
if not "%FIGMA_MCP_INSTALLER_NO_PAUSE%"=="1" pause
exit /b %INSTALL_EXIT_CODE%

:payload_ready
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PAYLOAD_FILE%" %*
set "INSTALL_EXIT_CODE=%ERRORLEVEL%"

if exist "%PAYLOAD_FILE%" del /f /q "%PAYLOAD_FILE%" >nul 2>&1

if "%INSTALL_EXIT_CODE%"=="0" (
  echo.
  echo Installation workflow completed successfully.
  echo Press any key to close this window.
  if not "%FIGMA_MCP_INSTALLER_NO_PAUSE%"=="1" pause >nul
) else (
  echo.
  echo Installation failed with exit code %INSTALL_EXIT_CODE%.
  echo This window will stay open so you can read the error above.
  if not "%FIGMA_MCP_INSTALLER_NO_PAUSE%"=="1" pause
)
exit /b %INSTALL_EXIT_CODE%

:__POWERSHELL_PAYLOAD__
param(
    [switch]$Force,
    [switch]$SkipLaunch
)

$ErrorActionPreference = 'Stop'
$serverName = 'figma-desktop'
$serverUrl = 'http://127.0.0.1:3845/mcp'

function Write-Step {
    param([string]$Message)
    Write-Host ''
    Write-Host ('[{0}] {1}' -f (Get-Date -Format 'HH:mm:ss'), $Message) -ForegroundColor Cyan
}

function Find-CodexExecutable {
    $command = Get-Command 'codex.exe' -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $command = Get-Command 'codex' -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin\offline-cli\runtime\codex.exe'),
        (Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin\offline-cli\shim\codex.cmd'),
        (Join-Path $env:USERPROFILE '.local\bin\codex.exe')
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    throw '未找到 Codex 命令行程序。请先安装或更新 Codex 桌面应用，然后重新运行本安装器。'
}

function Find-FigmaExecutable {
    $running = Get-Process -Name 'Figma' -ErrorAction SilentlyContinue |
        Where-Object { $_.Path } |
        Select-Object -First 1
    if ($running) {
        return $running.Path
    }

    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Figma\Figma.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Figma\Figma.exe'),
        (Join-Path $env:ProgramFiles 'Figma\Figma.exe')
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }

    return $null
}

function Test-LocalPort {
    param(
        [string]$HostName = '127.0.0.1',
        [int]$Port = 3845,
        [int]$TimeoutMilliseconds = 1200
    )

    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $asyncResult = $client.BeginConnect($HostName, $Port, $null, $null)
        if (-not $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMilliseconds, $false)) {
            return $false
        }
        $client.EndConnect($asyncResult)
        return $true
    }
    catch {
        return $false
    }
    finally {
        $client.Dispose()
    }
}

function Invoke-Codex {
    param([string[]]$Arguments)

    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = & $script:codexPath @Arguments 2>&1
        $exitCode = $LASTEXITCODE
        return [pscustomobject]@{
            ExitCode = $exitCode
            Output = (($output | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine)
        }
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
}

try {
    Write-Step '检查 Codex 和 Figma 桌面端'
    $script:codexPath = Find-CodexExecutable
    $figmaPath = Find-FigmaExecutable

    Write-Host ('Codex: {0}' -f $script:codexPath)
    if ($figmaPath) {
        Write-Host ('Figma: {0}' -f $figmaPath)
    }
    else {
        Write-Warning '未找到 Figma 桌面应用。Codex 配置仍会安装，但使用本地 MCP 前需要先安装 Figma Desktop。'
    }

    Write-Step ('检查 MCP 配置：{0}' -f $serverName)
    $existing = Invoke-Codex -Arguments @('mcp', 'get', $serverName)
    $alreadyCorrect = $existing.ExitCode -eq 0 -and $existing.Output.Contains($serverUrl)

    if ($alreadyCorrect -and -not $Force) {
        Write-Host ('已正确配置，无需重复写入：{0}' -f $serverUrl) -ForegroundColor Green
    }
    else {
        $codexHome = if ($env:CODEX_HOME) {
            $env:CODEX_HOME
        }
        else {
            Join-Path $env:USERPROFILE '.codex'
        }
        $configPath = Join-Path $codexHome 'config.toml'

        if (Test-Path -LiteralPath $configPath -PathType Leaf) {
            $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            $backupPath = '{0}.figma-mcp-backup-{1}' -f $configPath, $timestamp
            Copy-Item -LiteralPath $configPath -Destination $backupPath
            Write-Host ('配置备份：{0}' -f $backupPath)
        }

        if ($existing.ExitCode -eq 0) {
            Write-Host '正在移除旧的同名配置...'
            $remove = Invoke-Codex -Arguments @('mcp', 'remove', $serverName)
            if ($remove.ExitCode -ne 0) {
                throw "无法移除旧配置。`n$($remove.Output)"
            }
        }

        Write-Host ('正在注册：{0} -> {1}' -f $serverName, $serverUrl)
        $add = Invoke-Codex -Arguments @('mcp', 'add', $serverName, '--url', $serverUrl)
        if ($add.ExitCode -ne 0) {
            throw "Codex MCP 注册失败。`n$($add.Output)"
        }
    }

    Write-Step '验证 Codex MCP 配置'
    $verified = Invoke-Codex -Arguments @('mcp', 'get', $serverName)
    if ($verified.ExitCode -ne 0 -or -not $verified.Output.Contains($serverUrl)) {
        throw "配置验证失败。`n$($verified.Output)"
    }
    Write-Host $verified.Output
    Write-Host 'Codex 侧配置已安装完成。' -ForegroundColor Green

    Write-Step '检查 Figma 本地 MCP 服务'
    if (Test-LocalPort) {
        Write-Host ('服务正在运行：{0}' -f $serverUrl) -ForegroundColor Green
        Write-Host ''
        Write-Host '全部就绪。请重启 Codex 或新建聊天，让工具列表重新加载。' -ForegroundColor Green
        exit 0
    }

    if ($figmaPath -and -not $SkipLaunch) {
        $figmaRunning = Get-Process -Name 'Figma' -ErrorAction SilentlyContinue
        if (-not $figmaRunning) {
            Write-Host '正在启动 Figma Desktop...'
            Start-Process -FilePath $figmaPath
            Start-Sleep -Seconds 3
        }
    }

    if (Test-LocalPort) {
        Write-Host ('服务正在运行：{0}' -f $serverUrl) -ForegroundColor Green
        Write-Host ''
        Write-Host '全部就绪。请重启 Codex 或新建聊天，让工具列表重新加载。' -ForegroundColor Green
        exit 0
    }

    Write-Host ''
    Write-Host 'Codex 侧已安装完成，但 Figma 本地服务尚未开启。' -ForegroundColor Yellow
    Write-Host '请在 Figma Desktop 中完成一次以下操作：' -ForegroundColor Yellow
    Write-Host '  1. 打开任意 Figma Design 文件'
    Write-Host '  2. 按 Shift+D 进入 Dev Mode'
    Write-Host '  3. 在右侧 Inspect 面板的 MCP server 区域点击 Enable desktop MCP server'
    Write-Host '  4. 重新运行本安装器验证，随后重启 Codex 或新建聊天'
    Write-Host ''
    Write-Host ('本地地址：{0}' -f $serverUrl)
    Write-Host '官方说明：https://developers.figma.com/docs/figma-mcp-server/local-server-installation/'
    exit 0
}
catch {
    Write-Error $_
    exit 1
}
