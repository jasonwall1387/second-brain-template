# Usage: powershell -ExecutionPolicy Bypass -File install.ps1 -Destination C:\path\to\MyVault [-SkipGit]
# PowerShell 5.1+. Copies only scaffold-files.txt; preserves existing files and history.
param(
  [Parameter(Mandatory = $true)][string]$Destination,
  [switch]$SkipGit
)
$ErrorActionPreference = 'Stop'
$src = [IO.Path]::GetFullPath($PSScriptRoot)
$dest = [IO.Path]::GetFullPath($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destination))
$separator = [IO.Path]::DirectorySeparatorChar
$comparison = if ($env:OS -eq 'Windows_NT') { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }

# Refuse junctions/reparse points as well as symbolic links in both trees. This check
# includes existing ancestors, so lexical containment cannot conceal a redirected path.
function Assert-NoLinks([string]$Path) {
  $current = $Path
  while ($current) {
    $item = Get-Item -LiteralPath $current -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
      throw "Install stopped: linked path is not supported: $current"
    }
    $parent = [IO.Path]::GetDirectoryName($current)
    if ($parent -eq $current) { break }
    $current = $parent
  }
}
Assert-NoLinks $src
Assert-NoLinks $dest
$srcPrefix = $src.TrimEnd($separator) + $separator
$destPrefix = $dest.TrimEnd($separator) + $separator
if ($srcPrefix.StartsWith($destPrefix, $comparison) -or $destPrefix.StartsWith($srcPrefix, $comparison)) {
  throw 'Install stopped: source and destination must not overlap.'
}
if ((Test-Path -LiteralPath $dest) -and -not (Test-Path -LiteralPath $dest -PathType Container)) {
  throw 'Install stopped: destination must be a directory.'
}

function Assert-ScaffoldPath([string]$Base, [string]$Relative, [bool]$Required) {
  $current = $Base
  $parts = $Relative.Split('/')
  for ($i = 0; $i -lt $parts.Length; $i++) {
    $current = Join-Path $current $parts[$i]
    Assert-NoLinks $current
    if (Test-Path -LiteralPath $current) {
      $kind = if ($i -eq $parts.Length - 1) { 'Leaf' } else { 'Container' }
      if (-not (Test-Path -LiteralPath $current -PathType $kind)) { throw "Install stopped: wrong file type: $current" }
    } elseif ($Required) { throw "Install stopped: missing scaffold file: $Relative" }
  }
}
$manifest = Join-Path $src 'scaffold-files.txt'
Assert-NoLinks $manifest
$files = @([IO.File]::ReadAllLines($manifest) | Where-Object { $_ -and -not $_.StartsWith('#') })
if (-not $files.Count) { throw 'Install stopped: scaffold manifest is empty.' }
foreach ($rel in $files) {
  if ([IO.Path]::IsPathRooted($rel) -or $rel -match '[\\:]' -or @($rel.Split('/') | Where-Object { $_ -in @('', '.', '..', '.git') }).Count) {
    throw 'Install stopped: unsafe path in scaffold manifest.'
  }
  Assert-ScaffoldPath $src $rel $true
  Assert-ScaffoldPath $dest $rel $false
}

$fresh = -not (Test-Path -LiteralPath $dest) -or @(Get-ChildItem -LiteralPath $dest -Force).Count -eq 0
[IO.Directory]::CreateDirectory($dest) | Out-Null
$installed = @(); $skipped = 0
foreach ($rel in $files) {
  $target = Join-Path $dest $rel
  if (Test-Path -LiteralPath $target) {
    $skipped++; Write-Host "Preserved existing file: $rel"; continue
  }
  [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
  [IO.File]::Copy((Join-Path $src $rel), $target, $false)
  $installed += $rel
}
Write-Host "Copied $($installed.Count) scaffold files ($skipped existing files preserved)."

$git = Get-Command git -ErrorAction SilentlyContinue
if ($SkipGit -or -not $git) {
  Write-Host 'Git skipped.'
} else {
  # Capture native stderr on PS 5.1 without turning a normal non-repo exit into a
  # PowerShell error. We only use the exit code; no Git changes occur in this probe.
  $oldPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    & $git.Source -C $dest rev-parse --git-dir 2>$null | Out-Null
    $hasGit = $LASTEXITCODE -eq 0
  } finally { $ErrorActionPreference = $oldPreference }
  if (-not $fresh -or $hasGit -or (Test-Path -LiteralPath (Join-Path $dest '.git'))) {
    Write-Host 'Existing vault or Git checkout: no files staged or committed. Review additions and ignore rules yourself.'
  } else {
    Push-Location -LiteralPath $dest
    try {
      & $git.Source init -b main | Out-Null
      if ($LASTEXITCODE -ne 0) { throw 'Git initialization failed.' }
      & $git.Source add -- @installed | Out-Null
      if ($LASTEXITCODE -ne 0) { throw 'Staging scaffold files failed.' }
      & $git.Source commit -m 'Second brain initialized from template' | Out-Null
      if ($LASTEXITCODE -ne 0) { throw 'Initial scaffold commit failed. Configure Git identity and review the staged files.' }
    } finally { Pop-Location }
    Write-Host 'Local Git initialized with only the new scaffold files. Audit secrets before adding a remote.'
  }
}
Write-Host 'Next: open the vault in Obsidian, then point Claude Code at it and run /ingest.'
if ($skipped -gt 0) { Write-Host 'Review the listed collisions, especially CLAUDE.md, index.md and .gitignore, before using the new commands.' }
