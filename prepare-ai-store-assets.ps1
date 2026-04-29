$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourceDir = Join-Path $root "play-store\ai-source"
$outDir = Join-Path $root "play-store\ai-enhanced"
$downloadDir = "C:\Users\prave\Downloads\lumina-play-store-assets-ai"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $downloadDir "03-phone-screenshots") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $downloadDir "04-7-inch-tablet-screenshots") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $downloadDir "05-10-inch-tablet-screenshots") | Out-Null

function Save-CoverImage($sourcePath, $destPath, $targetWidth, $targetHeight) {
  $src = [System.Drawing.Image]::FromFile($sourcePath)
  try {
    $scale = [Math]::Max($targetWidth / $src.Width, $targetHeight / $src.Height)
    $scaledWidth = [int][Math]::Ceiling($src.Width * $scale)
    $scaledHeight = [int][Math]::Ceiling($src.Height * $scale)
    $x = [int](($targetWidth - $scaledWidth) / 2)
    $y = [int](($targetHeight - $scaledHeight) / 2)

    $bmp = New-Object System.Drawing.Bitmap $targetWidth, $targetHeight
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    try {
      $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
      $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
      $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
      $g.DrawImage($src, $x, $y, $scaledWidth, $scaledHeight)
      $bmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally {
      $g.Dispose()
      $bmp.Dispose()
    }
  } finally {
    $src.Dispose()
  }
}

function Copy-Asset($sourcePath, $destPath) {
  Copy-Item -LiteralPath $sourcePath -Destination $destPath -Force
}

$feature = Join-Path $sourceDir "ai-feature-source.png"
$phone1 = Join-Path $sourceDir "ai-phone-01-echo-reveal-source.png"
$phone2 = Join-Path $sourceDir "ai-phone-02-boss-source.png"
$phone3 = Join-Path $sourceDir "ai-phone-03-duo-source.png"
$trailerThumbnail = Join-Path $sourceDir "ai-trailer-thumbnail-source.png"

$phone1Out = Join-Path $outDir "ai-phone-01-echo-reveal.png"
$phone2Out = Join-Path $outDir "ai-phone-02-boss-trial.png"
$phone3Out = Join-Path $outDir "ai-phone-03-local-duo.png"
$phone4Out = Join-Path $outDir "ai-phone-04-crystal-cavern.png"
$featureOut = Join-Path $outDir "ai-feature-graphic-1024x500.png"
$thumbnailOut = Join-Path $outDir "ai-trailer-thumbnail-1280x720.png"

Save-CoverImage $phone1 $phone1Out 1080 1920
Save-CoverImage $phone2 $phone2Out 1080 1920
Save-CoverImage $phone3 $phone3Out 1080 1920
Save-CoverImage $feature $phone4Out 1080 1920
Save-CoverImage $feature $featureOut 1024 500
if (Test-Path $trailerThumbnail) {
  Save-CoverImage $trailerThumbnail $thumbnailOut 1280 720
} else {
  Save-CoverImage $feature $thumbnailOut 1280 720
}

Copy-Asset (Join-Path $root "assets\lumina-app-icon.png") (Join-Path $downloadDir "01-app-icon-512.png")
Copy-Asset $featureOut (Join-Path $downloadDir "02-feature-graphic-ai-1024x500.png")
Copy-Asset $thumbnailOut (Join-Path $downloadDir "06-youtube-trailer-thumbnail-ai-1280x720.png")

Copy-Asset $phone1Out (Join-Path $downloadDir "03-phone-screenshots\phone-01-echo-reveal-ai.png")
Copy-Asset $phone2Out (Join-Path $downloadDir "03-phone-screenshots\phone-02-boss-trial-ai.png")
Copy-Asset $phone3Out (Join-Path $downloadDir "03-phone-screenshots\phone-03-local-duo-ai.png")
Copy-Asset $phone4Out (Join-Path $downloadDir "03-phone-screenshots\phone-04-crystal-cavern-ai.png")

Copy-Asset $phone1Out (Join-Path $downloadDir "04-7-inch-tablet-screenshots\tablet-7-01-echo-reveal-ai.png")
Copy-Asset $phone2Out (Join-Path $downloadDir "04-7-inch-tablet-screenshots\tablet-7-02-boss-trial-ai.png")
Copy-Asset $phone3Out (Join-Path $downloadDir "05-10-inch-tablet-screenshots\tablet-10-01-local-duo-ai.png")
Copy-Asset $phone4Out (Join-Path $downloadDir "05-10-inch-tablet-screenshots\tablet-10-02-crystal-cavern-ai.png")

$zip = "C:\Users\prave\Downloads\lumina-play-store-assets-ai.zip"
if (Test-Path $zip) {
  Remove-Item -LiteralPath $zip -Force
}
Compress-Archive -Path (Join-Path $downloadDir "*") -DestinationPath $zip -Force

Write-Host "Prepared AI Play Store assets in $downloadDir"
Write-Host "Zip: $zip"
