# Capturas de Miki Tweaks para el README y la web, sin admin y sin tocar el sistema.
# Uso (desde la raíz del repo, en los dos idiomas):
#   foreach ($l in 'es','en') { powershell -STA -File .\herramientas\capturas.ps1 -CapSrc .\MikiTweaks.ps1 -CapFacts .\herramientas\facts.xml -CapOut .\docs\img\$l -CapLang $l -CapKeys 'inicio,resumen,modos,Red=red,Windows=ajustes-windows' }
# facts.xml (datos del escaneo de tu PC) se crea la primera vez y no se sube a git.
# carga la app en modo prueba con los datos de facts.xml, la dibuja fuera de pantalla y guarda PNG.
param([string]$CapSrc, [string]$CapFacts, [string]$CapOut, [ValidateSet('es', 'en')][string]$CapLang, [string[]]$CapKeys, [switch]$CapListKeys)
$ErrorActionPreference = 'Stop'
$CapKeys = @($CapKeys | ForEach-Object { $_ -split ',' } | Where-Object { $_ })

# Carpeta de datos aislada: solo el perfil y el idioma (nada del PC real se lee de ahí ni se escribe en la de verdad)
$iso = Join-Path $env:TEMP "mt-capturas-$CapLang"; Remove-Item $iso -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force (Join-Path $iso 'MikiTweaks') | Out-Null
@{ lang = $CapLang; perfil = @{ uses = @('competitivo'); priority = 'rendimiento'; battery = 'enchufado'; type = 'portatil' } } | ConvertTo-Json -Depth 4 |
    Set-Content (Join-Path $iso 'MikiTweaks\ajustes.json') -Encoding UTF8
@{ current = 'juego' } | ConvertTo-Json | Set-Content (Join-Path $iso 'MikiTweaks\modo.json') -Encoding UTF8
$env:LOCALAPPDATA = $iso
$env:COMPUTERNAME = 'MI-PC'
$env:FT_TEST = '1'

$code = [IO.File]::ReadAllText($CapSrc)
$code = $code.Replace('if (-not $Check -and -not ([Security.Principal.WindowsPrincipal]$me).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {', 'if ($false) {')
# Los informes de error van a la carpeta aislada, nunca al escritorio real
$code = $code.Replace("(Join-Path ([Environment]::GetFolderPath('Desktop')) 'Miki Tweaks - errores.txt')", "(Join-Path `$DataDir 'errores-escritorio.txt')")
$tmp = Join-Path $iso 'app.ps1'; [IO.File]::WriteAllText($tmp, $code, (New-Object Text.UTF8Encoding($true)))
. $tmp

if (-not (Test-Path $CapFacts)) {
    # Escaneo real del PC (solo lectura) con el código actual, guardado para reutilizarlo
    $capSync = [hashtable]::Synchronized(@{ Steps = [Collections.ArrayList]::Synchronized((New-Object Collections.ArrayList)); GameDefs = $GameDefs })
    & $ScanScript $capSync
    $capSync.Facts | Export-Clixml $CapFacts -Depth 6
    Write-Output "Datos del escaneo guardados (error: [$($capSync.Error)])"
}
$script:Sync = @{ Facts = (Import-Clixml $CapFacts); Error = $null }
$window.WindowStartupLocation = 'Manual'; $window.Left = -4000; $window.Top = 0; $window.ShowActivated = $false
$window.Show(); DoEvents
function Snap($name) {
    for ($i = 0; $i -lt 10; $i++) { DoEvents; Start-Sleep -Milliseconds 60 }
    if ($script:Lang -eq 'en' -and ('MtI18n' -as [type])) { [MtI18n]::Walk($window); DoEvents }
    $bmp = New-Object Windows.Media.Imaging.RenderTargetBitmap([int]$window.ActualWidth, [int]$window.ActualHeight, 96, 96, [Windows.Media.PixelFormats]::Pbgra32); $bmp.Render($window)
    $enc = New-Object Windows.Media.Imaging.PngBitmapEncoder; $enc.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bmp))
    New-Item -ItemType Directory -Force $CapOut | Out-Null
    $fs = [IO.File]::Create((Join-Path $CapOut "$name.png")); $enc.Save($fs); $fs.Close()
    Write-Output "  $CapLang/$name.png"
}
if ($CapKeys -contains 'inicio') { Snap 'inicio' }
$script:StepRows = New-Object System.Collections.Generic.List[object]
Finish-Scan; $script:ScoreTimer.Stop(); $script:ScoreCur = Get-Score; Set-Gauge $script:ScoreCur
if ($CapListKeys) { Write-Output ("Secciones: " + (@($script:NavButtons.Keys) -join ', ')) }
foreach ($k in $CapKeys) {
    if ($k -eq 'inicio') { continue }
    $nav, $file = $k -split '=', 2; if (-not $file) { $file = $nav }
    if ($script:NavButtons.ContainsKey($nav)) { Select-Nav $nav; Snap $file } else { Write-Output "  (no existe la sección $nav)" }
}
Stop-Monitor; $window.Close()
Write-Output "Puntuación: $(Get-Score) · lateral: $($UI.SideScore.Text) · idioma: $script:Lang"
