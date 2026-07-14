# Second Brain Template - installer (Windows / PowerShell 5.1+)
#
# Usage (from anywhere):
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Destination "C:\path\to\MyVault"
# Or from inside a cloned copy of this repo:
#   .\install.ps1 -Destination "$HOME\Documents\SecondBrain"
#
# What it does: copies the template scaffold into your chosen vault folder,
# initializes local git (optional), and prints the getting-started steps.
# It never touches the network and never overwrites existing files.

param(
  [Parameter(Mandatory = $true)]
  [string]$Destination,
  [switch]$SkipGit
)

$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot

Write-Host ""
Write-Host "Second Brain Template installer" -ForegroundColor Cyan
Write-Host "Source:      $src"
Write-Host "Destination: $Destination"
Write-Host ""

# 1. Destination
if (-not (Test-Path $Destination)) {
  New-Item -ItemType Directory -Path $Destination -Force | Out-Null
  Write-Host "[1/4] Created $Destination"
} else {
  Write-Host "[1/4] Destination exists - files will be added, never overwritten"
}

# 2. Copy scaffold (skip installer + git internals; never overwrite)
$exclude = @('install.ps1', 'install.sh', '.git')
$copied = 0; $skipped = 0
Get-ChildItem -LiteralPath $src -Recurse -File | ForEach-Object {
  $rel = $_.FullName.Substring($src.Length + 1)
  $top = $rel.Split([IO.Path]::DirectorySeparatorChar)[0]
  if ($exclude -contains $top -or $exclude -contains $_.Name) { return }
  $target = Join-Path $Destination $rel
  if (Test-Path $target) { $skipped++; return }
  $dir = Split-Path $target -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  Copy-Item -LiteralPath $_.FullName -Destination $target
  $copied++
}
Write-Host "[2/4] Copied $copied files ($skipped already existed, left untouched)"

# 3. Local git (undo/history safety net - LOCAL only; see the README before adding any remote)
if (-not $SkipGit) {
  $git = Get-Command git -ErrorAction SilentlyContinue
  if ($git) {
    if (-not (Test-Path (Join-Path $Destination '.git'))) {
      Push-Location $Destination
      git init -b main | Out-Null
      git add . | Out-Null
      git commit -m "Second brain initialized from template" | Out-Null
      Pop-Location
      Write-Host "[3/4] Local git initialized (1 commit). Do NOT push to a public remote before a secrets audit."
    } else {
      Write-Host "[3/4] Git repo already present - untouched"
    }
  } else {
    Write-Host "[3/4] git not found - skipped (optional; install git for an undo safety net)"
  }
} else {
  Write-Host "[3/4] Git skipped (-SkipGit)"
}

# 4. Next steps
Write-Host "[4/4] Done." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Open $Destination as a vault in Obsidian (free) - File > Open folder as vault"
Write-Host "  2. Point Claude Code at the folder:  cd `"$Destination`"  then run  claude"
Write-Host "     (it reads CLAUDE.md automatically and becomes your librarian)"
Write-Host "  3. Look at the example- pages in wiki\ to see the shape, then delete them"
Write-Host "  4. Drop your first sources into raw\ and run /ingest"
Write-Host ""
