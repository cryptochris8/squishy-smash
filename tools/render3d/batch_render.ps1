# Batch driver for blender_render_squishy.py over all 48 Meshy FBX models.
#
#   powershell -File batch_render.ps1 -Mode heroes        # 1024 hero per friend (fast review pass)
#   powershell -File batch_render.ps1 -Mode full          # 2048 hero + GLB + 60f turntable @1080
#   powershell -File batch_render.ps1 -Mode full -Only soft_dumpling,goo_ball
#
# Resumable: skips a friend when its final output for the mode already exists.
# Per-friend yaw overrides live in yaw_overrides.json next to this script.

param(
    [ValidateSet("heroes", "full")] [string]$Mode = "heroes",
    [string[]]$Only = @()
)

$blender = "C:\Program Files\Blender Foundation\Blender 4.3\blender.exe"
$script  = Join-Path $PSScriptRoot "blender_render_squishy.py"
$fbxDir  = "C:\Users\chris\Roblox-squishy\tools\mesh_pipeline\output"
$outRoot = "C:\Users\chris\Squishy-smash\_tmp_3d_renders"
$yawFile = Join-Path $PSScriptRoot "yaw_overrides.json"

$yaws = @{}
if (Test-Path $yawFile) {
    (Get-Content $yawFile -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $yaws[$_.Name] = $_.Value }
}

$fbxes = Get-ChildItem $fbxDir -Filter *.fbx | Sort-Object Name
if ($Only.Count -gt 0) { $fbxes = $fbxes | Where-Object { $Only -contains $_.BaseName } }

$done = 0
foreach ($fbx in $fbxes) {
    $name = $fbx.BaseName
    $out  = Join-Path $outRoot $name
    $yaw  = 0.0
    if ($yaws.ContainsKey($name)) { $yaw = $yaws[$name] }

    if ($Mode -eq "heroes") {
        $marker = Join-Path $out "$($name)_hero_1024.png"
        $extra  = @("--hero", "1024")
    } else {
        $marker = Join-Path $out "turntable\$($name)_0060.png"
        $extra  = @("--hero", "2048", "--glb", "--turntable", "60", "--res", "1080")
    }
    if (Test-Path $marker) { Write-Output "SKIP  $name"; $done++; continue }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    & $blender -b --factory-startup -P $script -- --fbx $fbx.FullName --out $out --name $name --yaw $yaw @extra 2>$null |
        Where-Object { $_ -match "^\[render3d\] ALL DONE" } | Out-Null
    $sw.Stop()
    if (Test-Path $marker) {
        $done++
        Write-Output ("OK    {0}  ({1:n0}s)  [{2}/{3}]" -f $name, $sw.Elapsed.TotalSeconds, $done, $fbxes.Count)
    } else {
        Write-Output "FAIL  $name"
    }
}
Write-Output "BATCH COMPLETE ($Mode): $done/$($fbxes.Count)"
