param(
    [string]$InputPath = (Join-Path $PSScriptRoot '..\video'),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\video\frames'),
    [ValidateRange(0.1, 60)][double]$Interval = 2,
    [ValidateRange(0, 86400)][double]$Start = 0,
    [ValidateRange(0, 86400)][double]$Duration = 0,
    [string]$ToolDirectory = 'D:\DevTools\otherTools\video_tools\ffmpeg\bin',
    [switch]$ExtractLogos
)

$ErrorActionPreference = 'Stop'
$ffmpeg = Join-Path $ToolDirectory 'ffmpeg.exe'
$ffprobe = Join-Path $ToolDirectory 'ffprobe.exe'
if (!(Test-Path -LiteralPath $ffmpeg)) { $ffmpeg = (Get-Command ffmpeg -ErrorAction Stop).Source }
if (!(Test-Path -LiteralPath $ffprobe)) { $ffprobe = (Get-Command ffprobe -ErrorAction Stop).Source }
$source = Get-Item -LiteralPath $InputPath
if ($ExtractLogos) {
    $assetDirectory = Join-Path $PSScriptRoot '..\assets\recording'
    New-Item -ItemType Directory -Path $assetDirectory -Force | Out-Null
    $recording = Join-Path $PSScriptRoot '..\video\1000087223.mp4'
    # Coordinates in the supplied 1080x2400 recording, stable home screen at 10 seconds.
    $crops = @{ wps='116:116:82:712'; xsus='116:116:82:928'; bilibili='116:116:82:1146'; apple='116:116:82:1364'; anti='116:116:82:1582'; tencent='116:116:82:1800'; chatgpt='116:116:82:2018'; avatar='94:94:38:144' }
    foreach ($name in $crops.Keys) {
        & $ffmpeg -hide_banner -loglevel error -y -ss 10 -i $recording -frames:v 1 -vf "crop=$($crops[$name])" (Join-Path $assetDirectory "$name.png")
        if ($LASTEXITCODE -ne 0) { throw "Logo extraction failed: $name" }
    }
    $alternatives = @{
        flowus=@(51,'120:120:76:1096'); docs=@(51,'120:120:76:1434'); yuque=@(51,'120:120:76:1820'); baidu=@(51,'112:100:80:2154');
        surfshark=@(53,'120:120:76:1096'); nordvpn=@(53,'120:120:76:1388'); nexitally=@(53,'120:120:76:1658');
        migu=@(55,'120:120:76:1096'); mango=@(55,'120:120:76:1372'); iqiyi=@(55,'120:120:76:1648'); youku=@(55,'120:120:76:1930');
        soundcloud=@(57,'120:120:76:1096'); tidal=@(57,'120:120:76:1446'); deezer=@(57,'120:120:76:1778'); spotify=@(57,'120:120:76:2054');
        telegram=@(90,'160:160:76:332')
    }
    foreach ($name in $alternatives.Keys) {
        & $ffmpeg -hide_banner -loglevel error -y -ss $alternatives[$name][0] -i $recording -frames:v 1 -vf "crop=$($alternatives[$name][1])" (Join-Path $assetDirectory "$name.png")
        if ($LASTEXITCODE -ne 0) { throw "Alternative logo extraction failed: $name" }
    }
    $libraryIcons = @('kimi','baidu','qwen','doubao','zhipu','spark','hailuo','tiangong','yuanbao','deepseek','trae','360','baichuan','codegeex','stepfun','kling','jimeng','vidu')
    for ($i = 0; $i -lt $libraryIcons.Count; $i++) {
        $x = if ($i % 2 -eq 0) { 66 } else { 574 }
        $y = 810 + [math]::Floor($i / 2) * 186
        & $ffmpeg -hide_banner -loglevel error -y -ss 63 -i $recording -frames:v 1 -vf "crop=100:100:$($x):$($y)" (Join-Path $assetDirectory "$($libraryIcons[$i]).png")
        if ($LASTEXITCODE -ne 0) { throw "Library logo extraction failed: $($libraryIcons[$i])" }
    }
    Write-Output "Recording logo crops -> $assetDirectory"
    return
}
$videos = if ($source.PSIsContainer) { @(Get-ChildItem -LiteralPath $source.FullName -Filter '*.mp4') } else { @($source) }
if (!$videos.Count) { throw 'No MP4 videos found.' }
$culture = [Globalization.CultureInfo]::InvariantCulture
$step = $Interval.ToString($culture)
$startText = $Start.ToString($culture)
foreach ($video in $videos) {
    # A fresh directory prevents stale frames from an earlier sampling rate appearing in the sheets.
    $folder = Join-Path $OutputDirectory ($video.BaseName + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    $metadata = & $ffprobe -v error -show_entries format=duration:stream=width,height -of json $video.FullName
    if ($LASTEXITCODE -ne 0) { throw "ffprobe failed: $($video.Name)" }
    $seek = @('-ss', $startText)
    $limit = if ($Duration -gt 0) { @('-t', $Duration.ToString($culture)) } else { @() }
    $filter = "fps=1/$($step):start_time=0,scale=540:-2,drawtext=fontfile='C\:/Windows/Fonts/consola.ttf':text='%{pts\:hms\:$startText}':fontsize=22:fontcolor=white:box=1:boxcolor=black@0.8:x=8:y=8"
    & $ffmpeg -hide_banner -loglevel error @seek -i $video.FullName @limit -vf $filter -q:v 2 (Join-Path $folder 'frame-%04d.jpg')
    if ($LASTEXITCODE -ne 0) { throw "Frame extraction failed: $($video.Name)" }
    $frames = @(Get-ChildItem -LiteralPath $folder -Filter 'frame-*.jpg')
    if (!$frames.Count) { throw "No frames produced: $($video.Name)" }
    & $ffmpeg -hide_banner -loglevel error -framerate 1 -i (Join-Path $folder 'frame-%04d.jpg') -vf 'scale=216:-2,tile=4x3:padding=4:margin=4:color=gray' -fps_mode vfr -q:v 2 (Join-Path $folder 'sheet-%02d.jpg')
    if ($LASTEXITCODE -ne 0) { throw "Contact sheet failed: $($video.Name)" }
    [ordered]@{ source = $video.FullName; start = $Start; interval = $Interval; frames = $frames.Count; metadata = ($metadata | ConvertFrom-Json) } |
        ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $folder 'manifest.json') -Encoding UTF8
    Write-Output "$($video.Name): $($frames.Count) frames -> $folder"
}
