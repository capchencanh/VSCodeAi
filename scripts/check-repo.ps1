<#
.SYNOPSIS
  Kiem tra quy tac push cua repo (xem QUY_TAC_PUSH.md). Moi loi in kem ma quy tac Rxx.

  -Staged : chi kiem file dang staged (pre-commit hook goi che do nay)
  -All    : kiem moi file dang track (CI / chay tay)

  Exit 1 neu co LOI (chan commit/push). CANH BAO chi in ra, khong chan.
.EXAMPLE
  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\check-repo.ps1 -All
#>
param([switch]$Staged, [switch]$All)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if (-not $Staged -and -not $All) { $Staged = $true }

$script:errors = New-Object System.Collections.ArrayList
$script:warns = New-Object System.Collections.ArrayList
function Err([string]$rule, [string]$file, [string]$msg) { [void]$script:errors.Add("[$rule] $file : $msg") }
function Warn([string]$rule, [string]$file, [string]$msg) { [void]$script:warns.Add("[$rule] $file : $msg") }

# Doc noi dung file: ban staged (index) khi -Staged, ban working tree khi -All. Khong co -> $null
function Read-RepoFile([string]$p) {
  if ($Staged) {
    $out = & git show ":$p" 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }
    return ($out -join "`n")
  }
  if (-not (Test-Path -LiteralPath $p)) { return $null }
  return [IO.File]::ReadAllText((Join-Path $root $p), (New-Object System.Text.UTF8Encoding($false)))
}
function Read-Json([string]$p) {
  $t = Read-RepoFile $p
  if ($null -eq $t) { return $null }
  try { return ($t | ConvertFrom-Json) } catch { Err 'R3' $p "JSON khong hop le: $($_.Exception.Message)"; return $null }
}
function Get-Arg($argsArr, [string]$flag) {
  $a = @($argsArr); $i = [array]::IndexOf($a, $flag)
  if ($i -ge 0 -and $i + 1 -lt $a.Count) { return $a[$i + 1] }
  return $null
}

# ---------- Danh sach file can kiem ----------
if ($Staged) { $files = @(& git diff --cached --name-only --diff-filter=ACMR) }
else { $files = @(& git ls-files) + @(& git ls-files --others --exclude-standard) }   # tracked + file moi chua add (khong tinh file ignore)
$files = @($files | Where-Object { $_ })

# Gia tri mat khau duoc phep (placeholder): rong, ..., <...>, ${...}, __X__, ***, {...}
$okPw = '^\s*$|^\.\.\.$|^<.*>$|^\$\{.*\}$|^__.*__$|^\*+$|\{'

foreach ($f in $files) {
  # R2 - duong dan bi cam
  if ($f -match '^Backup/|^\.agents/|^\.git-du-an/|^skills-lock\.json$|(^|/)UserName\.md$|(^|/)CLAUDE\.local\.md$|\.bak$|(^|/)\.env$|^\.vsp\.json$|^\.mcp\.json$|^\.mcp\.all\.json$|(^|/)cookies[^/]*\.txt$') {
    Err 'R2' $f 'file ca nhan/bi mat khong duoc day len git'
  }
  if ($f -match '^CodeABAP/[^/]+/\.mcp\.json$') {
    Err 'R2' $f '.mcp.json du an CO MAT KHAU - khong day; chi day .mcp.json.example (tao bang scripts\tao-du-an.ps1)'
  } elseif ($f -match '^CodeABAP/' -and $f -notmatch '^CodeABAP/[^/]+/(\.mcp\.json\.example|\.claude/settings\.json)$') {
    Err 'R2' $f 'trong CodeABAP/ chi duoc day .mcp.json.example, .claude/settings.json - code/tai lieu du an luu bang: .\scripts\git-du-an.ps1 luu <KH>'
  }

  # R8 - file lon
  if ($Staged) { $size = [int64](& git cat-file -s ":$f" 2>$null) } elseif (Test-Path -LiteralPath $f) { $size = (Get-Item -LiteralPath $f).Length } else { $size = 0 }
  if ($size -gt 5MB) { Err 'R8' $f ("file {0:N1} MB > 5 MB" -f ($size / 1MB)) }

  # R1 - mat khau that trong noi dung (bo qua file nhi phan)
  if ($f -match '\.(xlsx|docx|pptx|png|jpg|jpeg|gif|zip|rar|pdf|exe|dll)$') { continue }
  $t = Read-RepoFile $f
  if ($null -eq $t) { continue }
  $ln = 0
  foreach ($line in ($t -split "`n")) {
    $ln++
    $m = [regex]::Match($line, '"(SAP_PASSWORD|password|pass)"\s*:\s*"([^"]*)"', 'IgnoreCase')
    if ($m.Success -and $m.Groups[2].Value -notmatch $okPw) { Err 'R1' "${f}:$ln" "mat khau that ($($m.Groups[1].Value)) - chi ghi trong .mcp.json tren may, file day len de trong" }
    $m = [regex]::Match($line, '^\s*(SAP_PASSWORD|VSP_\w+_PASSWORD)\s*=\s*(.*)$')
    if ($m.Success -and $m.Groups[2].Value.Trim() -notmatch $okPw) { Err 'R1' "${f}:$ln" "mat khau that ($($m.Groups[1].Value))" }
  }
}

