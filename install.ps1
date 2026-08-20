param(
  [string]$InstallDir,
  [string]$SourceRoot,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'

$repoUrl = 'https://github.com/AOTMAN0903/DPWeb'
$archiveUrl = "$repoUrl/archive/refs/heads/main.zip"
$skillName = 'dpweb'
$requiredItems = @('SKILL.md', 'agents', 'references', 'scripts')

function Resolve-DefaultInstallDir {
  if ($InstallDir) {
    return $InstallDir
  }

  if ($env:CODEX_HOME) {
    return (Join-Path $env:CODEX_HOME "skills/$skillName")
  }

  if (-not $env:USERPROFILE) {
    throw 'Cannot resolve USERPROFILE. Pass -InstallDir explicitly.'
  }

  return (Join-Path $env:USERPROFILE ".codex/skills/$skillName")
}

function Test-SkillSource([string]$Path) {
  if (-not $Path -or -not (Test-Path -LiteralPath $Path -PathType Container)) {
    return $false
  }

  foreach ($item in $requiredItems) {
    if (-not (Test-Path -LiteralPath (Join-Path $Path $item))) {
      return $false
    }
  }

  return $true
}

function Get-LocalSourceRoot {
  if ($SourceRoot) {
    $resolved = (Resolve-Path -LiteralPath $SourceRoot).Path
    if (-not (Test-SkillSource $resolved)) {
      throw "SourceRoot is not a dpweb skill package: $resolved"
    }
    return $resolved
  }

  $scriptRoot = $PSScriptRoot
  if (Test-SkillSource $scriptRoot) {
    return $scriptRoot
  }

  return $null
}

function Get-RemoteSourceRoot {
  $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("dpweb-skill-install-" + [System.Guid]::NewGuid().ToString('N'))
  $zipPath = Join-Path $tempRoot 'dpweb-main.zip'
  New-Item -ItemType Directory -Path $tempRoot | Out-Null

  Write-Host "Downloading $archiveUrl"
  Invoke-WebRequest -Uri $archiveUrl -OutFile $zipPath

  Expand-Archive -LiteralPath $zipPath -DestinationPath $tempRoot -Force
  $source = Join-Path $tempRoot 'DPWeb-main'
  if (-not (Test-SkillSource $source)) {
    throw "Downloaded archive does not contain the expected dpweb skill package: $source"
  }

  return @{ Source = $source; TempRoot = $tempRoot }
}

function Copy-SkillPackage([string]$Source, [string]$Destination) {
  $parent = Split-Path -Parent $Destination
  if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent | Out-Null
  }

  if (Test-Path -LiteralPath $Destination) {
    if (-not $Force) {
      $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
      $backup = "$Destination.backup-$timestamp"
      Move-Item -LiteralPath $Destination -Destination $backup
      Write-Host "Existing skill backed up to $backup"
    }
    else {
      Remove-Item -LiteralPath $Destination -Recurse -Force
    }
  }

  New-Item -ItemType Directory -Path $Destination | Out-Null
  foreach ($item in $requiredItems) {
    Copy-Item -LiteralPath (Join-Path $Source $item) -Destination $Destination -Recurse -Force
  }
}

$targetDir = Resolve-DefaultInstallDir
$sourceRootToUse = Get-LocalSourceRoot
$tempRootToClean = $null

try {
  if (-not $sourceRootToUse) {
    $remote = Get-RemoteSourceRoot
    $sourceRootToUse = $remote.Source
    $tempRootToClean = $remote.TempRoot
  }

  Copy-SkillPackage -Source $sourceRootToUse -Destination $targetDir

  Write-Host ''
  Write-Host "Installed $skillName skill to: $targetDir"
  Write-Host 'Restart Codex or reload skills if the new skill does not appear immediately.'
}
finally {
  if ($tempRootToClean -and (Test-Path -LiteralPath $tempRootToClean)) {
    Remove-Item -LiteralPath $tempRootToClean -Recurse -Force
  }
}
