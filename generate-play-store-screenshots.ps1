$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$outDir = Join-Path $root "play-store\screenshots"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function New-Canvas($width, $height) {
  $bitmap = New-Object System.Drawing.Bitmap $width, $height
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  return @{ Bitmap = $bitmap; Graphics = $graphics }
}

function New-Brush($a, $r, $g, $b) {
  return New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($a, $r, $g, $b))
}

function Add-Background($g, $w, $h, $hue) {
  $rect = New-Object System.Drawing.Rectangle 0, 0, $w, $h
  $top = [System.Drawing.Color]::FromArgb(255, 5, 7, 20)
  $bottom = if ($hue -eq "ember") {
    [System.Drawing.Color]::FromArgb(255, 42, 18, 12)
  } elseif ($hue -eq "ice") {
    [System.Drawing.Color]::FromArgb(255, 7, 40, 66)
  } else {
    [System.Drawing.Color]::FromArgb(255, 7, 28, 56)
  }
  $brush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
    $rect,
    $top,
    $bottom,
    [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
  )
  $g.FillRectangle($brush, $rect)
  $brush.Dispose()

  $mist = New-Brush 34 95 185 255
  for ($i = 0; $i -lt 12; $i++) {
    $x = [int](($w * 0.08) + (($i * 97) % [Math]::Max(1, $w - 80)))
    $y = [int](($h * 0.12) + (($i * 173) % [Math]::Max(1, $h - 260)))
    $r = [int]($w * (0.12 + (($i % 4) * 0.025)))
    $g.FillEllipse($mist, $x - $r, $y - $r, $r * 2, $r * 2)
  }
  $mist.Dispose()

  $star = New-Brush 130 139 207 245
  for ($i = 0; $i -lt 90; $i++) {
    $x = [int](($i * 113) % $w)
    $y = [int](($i * 227) % [Math]::Max(1, $h - 120))
    $s = 2 + ($i % 3)
    $g.FillRectangle($star, $x, $y, $s, $s)
  }
  $star.Dispose()
}

function Add-Text($g, $text, $x, $y, $size, $color, $bold = $false, $center = $false) {
  $style = if ($bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
  $font = New-Object System.Drawing.Font "Segoe UI", $size, $style
  $brush = New-Object System.Drawing.SolidBrush $color
  $format = New-Object System.Drawing.StringFormat
  if ($center) { $format.Alignment = [System.Drawing.StringAlignment]::Center }
  $g.DrawString($text, $font, $brush, $x, $y, $format)
  $format.Dispose()
  $brush.Dispose()
  $font.Dispose()
}

function Add-PixelText($g, $text, $x, $y, $size, $color, $center = $false) {
  $font = New-Object System.Drawing.Font "Consolas", $size, ([System.Drawing.FontStyle]::Bold)
  $brush = New-Object System.Drawing.SolidBrush $color
  $format = New-Object System.Drawing.StringFormat
  if ($center) { $format.Alignment = [System.Drawing.StringAlignment]::Center }
  $g.DrawString($text, $font, $brush, $x, $y, $format)
  $format.Dispose()
  $brush.Dispose()
  $font.Dispose()
}

function Add-Tile($g, $x, $y, $size, $kind) {
  $base = switch ($kind) {
    "blue" { [System.Drawing.Color]::FromArgb(255, 22, 59, 103) }
    "ember" { [System.Drawing.Color]::FromArgb(255, 115, 52, 18) }
    "ice" { [System.Drawing.Color]::FromArgb(255, 35, 89, 110) }
    default { [System.Drawing.Color]::FromArgb(255, 20, 18, 30) }
  }
  $brush = New-Object System.Drawing.SolidBrush $base
  $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(120, 90, 150, 225)), 2
  $g.FillRectangle($brush, $x, $y, $size, $size)
  $g.DrawRectangle($pen, $x, $y, $size, $size)
  $shine = New-Brush 45 180 226 255
  $g.FillRectangle($shine, $x + 5, $y + 5, [int]($size * 0.12), [int]($size * 0.52))
  $shine.Dispose()
  $pen.Dispose()
  $brush.Dispose()
}

function Add-Room($g, $x, $y, $cols, $rows, $tile, $kind) {
  for ($c = 0; $c -lt $cols; $c++) {
    Add-Tile $g ($x + $c * $tile) $y $tile $kind
    Add-Tile $g ($x + $c * $tile) ($y + ($rows - 1) * $tile) $tile $kind
  }
  for ($r = 1; $r -lt ($rows - 1); $r++) {
    Add-Tile $g $x ($y + $r * $tile) $tile $kind
    Add-Tile $g ($x + ($cols - 1) * $tile) ($y + $r * $tile) $tile $kind
  }
}

