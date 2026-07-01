# optimize_assets_01a.ps1  (QV01A pass)
#  1) guardseed_title / guardseed_boss  -> assets/qv01/ui/   (opaque, downscale)
#  2) ally/enemy 5-pose sheets -> idle + action frames, chroma-keyed, BASELINE-ALIGNED
#     on a uniform per-character canvas so idle<->action swaps don't jump.
#  Pure PowerShell + System.Drawing. Sheets are on magenta chroma-key.

Add-Type -AssemblyName System.Drawing
$ErrorActionPreference="Stop"
$repo = Split-Path $PSScriptRoot -Parent
$srcRoot = Join-Path $repo "_incoming\qv01\guard_seed_quarterview_assets_v01"
$inA = Join-Path $repo "_incoming\qv01a"
$out = Join-Path $repo "assets\qv01"

function Save-Png($bmp,$dest){ $bmp.Save($dest,[System.Drawing.Imaging.ImageFormat]::Png) }

function Resized($bmp,$tw,$th){
  $c=New-Object System.Drawing.Bitmap($tw,$th)
  $g=[System.Drawing.Graphics]::FromImage($c)
  $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.CompositingQuality=[System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $g.Clear([System.Drawing.Color]::Transparent)
  $g.DrawImage($bmp,0,0,$tw,$th)
  $g.Dispose()
  return $c
}

# ---- 1) UI images (opaque) ----
New-Item -ItemType Directory -Force -Path (Join-Path $out "ui") | Out-Null
foreach($n in @("guardseed_title","guardseed_boss")){
  $img=[System.Drawing.Bitmap]::FromFile((Join-Path $inA "$n.png"))
  $tw=620; $th=[int][math]::Round($img.Height*$tw/$img.Width)
  $r=Resized $img $tw $th
  Save-Png $r (Join-Path $out "ui\$n.png")
  $img.Dispose(); $r.Dispose()
  Write-Output ("UI   {0,-18} -> {1}x{2}" -f $n,$tw,$th)
}

# ---- key + trim a magenta-bg bitmap; returns @{bmp=;h=;w=} or $null ----
function KeyTrim($bmp){
  $w=$bmp.Width;$h=$bmp.Height
  $rect=New-Object System.Drawing.Rectangle(0,0,$w,$h)
  $d=$bmp.LockBits($rect,[System.Drawing.Imaging.ImageLockMode]::ReadWrite,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $stride=$d.Stride; $by=New-Object byte[] ($stride*$h)
  [System.Runtime.InteropServices.Marshal]::Copy($d.Scan0,$by,0,$by.Length)
  $minX=$w;$minY=$h;$maxX=-1;$maxY=-1
  for($y=0;$y -lt $h;$y++){
    $row=$y*$stride
    for($x=0;$x -lt $w;$x++){
      $i=$row+$x*4
      $b=[int]$by[$i];$g=[int]$by[$i+1];$r=[int]$by[$i+2]
      $dd=($r-$g)+($b-$g)
      if($r -gt 150 -and $b -gt 150 -and $g -lt 105 -and $dd -gt 150){ $by[$i+3]=0 }
      else {
        if($r -gt 135 -and $b -gt 135 -and $g -lt 150 -and $dd -gt 105){
          $by[$i+3]=110; $cap=$g+55
          if($r -gt $cap){$by[$i+2]=$cap}; if($b -gt $cap){$by[$i]=$cap}
        }
        if($by[$i+3] -gt 12){
          if($x -lt $minX){$minX=$x}; if($x -gt $maxX){$maxX=$x}
          if($y -lt $minY){$minY=$y}; if($y -gt $maxY){$maxY=$y}
        }
      }
    }
  }
  [System.Runtime.InteropServices.Marshal]::Copy($by,0,$d.Scan0,$by.Length)
  $bmp.UnlockBits($d)
  if($maxX -lt 0){ return $null }
  $pad=5
  $minX=[math]::Max(0,$minX-$pad);$minY=[math]::Max(0,$minY-$pad)
  $maxX=[math]::Min($w-1,$maxX+$pad);$maxY=[math]::Min($h-1,$maxY+$pad)
  $cw=$maxX-$minX+1;$ch=$maxY-$minY+1
  $crop=New-Object System.Drawing.Bitmap($cw,$ch)
  $cg=[System.Drawing.Graphics]::FromImage($crop); $cg.Clear([System.Drawing.Color]::Transparent)
  $cg.DrawImage($bmp,(New-Object System.Drawing.Rectangle(0,0,$cw,$ch)),$minX,$minY,$cw,$ch,[System.Drawing.GraphicsUnit]::Pixel)
  $cg.Dispose()
  return @{bmp=$crop;w=$cw;h=$ch}
}

# ---- segment sheet columns into frame windows (midpoint-extended) ----
function SegmentFrames($path){
  $src=[System.Drawing.Bitmap]::FromFile($path)
  $w=$src.Width;$h=$src.Height
  $bmp=New-Object System.Drawing.Bitmap($src); $src.Dispose()
  $rect=New-Object System.Drawing.Rectangle(0,0,$w,$h)
  $d=$bmp.LockBits($rect,[System.Drawing.Imaging.ImageLockMode]::ReadOnly,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $stride=$d.Stride; $by=New-Object byte[] ($stride*$h)
  [System.Runtime.InteropServices.Marshal]::Copy($d.Scan0,$by,0,$by.Length)
  $bmp.UnlockBits($d)
  $col=New-Object 'int[]' $w
  for($y=0;$y -lt $h;$y+=2){
    $row=$y*$stride
    for($x=0;$x -lt $w;$x++){
      $i=$row+$x*4
      $b=[int]$by[$i];$g=[int]$by[$i+1];$r=[int]$by[$i+2]
      $dd=($r-$g)+($b-$g)
      if(-not ($r -gt 150 -and $b -gt 150 -and $g -lt 120 -and $dd -gt 150)){ $col[$x]++ }
    }
  }
  $thresh=[int]($h*0.055); $minW=[int]($w*0.05); $gapMerge=[int]($w*0.008)
  $st=New-Object System.Collections.ArrayList; $en=New-Object System.Collections.ArrayList
  $inRun=$false;$start=0
  for($x=0;$x -lt $w;$x++){
    if($col[$x] -gt $thresh){ if(-not $inRun){$inRun=$true;$start=$x} }
    else { if($inRun){$inRun=$false;[void]$st.Add([int]$start);[void]$en.Add([int]($x-1))} }
  }
  if($inRun){[void]$st.Add([int]$start);[void]$en.Add([int]($w-1))}
  # merge tiny gaps, drop specks
  $fs=New-Object System.Collections.ArrayList; $fe=New-Object System.Collections.ArrayList
  for($k=0;$k -lt $st.Count;$k++){
    $s=[int]$st[$k];$e=[int]$en[$k]
    if($fs.Count -gt 0 -and ($s-[int]$fe[$fe.Count-1]) -lt $gapMerge){ $fe[$fe.Count-1]=$e }
    elseif(($e-$s+1) -ge $minW){ [void]$fs.Add($s);[void]$fe.Add($e) }
    elseif($fs.Count -gt 0){ } # ignore leading speck
  }
  # midpoint-extend each frame window toward neighbours (capture weapons)
  $wins=New-Object System.Collections.ArrayList
  for($k=0;$k -lt $fs.Count;$k++){
    $left = if($k -eq 0){0}else{[int](([int]$fe[$k-1]+[int]$fs[$k])/2)}
    $right= if($k -eq $fs.Count-1){$w-1}else{[int](([int]$fe[$k]+[int]$fs[$k+1])/2)}
    [void]$wins.Add(@($left,$right))
  }
  return @{sheet=$path;w=$w;h=$h;wins=$wins}
}

function CropRegion($path,$x0,$x1){
  $src=[System.Drawing.Bitmap]::FromFile($path)
  $cw=$x1-$x0+1;$ch=$src.Height
  $crop=New-Object System.Drawing.Bitmap($cw,$ch)
  $g=[System.Drawing.Graphics]::FromImage($crop)
  $g.DrawImage($src,(New-Object System.Drawing.Rectangle(0,0,$cw,$ch)),$x0,0,$cw,$ch,[System.Drawing.GraphicsUnit]::Pixel)
  $g.Dispose(); $src.Dispose()
  return $crop
}

# ---- process one sheet: output idle + act aligned on uniform canvas ----
function ProcessSheet($cat,$name,$sheetFile,$targetH){
  $path=Join-Path $srcRoot "$cat\$sheetFile"
  $seg=SegmentFrames $path
  $wins=$seg.wins
  if($wins.Count -lt 2){ Write-Output ("SKIP {0} (frames={1})" -f $name,$wins.Count); return }
  # keyed frames for idle(0) and action(1)
  $idxs=@(0,1)
  $keyed=@{}
  foreach($ix in $idxs){
    $win=$wins[$ix]
    $region=CropRegion $path ([int]$win[0]) ([int]$win[1])
    $kt=KeyTrim $region
    $region.Dispose()
    $keyed[$ix]=$kt
  }
  if(-not $keyed[0]){ Write-Output ("SKIP {0} (no idle content)" -f $name); return }
  $scale = $targetH / $keyed[0].h
  # uniform canvas: width = max scaled frame width; height = targetH + headroom
  $cwArr = @()
  foreach($ix in $idxs){ if($keyed[$ix]){ $cwArr += [int][math]::Round($keyed[$ix].w*$scale) } }
  $canvasW = ([int]($cwArr | Measure-Object -Maximum).Maximum) + 8
  $canvasH = [int][math]::Round($targetH*1.42)
  $suffix=@{0='idle';1='act'}
  foreach($ix in $idxs){
    $kt=$keyed[$ix]; if(-not $kt){ continue }
    $sw=[int][math]::Round($kt.w*$scale); $sh=[int][math]::Round($kt.h*$scale)
    $canvas=New-Object System.Drawing.Bitmap($canvasW,$canvasH)
    $g=[System.Drawing.Graphics]::FromImage($canvas)
    $g.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode=[System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $dx=[int](($canvasW-$sw)/2); $dy=$canvasH-$sh   # bottom-center baseline
    $g.DrawImage($kt.bmp,$dx,$dy,$sw,$sh)
    $g.Dispose()
    Save-Png $canvas (Join-Path $out "$cat\${name}_$($suffix[$ix]).png")
    $canvas.Dispose(); $kt.bmp.Dispose()
  }
  Write-Output ("SHEET {0,-14} frames={1} idleH={2} scale={3:N2} canvas={4}x{5}" -f $name,$wins.Count,$keyed[0].h,$scale,$canvasW,$canvasH)
}

$allyJobs=@("warrior","archer","mage","priest")
foreach($j in $allyJobs){ ProcessSheet "allies" "ally_$j" "ally_${j}_5pose_sheet.png" 470 }
$foeJobs=@("goblin","ogre","orc_mage")
foreach($j in $foeJobs){ ProcessSheet "enemies" "enemy_$j" "enemy_${j}_5pose_sheet.png" 500 }

Write-Output "DONE 01A"
