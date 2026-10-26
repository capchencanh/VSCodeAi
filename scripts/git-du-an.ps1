<#
.SYNOPSIS
  Repo git RIENG cho tung du an CodeABAP\<KH>\ (code, FS, TS, NOTES, TRANG_THAI...), private tren GitHub.
  Repo team VSCodeSkillAI chi giu bo kit + .mcp.json.example, .claude\settings.json cua du an.

  Git-dir nam NGOAI thu muc du an: .git-du-an\<KH>.git o goc repo (da gitignore).
  KHONG git init / git clone thang vao CodeABAP\<KH>: thu muc co .git rieng -> Claude Code khong nap skill cua repo team.

  LENH (dung o goc repo; dang dung trong CodeABAP\<KH> thi bo <KH>):
    .\scripts\git-du-an.ps1 tao <KH>                # du an moi: tao repo + commit dau (chi tren may)
    .\scripts\git-du-an.ps1 noi <KH> [-Url <url>]   # noi GitHub: nhan du an dong nghiep / day lan dau
    .\scripts\git-du-an.ps1 luu [<KH>] [-m "..."]   # add + commit + push (bo <KH> = moi du an)
    .\scripts\git-du-an.ps1 lay [<KH>]              # lay ban moi tu GitHub
    .\scripts\git-du-an.ps1 xem [<KH>]              # thay doi chua luu, commit chua day, 3 commit gan nhat
  VS Code: Ctrl+Shift+P > Tasks: Run Task > "Luu du an" / "Lay ban moi du an".

  Mac dinh -Url: https://github.com/citekcstech/abap-<kh>.git (tao repo PRIVATE tren GitHub truoc khi 'noi').
  Khong len repo du an: .mcp.json (mat khau), .mcp.json.example + .claude\settings.json (thuoc repo team), cookie, .env, file nen.
  Lenh git bat ky: git --git-dir=.git-du-an\<KH>.git --work-tree=CodeABAP\<KH> <lenh>