function Add-Light($g, $cx, $cy, $scale, $colorName = "blue") {
  $main = if ($colorName -eq "gold") {
    [System.Drawing.Color]::FromArgb(255, 255, 215, 86)
  } elseif ($colorName -eq "violet") {
    [System.Drawing.Color]::FromArgb(255, 176, 92, 255)
  } else {
    [System.Drawing.Color]::FromArgb(255, 105, 206, 255)
  }
  for ($i = 8; $i -ge 1; $i--) {
    $alpha = [int](12 + (76 / $i))
    $radius = [int]($scale * $i * 9)
    $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($alpha, $main.R, $main.G, $main.B))
    $g.FillEllipse($brush, $cx - $radius, $cy - $radius, $radius * 2, $radius * 2)
    $brush.Dispose()
  }
  $brushMain = New-Object System.Drawing.SolidBrush $main
  $white = New-Brush 255 240 250 255
  $r = [int](18 * $scale)
  $g.FillEllipse($brushMain, $cx - $r, $cy - $r, $r * 2, $r * 2)
  $g.FillEllipse($white, $cx - [int](7 * $scale), $cy - [int](9 * $scale), [int](14 * $scale), [int](14 * $scale))
  $white.Dispose()
  $brushMain.Dispose()
}

function Add-HUD($g, $w, $h, $title, $score, $timer = "0:42") {
  $lifeBrush = New-Brush 255 255 88 116
  for ($i = 0; $i -lt 3; $i++) {
    $x = 42 + ($i * 56)
    $y = 42
    $g.FillEllipse($lifeBrush, $x, $y, 24, 24)
    $g.FillEllipse($lifeBrush, $x + 16, $y, 24, 24)
    $points = @(
      [System.Drawing.Point]::new($x - 2, $y + 15),
      [System.Drawing.Point]::new($x + 42, $y + 15),
      [System.Drawing.Point]::new($x + 20, $y + 45)
    )
    $g.FillPolygon($lifeBrush, $points)
  }
  $lifeBrush.Dispose()
  Add-PixelText $g $timer ([int]($w / 2)) 30 30 ([System.Drawing.Color]::FromArgb(255, 206, 220, 245)) $true
  Add-PixelText $g $score ($w - 150) 26 38 ([System.Drawing.Color]::FromArgb(255, 255, 220, 86))
  Add-PixelText $g $title ([int]($w / 2)) 110 44 ([System.Drawing.Color]::FromArgb(220, 210, 238, 255)) $true
}

function Add-MobileControls($g, $w, $h, $duo = $false) {
  $panel = New-Brush 180 8 18 32
  $g.FillRectangle($panel, 0, $h - 360, $w, 360)
  $panel.Dispose()

  $penBlue = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(220, 106, 207, 255)), 3
  $fill = New-Brush 72 80 150 190
  $cx = if ($duo) { 165 } else { 195 }
  $cy = $h - 170
  $g.DrawEllipse($penBlue, $cx - 110, $cy - 110, 220, 220)
  $g.FillEllipse($fill, $cx - 42, $cy - 42, 84, 84)
  Add-PixelText $g "MOVE" ($cx - 72) ($cy - 145) 20 ([System.Drawing.Color]::FromArgb(255, 220, 236, 255))

  $penGold = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(230, 255, 198, 80)), 3
  $btnFill = New-Brush 88 16 24 45
  $g.FillRectangle($btnFill, $w - 410, $h - 250, 170, 170)
  $g.DrawRectangle($penBlue, $w - 410, $h - 250, 170, 170)
  Add-PixelText $g "ECHO" ($w - 325) ($h - 160) 23 ([System.Drawing.Color]::FromArgb(255, 234, 246, 255)) $true
  $g.FillRectangle($btnFill, $w - 200, $h - 250, 170, 170)
  $g.DrawRectangle($penGold, $w - 200, $h - 250, 170, 170)
  Add-PixelText $g "DASH" ($w - 115) ($h - 160) 23 ([System.Drawing.Color]::FromArgb(255, 255, 230, 160)) $true

  if ($duo) {
    Add-PixelText $g "P2" ($w - 120) ($h - 308) 30 ([System.Drawing.Color]::FromArgb(255, 255, 202, 74)) $true
    Add-PixelText $g "P1" 100 ($h - 308) 30 ([System.Drawing.Color]::FromArgb(255, 104, 210, 255)) $true
  }

  $fill.Dispose()
  $btnFill.Dispose()
  $penBlue.Dispose()
  $penGold.Dispose()
}

