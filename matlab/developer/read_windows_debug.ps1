$ErrorActionPreference = 'Stop'
$desktop = [Environment]::GetFolderPath('Desktop')
$outDir = 'C:\Users\11782\AppData\Local\Temp\yunlink-debug'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outUtf8 = Join-Path $outDir 'relay.utf8.txt'
$outRaw = Join-Path $outDir 'relay.bin'
$outMeta = Join-Path $outDir 'relay.meta.txt'

$files = @(Get-ChildItem -LiteralPath $desktop -File -Force | Where-Object { $_.Name.StartsWith('debug') })
if ($files.Count -eq 0) {
    $files = @(Get-ChildItem -LiteralPath $desktop -File -Force | Where-Object { $_.Extension -eq '.txt' })
}
if ($files.Count -eq 0) { throw "no debug txt on desktop: $desktop" }
$target = $files | Sort-Object LastWriteTime -Descending | Select-Object -First 1

$bytes = [IO.File]::ReadAllBytes($target.FullName)
[IO.File]::WriteAllBytes($outRaw, $bytes)

function Try-Decode([byte[]]$data, [string]$name, $enc) {
    $text = $enc.GetString($data)
    $repl = ([regex]::Matches($text, [char]0xFFFD)).Count
    $cn = ([regex]::Matches($text, '[\u4e00-\u9fff]')).Count
    $ascii = 0
    foreach ($ch in $text.ToCharArray()) {
        if ([int]$ch -ge 32 -and [int]$ch -lt 127) { $ascii++ }
    }
    $score = $ascii + ($cn * 2) - ($repl * 80)
    if ($text.StartsWith('YunLink') -or $text.Contains('ex00_setup') -or $text.Contains('MATLAB')) { $score += 500 }
    if ($text.Contains('错误') -or $text.Contains('Error') -or $text.Contains('error')) { $score += 200 }
    return @{ Name = $name; Text = $text; Score = $score; Repl = $repl; Cn = $cn; Ascii = $ascii }
}

$results = @()
if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $results += Try-Decode $bytes 'utf8-bom' (New-Object System.Text.UTF8Encoding $true)
} elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
    $results += Try-Decode $bytes 'utf16le-bom' ([Text.Encoding]::Unicode)
} elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
    $results += Try-Decode $bytes 'utf16be-bom' ([Text.Encoding]::BigEndianUnicode)
} else {
    $results += Try-Decode $bytes 'utf8' (New-Object System.Text.UTF8Encoding $false, $true)
    try { $results += Try-Decode $bytes 'gb18030' ([Text.Encoding]::GetEncoding(54936)) } catch {}
    try { $results += Try-Decode $bytes 'gbk' ([Text.Encoding]::GetEncoding(936)) } catch {}
    if ($bytes.Length % 2 -eq 0) {
        $results += Try-Decode $bytes 'utf16le' ([Text.Encoding]::Unicode)
    }
}

$best = $results | Sort-Object { $_.Score } -Descending | Select-Object -First 1
$utf8 = New-Object System.Text.UTF8Encoding $false
[IO.File]::WriteAllText($outUtf8, $best.Text, $utf8)
$meta = @(
    "src=$($target.FullName)"
    "name=$($target.Name)"
    "len=$($target.Length)"
    "mtime=$($target.LastWriteTime.ToString('s'))"
    "encoding=$($best.Name)"
    "score=$($best.Score)"
    "ascii=$($best.Ascii)"
    "cn=$($best.Cn)"
    "repl=$($best.Repl)"
) -join "`n"
[IO.File]::WriteAllText($outMeta, $meta, $utf8)
Write-Output $meta
