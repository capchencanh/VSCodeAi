# Chuyen 1 file TS .md -> .docx giu nguyen dinh dang CITEK.
#
# Cach lam: tai su dung package .docx template va chi thay `word/document.xml`
# + va header (ten cong ty/logo khach theo du an) + metadata. Moi part khac
# (styles, footer, numbering, theme) giu nguyen byte -> khong mat dinh dang.
#
# Vi du:
#   powershell -File build-docx.ps1 `
#     -MdPath       "CodeABAP\Document\VAS_TS_...ZMB51_V1.0.md" `
#     -Template     "CodeABAP\Document\BIDIPHAR_BP_SD_V2.0.docx" `
#     -CustomerName "CONG TY CO PHAN ... (VIET TAT)" `
#     -CustomerLogo "CodeABAP\Document\logo_khachhang.png"
#
# Yeu cau: Node.js (sinh document.xml) + Microsoft Word (sinh muc luc, cap nhat
# field so trang). Khong co Word thi van ra file .docx dung, chi la muc luc con
# rong -> mo Word bam Ctrl+A roi F9.

param(
  [Parameter(Mandatory = $true)][string]$MdPath,
  [Parameter(Mandatory = $true)][string]$Template,
  [string]$OutPath,
  # Ten cong ty khach hang tren header, phan sau chu "TAI" (VD "CONG TY CO PHAN DUOC ... (BIDIPHAR)")
  [string]$CustomerName,
  # Logo khach hang (PNG/JPEG) o goc phai header. Bo trong -> o logo de trong.
  [string]$CustomerLogo,
  [switch]$SkipWord
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$MdPath   = (Resolve-Path $MdPath).Path
$Template = (Resolve-Path $Template).Path
if ($CustomerLogo) { $CustomerLogo = (Resolve-Path $CustomerLogo).Path }
if (-not $OutPath) { $OutPath = [IO.Path]::ChangeExtension($MdPath, '.docx') }

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$gen = Join-Path $scriptDir 'md2docx.js'
if (-not (Test-Path $gen)) { throw "Khong tim thay $gen" }

$utf8 = New-Object Text.UTF8Encoding $false
$work = Join-Path ([IO.Path]::GetTempPath()) ("ts_build_" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force -Path $work | Out-Null

try {
  # 0. Giai nen cac part can doc/sua cua template ra thu muc tam (giu duong dan trong zip)
  $pkgDir = Join-Path $work 'pkg'
  $zipT = [IO.Compression.ZipFile]::OpenRead($Template)
  try {
    foreach ($en in $zipT.Entries) {
      if ($en.FullName -match '^(word/document\.xml|word/header\d*\.xml|word/_rels/header\d*\.xml\.rels|\[Content_Types\]\.xml|docProps/core\.xml)$') {
        $dst = Join-Path $pkgDir ($en.FullName -replace '/', '\')
        New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
        $sr = New-Object IO.StreamReader($en.Open(), [Text.Encoding]::UTF8)
        [IO.File]::WriteAllText($dst, $sr.ReadToEnd(), $utf8)
        $sr.Dispose()
      }
    }
  } finally { $zipT.Dispose() }
  $tplDoc = Join-Path $pkgDir 'word\document.xml'
  if (-not (Test-Path $tplDoc)) { throw 'Template khong phai file .docx hop le (thieu word/document.xml)' }

  # 1. Sinh document.xml tu markdown (lay sectPr/kho giay tu document.xml cua template)
  $newDoc = Join-Path $work 'document.xml'
  & node $gen $MdPath $newDoc $tplDoc
  if ($LASTEXITCODE -ne 0) { throw 'md2docx.js that bai' }
  Copy-Item $newDoc $tplDoc -Force

  # 2. Va header (ten cong ty + logo khach) va metadata
  $nodeArgs = @((Join-Path $scriptDir 'patch-package.js'), $pkgDir, '--md', $MdPath)
  if ($CustomerName) { $nodeArgs += @('--name', $CustomerName) }
  if ($CustomerLogo) { $nodeArgs += @('--logo', $CustomerLogo) }
  & node @nodeArgs
  if ($LASTEXITCODE -ne 0) { throw 'patch-package.js that bai' }

  # 3. Kiem tra XML hop le TRUOC khi dong goi (tranh tao ra file Word phai repair)
  foreach ($xf in Get-ChildItem $pkgDir -Recurse -File) {
    if ($xf.Extension -eq '.xml' -or $xf.Extension -eq '.rels') {
      $null = [xml][IO.File]::ReadAllText($xf.FullName, [Text.Encoding]::UTF8)
    }
  }
  Write-Output 'XML well-formed: OK'

  # 4. Copy template roi thay/them dung cac entry da sua
  #    File dang mo trong Word se bi khoa -> bao loi ro thay vi stack trace .NET
  if (Test-Path $OutPath) {
    try {
      $fsTest = [IO.File]::Open($OutPath, 'Open', 'ReadWrite', 'None')
      $fsTest.Close()
    } catch {
      throw "File '$OutPath' dang bi mo (nhieu kha nang la Microsoft Word). Dong file do roi chay lai."
    }
  }
  Copy-Item $Template $OutPath -Force
  $zip = [IO.Compression.ZipFile]::Open($OutPath, [IO.Compression.ZipArchiveMode]::Update)
  try {
    $root = (Resolve-Path $pkgDir).Path.TrimEnd('\') + '\'
    foreach ($f in Get-ChildItem $pkgDir -Recurse -File) {
      $name = $f.FullName.Substring($root.Length) -replace '\\', '/'
      $old = $zip.GetEntry($name)
      if ($null -ne $old) { $old.Delete() }
      $ne = $zip.CreateEntry($name, [IO.Compression.CompressionLevel]::Optimal)
      $st = $ne.Open()
      try { $b = [IO.File]::ReadAllBytes($f.FullName); $st.Write($b, 0, $b.Length) } finally { $st.Dispose() }
    }
  } finally { $zip.Dispose() }
} finally {
  Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output "Da tao: $OutPath"

if ($SkipWord) { Write-Output 'Bo qua buoc Word - muc luc con rong, mo Word bam Ctrl+A roi F9.'; return }

# 5. Mo bang Word de sinh muc luc + cap nhat field so trang, dong thoi la phep
#    thu that: Word mo duoc ma khong hoi repair nghia la file hop le.
#    Word save lai cung loai bo media khong con dung cua template (VD logo khach cu).
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
try {
  $d = $word.Documents.Open($OutPath, $false, $false, $false)
  foreach ($r in $d.StoryRanges) {
    $cur = $r
    while ($null -ne $cur) { $null = $cur.Fields.Update(); $cur = $cur.NextStoryRange }
  }
  # Chi header/footer chinh (Item 1 = wdHeaderFooterPrimary). Duyet ca bo Headers se lam
  # Word tu tao them header/footer rong cho trang dau + trang chan (header2/3.xml thua).
  foreach ($sec in $d.Sections) {
    $null = $sec.Headers.Item(1).Range.Fields.Update()
    $null = $sec.Footers.Item(1).Range.Fields.Update()
  }
  if ($d.TablesOfContents.Count -gt 0) {
    $toc = $d.TablesOfContents.Item(1)
    $toc.Update()
    # Template to muc luc mau 00586F; style TOC1-3 mac dinh la xam 333333.
    # Word dung mau BGR: RGB(0,88,111) -> 0x6F5800
    $toc.Range.Font.Color = 0x6F5800
  }
  $null = $d.Repaginate()

  Write-Output ("So trang : " + $d.ComputeStatistics(2))
  Write-Output ("So bang  : " + $d.Tables.Count)
  Write-Output ("Muc TOC  : " + $(if ($d.TablesOfContents.Count -gt 0) { $d.TablesOfContents.Item(1).Range.Paragraphs.Count } else { 0 }))
  $d.Save()
  $d.Close(0)
} finally {
  # COM co the gan vao Word user dang mo -> chi Quit khi khong con tai lieu nao khac,
  # tranh dong mat file user dang lam do.
  if ($word.Documents.Count -eq 0) { $word.Quit() }
  [void][Runtime.InteropServices.Marshal]::ReleaseComObject($word)
}
Write-Output 'Hoan tat.'
