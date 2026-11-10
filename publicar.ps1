<#
  Publica una versión nueva de Miki Tweaks en GitHub con un solo comando:
    .\publicar.ps1 8.4

  Antes, escribe en CHANGELOG.md una sección «## 8.4» con las novedades: se usa como notas de la release.
  Pasos: pone la versión en el script, comprueba (sintaxis, PSScriptAnalyzer, tests), regenera version.json,
  prepara la carpeta y el ZIP, hace commit + etiqueta + push y crea la release con el ZIP.
  Si algo falla, se para antes de publicar nada. Con -Prueba hace todo menos commit, push y release.
#>
param(
    [Parameter(Mandatory)][ValidatePattern('^\d+\.\d+(\.\d+)?$')][string]$Version,
    [switch]$Prueba
)
$ErrorActionPreference = 'Stop'
$repo    = $PSScriptRoot
$script  = Join-Path $repo 'MikiTweaks.ps1'
$dist    = Join-Path (Split-Path $repo) 'Miki Tweaks'          # carpeta que va dentro del ZIP
$zip     = Join-Path (Split-Path $repo) "Miki-Tweaks-$Version.zip"
$gh      = Join-Path $env:LOCALAPPDATA 'Programs\gh\bin\gh.exe'
$ghRepo  = 'mikimagdalenius-dev/miki-tweaks'
function Paso($t) { Write-Host "`n▶ $t" -ForegroundColor Cyan }
function Falla($t) { throw "✗ $t" }

Set-Location $repo

Paso 'Comprobaciones previas'
if (-not (Test-Path $gh)) { Falla "No encuentro gh en $gh" }
& $gh auth status *> $null; if ($LASTEXITCODE) { Falla 'gh no tiene sesión iniciada (gh auth login)' }
if (git status --porcelain -- . ':!MikiTweaks.ps1' ':!CHANGELOG.md' ':!version.json') { Falla 'Hay cambios sin guardar en git aparte del script y el CHANGELOG. Haz commit o descártalos.' }
if (git tag -l "v$Version") { Falla "La etiqueta v$Version ya existe" }
$changelog = Get-Content (Join-Path $repo 'CHANGELOG.md') -Raw -Encoding UTF8
$m = [regex]::Match($changelog, "(?ms)^##\s+$([regex]::Escape($Version))\b[^\n]*\n(.*?)(?=^##\s|\z)")
if (-not $m.Success -or -not $m.Groups[1].Value.Trim()) { Falla "Falta la sección «## $Version» con novedades en CHANGELOG.md" }
$notas = $m.Groups[1].Value.Trim()

Paso "Versión $Version en el script"
$txt = [IO.File]::ReadAllText($script)
$actual = [regex]::Match($txt, "\`$AppVersion\s*=\s*'([^']+)'").Groups[1].Value
if ([version]$Version -le [version]$actual -and $Version -ne $actual) { Falla "La versión $Version no es mayor que la actual ($actual)" }
# Solo la declaración (inicio de línea): el estático [regex]::Replace(..., 1) tomaba el 1 como opción y cambiaba todas las apariciones
$txt = ([regex]"(?m)^(\`$AppVersion\s*=\s*)'[^']+'").Replace($txt, "`${1}'$Version'", 1)
[IO.File]::WriteAllText($script, $txt, (New-Object Text.UTF8Encoding($true)))   # con BOM: PowerShell 5.1 lo necesita para los acentos

Paso 'Sintaxis'
$e = $null; [void][Management.Automation.Language.Parser]::ParseFile($script, [ref]$null, [ref]$e)
if ($e.Count) { $e | Select-Object -First 5 | ForEach-Object { Write-Host "  línea $($_.Extent.StartLineNumber): $($_.Message)" }; Falla "$($e.Count) errores de sintaxis" }

Paso 'PSScriptAnalyzer (solo errores)'
$a = @(Invoke-ScriptAnalyzer -Path $script -Severity Error)
if ($a.Count) { $a | ForEach-Object { Write-Host "  línea $($_.Line): $($_.Message)" }; Falla "$($a.Count) errores de PSScriptAnalyzer" }

Paso 'version.json'
# El script se descarga de la etiqueta de la versión, no de main: main tarda unos minutos en refrescarse en la caché de GitHub
# y mientras tanto la huella no coincidiría (la app rechaza la actualización hasta el siguiente intento)
$manifest = [ordered]@{ version = $Version; url = "https://raw.githubusercontent.com/$ghRepo/v$Version/MikiTweaks.ps1"; sha256 = (Get-FileHash $script -Algorithm SHA256).Hash; notes = '' }
[IO.File]::WriteAllText((Join-Path $repo 'version.json'), ($manifest | ConvertTo-Json), (New-Object Text.UTF8Encoding($false)))

Paso 'Tests'
Import-Module Pester -MinimumVersion 5.5
$c = New-PesterConfiguration; $c.Run.Path = (Join-Path $repo 'tests'); $c.Run.PassThru = $true; $c.Output.Verbosity = 'Normal'
$r = Invoke-Pester -Configuration $c
if ($r.FailedCount -or -not $r.PassedCount) { Falla "$($r.FailedCount) tests fallados" }

Paso 'Carpeta y ZIP'
Copy-Item $script (Join-Path $dist 'MikiTweaks.ps1') -Force
Compress-Archive -Path $dist -DestinationPath $zip -Force
Write-Host "  $zip ($([math]::Round((Get-Item $zip).Length / 1KB)) KB)"

if ($Prueba) { Write-Host "`n✓ Prueba completa. No se ha publicado nada (el script queda con la versión $Version)." -ForegroundColor Green; return }

Paso 'Commit, etiqueta y push'
git add -A; git commit -q -m "Miki Tweaks $Version"; git tag "v$Version"
git push -q origin main "v$Version"; if ($LASTEXITCODE) { Falla 'git push falló' }

Paso 'Release en GitHub'
$nf = Join-Path $env:TEMP "mt-notas-$Version.md"
[IO.File]::WriteAllText($nf, "$notas`n`n**Instalación:** descarga el ZIP, clic derecho → Propiedades → Desbloquear, extrae y abre «Abrir Miki Tweaks.cmd». Si ya la tienes instalada, se actualiza sola.", (New-Object Text.UTF8Encoding($false)))
# En la release va con nombre fijo: la web descarga siempre releases/latest/download/Miki-Tweaks.zip
$rel = Join-Path $env:TEMP "mt-release-$Version"; New-Item -ItemType Directory -Force $rel | Out-Null
$zipRel = Join-Path $rel 'Miki-Tweaks.zip'; Copy-Item $zip $zipRel -Force
& $gh release create "v$Version" $zipRel --repo $ghRepo --title "Miki Tweaks $Version" --notes-file $nf
Remove-Item $nf; Remove-Item $rel -Recurse -Force
if ($LASTEXITCODE) { Falla 'No se pudo crear la release (el código ya está subido: créala a mano o vuelve a lanzar solo este paso)' }

Write-Host "`n✓ Miki Tweaks $Version publicada. Las copias instaladas se actualizarán en su próxima comprobación." -ForegroundColor Green
