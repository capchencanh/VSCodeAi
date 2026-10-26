<#
.SYNOPSIS
  Tao (hoac nhan ve) workspace du an CodeABAP\<KH>.

  Len repo team (git):        CodeABAP\<KH>\.mcp.json.example  (giong .mcp.json nhung SAP_PASSWORD de trong)
                              CodeABAP\<KH>\.claude\settings.json (tat san server refresh cookie)
  Len repo du an (rieng KH):  CLAUDE.md, NOTES.md, TRANG_THAI.md, src\, sql\, .vscode\tasks.json, <CN>\ - xem git-du-an.ps1
                              (du an moi: script tu tao repo du an + commit dau; nhan du an team: git-du-an.ps1 noi <KH>)
  Chi tren may (gitignore):   CodeABAP\<KH>\.mcp.json (CO mat khau: env SAP_PASSWORD cua tung server GUI)

  MAT KHAU: ghi thang vao "env": { "SAP_PASSWORD": "..." } cua tung server GUI trong CodeABAP\<KH>\.mcp.json.
  Tao du an xong, script tao .mcp.json.example 1 lan. Sau nay sua .mcp.json -> chay .\scripts\cap-nhat-mcp-example.ps1 <KH>.

  LENH NHANH (Terminal, dung o goc repo):
    .\scripts\tao-du-an.ps1 <KH> <gui|cloud>       # du an SAP, vd: .\scripts\tao-du-an.ps1 ACG gui
    .\scripts\tao-du-an.ps1 <KH>                   # du an KHONG phai SAP (loai 'khac'): src\, .mcp.json rong, CLAUDE.md chung
    .\scripts\tao-chuc-nang.ps1 <KH> <CN>          # sau do tao chuc nang: .\scripts\tao-chuc-nang.ps1 ACG ZFI01
    Bi chan chay script: powershell -ExecutionPolicy Bypass -File .\scripts\tao-du-an.ps1 ACG gui

  Tao chuc nang con co cach VS Code: Ctrl+Shift+P > Tasks: Run Task > "Tao chuc nang moi"
  (xem ghi chu dau file tao-chuc-nang.ps1).

.EXAMPLE
  # Tao du an moi, lay server tu kho .mcp.all.json o goc (giu mat khau trong .mcp.json, example de trong).
  # -Servers = ten server TRONG KHO; script tu doi sang ten chuan CLD_<KH>_[REFRESH_]<DEV|CUS> / GUI_<KH>_<ENV><client>
  .\scripts\tao-du-an.ps1 SGC cloud -Servers mcp_SGC_DEV,mcp_SGC_CUS,Cloud_Refresh_SGC_DEV
  # Tao du an moi tu template (sua SAP_URL/SAP_USER/SAP_PASSWORD trong .mcp.json)
  .\scripts\tao-du-an.ps1 CADIVI gui -Client 800
  # Nhan du an cua team (da co .mcp.json.example sau git pull): lay code truoc, roi tao .mcp.json (dien mat khau)
  .\scripts\git-du-an.ps1 noi ACG
  .\scripts\tao-du-an.ps1 ACG gui
  # Da sua .mcp.json (them server, doi URL...): dung script rieng
  .\scripts\cap-nhat-mcp-example.ps1 ACG

  File da ton tai se KHONG bi ghi de.
