Add-Type -AssemblyName System.Drawing

function Resize-Image($srcPath, $destPath, [int]$w, [int]$h) {
    $src = [System.Drawing.Image]::FromFile($srcPath)
    $dest = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($dest)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($src, 0, 0, $w, $h)
    $g.Dispose()
    $src.Dispose()
    $parent = Split-Path $destPath
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    if (Test-Path $destPath) { Remove-Item $destPath -Force }
    $dest.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $dest.Dispose()
    Write-Host "Created: $destPath (${w}x${h})"
}

$icon1024 = "assets/branding/icon_1024.png"
$iconFg = "assets/branding/icon_foreground.png"
$iconMono = "assets/branding/icon_monochrome.png"
$splash = "assets/branding/splash_icon.png"

$densities = @(
    @{ folder = "mipmap-mdpi"; launcher = 48; fg = 108; splash = 144; draw = "drawable-mdpi" },
    @{ folder = "mipmap-hdpi"; launcher = 72; fg = 162; splash = 192; draw = "drawable-hdpi" },
    @{ folder = "mipmap-xhdpi"; launcher = 96; fg = 216; splash = 256; draw = "drawable-xhdpi" },
    @{ folder = "mipmap-xxhdpi"; launcher = 144; fg = 324; splash = 384; draw = "drawable-xxhdpi" },
    @{ folder = "mipmap-xxxhdpi"; launcher = 192; fg = 432; splash = 512; draw = "drawable-xxxhdpi" }
)

foreach ($d in $densities) {
    $dir = "android/app/src/main/res/" + $d.folder
    Resize-Image $icon1024 "$dir/ic_launcher.png" $d.launcher $d.launcher
    Resize-Image $iconFg "$dir/ic_launcher_foreground.png" $d.fg $d.fg
    Resize-Image $iconMono "$dir/ic_launcher_monochrome.png" $d.fg $d.fg
    
    $drawDir = "android/app/src/main/res/" + $d.draw
    Resize-Image $splash "$drawDir/splash_icon.png" $d.splash $d.splash
}

Resize-Image $splash "android/app/src/main/res/drawable/splash_icon.png" 288 288
Write-Host "All icons generated successfully."
