# Optimize skybox PNGs in-place using pngquant.
#
# Skyboxes ship at 1.5-2.8 MB each (16 PNGs ~= 36 MB). Decoded in memory
# they hit ~8 MB per image, which can trip iOS's image decoder under
# memory pressure on older devices and silently fall back to gradients.
# pngquant typically reduces them to ~20-30% of original size with no
# perceptible quality loss for skybox panoramas.
#
# Run from project root:
#   pwsh ./tools/optimize_skyboxes.ps1
#
# Requires pngquant. Install with:
#   choco install pngquant -y

if (-not (Get-Command pngquant -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: pngquant not found on PATH." -ForegroundColor Red
    Write-Host "Install with: choco install pngquant -y" -ForegroundColor Yellow
    Write-Host "(Then close and reopen your shell so PATH refreshes.)" -ForegroundColor Yellow
    exit 1
}

$arenas = "assets/images/arenas"
if (-not (Test-Path $arenas)) {
    Write-Host "ERROR: $arenas not found. Run from project root." -ForegroundColor Red
    exit 1
}

$pngs = Get-ChildItem "$arenas/skybox_*.png"
if ($pngs.Count -eq 0) {
    Write-Host "No skybox PNGs found in $arenas" -ForegroundColor Yellow
    exit 0
}

$totalBefore = 0
$totalAfter = 0
$failed = 0

foreach ($png in $pngs) {
    $before = $png.Length
    $totalBefore += $before

    # --skip-if-larger: keep original if pngquant somehow produces a larger file.
    # --strip: drop metadata chunks (EXIF, color profile) — saves bytes, no
    # visual impact for procedural skyboxes.
    # --quality=70-85: visually lossless for natural-looking gradients;
    # exits non-zero if it can't hit the floor (handled below).
    & pngquant --quality=70-85 --strip --skip-if-larger --force `
        --output $png.FullName -- $png.FullName 2>$null

    $after = (Get-Item $png.FullName).Length
    $totalAfter += $after

    if ($after -eq $before) {
        Write-Host "  $($png.Name): $([math]::Round($before/1KB)) KB (unchanged)" -ForegroundColor DarkGray
    } else {
        $pct = [math]::Round(($after / $before) * 100, 1)
        Write-Host "  $($png.Name): $([math]::Round($before/1KB)) KB -> $([math]::Round($after/1KB)) KB ($pct%)" -ForegroundColor Green
    }
}

Write-Host ""
$savedMB = [math]::Round(($totalBefore - $totalAfter) / 1MB, 2)
$beforeMB = [math]::Round($totalBefore / 1MB, 2)
$afterMB = [math]::Round($totalAfter / 1MB, 2)
Write-Host "Total: $beforeMB MB -> $afterMB MB (saved $savedMB MB)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next: review with 'git diff --stat assets/images/arenas/'," -ForegroundColor Yellow
Write-Host "      spot-check one or two visually, then commit + tag a new vX.Y release." -ForegroundColor Yellow