#>
param(
  [Parameter(Position = 0)][ValidateSet('tao', 'noi', 'luu', 'lay', 'xem')][string]$Lenh = 'xem',
  [Parameter(Position = 1)][string]$KH = '',
  [string]$Url = '',
  [Alias('m')][string]$Message = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$gdRoot = Join-Path $root '.git-du-an'
$defaultUrl = 'https://github.com/citekcstech/abap-{0}.git'
$exclude = @(
  '# Khong len repo du an (scripts\git-du-an.ps1 tao)',
  '.mcp.json', '/.mcp.json.example', '/.claude/settings.json', '.claude/settings.local.json', '.claude/scheduled_tasks.lock',
  '.env', '.vsp.json', 'cookies*.txt', '*.rar', '*.zip', '~$*', 'Thumbs.db', 'desktop.ini'
)
$script:failed = $false

function Stop-WithMessage([string]$msg) { Write-Host "LOI: $msg" -ForegroundColor Red; exit 1 }

# Dang dung trong CodeABAP\<KH>\... ma khong truyen <KH> -> tu nhan du an
if ($KH -eq '') {
  $cwd = (Get-Location).Path
  $base = (Join-Path $root 'CodeABAP') + '\'
  if ($cwd.StartsWith($base, [StringComparison]::OrdinalIgnoreCase)) { $KH = ($cwd.Substring($base.Length) -split '\\')[0] }
}

function Get-GitDir([string]$kh) { Join-Path $gdRoot "$kh.git" }
function Get-WorkTree([string]$kh) { Join-Path $root "CodeABAP\$kh" }
function Test-Repo([string]$kh) { Test-Path (Join-Path (Get-GitDir $kh) 'HEAD') }

# git tren repo du an, hien stderr (tien trinh push/pull); $LASTEXITCODE = ma thoat git
function G([string]$kh) {
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  try { & git --git-dir="$(Get-GitDir $kh)" --work-tree="$(Get-WorkTree $kh)" @args } finally { $ErrorActionPreference = $old }
}
# Nhu G nhung bo stderr (dung khi chi can lay ket qua)
function GQ([string]$kh) {
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  try { & git --git-dir="$(Get-GitDir $kh)" --work-tree="$(Get-WorkTree $kh)" @args 2>$null } finally { $ErrorActionPreference = $old }
}

function Initialize-Repo([string]$kh) {
  $wt = Get-WorkTree $kh
  if (Test-Path (Join-Path $wt '.git')) { Stop-WithMessage "CodeABAP\$kh co .git rieng -> Claude Code khong nap skill team. Xem HUONG_DAN_CAU_TRUC.md muc 8." }
  if (Test-Repo $kh) { return }
  New-Item -ItemType Directory -Force $gdRoot | Out-Null
  GQ $kh init -q -b main | Out-Null
  if ($LASTEXITCODE -ne 0) { Stop-WithMessage "git init that bai cho $kh" }
  [IO.File]::WriteAllLines((Join-Path (Get-GitDir $kh) 'info\exclude'), $exclude)
  GQ $kh config core.quotepath false | Out-Null
  GQ $kh config core.longpaths true | Out-Null
  Write-Host "  $kh : tao repo du an .git-du-an\$kh.git"
}

# pull --rebase; xung dot -> huy rebase (giu nguyen commit tren may, chua day), bao file xung dot
function Invoke-PullRebase([string]$kh) {
  G $kh pull -q --rebase --autostash origin main | Out-Host
  if ($LASTEXITCODE -eq 0) { return $true }
  $conf = @(GQ $kh diff --name-only --diff-filter=U)
  $gd = Get-GitDir $kh
  if ((Test-Path (Join-Path $gd 'rebase-merge')) -or (Test-Path (Join-Path $gd 'rebase-apply'))) { GQ $kh rebase --abort | Out-Null }
  Write-Host "  $kh : XUNG DOT - GitHub va may ban cung sua: $($conf -join ', ')" -ForegroundColor Red
  Write-Host "         Da giu nguyen ban tren may (chua day). Gop tay: git --git-dir=.git-du-an\$kh.git --work-tree=CodeABAP\$kh pull --rebase" -ForegroundColor Red
  $script:failed = $true
  return $false
}

function Push-Repo([string]$kh) {
  $remote = GQ $kh remote get-url origin
  if (-not $remote) { Write-Host "  $kh : chua noi GitHub - moi luu tren may (chay: .\scripts\git-du-an.ps1 noi $kh)" -ForegroundColor Yellow; return }
  G $kh push -q -u origin main
  if ($LASTEXITCODE -ne 0) {
    # Chi lay ve + day lai khi GitHub that su co commit ma may chua co; con lai la loi mang/quyen
    GQ $kh fetch -q origin | Out-Null
    $behind = $false
    if (GQ $kh rev-parse -q --verify refs/remotes/origin/main) { GQ $kh merge-base --is-ancestor origin/main HEAD | Out-Null; $behind = ($LASTEXITCODE -ne 0) }
    if (-not $behind) { Write-Host "  $kh : day len GitHub loi (mang/quyen truy cap) - xem thong bao git o tren" -ForegroundColor Red; $script:failed = $true; return }
    Write-Host "  $kh : GitHub co ban moi hon -> lay ve roi day lai" -ForegroundColor Yellow
    if (-not (Invoke-PullRebase $kh)) { return }
    G $kh push -q -u origin main
  }
  if ($LASTEXITCODE -eq 0) { Write-Host "  $kh : da day len $remote" } else { $script:failed = $true }
}

function Save-Repo([string]$kh, [string]$msg, [switch]$NoPush) {
  if (-not (Test-Repo $kh)) { Write-Host "  $kh : chua co repo du an (chay: .\scripts\git-du-an.ps1 tao $kh)" -ForegroundColor Yellow; return }
  GQ $kh add -A | Out-Null
  $staged = @(GQ $kh diff --cached --name-only)
  if ($staged.Count -eq 0) { Write-Host "  $kh : khong co thay doi" }
  else {
    # Chan mat khau that va file qua lon (cung tinh than R1/R8 cua check-repo.ps1)
    $okPw = '^\s*$|^\.\.\.$|^<.*>$|^\$\{.*\}$|^__.*__$|^\*+$|\{'
    $bad = New-Object System.Collections.ArrayList
    $cur = ''
    foreach ($l in @(GQ $kh diff --cached -U0 --no-color)) {
      if ($l -match '^\+\+\+ b/(.+)$') { $cur = $Matches[1]; continue }
      if ($l -notmatch '^\+') { continue }
      $m = [regex]::Match($l, '"(SAP_PASSWORD|password|pass)"\s*:\s*"([^"]*)"', 'IgnoreCase')
      if ($m.Success -and $m.Groups[2].Value -notmatch $okPw -and $bad -notcontains $cur) { [void]$bad.Add($cur) }
      $m = [regex]::Match($l, '^\+\s*(SAP_PASSWORD|VSP_\w+_PASSWORD)\s*=\s*(.*)$')
      if ($m.Success -and $m.Groups[2].Value.Trim() -notmatch $okPw -and $bad -notcontains $cur) { [void]$bad.Add($cur) }
    }
    foreach ($f in $staged) {
      $fp = Join-Path (Get-WorkTree $kh) $f
      if ((Test-Path -LiteralPath $fp) -and (Get-Item -LiteralPath $fp).Length -gt 50MB) { [void]$bad.Add("$f (> 50 MB)") }
    }
    if ($bad.Count -gt 0) {
      GQ $kh reset -q | Out-Null
      Write-Host "  $kh : KHONG LUU - file co mat khau that hoac qua lon:" -ForegroundColor Red
      $bad | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
      $script:failed = $true; return
    }
    if ($msg -eq '') { $msg = "Luu $kh $(Get-Date -Format 'dd.MM.yyyy HH:mm') ($($staged.Count) file)" }
    GQ $kh commit -q -m $msg | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host "  $kh : commit that bai (git config user.name/user.email?)" -ForegroundColor Red; $script:failed = $true; return }
    Write-Host "  $kh : da luu $($staged.Count) file - $msg"
  }
  if (-not $NoPush) { Push-Repo $kh }
}

