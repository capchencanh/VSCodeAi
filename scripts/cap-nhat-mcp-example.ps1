<#
.SYNOPSIS
  Tao lai CodeABAP\<KH>\.mcp.json.example tu CodeABAP\<KH>\.mcp.json (xoa mat khau SAP_PASSWORD).
  .mcp.json (co mat khau) chi o tren may; .mcp.json.example moi duoc day len git.

  Dung khi: da sua .mcp.json (them/bot server, doi URL/user/client/args...) va muon cap nhat ban cho team.

.EXAMPLE
  .\scripts\cap-nhat-mcp-example.ps1 AVN        # 1 du an
  .\scripts\cap-nhat-mcp-example.ps1            # tat ca du an (hoac chi du an hien tai neu dang dung trong CodeABAP\<KH>)
  ..\..\scripts\cap-nhat-mcp-example.ps1        # dang dung trong CodeABAP\AVN -> chi AVN

  Lenh lien quan: tao-du-an.ps1 <KH> <gui|cloud> (tao du an moi - tu goi script nay 1 lan).
#>
param([Parameter(Position = 0)][string]$KH = '')

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$base = Join-Path $root 'CodeABAP'
$utf8 = New-Object System.Text.UTF8Encoding($false)

# Chon du an: tham so > thu muc hien tai trong CodeABAP\<KH> > tat ca
if ($KH -eq '') {
  $cwd = (Get-Location).Path
  if ($cwd.StartsWith($base + '\', [StringComparison]::OrdinalIgnoreCase)) { $KH = ($cwd.Substring($base.Length + 1) -split '\\')[0] }
}
if ($KH -ne '') { $projects = @($KH) }
else { $projects = @(Get-ChildItem -Directory $base | Where-Object { Test-Path (Join-Path $_.FullName '.mcp.json') } | ForEach-Object { $_.Name }) }

$done = 0
foreach ($k in $projects) {
  $mcpPath = Join-Path $base "$k\.mcp.json"
  $exPath = Join-Path $base "$k\.mcp.json.example"
  if (-not (Test-Path $mcpPath)) { Write-Host "LOI: khong co $mcpPath" -ForegroundColor Red; continue }
  try { $cfg = [IO.File]::ReadAllText($mcpPath, $utf8) | ConvertFrom-Json }
  catch { Write-Host "LOI: $mcpPath khong phai JSON hop le - $($_.Exception.Message)" -ForegroundColor Red; continue }

  $missing = @()
  foreach ($p in $cfg.mcpServers.PSObject.Properties) {
    if ($p.Value.env -and $p.Value.env.SAP_URL) {
      if (-not $p.Value.env.SAP_PASSWORD) { $missing += $p.Name }
      $p.Value.env | Add-Member -NotePropertyName SAP_PASSWORD -NotePropertyValue '' -Force
    }
  }
  $new = $cfg | ConvertTo-Json -Depth 20
  $old = ''; if (Test-Path $exPath) { $old = [IO.File]::ReadAllText($exPath, $utf8) }
  if ($new -eq $old) { Write-Host "  khong doi: CodeABAP\$k\.mcp.json.example" }
  else { [IO.File]::WriteAllText($exPath, $new, $utf8); Write-Host "  cap nhat: CodeABAP\$k\.mcp.json.example (mat khau de trong)"; $done++ }
  foreach ($m in $missing) { Write-Host "  >> Dien SAP_PASSWORD cua $m trong CodeABAP\$k\.mcp.json" -ForegroundColor Yellow }
}
if ($done -gt 0) { Write-Host "Day len git: git add CodeABAP\<KH>\.mcp.json.example" }
