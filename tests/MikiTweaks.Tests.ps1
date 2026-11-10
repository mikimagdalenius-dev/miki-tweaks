# Tests de Miki Tweaks (Pester 5 o superior). Se ejecutan sin admin y sin abrir la interfaz:
# de MikiTweaks.ps1 solo se cargan las funciones que se prueban.
#   Invoke-Pester .\tests

BeforeAll {
    $script:Src = Join-Path $PSScriptRoot '..\MikiTweaks.ps1'
    $errs = $null
    $script:Ast = [Management.Automation.Language.Parser]::ParseFile($script:Src, [ref]$null, [ref]$errs)
    $script:ParseErrors = $errs

    function Import-AppFunction([string[]]$Name) {
        foreach ($n in $Name) {
            $fn = $script:Ast.Find({ param($a) $a -is [Management.Automation.Language.FunctionDefinitionAst] -and $a.Name -eq $n }, $true)
            if (-not $fn) { throw "No existe la función $n en MikiTweaks.ps1" }
            # Definición completa (con sus parámetros), declarada global para que la vean los tests
            . ([scriptblock]::Create(($fn.Extent.Text -replace "^function\s+$([regex]::Escape($n))", "function global:$n")))
        }
    }
    $script:AppVersion = [regex]::Match((Get-Content $script:Src -Raw), "\`$AppVersion\s*=\s*'([^']+)'").Groups[1].Value
}

Describe 'Script' {
    It 'no tiene errores de sintaxis' {
        $script:ParseErrors.Count | Should -Be 0
    }
    It 'declara una versión válida' {
        { [version]$script:AppVersion } | Should -Not -Throw
    }
}

Describe 'Interfaz' {
    # WPF solo construye las plantillas al dibujar un control: un error ahí no sale al cargar la ventana, sino al usarla
    BeforeAll {
        Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
        $l = Get-Content $script:Src -Encoding UTF8
        $start = ($l | Select-String '^\s*<Window\b' | Select-Object -First 1).LineNumber - 1
        $end = $start + ($l[$start..($start + 400)] | Select-String "^'@" | Select-Object -First 1).LineNumber - 1
        $script:Win = [Windows.Markup.XamlReader]::Parse(($l[$start..($end - 1)] -join "`n"))
        $script:Styles = @($script:Win.Resources.Keys | ForEach-Object { $script:Win.Resources[$_] } | Where-Object { $_ -is [Windows.Style] -and $_.TargetType -and -not $_.TargetType.IsAbstract })
    }
    AfterAll { if ($script:Win) { $script:Win.Close() } }

    It 'la ventana principal tiene estilos' {
        $script:Styles.Count | Should -BeGreaterThan 0
    }
    It 'todas las plantillas de estilo se construyen sin error' {
        foreach ($s in $script:Styles) {
            $c = [Activator]::CreateInstance($s.TargetType); $c.Style = $s
            if ($c -is [Windows.Controls.Primitives.ScrollBar]) { $c.Orientation = 'Vertical'; $c.Maximum = 100; $c.ViewportSize = 20 }
            $g = New-Object Windows.Controls.Grid; [void]$g.Children.Add($c)
            { $g.Measure([Windows.Size]::new(300, 300)); $g.Arrange([Windows.Rect]::new(0, 0, 300, 300)); $g.UpdateLayout() } | Should -Not -Throw -Because "el estilo $($s.TargetType.Name) tiene que poder dibujarse"
        }
    }
}

Describe 'Canal de actualizaciones (version.json)' {
    # Si esto falla, las copias instaladas rechazarían la actualización o recibirían otra versión
    BeforeAll { $script:Manifest = Get-Content (Join-Path $PSScriptRoot '..\version.json') -Raw | ConvertFrom-Json }
    It 'anuncia la misma versión que el script' {
        $script:Manifest.version | Should -Be $script:AppVersion
    }
    It 'tiene la huella SHA-256 del script tal cual está en el repo' {
        $script:Manifest.sha256 | Should -Be (Get-FileHash $script:Src -Algorithm SHA256).Hash
    }
    It 'descarga por https desde el repo' {
        $script:Manifest.url | Should -Match '^https://raw\.githubusercontent\.com/.+/MikiTweaks\.ps1$'
    }
}