function Connect-Repo([string]$kh) {
  $u = $Url; if ($u -eq '') { $u = $defaultUrl -f $kh.ToLower() }
  New-Item -ItemType Directory -Force (Get-WorkTree $kh) | Out-Null
  Initialize-Repo $kh
  if (GQ $kh remote get-url origin) { GQ $kh remote set-url origin $u | Out-Null } else { GQ $kh remote add origin $u | Out-Null }
  G $kh fetch -q origin
  if ($LASTEXITCODE -ne 0) { Stop-WithMessage "khong lay duoc $u - repo da tao (private) tren GitHub chua, ban co quyen truy cap chua?" }
  $hasRemote = [bool](GQ $kh rev-parse -q --verify refs/remotes/origin/main)
  $hasLocal = [bool](GQ $kh rev-parse -q --verify HEAD)
  if ($hasRemote -and -not $hasLocal) {
    # Nhan du an: file tren may trung ten nhung khac ban GitHub -> sao luu truoc khi lay
    $bak = Join-Path $gdRoot ("$kh.bak-" + (Get-Date -Format 'yyyyMMdd_HHmmss'))
    $n = 0
    foreach ($f in @(GQ $kh ls-tree -r --name-only origin/main)) {
      $lp = Join-Path (Get-WorkTree $kh) $f
      if (-not (Test-Path -LiteralPath $lp)) { continue }
      if ((GQ $kh hash-object -- $lp) -eq (GQ $kh rev-parse "origin/main:$f")) { continue }
      $dst = Join-Path $bak $f
      New-Item -ItemType Directory -Force (Split-Path -Parent $dst) | Out-Null
      Copy-Item -LiteralPath $lp $dst
      $n++
    }
    G $kh checkout -q -f -B main origin/main
    if ($LASTEXITCODE -ne 0) { Stop-WithMessage "khong lay duoc code du an $kh" }
    Write-Host "  $kh : da nhan du an tu $u"
    if ($n -gt 0) { Write-Host "  $kh : $n file tren may khac ban GitHub -> da sao luu o $bak" -ForegroundColor Yellow }
  } elseif ($hasLocal -and -not $hasRemote) {
    Push-Repo $kh
  } elseif ($hasLocal -and $hasRemote) {
    if (-not (GQ $kh merge-base HEAD origin/main)) { Stop-WithMessage "repo GitHub $u co lich su khac han repo tren may - hoi nguoi tao repo truoc khi gop" }
    GQ $kh branch -q -u origin/main main | Out-Null
    Write-Host "  $kh : da noi $u (chay 'lay' / 'luu' de dong bo)"
  } else {
    Write-Host "  $kh : da noi $u (repo GitHub dang trong - chay 'luu' de day)"
  }
}