function Add-Enemy($g, $cx, $cy, $kind) {
  if ($kind -eq "spark") {
    Add-Light $g $cx $cy 0.9 "gold"
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(220, 255, 229, 96)), 3
    $g.DrawLine($pen, $cx - 36, $cy, $cx + 36, $cy)
    $g.DrawLine($pen, $cx, $cy - 36, $cx, $cy + 36)
    $pen.Dispose()
  } else {
    Add-Light $g $cx $cy 1.0 "violet"
    Add-PixelText $g "!" ($cx - 8) ($cy - 20) 24 ([System.Drawing.Color]::FromArgb(255, 255, 230, 255))
  }
}

function Save-Png($canvas, $path) {
  $canvas.Bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $canvas.Graphics.Dispose()
  $canvas.Bitmap.Dispose()
}

function New-GameplayShot($name, $headline, $subhead, $theme, $duo, $boss) {
  $w = 1080
  $h = 1920
  $canvas = New-Canvas $w $h
  $g = $canvas.Graphics
  Add-Background $g $w $h $theme
  Add-HUD $g $w $h $headline "86" "0:37"

  $tile = 56
  Add-Room $g 215 270 12 7 $tile "blue"
  $lowerRoomKind = if ($theme -eq "ember") { "ember" } else { "dark" }
  Add-Room $g 100 910 15 6 $tile $lowerRoomKind
  Add-Room $g 300 1230 10 5 $tile "ice"

  Add-Light $g 540 735 3.4 "blue"
  Add-Light $g 540 735 1.4 "blue"
  Add-Enemy $g 710 520 "spark"
  Add-Enemy $g 340 1120 "void"
  Add-Enemy $g 760 1380 "spark"

  $door = New-Brush 170 100 80 250
  $g.FillRectangle($door, 526, 610, 70, 112)
  $door.Dispose()

  if ($boss) {
    $barBg = New-Brush 230 18 14 30
    $bar = New-Brush 255 111 83 255
    $g.FillRectangle($barBg, 160, 210, 760, 28)
    $g.FillRectangle($bar, 160, 210, 580, 28)
    $barBg.Dispose()
    $bar.Dispose()
    Add-PixelText $g "PRISM WARDEN" 540 160 42 ([System.Drawing.Color]::FromArgb(255, 235, 242, 255)) $true
    Add-Light $g 730 805 2.2 "gold"
    Add-Light $g 810 850 1.2 "violet"
  }

  if ($duo) {
    Add-Light $g 450 745 1.6 "blue"
    Add-Light $g 630 745 1.6 "gold"
    Add-PixelText $g "DUO MODE" 540 158 48 ([System.Drawing.Color]::FromArgb(255, 235, 242, 255)) $true
  }

  $captionFill = New-Brush 205 8 18 36
  $g.FillRectangle($captionFill, 70, 1518, 940, 130)
  $captionFill.Dispose()
  Add-Text $g $headline 100 1530 42 ([System.Drawing.Color]::FromArgb(255, 238, 248, 255)) $true
  Add-Text $g $subhead 100 1590 27 ([System.Drawing.Color]::FromArgb(255, 183, 215, 238))
  Add-MobileControls $g $w $h $duo
  Save-Png $canvas (Join-Path $outDir $name)
}

New-GameplayShot "phone-01-echo-reveal.png" "Echo reveals the ruins" "Pulse light to uncover paths, doors, and hidden danger." "ice" $false $false
New-GameplayShot "phone-02-boss-trial.png" "Face prism bosses" "Break shields, dodge projectiles, and escape the arena." "ember" $false $true
New-GameplayShot "phone-03-local-duo.png" "Play local duo" "Share one device with two lights and mobile controls." "ice" $true $false
New-GameplayShot "phone-04-upgrades.png" "Collect sparks and cores" "Unlock upgrades, chase stars, and return for daily runs." "dark" $false $false

Copy-Item (Join-Path $outDir "phone-01-echo-reveal.png") (Join-Path $outDir "tablet-7-01-echo-reveal.png") -Force
Copy-Item (Join-Path $outDir "phone-02-boss-trial.png") (Join-Path $outDir "tablet-7-02-boss-trial.png") -Force
Copy-Item (Join-Path $outDir "phone-03-local-duo.png") (Join-Path $outDir "tablet-10-01-local-duo.png") -Force
Copy-Item (Join-Path $outDir "phone-04-upgrades.png") (Join-Path $outDir "tablet-10-02-upgrades.png") -Force

Write-Host "Generated Play Store screenshots in $outDir"
