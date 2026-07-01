# optimize_assets.ps1
# Guard Seed x Quarterview R&D 01 asset optimizer.
#
# Source: _incoming/qv01/guard_seed_quarterview_assets_v01/  (READ-ONLY, never modified)
# Output: assets/qv01/{backgrounds,allies,enemies,player}/    (used by the HTML at runtime)
#
# Character PNGs ship on a saturated MAGENTA chroma-key background (R~250 G~2 B~248, opaque).
# This script keys out the magenta -> transparent alpha, trims to the content bounding box,
# and downscales for a 390px mobile prototype. Backgrounds are opaque scene art -> only resized.
#
# Pure PowerShell + System.Drawing (no ImageMagick / Python / sharp). LockBits for speed.

Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"
$repo = Split-Path $PSScriptRoot -Parent
$src  = Join-Path $repo "_incoming\qv01\guard_seed_quarterview_assets_v01"
$out  = Join-Path $repo "assets\qv01"

function Save-Resized {
    param([System.Drawing.Bitmap]$bmp, [int]$targetW, [int]$targetH, [string]$dest)
    $canvas = New-Object System.Drawing.Bitmap($targetW, $targetH)
    $g = [System.Drawing.Graphics]::FromImage($canvas)
    $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($bmp, 0, 0, $targetW, $targetH)
    $g.Dispose()
    $canvas.Save($dest, [System.Drawing.Imaging.ImageFormat]::Png)
    $canvas.Dispose()
}

# --- Backgrounds: opaque, just downscale to ~900px wide -------------------------
$bgTargetW = 900
Get-ChildItem (Join-Path $src "backgrounds") -Filter *.png | ForEach-Object {
    $img = [System.Drawing.Bitmap]::FromFile($_.FullName)
    $h = [int]([math]::Round($img.Height * $bgTargetW / $img.Width))
    $dest = Join-Path $out ("backgrounds\" + $_.Name)
    Save-Resized -bmp $img -targetW $bgTargetW -targetH $h -dest $dest
    $img.Dispose()
    Write-Output ("BG   {0,-28} -> {1}x{2}" -f $_.Name, $bgTargetW, $h)
}

# --- Characters: magenta chroma-key + trim + downscale --------------------------
# Which source files to process from each category (anchors + situational player poses).
$charJobs = @(
    @{ cat = "allies";  files = @("ally_warrior_anchor.png","ally_archer_anchor.png","ally_mage_anchor.png","ally_priest_anchor.png"); h = 470 },
    @{ cat = "enemies"; files = @("enemy_goblin_anchor.png","enemy_ogre_anchor.png","enemy_orc_mage_anchor.png"); h = 500 },
    @{ cat = "player";  files = @("player_guard_anchor.png","player_guard_dash_land.png","player_guard_heavy_block.png","player_guard_parry_release.png","player_guard_miss_recover.png","player_guard_fireball_block.png","player_guard_victory_stand.png"); h = 620 }
)

function KeyAndTrim {
    param([string]$path)
    $src = [System.Drawing.Bitmap]::FromFile($path)
    $w = $src.Width; $h = $src.Height
    $bmp = New-Object System.Drawing.Bitmap($src)   # ensure 32bppArgb copy
    $src.Dispose()

    $rect = New-Object System.Drawing.Rectangle(0,0,$w,$h)
    $data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $stride = $data.Stride
    $bytes = New-Object byte[] ($stride * $h)
    [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)

    $minX = $w; $minY = $h; $maxX = -1; $maxY = -1
    for ($y = 0; $y -lt $h; $y++) {
        $row = $y * $stride
        for ($x = 0; $x -lt $w; $x++) {
            $i = $row + $x * 4
            $b = $bytes[$i]; $g = $bytes[$i+1]; $r = $bytes[$i+2]
            $d = ($r - $g) + ($b - $g)     # magenta strength: R & B above G
            if ($r -gt 150 -and $b -gt 150 -and $g -lt 105 -and $d -gt 150) {
                # strong magenta -> fully transparent
                $bytes[$i+3] = 0
            }
            else {
                if ($r -gt 135 -and $b -gt 135 -and $g -lt 150 -and $d -gt 105) {
                    # borderline halo -> partial alpha + despill R/B toward G
                    $bytes[$i+3] = 110
                    $cap = $g + 55
                    if ($r -gt $cap) { $bytes[$i+2] = $cap }
                    if ($b -gt $cap) { $bytes[$i]   = $cap }
                }
                # track content bbox for kept pixels
                if ($bytes[$i+3] -gt 12) {
                    if ($x -lt $minX) { $minX = $x }
                    if ($x -gt $maxX) { $maxX = $x }
                    if ($y -lt $minY) { $minY = $y }
                    if ($y -gt $maxY) { $maxY = $y }
                }
            }
        }
    }
    [System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $data.Scan0, $bytes.Length)
    $bmp.UnlockBits($data)

    if ($maxX -lt 0) { return $bmp }   # nothing kept (shouldn't happen)
    # pad bbox slightly
    $pad = 6
    $minX = [math]::Max(0, $minX - $pad); $minY = [math]::Max(0, $minY - $pad)
    $maxX = [math]::Min($w-1, $maxX + $pad); $maxY = [math]::Min($h-1, $maxY + $pad)
    $cw = $maxX - $minX + 1; $ch = $maxY - $minY + 1
    $crop = New-Object System.Drawing.Bitmap($cw, $ch)
    $cg = [System.Drawing.Graphics]::FromImage($crop)
    $cg.Clear([System.Drawing.Color]::Transparent)
    $cg.DrawImage($bmp, (New-Object System.Drawing.Rectangle(0,0,$cw,$ch)), $minX, $minY, $cw, $ch, [System.Drawing.GraphicsUnit]::Pixel)
    $cg.Dispose()
    $bmp.Dispose()
    return $crop
}

foreach ($job in $charJobs) {
    foreach ($f in $job.files) {
        $p = Join-Path $src ($job.cat + "\" + $f)
        $keyed = KeyAndTrim -path $p
        $targetH = $job.h
        $targetW = [int]([math]::Round($keyed.Width * $targetH / $keyed.Height))
        $dest = Join-Path $out ($job.cat + "\" + $f)
        Save-Resized -bmp $keyed -targetW $targetW -targetH $targetH -dest $dest
        Write-Output ("CHAR {0,-32} -> {1}x{2}" -f $f, $targetW, $targetH)
        $keyed.Dispose()
    }
}

Write-Output "DONE"