#>
param(
  [Parameter(Mandatory = $true, Position = 0)][string]$KH,
  [Parameter(Position = 1)][ValidateSet('cloud', 'gui', 'khac')][string]$Platform = 'khac',
  [string[]]$Servers = @(),
  [string]$Client = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$proj = Join-Path $root "CodeABAP\$KH"
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Write-IfMissing([string]$path, [string]$content) {
  if (Test-Path $path) { Write-Host "  skip (da co): $path"; return }
  [IO.File]::WriteAllText($path, $content, $utf8)
  Write-Host "  tao: $path"
}

# Goc repo KHONG duoc co .mcp.json: Claude Code nap no cho moi thu muc con -> lan server cua du an.
# Kho server ca nhan dat ten .mcp.all.json (nguon cho -Servers).
$rootMcp = Join-Path $root '.mcp.json'
$srcMcp = Join-Path $root '.mcp.all.json'
if (Test-Path $rootMcp) {
  Write-Warning "Goc repo dang co .mcp.json -> moi du an se bi nap kem server goc. Doi ten thanh .mcp.all.json."
  if (-not (Test-Path $srcMcp)) { $srcMcp = $rootMcp }
}

if ($Platform -eq 'khac') { New-Item -ItemType Directory -Force (Join-Path $proj 'src') | Out-Null }
else { New-Item -ItemType Directory -Force (Join-Path $proj 'src'), (Join-Path $proj 'sql') | Out-Null }

$mcpPath = Join-Path $proj '.mcp.json'
$exPath = Join-Path $proj '.mcp.json.example'
$nhanVe = Test-Path $exPath   # da co example tu repo team -> du an cua team, khong phai du an moi

# --- .mcp.json (CO mat khau, chi tren may) ---
$nameMap = @{}   # ten server goc -> ten chuan
if (Test-Path $mcpPath) {
  Write-Host "  skip (da co): $mcpPath"
} elseif ($Servers.Count -gt 0) {
  if (-not (Test-Path $srcMcp)) { throw "Khong co kho server $srcMcp de lay -Servers" }
  $rootCfg = [IO.File]::ReadAllText($srcMcp, $utf8) | ConvertFrom-Json
  $out = [ordered]@{}
  foreach ($s in $Servers) {
    $def = $rootCfg.mcpServers.$s
    if ($null -eq $def) { throw "Khong thay server '$s' trong $srcMcp" }
    $srv = [ordered]@{}
    foreach ($p in $def.PSObject.Properties) { if ($p.Name -notin @('env', 'args')) { $srv[$p.Name] = $p.Value } }
    $a = @($def.args)
    if ($def.env -and $def.env.SAP_URL) {
      # Server GUI: giu nguyen env (ca SAP_PASSWORD); bo --url/--client/--user/--password/--system trong args
      $newName = $s
      if ($s -notmatch '^GUI_[A-Z0-9]+_(DEV|QAS|PRD)\d+$') { $newName = "GUI_$($KH.ToUpper())_DEV$($def.env.SAP_CLIENT)" }
      $newArgs = New-Object System.Collections.ArrayList
      for ($i = 0; $i -lt $a.Count; $i++) {
        if ($a[$i] -in @('--url', '--client', '--user', '--password', '--pass', '--system')) { $i++; continue }
        [void]$newArgs.Add($a[$i])
      }
      $srv['args'] = $newArgs
      $srv['env'] = $def.env
    } else {
      # Server Cloud: ten CLD_<KH>_[REFRESH_]<DEV|CUS>, cookie cookies-cloud-<KH>_<DEV|CUS>.txt
      $a = [System.Collections.ArrayList]@($a)
      $iCk = [Math]::Max($a.IndexOf('--cookie-file'), $a.IndexOf('--cookie-save'))
      $ckOld = ''
      if ($iCk -ge 0) { $ckOld = Split-Path -Leaf $a[$iCk + 1] }
      $envTag = 'DEV'
      if ($s -match 'cus' -or $ckOld -match 'cus') { $envTag = 'CUS' }
      $isRefresh = $a -contains '--browser-auth'
      $newName = "CLD_$($KH.ToUpper())_$(if ($isRefresh) { 'REFRESH_' } else { '' })$envTag"
      if ($iCk -ge 0) {
        $ckNew = "cookies-cloud-$($KH.ToUpper())_$envTag.txt"
        $a[$iCk + 1] = Join-Path (Split-Path -Parent $a[$iCk + 1]) $ckNew
        if ($ckOld -ne $ckNew) { Write-Host "  >> Cookie doi ten: $ckOld -> $ckNew (doi ten file trong thu muc vsp hoac dang nhap lai bang $newName refresh)" }
      }
      $srv['args'] = $a
      if ($def.env) { $srv['env'] = $def.env }
    }
    if ($out.Contains($newName)) { throw "Trung ten server sau chuan hoa: $newName (tu '$s')" }
    $nameMap[$s] = $newName
    $out[$newName] = $srv
  }
  Write-IfMissing $mcpPath ([ordered]@{ mcpServers = $out } | ConvertTo-Json -Depth 20)
} elseif (Test-Path $exPath) {
  # Dong nghiep da push .mcp.json.example -> tao .mcp.json tu do, nguoi dung tu dien mat khau
  Write-IfMissing $mcpPath ([IO.File]::ReadAllText($exPath, $utf8))
} else {
  $tpl = [IO.File]::ReadAllText((Join-Path $root "templates\mcp\$Platform.mcp.json.example"), $utf8)
  Write-IfMissing $mcpPath $tpl.Replace('__KH__', $KH.ToUpper()).Replace('__CLIENT__', $Client)
  if ($Platform -eq 'gui') { Write-Host "  >> Sua SAP_URL/SAP_USER trong $mcpPath" }
}

# --- .mcp.json.example (len git): tao lan dau bang script rieng (sau nay sua .mcp.json thi chay cap-nhat-mcp-example.ps1) ---
& (Join-Path $PSScriptRoot 'cap-nhat-mcp-example.ps1') $KH

# --- .claude\settings.json (dung chung): tat san server refresh cookie (browser-auth) ---
$refresh = @($Servers | Where-Object { $_ -match 'refresh' } | ForEach-Object { $nameMap[$_] })
if ($Servers.Count -eq 0 -and $Platform -eq 'cloud' -and -not (Test-Path (Join-Path $proj '.claude\settings.json'))) { $refresh = @("CLD_$($KH.ToUpper())_REFRESH_DEV") }
# Luon tao settings.json (ke ca GUI, danh sach rong) de thu muc du an la 1 "project" rieng cua Claude Code
New-Item -ItemType Directory -Force (Join-Path $proj '.claude') | Out-Null
$set = [ordered]@{ disabledMcpjsonServers = @($refresh) } | ConvertTo-Json -Depth 5
Write-IfMissing (Join-Path $proj '.claude\settings.json') $set

# --- CLAUDE.md + NOTES.md (ca nhan) ---
if ($Platform -eq 'cloud') { $platName = 'SAP S/4HANA Public Cloud' } else { $platName = 'SAP S/4HANA On-Premise (GUI)' }
if ($Servers.Count -gt 0) { $srvDev = $nameMap[$Servers[0]] } else { $srvDev = '<ten server DEV>' }
if ($Client -eq '') { $Client = '<client>' }

$claudeTpl = 'CLAUDE.md'; if ($Platform -eq 'khac') { $claudeTpl = 'CLAUDE.khac.md' }
$claude = [IO.File]::ReadAllText((Join-Path $root "templates\project\$claudeTpl"), $utf8)
$claude = $claude.Replace('__KH__', $KH).Replace('__PLATFORM_KEY__', $Platform).Replace('__PLATFORM__', $platName).Replace('__SERVER_DEV__', $srvDev).Replace('__CLIENT__', $Client)
# Dong "- [cloud] ..." cua template chi giu cho du an Public Cloud
if ($Platform -eq 'cloud') { $claude = $claude -replace '(?m)^- \[cloud\] ', '- ' } else { $claude = $claude -replace '(?m)^- \[cloud\] .*\r?\n', '' }
Write-IfMissing (Join-Path $proj 'CLAUDE.md') $claude

$notes = [IO.File]::ReadAllText((Join-Path $root 'templates\project\NOTES.md'), $utf8)
Write-IfMissing (Join-Path $proj 'NOTES.md') $notes.Replace('__KH__', $KH)

$trangThai = [IO.File]::ReadAllText((Join-Path $root 'templates\project\TRANG_THAI.md'), $utf8)
Write-IfMissing (Join-Path $proj 'TRANG_THAI.md') $trangThai.Replace('__KH__', $KH)

# VS Code task "Tao chuc nang moi" khi mo rieng thu muc du an (chi hoi ten chuc nang)
New-Item -ItemType Directory -Force (Join-Path $proj '.vscode') | Out-Null
Write-IfMissing (Join-Path $proj '.vscode\tasks.json') ([IO.File]::ReadAllText((Join-Path $root 'templates\project\tasks.json'), $utf8))

# --- Repo du an (code/tai lieu) - git-dir nam ngoai thu muc du an, xem git-du-an.ps1 ---
if (Test-Path (Join-Path $root ".git-du-an\$KH.git\HEAD")) { Write-Host "  skip (da co): repo du an .git-du-an\$KH.git" }
elseif ($nhanVe) { Write-Host "  >> Du an cua team: lay code bang .\scripts\git-du-an.ps1 noi $KH" }
else { & (Join-Path $PSScriptRoot 'git-du-an.ps1') tao $KH }

Write-Host ""
Write-Host "Xong. Mo VS Code: File > Open Folder > $proj"
Write-Host "Kiem tra trong Claude Code: /mcp (chi thay server cua $KH), /skills (thay skill team)."
Write-Host "Repo team: chi .mcp.json.example + .claude\settings.json cua du an. Code/tai lieu: .\scripts\git-du-an.ps1 luu $KH (.mcp.json co mat khau - KHONG len dau ca)."