Describe 'Copias de seguridad de los ajustes' {
    BeforeEach {
        $global:BackupFile = Join-Path $TestDrive 'backup.json'
        $script:Backup = @{}
        Import-AppFunction Save-BackupFile, Backup-Item, Get-BackupItem, Clear-BackupItem, Test-HasBackup
    }
    It 'guarda el valor original y no lo pisa al volver a aplicar' {
        Backup-Item 'red#0' @{ value = 'original' }
        Backup-Item 'red#0' @{ value = 'ya cambiado' }
        (Get-BackupItem 'red#0').value | Should -Be 'original'
    }
    It 'escribe la copia en disco' {
        Backup-Item 'red#0' @{ value = '1' }
        (Get-Content $global:BackupFile -Raw | ConvertFrom-Json).'red#0'.value | Should -Be '1'
    }
    It 'reconoce los ajustes con varias partes (id#n)' {
        Backup-Item 'red#1' @{ value = '1' }
        Test-HasBackup 'red' | Should -BeTrue
        Test-HasBackup 'otro' | Should -BeFalse
    }
    It 'borra la copia al deshacer' {
        Backup-Item 'red#0' @{ value = '1' }
        Clear-BackupItem 'red#0'
        Get-BackupItem 'red#0' | Should -BeNullOrEmpty
        Test-HasBackup 'red' | Should -BeFalse
    }
}

Describe 'Informe de errores' {
    BeforeEach {
        $global:DataDir = $TestDrive
        $global:AppVersion = '9.9'
        Remove-Item (Join-Path $TestDrive 'errores.log') -ErrorAction SilentlyContinue
        Import-AppFunction Get-ErrorReport
    }
    It 'no escribe nada en el escritorio del usuario' {
        (Get-Content $script:Src -Raw) | Should -Not -Match "GetFolderPath\('Desktop'\)\)\s*'Miki Tweaks - errores"
    }
    It 'devuelve nada si no hay errores' {
        Get-ErrorReport | Should -BeNullOrEmpty
    }
    It 'copia solo los últimos errores, con la versión' {
        $sep = '-' * 70
        $log = (1..12 | ForEach-Object { "Miki Tweaks 9.9  |  fallo $_`r`nDetalle $_`r`n$sep" }) -join "`r`n"
        Set-Content (Join-Path $TestDrive 'errores.log') $log -Encoding UTF8
        $r = Get-ErrorReport 3
        $r | Should -Match '^Miki Tweaks [\d\.]+ · 3 de 12 errores'
        $r | Should -Match 'fallo 12'
        $r | Should -Match 'fallo 10'
        $r | Should -Not -Match 'fallo 9\b'
    }
}

Describe 'Traducciones' {
    It 'el diccionario de inglés es JSON válido y no menciona el archivo del escritorio' {
        $line = (Get-Content $script:Src -Encoding UTF8) | Where-Object { $_ -like '{"tpl":*' } | Select-Object -First 1
        $d = $line | ConvertFrom-Json
        @($d.map).Count | Should -BeGreaterThan 100
        $line | Should -Not -Match 'errores\.txt'
    }
}

Describe 'Escritura en el registro' {
    BeforeAll {
        Import-AppFunction Set-RegValue, Remove-RegValue
        $script:Key = 'HKCU:\Software\MikiTweaks-Tests'
    }
    AfterAll { Remove-Item $script:Key -Recurse -Force -ErrorAction SilentlyContinue }

    It 'crea la clave si no existe y escribe un DWORD' {
        Set-RegValue $script:Key 'Numero' 1
        (Get-ItemProperty $script:Key).Numero | Should -Be 1
    }
    It 'escribe texto' {
        Set-RegValue $script:Key 'Texto' 'hola' 'String'
        (Get-ItemProperty $script:Key).Texto | Should -Be 'hola'
    }
    It 'aplicar y deshacer deja el valor como estaba' {
        Set-RegValue $script:Key 'Ciclo' 0
        $antes = (Get-ItemProperty $script:Key).Ciclo
        Set-RegValue $script:Key 'Ciclo' 1
        Set-RegValue $script:Key 'Ciclo' $antes
        (Get-ItemProperty $script:Key).Ciclo | Should -Be 0
    }
    It 'borra un valor' {
        Remove-RegValue $script:Key 'Texto'
        (Get-ItemProperty $script:Key).PSObject.Properties.Name | Should -Not -Contain 'Texto'
    }
}
