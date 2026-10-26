<#
.SYNOPSIS
  Dau ngay lam viec: lay ban moi repo team + moi repo du an, kiem quy tac repo,
  liet ke viec dang cho trong CodeABAP\<KH>\TRANG_THAI.md (dong co Giai doan khac 'Xong').

  VS Code: Ctrl+Shift+P > Tasks: Run Task > "Bat dau ngay"
  Terminal: .\scripts\bat-dau-ngay.ps1
#>
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$root = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)

Write-Host "== 1. Repo team (skill, script, template) ==" -ForegroundColor Cyan
$branch = & git -C $root branch --show-current
& git -C $root pull -q --ff-only
if ($LASTEXITCODE -eq 0) { Write-Host "  da lay ban moi (nhanh $branch)" }
else { Write-Host "  khong lay duoc ban moi nhanh $branch (chua co upstream / co thay doi chua commit) - xem: git status" -ForegroundColor Yellow }

Write-Host "== 2. Repo du an ==" -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'git-du-an.ps1') lay

Write-Host "== 3. Kiem tra quy tac repo (QUY_TAC_PUSH.md) ==" -ForegroundColor Cyan
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'check-repo.ps1') -All |
  Where-Object { $_ -match '^(LOI|check-repo)' } | ForEach-Object { Write-Host "  $_" }

Write-Host "== 4. Viec dang cho (TRANG_THAI.md) ==" -ForegroundColor Cyan
$n = 0
foreach ($f in @(Get-ChildItem (Join-Path $root 'CodeABAP') -Filter 'TRANG_THAI.md' -Recurse -Depth 1 -File)) {
  $kh = $f.Directory.Name
  $inTable = $false   # chi doc dong du lieu: sau dong ke |---|, truoc dong khong bat dau bang |
  foreach ($line in [IO.File]::ReadAllLines($f.FullName, $utf8)) {
    if ($line -notmatch '^\|') { $inTable = $false; continue }
    if ($line -match '^\|\s*:?-{3,}') { $inTable = $true; continue }
    if (-not $inTable) { continue }
    $c = @($line.Trim().Trim('|') -split '\|' | ForEach-Object { $_.Trim() })
    if ($c.Count -lt 3 -or $c[0] -eq '') { continue }
    if ($c[1] -match '^Xong') { continue }
    Write-Host ("  {0,-8} {1,-14} [{2}] cho: {3}" -f $kh, $c[0], $c[1], $c[2])
    $n++
  }
}
if ($n -eq 0) { Write-Host "  (khong co viec dang cho)" }
