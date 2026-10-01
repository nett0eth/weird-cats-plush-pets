# Weird Cats Plush Pets installer for Windows (Codex / ChatGPT desktop).
#
# One command (downloads the pack, installs all 25 cats, cleans up):
#   irm https://raw.githubusercontent.com/nett0eth/weird-cats-plush-pets/main/install/install.ps1 | iex
#
# Only some cats from the one-liner (piped scripts cannot take arguments, so use PLUSH):
#   $env:PLUSH = "lucky,prism"; irm https://raw.githubusercontent.com/nett0eth/weird-cats-plush-pets/main/install/install.ps1 | iex
#
# From a clone:
#   .\install\install.ps1                 # install every cat
#   .\install\install.ps1 lucky prism     # install only some
#   .\install\install.ps1 -Uninstall      # remove them again (all, or only the ones you name)
#
# Environment: CODEX_HOME (default ~\.codex), PLUSH (cats to install), PLUSH_UNINSTALL=1,
#              PLUSH_ARCHIVE_URL (override the download: https URL or a local .zip path)
param(
  [Parameter(ValueFromRemainingArguments = $true)][string[]]$Cats,
  [switch]$Uninstall
)

& {
  param([string[]]$Cats, [bool]$Uninstall)
  $ErrorActionPreference = 'Stop'
  $ProgressPreference = 'SilentlyContinue'      # Invoke-WebRequest is very slow in Windows PowerShell 5.1 with the progress bar

  if (-not $Cats -and $env:PLUSH) { $Cats = $env:PLUSH -split '[,\s]+' | Where-Object { $_ } }
  if ($env:PLUSH_UNINSTALL -and $env:PLUSH_UNINSTALL -notin '0', 'false') { $Uninstall = $true }
  $Cats = @($Cats | Where-Object { $_ } | ForEach-Object { ($_ -replace '^weird-cats-plush-', '').ToLower() })

  $userHome = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
  $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $userHome '.codex' }
  $target = Join-Path $codexHome 'pets'
  $short = { param($n) $n -replace '^weird-cats-(plush|dots)-', '' }

  # ---- uninstall: works from what is installed, no download needed ----
  if ($Uninstall) {
    $found = 0
    if (Test-Path $target) {
      foreach ($dir in Get-ChildItem -Path $target -Directory | Where-Object { $_.Name -like 'weird-cats-plush-*' -or $_.Name -like 'weird-cats-dots-*' }) {
        if ($Cats.Count -and ($Cats -notcontains (& $short $dir.Name))) { continue }
        Remove-Item -Recurse -Force -Path $dir.FullName -Confirm:$false
        Write-Host "removed   $($dir.Name)"; $found++
      }
    }
    if (-not $found) { Write-Host "Nothing to remove in $target" }
    return
  }

  # ---- find the pets: next to this script (a clone), or download the repo zip (piped one-liner) ----
  $tmp = $null
  $here = if ($PSCommandPath) { Split-Path -Parent $PSCommandPath } else { $null }
  $source = if ($here -and (Test-Path (Join-Path (Split-Path -Parent $here) 'pets'))) { Join-Path (Split-Path -Parent $here) 'pets' } else { $null }
  try {
    if (-not $source) {
      $url = if ($env:PLUSH_ARCHIVE_URL) { $env:PLUSH_ARCHIVE_URL } else { 'https://github.com/nett0eth/weird-cats-plush-pets/archive/refs/heads/main.zip' }
      $tmp = Join-Path ([IO.Path]::GetTempPath()) ('weird-cats-plush-' + [Guid]::NewGuid().ToString('N').Substring(0, 8))
      New-Item -ItemType Directory -Force -Path $tmp | Out-Null
      $zip = Join-Path $tmp 'pack.zip'
      if (Test-Path -LiteralPath $url) { Copy-Item -LiteralPath $url -Destination $zip }
      else {
        Write-Host "Downloading Weird Cats Plush Pets..."
        try { [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12 } catch {}
        try { Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zip }
        catch { throw "Could not download $url ($($_.Exception.Message)). If the repository is still private, clone it and run .\install\install.ps1 instead." }
      }
      Expand-Archive -LiteralPath $zip -DestinationPath (Join-Path $tmp 'x') -Force
      $found = Get-ChildItem -Path (Join-Path $tmp 'x') -Directory -Recurse -Filter 'pets' | Where-Object { Get-ChildItem $_.FullName -Directory -Filter 'weird-cats-plush-*' } | Select-Object -First 1
      if (-not $found) { throw "The downloaded archive has no pets folder." }
      $source = $found.FullName
    }

    $pets = @(Get-ChildItem -Path $source -Directory | Where-Object { $_.Name -like 'weird-cats-plush-*' })
    $available = ($pets.Name | ForEach-Object { & $short $_ }) -join ', '
    if ($Cats.Count) {
      $unknown = $Cats | Where-Object { $pets.Name -notcontains "weird-cats-plush-$_" }
      if ($unknown) { Write-Warning "Unknown cat(s): $($unknown -join ', '). Available: $available" }
      $pets = @($pets | Where-Object { $Cats -contains (& $short $_.Name) })
    }
    if (-not $pets) { throw "No matching pets. Available: $available" }

    New-Item -ItemType Directory -Force -Path $target | Out-Null
    foreach ($pet in $pets) {
      $dest = Join-Path $target $pet.Name
      # early test builds were called weird-cats-dots-*: drop them so the app does not list duplicates
      $legacy = Join-Path $target ($pet.Name -replace '^weird-cats-plush-', 'weird-cats-dots-')
      if (Test-Path $legacy) { Remove-Item -Recurse -Force -Path $legacy -Confirm:$false }
      if (Test-Path -LiteralPath $dest) { Remove-Item -Recurse -Force -LiteralPath $dest -Confirm:$false }   # our own folder only: no stale files
      New-Item -ItemType Directory -Force -Path $dest | Out-Null
      Copy-Item -Force -Path (Join-Path $pet.FullName '*') -Destination $dest
      $name = (Get-Content (Join-Path $pet.FullName 'pet.json') -Raw | ConvertFrom-Json).displayName
      Write-Host "installed $name"
    }
    Write-Host ""
    Write-Host "Done: $($pets.Count) cat(s) in $target"
    Write-Host "Restart Codex or ChatGPT, open Settings > Pets and pick a cat ending in 'Weird Cats Plush Pets'."
  }
  finally { if ($tmp -and (Test-Path $tmp)) { Remove-Item -Recurse -Force -Path $tmp -Confirm:$false -ErrorAction SilentlyContinue } }
} -Cats $Cats -Uninstall ([bool]$Uninstall)