function Update-Repo([string]$kh) {
  if (-not (GQ $kh remote get-url origin)) { Write-Host "  $kh : chua noi GitHub - bo qua"; return }
  G $kh fetch -q origin
  if ($LASTEXITCODE -ne 0) { Write-Host "  $kh : khong ket noi duoc GitHub (mang/quyen)" -ForegroundColor Red; $script:failed = $true; return }
  if (-not (GQ $kh rev-parse -q --verify refs/remotes/origin/main)) { Write-Host "  $kh : GitHub dang trong - bo qua"; return }
  if (Invoke-PullRebase $kh) { Write-Host "  $kh : da lay ban moi" }
}

function Show-Repo([string]$kh) {
  if (-not (Test-Repo $kh)) { Write-Host ("  {0,-10} chua co repo du an" -f $kh) -ForegroundColor Yellow; return }
  $chg = @(GQ $kh status --porcelain).Count
  $info = "chua noi GitHub"
  if (GQ $kh remote get-url origin) {
    $ab = GQ $kh rev-list --left-right --count 'origin/main...HEAD'
    if ($ab) { $x = "$ab" -split '\s+'; $info = "chua day $($x[1]) commit, GitHub moi hon $($x[0]) (theo lan lay gan nhat)" }
    else { $info = "chua day lan nao" }
  }
  Write-Host ("  {0,-10} thay doi chua luu: {1,-4} {2}" -f $kh, $chg, $info)
  GQ $kh log -3 --format='               %h %ad %s' --date=format:'%d.%m.%Y' | ForEach-Object { Write-Host $_ }
}

switch ($Lenh) {
  'tao' {
    if ($KH -eq '') { Stop-WithMessage "Cach dung: .\scripts\git-du-an.ps1 tao <KH>" }
    if (-not (Test-Path (Get-WorkTree $KH))) { Stop-WithMessage "chua co CodeABAP\$KH (tao bang tao-du-an.ps1; nhan du an dong nghiep thi dung 'noi')" }
    Initialize-Repo $KH
    if (GQ $KH rev-parse -q --verify HEAD) { Write-Host "  $KH : repo da co commit - dung 'luu' de luu tiep" }
    else { Save-Repo $KH "Khoi tao repo du an $KH" -NoPush }
    if ($Url -ne '') { Connect-Repo $KH }
    else { Write-Host "  Noi GitHub: tao repo PRIVATE $($defaultUrl -f $KH.ToLower()) roi chay .\scripts\git-du-an.ps1 noi $KH" }
  }
  'noi' {
    if ($KH -eq '') { Stop-WithMessage "Cach dung: .\scripts\git-du-an.ps1 noi <KH> [-Url <url>]" }
    Connect-Repo $KH
  }
  default {
    if ($KH -ne '') { $list = @($KH) }
    elseif ($Lenh -eq 'xem') { $list = @(Get-ChildItem -Directory (Join-Path $root 'CodeABAP') | ForEach-Object { $_.Name }) }
    else { $list = @(Get-ChildItem -Directory (Join-Path $root 'CodeABAP') | Where-Object { Test-Repo $_.Name } | ForEach-Object { $_.Name }) }
    if ($list.Count -eq 0) { Write-Host "Chua co repo du an nao (tao: .\scripts\git-du-an.ps1 tao <KH>)"; exit 0 }
    foreach ($k in $list) {
      switch ($Lenh) { 'luu' { Save-Repo $k $Message } 'lay' { Update-Repo $k } 'xem' { Show-Repo $k } }
    }
  }
}
if ($script:failed) { exit 1 }
exit 0