# ---------- R3/R4/R5/R6 - cau hinh du an CodeABAP/<KH>/ (kiem .mcp.json.example - ban day len git) ----------
# vsp.exe che do MCP chi doc SAP_* tu flag/env/.env (khong doc .vsp.json, --system). Server GUI: env SAP_URL/USER/CLIENT/PASSWORD.
# .mcp.json tren may co mat khau; .mcp.json.example (len git) giong het nhung SAP_PASSWORD = "".
$projDirs = @($files | Where-Object { $_ -match '^CodeABAP/[^/]+/' } | ForEach-Object { ($_ -split '/')[1] } | Select-Object -Unique)
foreach ($kh in $projDirs) {
  $KHU = $kh.ToUpper()
  $mcpP = "CodeABAP/$kh/.mcp.json.example"; $setP = "CodeABAP/$kh/.claude/settings.json"
  $mcp = Read-Json $mcpP; $set = Read-Json $setP
  $disabled = @(); if ($set) { $disabled = @($set.disabledMcpjsonServers) }

  # R10 (-All, tren may): .mcp.json.example phai khop .mcp.json (tru mat khau) - lech thi chay lai tao-du-an.ps1
  $localP = Join-Path $root "CodeABAP\$kh\.mcp.json"
  if ($All -and $mcp -and (Test-Path $localP)) {
    try {
      $loc = [IO.File]::ReadAllText($localP, (New-Object System.Text.UTF8Encoding($false))) | ConvertFrom-Json
      foreach ($p in $loc.mcpServers.PSObject.Properties) { if ($p.Value.env -and $p.Value.env.PSObject.Properties.Name -contains 'SAP_PASSWORD') { $p.Value.env.SAP_PASSWORD = '' } }
      if (($loc | ConvertTo-Json -Depth 20 -Compress) -ne ($mcp | ConvertTo-Json -Depth 20 -Compress)) { Warn 'R10' $mcpP "khac .mcp.json tren may - chay: .\scripts\cap-nhat-mcp-example.ps1 $kh" }
    } catch { Warn 'R10' "CodeABAP/$kh/.mcp.json" "khong doc duoc: $($_.Exception.Message)" }
  }

  if ($mcp) {
    foreach ($p in $mcp.mcpServers.PSObject.Properties) {
      $n = $p.Name; $s = $p.Value; $a = @($s.args)
      $pwVal = $null; if ($s.env) { $pwVal = $s.env.SAP_PASSWORD }
      if ($pwVal) { Err 'R1' $mcpP "$n co SAP_PASSWORD trong file example - phai de trong """"" }
      if (($a -contains '--password') -or ($a -contains '--pass') -or ($a -contains '-p')) { Err 'R1' $mcpP "$n truyen mat khau qua args" }
      $cookie = Get-Arg $a '--cookie-file'; if (-not $cookie) { $cookie = Get-Arg $a '--cookie-save' }
      $isCloud = ($null -ne $cookie) -or ($a -contains '--browser-auth')
      if ($isCloud) {
        $m = [regex]::Match($n, "^CLD_$([regex]::Escape($KHU))_(REFRESH_)?(DEV|CUS)$")
        if (-not $m.Success) { Err 'R3' $mcpP "ten server '$n' sai quy uoc CLD_${KHU}_[REFRESH_]<DEV|CUS>"; continue }
        $envTag = $m.Groups[2].Value
        $want = "cookies-cloud-${KHU}_$envTag.txt"
        if ($cookie -and (Split-Path -Leaf $cookie) -ne $want) { Err 'R3' $mcpP "$n dung cookie '$(Split-Path -Leaf $cookie)', phai la '$want'" }
        if ($m.Groups[1].Success -and $disabled -notcontains $n) { Err 'R5' $setP "server refresh '$n' phai nam trong disabledMcpjsonServers (tranh bat trinh duyet moi lan mo)" }
      } else {
        if ($n -notmatch '^GUI_[A-Z0-9]+_(DEV|QAS|PRD)\d+$') { Err 'R3' $mcpP "ten server '$n' sai quy uoc GUI_<KH>_<DEV|QAS|PRD><client>" }
        if ($a -contains '--system') { Err 'R4' $mcpP "$n dung --system - che do MCP bo qua, server se loi 'SAP URL is required'" }
        $hasUrl = ($s.env -and $s.env.SAP_URL) -or ($a -contains '--url')
        if (-not $hasUrl) { Err 'R4' $mcpP "$n (GUI) thieu SAP_URL trong env" }
        foreach ($k in @('SAP_USER', 'SAP_CLIENT')) { if (-not ($s.env -and $s.env.$k)) { Warn 'R4' $mcpP "$n thieu $k trong env" } }
        if ($n -match '_PRD\d+$' -and $a -notcontains '--read-only') { Err 'R6' $mcpP "$n la PRD - bat buoc --read-only" }
      }
    }
  }
}

# ---------- R7 - skill ----------
foreach ($f in @($files | Where-Object { $_ -match '^\.claude/skills/[^/]+/SKILL\.md$' })) {
  $folder = ($f -split '/')[2]
  $t = Read-RepoFile $f
  if ($null -eq $t) { continue }
  $fm = [regex]::Match($t.TrimStart([char]0xFEFF), '^---\s*\r?\n(.*?)\r?\n---', 'Singleline')
  if (-not $fm.Success) { Err 'R7' $f 'thieu frontmatter --- name/description ---'; continue }
  $nm = [regex]::Match($fm.Groups[1].Value, '(?m)^name:\s*(.+?)\s*$')
  if (-not $nm.Success -or $nm.Groups[1].Value.Trim("'`"") -ne $folder) { Err 'R7' $f "name phai trung ten thu muc '$folder'" }
  $ds = [regex]::Match($fm.Groups[1].Value, '(?m)^description:\s*(.+)$')
  # Skill lenh (/ten, disable-model-invocation: true): description khong nap vao context -> khong can cong thuc TRIGGER/SKIP
  $cmdOnly = $fm.Groups[1].Value -match '(?m)^disable-model-invocation:\s*true\s*$'
  if (-not $ds.Success) { Err 'R7' $f 'thieu description' }
  else {
    $dv = $ds.Groups[1].Value.Trim().Trim("'`"")
    if ($dv.Length -gt 1024) { Err 'R7' $f "description $($dv.Length) ky tu > 1024 (gioi han Agent Skills) - rut gon" }
    if (-not $cmdOnly -and ($dv -notmatch 'TRIGGER' -or $dv -notmatch 'SKIP')) { Warn 'R7' $f 'description nen theo cong thuc 3 ve (chu de / TRIGGER / SKIP) - skill skill-authoring' }
  }
  # Trung ten skill global (~/.claude/skills) -> ban global duoc nap thay ban team (chi kiem tren may, -All)
  if ($All -and $env:USERPROFILE -and (Test-Path (Join-Path $env:USERPROFILE ".claude\skills\$folder\SKILL.md"))) { Warn 'R7' $f "trung ten skill global ~/.claude/skills/$folder - ban global che ban team, xoa/doi ten ban global" }
}
foreach ($f in @($files | Where-Object { $_ -match '^\.claude/skills/.*\.md$' })) {
  $t = Read-RepoFile $f
  if ($t -and $t -match '(?m)^\s*"\s*\S+\s+(add|modify|comment)\s+(begin|end)\b') { Warn 'R7' $f 'co marker kieu code ("... add begin/end) trong file .md - bo marker, ghi dung section' }
}

# ---------- R9 - goc repo khong co .mcp.json (chi kiem tren may, -All) ----------
if ($All -and (Test-Path (Join-Path $root '.mcp.json'))) {
  Warn 'R9' '.mcp.json' 'goc repo dang co .mcp.json - Claude Code nap no cho MOI thu muc con, lan voi server cua du an. Doi ten thanh .mcp.all.json'
}

# ---------- R11 - thu muc du an khong co .git rieng (chi kiem tren may, -All) ----------
# Thu muc co .git -> Claude Code dung tim skill tai do, mat toan bo skill repo team (thu 23.10.2026). Repo du an: scripts\git-du-an.ps1
if ($All -and (Test-Path (Join-Path $root 'CodeABAP'))) {
  foreach ($d in @(Get-ChildItem -Directory (Join-Path $root 'CodeABAP'))) {
    if (Test-Path (Join-Path $d.FullName '.git')) { Err 'R11' "CodeABAP/$($d.Name)/.git" 'du an co .git rieng -> Claude Code khong nap skill team. Dung git-dir ngoai: .\scripts\git-du-an.ps1 (HUONG_DAN_CAU_TRUC.md muc 8)' }
  }
}

# ---------- Ket qua ----------
foreach ($w in $script:warns) { Write-Host "CANH BAO $w" -ForegroundColor Yellow }
foreach ($e in $script:errors) { Write-Host "LOI      $e" -ForegroundColor Red }
$mode = if ($Staged) { 'staged' } else { 'all' }
Write-Host ("check-repo ({0}): {1} file, {2} loi, {3} canh bao. Quy tac: QUY_TAC_PUSH.md" -f $mode, $files.Count, $script:errors.Count, $script:warns.Count)
if ($script:errors.Count -gt 0) { exit 1 }
exit 0
