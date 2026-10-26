<#
.SYNOPSIS
  Tao cay thu muc chuan cho 1 chuc nang trong du an: CodeABAP\<KH>\<CN>\ (len repo du an, khong len repo team).

  Chung (GUI va Cloud):
    FS\        file FS cua khach hang
    TS\        tai lieu thiet ke ky thuat (Technical Specification)
    TestCase\  TEST_CASE_<CN>.md + anh/bang chung loi
    CAU_HOI_FS_<CN>.md
    NHAT_KY_<CN>.md   moc tien do + quyet dinh (lenh /cn-* ghi vao day, khong ghi auto-memory)
  GUI (On-Premise):  dictionary\, src\, form zxlwb\scripts\, ref\ (code chuong trinh cu/chuan de tham chieu, khong sua), HUONG_DAN_TAO_<CN>.md
  Cloud:             cds\, class\, ui5\
  Khac (khong SAP):  src\

  2 CACH TAO (chi can ten du an + ten chuc nang):

  Cach 1 - VS Code, khong go lenh:
    Ctrl+Shift+P > Tasks: Run Task > "Tao chuc nang moi"
      - Mo goc repo VSCodeSkillAI : nhap ten du an (vd AVN), roi ten chuc nang (vd YPS05)
      - Mo thu muc CodeABAP\<KH>   : chi nhap ten chuc nang (task do tao-du-an.ps1 cai san)

  Cach 2 - Terminal (Ctrl+`):
    .\scripts\tao-chuc-nang.ps1 AVN YPS05           # dang dung o goc repo
    ..\..\scripts\tao-chuc-nang.ps1 YPS05           # dang dung trong CodeABAP\AVN -> tu nhan du an
    Bi chan chay script: powershell -ExecutionPolicy Bypass -File .\scripts\tao-chuc-nang.ps1 AVN YPS05

.EXAMPLE
  .\scripts\tao-chuc-nang.ps1 AVN YPS05                    # chi can ten du an + ten chuc nang
  .\scripts\tao-chuc-nang.ps1 YPS05                        # dang dung trong CodeABAP\<KH>\ -> tu nhan du an
  .\scripts\tao-chuc-nang.ps1 ACG ZFI01 -Platform gui      # ep nen tang (mac dinh tu nhan tu .mcp.json)

  Ten chuc nang tu viet hoa. Nen tang tu nhan tu .mcp.json du an: co server GUI_* -> gui, CLD_* -> cloud, khong co -> khac.
  Thu muc/file da co se KHONG bi ghi de - chay lai de bo sung phan con thieu.
  Lenh lien quan: tao-du-an.ps1 <KH> [gui|cloud]  (tao du an truoc khi tao chuc nang; bo trong = du an khong phai SAP)
#>
param(
  [Parameter(Position = 0)][string]$KH = '',
  [Parameter(Position = 1)][string]$CN = '',
  [ValidateSet('', 'gui', 'cloud', 'khac')][string]$Platform = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

# Bao loi gon 1 dong (khong in stack trace PowerShell) roi thoat
function Stop-WithMessage([string]$msg) { Write-Host "LOI: $msg" -ForegroundColor Red; exit 1 }

# Chi truyen 1 tham so -> do la ten chuc nang, du an lay tu thu muc hien tai (CodeABAP\<KH>\...)
if ($CN -eq '' -and $KH -ne '') {
  $rel = (Get-Location).Path
  $base = (Join-Path $root 'CodeABAP') + '\'
  if (-not $rel.StartsWith($base, [StringComparison]::OrdinalIgnoreCase)) { Stop-WithMessage "thieu ten du an. Cach dung: .\scripts\tao-chuc-nang.ps1 <du an> <chuc nang>  (vd: .\scripts\tao-chuc-nang.ps1 AVN YPS05)" }
  $CN = $KH; $KH = ($rel.Substring($base.Length) -split '\\')[0]
}
if ($KH -eq '' -or $CN -eq '') { Stop-WithMessage "Cach dung: .\scripts\tao-chuc-nang.ps1 <du an> <chuc nang>  (vd: .\scripts\tao-chuc-nang.ps1 AVN YPS05)" }
$KH = $KH.Trim(); $CN = $CN.Trim().ToUpper()
$proj = Join-Path $root "CodeABAP\$KH"
$feat = Join-Path $proj $CN
$utf8 = New-Object System.Text.UTF8Encoding($false)

# Du an chua co: liet ke du an dang co (phong go nham), hoi tao luon bang tao-du-an.ps1
if (-not (Test-Path $proj)) {
  Write-Host "Chua co du an '$KH' (CodeABAP\$KH)." -ForegroundColor Yellow
  $existing = @(Get-ChildItem -Directory (Join-Path $root 'CodeABAP') | Where-Object { Test-Path (Join-Path $_.FullName '.mcp.json') } | ForEach-Object { $_.Name })
  if ($existing.Count -gt 0) { Write-Host "Du an dang co: $($existing -join ', ')" }
  $ans = ''
  if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    $ans = (Read-Host "Tao du an '$KH' ngay? Nhap gui / cloud / khac (khac = khong phai SAP; Enter = bo qua)").Trim().ToLower()
  }
  if ($ans -notin @('gui', 'cloud', 'khac')) { Stop-WithMessage "chua tao gi. Tao du an truoc: .\scripts\tao-du-an.ps1 $KH [gui|cloud]" }
  & (Join-Path $PSScriptRoot 'tao-du-an.ps1') $KH $ans
  if (-not (Test-Path $proj)) { Stop-WithMessage "tao du an '$KH' khong thanh cong." }
  if ($Platform -eq '') { $Platform = $ans }
  Write-Host ""
}

# Tu nhan nen tang tu .mcp.json du an: GUI_* -> gui, CLD_* -> cloud, khong co server SAP -> khac
#   (CLAUDE.md du an ghi "(`khac`)" -> luon khac, vd du an MCP_VSP co server GUI_* chi de test)
$projClaude = Join-Path $proj 'CLAUDE.md'
if ($Platform -eq '' -and (Test-Path $projClaude) -and ([IO.File]::ReadAllText($projClaude, $utf8) -match '\(`khac`\)')) { $Platform = 'khac' }
if ($Platform -eq '') {
  $Platform = 'khac'
  $mcp = Join-Path $proj '.mcp.json'
  if (Test-Path $mcp) {
    $names = @(([IO.File]::ReadAllText($mcp, $utf8) | ConvertFrom-Json).mcpServers.PSObject.Properties.Name)
    if (@($names | Where-Object { $_ -like 'GUI_*' }).Count -gt 0) { $Platform = 'gui' }
    elseif (@($names | Where-Object { $_ -like 'CLD_*' }).Count -gt 0) { $Platform = 'cloud' }
  }
}

$dirs = @('FS', 'TS', 'TestCase')
if ($Platform -eq 'gui') { $dirs += @('dictionary', 'src', 'form zxlwb\scripts', 'ref') }
elseif ($Platform -eq 'cloud') { $dirs += @('cds', 'class', 'ui5') }
else { $dirs += @('src') }

foreach ($d in $dirs) {
  $p = Join-Path $feat $d
  if (Test-Path $p) { Write-Host "  skip (da co): $CN\$d" }
  else { New-Item -ItemType Directory -Force $p | Out-Null; Write-Host "  tao: $CN\$d\" }
}

function New-FromTemplate([string]$tplName, [string]$target) {
  if (Test-Path $target) { Write-Host "  skip (da co): $(Split-Path -Leaf $target)"; return }
  $t = [IO.File]::ReadAllText((Join-Path $root "templates\feature\$tplName"), $utf8)
  [IO.File]::WriteAllText($target, $t.Replace('__CN__', $CN).Replace('__KH__', $KH), $utf8)
  Write-Host "  tao: $($target.Substring($feat.Length + 1))"
}

New-FromTemplate 'CAU_HOI_FS.md' (Join-Path $feat "CAU_HOI_FS_$CN.md")
New-FromTemplate 'NHAT_KY.md' (Join-Path $feat "NHAT_KY_$CN.md")
New-FromTemplate 'TEST_CASE.md' (Join-Path $feat "TestCase\TEST_CASE_$CN.md")
if ($Platform -eq 'gui') { New-FromTemplate 'HUONG_DAN_TAO.md' (Join-Path $feat "HUONG_DAN_TAO_$CN.md") }

Write-Host ""
Write-Host "Xong ($Platform): $feat"
