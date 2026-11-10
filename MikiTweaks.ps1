<#
  Miki Tweaks · (v7.7)
  Fortnite, VALORANT, League of Legends, CS2, Apex, Rainbow Six Siege, Overwatch 2, Rocket League, Marvel Rivals, Dota 2, PUBG
  1) Escanea el PC  2) Propone solo los ajustes que tienen sentido en ese equipo  3) Aplica / revierte con copia de seguridad
  Nunca toca: Medal, Riot Vanguard. Los planes de energía no se modifican (los Modos solo eligen cuál está activo).
#>
param([string]$Mode, [switch]$Auto, [switch]$Check, [switch]$Watch, [switch]$Tray)

# ======================= Elevación =======================
$me = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $Check -and -not ([Security.Principal.WindowsPrincipal]$me).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $extra = ''; if ($Mode) { $extra += " -Mode $Mode" }; if ($Auto) { $extra += ' -Auto' }; if ($Watch) { $extra += ' -Watch' }; if ($Tray) { $extra += ' -Tray' }
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$PSCommandPath`"$extra"
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing
$ErrorActionPreference = 'Stop'
$Inv = [Globalization.CultureInfo]::InvariantCulture

# ======================= Rutas =======================
$DataDir     = Join-Path $env:LOCALAPPDATA 'MikiTweaks'
$OldDataDirs = @((Join-Path $env:LOCALAPPDATA 'CompetitiveTweaks'), (Join-Path $env:LOCALAPPDATA 'FortniteTweaks'))
if (-not (Test-Path $DataDir)) { $od = $OldDataDirs | Where-Object { Test-Path $_ } | Select-Object -First 1; if ($od) { Copy-Item $od $DataDir -Recurse; Remove-Item (Join-Path $DataDir 'app'), (Join-Path $DataDir 'logo.png'), (Join-Path $DataDir 'logo.ico') -Recurse -Force -ErrorAction SilentlyContinue } }
$FsoKey      = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers'
$AppDir      = Join-Path $DataDir 'app'
$AppPath     = Join-Path $AppDir 'MikiTweaks.ps1'

# ======================= Juegos soportados =======================
$GameDefs = @(
    @{ Id = 'fortnite'; Name = 'Fortnite'; Abbr = 'FN'; Color = '#7C3AED'; Api = 'dx12'; Exes = @('FortniteClient-Win64-Shipping.exe')
       Epic = 'Fortnite'; EpicRel = @('FortniteGame\Binaries\Win64\FortniteClient-Win64-Shipping.exe'); Riot = $null; RiotRel = @()
       Rel = @('Fortnite\FortniteGame\Binaries\Win64\FortniteClient-Win64-Shipping.exe')
       Tips = @('Modo de renderizado: Rendimiento', 'NVIDIA Reflex: Activado + Aumento', 'Si vas sobrado de FPS, resolución 3D al 100 %; bájala solo si no llegas a los Hz del monitor') },
    @{ Id = 'valorant'; Name = 'VALORANT'; Abbr = 'VAL'; Color = '#E8404D'; Api = 'dx11'; Exes = @('VALORANT-Win64-Shipping.exe')
       Epic = $null; EpicRel = @(); Riot = 'valorant.live'; RiotRel = @('ShooterGame\Binaries\Win64\VALORANT-Win64-Shipping.exe')
       Rel = @('VALORANT\live\ShooterGame\Binaries\Win64\VALORANT-Win64-Shipping.exe')
       Tips = @('NVIDIA Reflex: Activado + Aumento', 'Modo de pantalla: Pantalla completa', 'Sincronización vertical desactivada') },
    @{ Id = 'lol'; Name = 'League of Legends'; Abbr = 'LoL'; Color = '#B8862B'; Api = 'dx11'; Exes = @('League of Legends.exe')
       Epic = $null; EpicRel = @(); Riot = 'league_of_legends.live'; RiotRel = @('Game\League of Legends.exe')
       Rel = @('League of Legends\Game\League of Legends.exe')
       Tips = @('Modo de ventana: Pantalla completa', 'Sincronización vertical desactivada', 'Limitar FPS a un valor fijo alto (por ejemplo 240) para que los frametimes sean estables') },
    @{ Id = 'cs2'; Name = 'Counter-Strike 2'; Abbr = 'CS2'; Color = '#D97706'; Api = 'dx11'; Exes = @('cs2.exe')
       Epic = $null; EpicRel = @(); Riot = $null; RiotRel = @()
       Rel = @('Counter-Strike Global Offensive\game\bin\win64\cs2.exe')
       Tips = @('NVIDIA Reflex: Activado + Aumento', 'Modo de pantalla: Pantalla completa', 'Sincronización vertical desactivada') },
    @{ Id = 'apex'; Name = 'Apex Legends'; Abbr = 'APX'; Color = '#C2272D'; Api = 'dx11'; Exes = @('r5apex.exe', 'r5apex_dx12.exe')
       Epic = $null; EpicRel = @(); Riot = $null; RiotRel = @()
       Rel = @('Apex Legends\r5apex.exe', 'Apex Legends\r5apex_dx12.exe', 'Apex\r5apex.exe', 'Apex\r5apex_dx12.exe')
       Tips = @('NVIDIA Reflex: Activado + Aumento', 'Modo de pantalla: Pantalla completa', 'Sincronización vertical desactivada') },
    @{ Id = 'r6'; Name = 'Rainbow Six Siege'; Abbr = 'R6'; Color = '#0EA5E9'; Api = 'dx11'; Exes = @('RainbowSix.exe', 'RainbowSix_Vulkan.exe')
       Epic = $null; EpicRel = @(); Riot = $null; RiotRel = @()
       Rel = @("Tom Clancy's Rainbow Six Siege\RainbowSix.exe", "Tom Clancy's Rainbow Six Siege\RainbowSix_Vulkan.exe", "Tom Clancy's Rainbow Six Siege X\RainbowSix.exe")
       Tips = @('NVIDIA Reflex: Activado + Aumento', 'Modo de pantalla: Pantalla completa', 'Sincronización vertical desactivada') },
    @{ Id = 'ow'; Name = 'Overwatch 2'; Abbr = 'OW'; Color = '#EA7A1E'; Api = 'dx11'; Exes = @('Overwatch.exe')
       Epic = $null; EpicRel = @(); Riot = $null; RiotRel = @()
       Rel = @('Overwatch\_retail_\Overwatch.exe')
       Tips = @('NVIDIA Reflex: Activado + Aumento', 'Reducir búfer: Activado', 'Modo de pantalla: Pantalla completa') },
    @{ Id = 'rl'; Name = 'Rocket League'; Abbr = 'RL'; Color = '#2563EB'; Api = 'dx11'; Exes = @('RocketLeague.exe')
       Epic = 'Rocket League'; EpicRel = @('Binaries\Win64\RocketLeague.exe'); Riot = $null; RiotRel = @()
       Rel = @('rocketleague\Binaries\Win64\RocketLeague.exe')
       Tips = @('Modo de pantalla: Pantalla completa', 'Sincronización vertical desactivada', 'One Frame Thread Lag: activado') },
    @{ Id = 'rivals'; Name = 'Marvel Rivals'; Abbr = 'MR'; Color = '#BE123C'; Api = 'dx12'; Exes = @('Marvel-Win64-Shipping.exe')
       Epic = 'Marvel Rivals'; EpicRel = @('MarvelGame\Marvel\Binaries\Win64\Marvel-Win64-Shipping.exe'); Riot = $null; RiotRel = @()
       Rel = @('MarvelRivals\MarvelGame\Marvel\Binaries\Win64\Marvel-Win64-Shipping.exe')
       Tips = @('NVIDIA Reflex: Activado + Aumento', 'Modo de pantalla: Pantalla completa', 'Sincronización vertical desactivada') },
    @{ Id = 'dota'; Name = 'Dota 2'; Abbr = 'D2'; Color = '#9F1D1D'; Api = 'dx11'; Exes = @('dota2.exe')
       Epic = $null; EpicRel = @(); Riot = $null; RiotRel = @()
       Rel = @('dota 2 beta\game\bin\win64\dota2.exe')
       Tips = @('Modo de pantalla: Pantalla completa', 'Sincronización vertical desactivada') },
    @{ Id = 'pubg'; Name = 'PUBG'; Abbr = 'PG'; Color = '#CA8A04'; Api = 'dx11'; Exes = @('TslGame.exe')
       Epic = $null; EpicRel = @(); Riot = $null; RiotRel = @()
       Rel = @('PUBG\TslGame\Binaries\Win64\TslGame.exe')
       Tips = @('NVIDIA Reflex: Activado + Aumento', 'Modo de pantalla: Pantalla completa', 'Sincronización vertical desactivada') }
)
# Juegos extra: añade los tuyos en juegos.json (junto a la app o en la carpeta de datos), sin tocar el código
foreach ($gf in @($(if ($PSScriptRoot) { Join-Path $PSScriptRoot 'juegos.json' }), (Join-Path $DataDir 'juegos.json'))) {
    if (-not $gf -or -not (Test-Path $gf)) { continue }
    try {
        foreach ($g in @(Get-Content $gf -Raw -Encoding UTF8 | ConvertFrom-Json)) {
            $h = @{}; foreach ($p in $g.PSObject.Properties) { $h[$p.Name] = $p.Value }
            foreach ($k in 'Exes', 'Rel', 'EpicRel', 'RiotRel', 'Tips') { $h[$k] = @($h[$k] | Where-Object { $_ }) }
            if (-not $h.Abbr) { $h.Abbr = "$($h.Name)".Substring(0, [math]::Min(3, "$($h.Name)".Length)).ToUpper() }
            if ("$($h.Color)" -notmatch '^#[0-9A-Fa-f]{6}$') { $h.Color = '#475569' }; if (-not $h.Api) { $h.Api = 'dx11' }   # el color se usa con transparencia (#AARRGGBB)
            if ($h.Id -and $h.Name -and $h.Exes.Count -and -not ($GameDefs | Where-Object { $_.Id -eq $h.Id })) { $GameDefs += $h }
        }
    } catch {}
}
$GameDefById = @{}; foreach ($g in $GameDefs) { $GameDefById[$g.Id] = $g }
$BackupFile  = Join-Path $DataDir 'backup.json'
$LogFile     = Join-Path $DataDir 'tweaks.log'
New-Item -ItemType Directory -Force -Path $DataDir | Out-Null
$FnIni       = Join-Path $env:LOCALAPPDATA 'FortniteGame\Saved\Config\WindowsClient\GameUserSettings.ini'
$GameBarKey  = 'HKCU:\Software\Microsoft\GameBar'
$GmTask      = 'MikiTweaks - Modo Juego'
$ApprovedRun = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'
$UserRun     = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'

# ======================= Backup =======================
$script:Backup = @{}
if (Test-Path $BackupFile) {
    try {
        $o = Get-Content $BackupFile -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($p in $o.PSObject.Properties) { $script:Backup[$p.Name] = $p.Value }
    } catch {}
}
function Save-BackupFile { ($script:Backup | ConvertTo-Json -Depth 6) | Set-Content -Path $BackupFile -Encoding UTF8 }
function Backup-Item($key, $value) { if (-not $script:Backup.ContainsKey($key)) { $script:Backup[$key] = $value; Save-BackupFile } }
function Get-BackupItem($key) { if ($script:Backup.ContainsKey($key)) { return $script:Backup[$key] } return $null }
function Clear-BackupItem($key) { if ($script:Backup.ContainsKey($key)) { $script:Backup.Remove($key); Save-BackupFile } }
function Test-HasBackup($id) { foreach ($k in @($script:Backup.Keys)) { if ($k -eq $id -or $k -like "$id#*") { return $true } }; return $false }

# ======================= Ajustes de la app =======================
$AppVersion   = '8.5'

# ======================= Protección contra errores =======================
# Si algo falla en un PC concreto, la app no se cierra: guarda el detalle y sigue con lo demás.
$script:SafeErrors = New-Object System.Collections.Generic.List[string]
function Write-CrashLog($err, $where) {
    try {
        # Se busca en toda la cadena de excepciones la capa de PowerShell, que es la que sabe la línea y la instrucción
        $rec = $null; $ex = $null
        if ($err -is [Management.Automation.ErrorRecord]) { $rec = $err; $ex = $err.Exception } elseif ($err -is [Exception]) { $ex = $err }
        $chain = @(); $e = $ex
        while ($e) { $chain += $e; if (-not $rec -and $e -is [Management.Automation.IContainsErrorRecord] -and $e.ErrorRecord -and $e.ErrorRecord.InvocationInfo) { $rec = $e.ErrorRecord }; $e = $e.InnerException }
        $inner = if ($chain.Count) { $chain[-1] } else { $null }
        $msg = if ($inner) { "$($inner.Message)" } else { "$err" }
        if ($rec) {
            $msg += "`r`nInstrucción: $("$($rec.InvocationInfo.Line)".Trim())"
            $msg += "`r`nLínea $($rec.InvocationInfo.ScriptLineNumber), columna $($rec.InvocationInfo.OffsetInLine)"
            if ($rec.ScriptStackTrace) { $msg += "`r`n$($rec.ScriptStackTrace)" }
        } elseif ($inner) { $msg += "`r`n$($inner.StackTrace)" }
        $os = try { (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).Caption } catch { 'Windows' }
        $bld = try { $cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop; "$($cv.CurrentBuild).$($cv.UBR)" } catch { [Environment]::OSVersion.Version.Build }
        $txt = "Miki Tweaks $AppVersion  |  $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')  |  $where`r`n$os (build $bld)$(if ($script:CurrentKey) { "  |  sección abierta: $($script:CurrentKey)" })`r`n$msg`r`n$('-' * 70)"
        Add-Content -Path (Join-Path $DataDir 'errores.log') -Value $txt -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {}
}
function Get-ErrorReport($max = 8) {
    # Los últimos fallos de errores.log, listos para pegar al reportar en GitHub ($null si no hay ninguno)
    $f = Join-Path $DataDir 'errores.log'
    if (-not (Test-Path $f)) { return $null }
    $entries = @(((Get-Content $f -Raw -Encoding UTF8) -split '(?m)^-{70}\s*$') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if (-not $entries.Count) { return $null }
    $last = @($entries | Select-Object -Last $max)
    "Miki Tweaks $AppVersion · $(if ($entries.Count -eq 1) { '1 error registrado' } else { "$($last.Count) de $($entries.Count) errores registrados" })`r`n`r`n" + ($last -join "`r`n$('-' * 70)`r`n")
}
function Copy-ErrorReport {
    $r = Get-ErrorReport
    if (-not $r) { Show-AppToast 'No hay ningún error registrado en este PC.' 'info'; return }
    [Windows.Clipboard]::SetText($r)
    Show-AppToast 'Informe copiado. Pégalo al reportar el fallo en GitHub.' 'ok'
}
function Invoke-Safe($where, [scriptblock]$code) {
    try { & $code } catch { Write-CrashLog $_ $where; [void]$script:SafeErrors.Add($where) }
}
function Get-SafeSection($where, [scriptblock]$code) {
    try { return (& $code) } catch {
        Write-CrashLog $_ "sección $where"; [void]$script:SafeErrors.Add($where)
        $sp = New-Object Windows.Controls.StackPanel
        $tb = New-Object Windows.Controls.TextBlock
        $tb.Text = "Esta sección no se ha podido mostrar en este PC. El resto de la app funciona con normalidad.`r`nPulsa «Copiar informe» y pégalo al reportar el fallo en GitHub para que se pueda arreglar."
        $tb.Foreground = [Windows.Media.Brushes]::LightCoral; $tb.TextWrapping = 'Wrap'; $tb.FontSize = 14; $tb.Margin = '4,12,4,12'
        [void]$sp.Children.Add($tb)
        try { $b = New-El '<Button {NS} Style="{DynamicResource Ghost}" Content="Copiar informe" HorizontalAlignment="Left" Margin="4,0,0,0"/>'; $b.Add_Click({ Copy-ErrorReport }); [void]$sp.Children.Add($b) } catch {}
        return $sp
    }
}
# Canal de actualizaciones: dirección https de un version.json. Se puede fijar aquí antes de repartir la app
# (p. ej. https://raw.githubusercontent.com/<usuario>/miki-tweaks/main/version.json) o en Ajustes.
$UpdateUrlDefault = 'https://raw.githubusercontent.com/mikimagdalenius-dev/miki-tweaks/main/version.json'
$ProjectUrlDefault = 'https://github.com/mikimagdalenius-dev/miki-tweaks'   # Página del proyecto (por ejemplo, la de GitHub) cuando exista: activa el botón «Web del proyecto»
$SupportUrlDefault = ''   # Enlace de donaciones (Ko-fi, GitHub Sponsors...) cuando exista: activa el botón «Apoyar el proyecto»
$SettingsFile = Join-Path $DataDir 'ajustes.json'
function Get-Setting($name, $default) {
    try { if (Test-Path $SettingsFile) { $o = Get-Content $SettingsFile -Raw -Encoding UTF8 | ConvertFrom-Json; if ($null -ne $o.$name) { return $o.$name } } } catch {}
    return $default
}
function Set-Setting($name, $value) {
    $h = @{}
    try { if (Test-Path $SettingsFile) { $o = Get-Content $SettingsFile -Raw -Encoding UTF8 | ConvertFrom-Json; foreach ($p in $o.PSObject.Properties) { $h[$p.Name] = $p.Value } } } catch {}
    $h[$name] = $value
    ($h | ConvertTo-Json -Depth 5) | Set-Content -Path $SettingsFile -Encoding UTF8
}

# ======================= Idiomas (espanol / ingles) =======================
# Los textos de la app estan escritos en espanol. En ingles, MtI18n los traduce al vuelo con un diccionario:
# frases exactas y plantillas con datos variables ("Escaneo completado: {0} ajustes analizados").
$I18nCs = @'
using System; using System.Collections.Generic; using System.Text; using System.Text.RegularExpressions;
using System.Windows; using System.Windows.Controls; using System.Windows.Documents; using System.Windows.Media;
public static class MtI18n {
  public static bool On = false;
  static Dictionary<string, string> Map = new Dictionary<string, string>();
  static List<KeyValuePair<Regex, string>> Tpl = new List<KeyValuePair<Regex, string>>();
  static List<int> TplLen = new List<int>();
  static Dictionary<string, string> Cache = new Dictionary<string, string>();
  static HashSet<string> Outs = new HashSet<string>();
  public static void Add(string es, string en) { if (!string.IsNullOrEmpty(es) && !Map.ContainsKey(es)) { Map[es] = en; if (en != es) Outs.Add(en); } }
  public static void AddTpl(string es, string en) {
    string[] parts = Regex.Split(es, @"\{(\d+)(?::[^}]*)?\}");
    StringBuilder sb = new StringBuilder("^"); int lit = 0;
    for (int i = 0; i < parts.Length; i++) {
      if (i % 2 == 0) { sb.Append(Regex.Escape(parts[i])); lit += parts[i].Length; }
      else sb.Append("(?<g" + parts[i] + ">.*?)");
    }
    sb.Append("$");
    if (lit < 4) return;
    Regex rx = new Regex(sb.ToString(), RegexOptions.Singleline | RegexOptions.CultureInvariant);
    int pos = 0; while (pos < TplLen.Count && TplLen[pos] >= lit) pos++;
    Tpl.Insert(pos, new KeyValuePair<Regex, string>(rx, en)); TplLen.Insert(pos, lit);
  }
  public static string T(string s) {
    if (!On || string.IsNullOrEmpty(s)) return s;
    if (Outs.Contains(s)) return s;
    string r; if (Cache.TryGetValue(s, out r)) return r;
    r = Tr(s); if (Cache.Count < 50000) { Cache[s] = r; if (r != s) { Outs.Add(r); Cache[r] = r; } } return r;
  }
  static string Tr(string s) {
    string v; if (Map.TryGetValue(s, out v)) return v;
    string t = s.Trim();
    if (t.Length > 0 && t.Length != s.Length && Map.TryGetValue(t, out v)) { int i = s.IndexOf(t); return s.Substring(0, i) + v + s.Substring(i + t.Length); }
    foreach (KeyValuePair<Regex, string> kv in Tpl) {
      Match m = kv.Key.Match(s);
      if (m.Success) return Regex.Replace(kv.Value, @"\{(\d+)(?::[^}]*)?\}", delegate (Match x) {
        Group g = m.Groups["g" + x.Groups[1].Value]; if (!g.Success) return "";
        string gv = g.Value; return (gv.Length > 0 && gv != s) ? T(gv) : gv; });
    }
    return s;
  }
  static void Inl(InlineCollection c) {
    foreach (Inline i in c) {
      Run r = i as Run; if (r != null) { string n = T(r.Text); if (!object.ReferenceEquals(n, r.Text) && n != r.Text) r.Text = n; continue; }
      Span sp = i as Span; if (sp != null) Inl(sp.Inlines);
    }
  }
  static void One(DependencyObject d) {
    TextBlock tb = d as TextBlock;
    if (tb != null) {
      if (tb.Inlines.Count == 1 && tb.Inlines.FirstInline is Run && !System.Windows.Data.BindingOperations.IsDataBound(tb, TextBlock.TextProperty)) { string s0 = tb.Text; string n0 = T(s0); if (n0 != s0) tb.Text = n0; }
      else Inl(tb.Inlines);
    }
    if (d is System.Windows.Controls.Primitives.TextBoxBase || d is PasswordBox) return;
    ContentControl cc = d as ContentControl;
    if (cc != null) { string s = cc.Content as string; if (s != null) { string n = T(s); if (n != s) cc.Content = n; } }
    HeaderedContentControl hc = d as HeaderedContentControl;
    if (hc != null) { string s = hc.Header as string; if (s != null) { string n = T(s); if (n != s) hc.Header = n; } }
    FrameworkElement fe = d as FrameworkElement;
    if (fe != null) { string s = fe.ToolTip as string; if (s != null) { string n = T(s); if (n != s) fe.ToolTip = n; } }
    Window w = d as Window; if (w != null && w.Title != null) { string n = T(w.Title); if (n != w.Title) w.Title = n; }
  }
  public static void Walk(DependencyObject root) {
    if (!On || root == null) return;
    HashSet<DependencyObject> seen = new HashSet<DependencyObject>(); Stack<DependencyObject> st = new Stack<DependencyObject>(); st.Push(root);
    while (st.Count > 0) {
      DependencyObject d = st.Pop(); if (!seen.Add(d)) continue;
      try { One(d); } catch { }
      if (d is Visual || d is System.Windows.Media.Media3D.Visual3D) {
        int n = 0; try { n = VisualTreeHelper.GetChildrenCount(d); } catch { }
        for (int i = 0; i < n; i++) { DependencyObject c = VisualTreeHelper.GetChild(d, i); if (c != null) st.Push(c); }
      }
      foreach (object o in LogicalTreeHelper.GetChildren(d)) { DependencyObject c = o as DependencyObject; if (c != null) st.Push(c); }
    }
  }
  public static MessageBoxResult Box(string text, string caption, MessageBoxButton b, MessageBoxImage i) { return MessageBox.Show(T(text), caption, b, i); }
  public static int Count { get { return Map.Count + Tpl.Count; } }
}
'@
function Initialize-I18n {
    try {
        if (-not ('MtI18n' -as [type])) {
            Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Xaml
            Add-Type -TypeDefinition $I18nCs -ReferencedAssemblies PresentationFramework, PresentationCore, WindowsBase, System.Xaml -ErrorAction Stop
        }
        $pref = "$(Get-Setting 'lang' 'auto')"
        $script:Lang = if ($pref -in 'es', 'en') { $pref } elseif ([Globalization.CultureInfo]::CurrentUICulture.TwoLetterISOLanguageName -eq 'es') { 'es' } else { 'en' }
        [MtI18n]::On = ($script:Lang -eq 'en')
        if ([MtI18n]::On -and [MtI18n]::Count -eq 0) {
            $d = $I18nEnJson | ConvertFrom-Json
            foreach ($pp in $d.map) { [MtI18n]::Add([string]$pp[0], [string]$pp[1]) }
            foreach ($t in $d.tpl) { [MtI18n]::AddTpl([string]$t[0], [string]$t[1]) }
        }
    } catch { $script:Lang = 'es'; try { [MtI18n]::On = $false } catch {} }
}
function Get-MsgBox { if ('MtI18n' -as [type]) { return [scriptblock]::Create('param($a,$b,$c,$d) [MtI18n]::Box($a,$b,$c,$d)') }; return [scriptblock]::Create('param($a,$b,$c,$d) [Windows.MessageBox]::Show($a,$b,$c,$d)') }
function Tr([string]$s) { if ('MtI18n' -as [type]) { return [MtI18n]::T($s) }; return $s }
$I18nEnJson = @'
{"tpl":[["✓ Miki Tweaks {0} instalada. Se usará la próxima vez que abras la app.","✓ Miki Tweaks {0} installed. It will be used the next time you open the app."],["Miki Tweaks {0} instalada. Se usará la próxima vez que abras la app.","Miki Tweaks {0} installed. It will be used the next time you open the app."],["Descargando Miki Tweaks {0}...","Downloading Miki Tweaks {0}..."],["No se pudo actualizar: {0}","Couldn\u0027t update: {0}"],["Detectada: {0} tarea","Detected: {0} task"],["{0} actualización de Windows pendiente","{0} pending Windows update"],["✓ {0} actualización instalada. Reinicia el PC para terminar.","✓ {0} update installed. Restart the PC to finish."],["✓ {0} actualización instalada.","✓ {0} update installed."],["✓ Perfil guardado ({0} ajuste): {1}","✓ Profile saved ({0} setting): {1}"],["Perfil guardado: {0} ajuste","Profile saved: {0} setting"],["Perfil cargado desde {0} ({1} ajuste marcado)","Profile loaded from {0} ({1} setting selected)"],["Perfil cargado: {0} ajuste marcado. Revísalo y pulsa Aplicar cambios.{1}","Profile loaded: {0} setting selected. Review it and press Apply changes.{1}"],["Gráfica dedicada: {0}","Dedicated graphics card: {0}"],["Detectado: {0} sin modo MSI","Detected: {0} without MSI mode"],["Detectado en el arranque: {0}","Detected at boot: {0}"],["Modos para tu perfil: {0}","Modes for your profile: {0}"],["{0}  (falló)","{0}  (failed)"],["Instalado: {0}","Installed: {0}"],["Instalado: {0}  ·  del {1}","Installed: {0}  ·  from {1}"],["{0}  ·  {1}","{0}  ·  {1}"],["{0}  ·  {1}  ·  {2}","{0}  ·  {1}  ·  {2}"],["\nInstrucción: {0}","\nStatement: {0}"],["\nLínea {0}, columna {1}","\nLine {0}, column {1}"],["  |  sección abierta: {0}","  |  open section: {0}"],["sección {0}","section {0}"],["Windows no deja cambiar {0} en este PC ({1} / {2})","Windows won\u0027t let {0} be changed on this PC ({1} / {2})"],["{0} del portátil","Laptop {0}"],["Servicios: {0}","Services: {0}"],["Quitar {0}","Remove {0}"],["{0} Si algún día la quieres, se reinstala gratis desde la Microsoft Store.","{0} If you ever want it back, it reinstalls for free from the Microsoft Store."],["Detectado: {0}","Detected: {0}"],["· {0}: se ha abierto la Microsoft Store para reinstalarla","· {0}: the Microsoft Store has been opened to reinstall it"],["esta versión de Windows (build {0}) bloquea la política de Widgets. Puedes ocultarlos a mano en Configuración \u003e Personalización \u003e Barra de tareas \u003e Widgets.","this version of Windows (build {0}) blocks the Widgets policy. You can hide them manually in Settings \u003e Personalization \u003e Taskbar \u003e Widgets."],["Detectadas: {0} tareas","Detected: {0} tasks"],["No abrir {0} al encender","Don\u0027t open {0} at startup"],["{0} a {1} Hz","{0} at {1} Hz"],["Detectado: {0} a {1} Hz (admite hasta {2} Hz)","Detected: {0} at {1} Hz (supports up to {2} Hz)"],["la pantalla no aceptó {0} Hz (código {1})","the display didn\u0027t accept {0} Hz (code {1})"],["Conexión activa: {0}","Active connection: {0}"],[" (libera {0:0.0} GB)"," (frees {0:0.0} GB)"],["Desactivar la hibernación{0}","Turn off hibernation{0}"],["Detectados: {0} dispositivos que Windows puede apagar","Detected: {0} devices Windows can turn off"],["{0} está en solo lectura","{0} is read-only"],["{0} Se cambia en el archivo de configuración del juego; ciérralo antes de aplicar.","{0} It\u0027s changed in the game\u0027s settings file; close the game before applying."],["Detectado en {0}: {1} = {2}","Detected in {0}: {1} = {2}"],["{0} está abierto. Ciérralo del todo y vuelve a aplicar.","{0} is open. Close it completely and apply again."],["{0} está abierto. Ciérralo del todo y vuelve a intentarlo.","{0} is open. Close it completely and try again."],["Juegos detectados: {0}","Games detected: {0}"],["Evita los picos de ping periódicos de la Wi-Fi: la tarjeta {0}. Al aplicarlo, la Wi-Fi se desconecta un par de segundos.","Prevents periodic Wi-Fi ping spikes: the card {0}. When applied, Wi-Fi disconnects for a couple of seconds."],["Conectado por Wi-Fi: {0}","Connected over Wi-Fi: {0}"],["Detectado: Reflex {0}","Detected: Reflex {0}"],["Limitar FPS a {0}","Cap FPS at {0}"],["Detectado: tope en {0} · monitor a {1} Hz","Detected: cap at {0} · monitor at {1} Hz"],["Windows le da prioridad alta a {0} cada vez que se abre, para que Discord, Medal o el navegador no le roben CPU.","Windows gives {0} high priority every time it opens, so Discord, Medal or the browser don\u0027t steal its CPU."],["Detectado: {0} · {1}","Detected: {0} · {1}"],["Siempre en la {0}","Always on the {0}"],["Ajusta el perfil de {0} en el panel de control de NVIDIA: la gráfica no baja de frecuencia en mitad de la partida y el procesador no prepara fotogramas de más. Solo afecta a este juego.","Sets the {0} profile in the NVIDIA Control Panel: the graphics card doesn\u0027t drop its clock mid-match and the processor doesn\u0027t prepare extra frames. It only affects this game."],["Detectado: {0} · driver {1}","Detected: {0} · driver {1}"],["NVIDIA rechazó el ajuste «{0}» (código {1})","NVIDIA rejected the setting «{0}» (code {1})"],["Estás usando la batería ({0} %)","You\u0027re on battery ({0}%)"],["Monitor de {0} Hz conectado a la gráfica dedicada","{0} Hz monitor connected to the dedicated graphics card"],["Funciona a {0} MT/s.","Running at {0} MT/s."],["RAM en doble canal ({0}x{1} GB)","RAM in dual channel ({0}x{1} GB)"],["La RAM va a {0} MT/s (los módulos admiten {1})","RAM runs at {0} MT/s (the modules support {1})"],["La RAM va más lenta de lo que admite ({0} de {1} MT/s)","RAM runs slower than it supports ({0} of {1} MT/s)"],["Disco casi lleno ({0} GB libres)","Disk almost full ({0} GB free)"],["Espacio en disco correcto ({0} GB libres)","Disk space OK ({0} GB free)"],["Tu cable de red va a {0} en vez de 1 Gbps","Your network cable runs at {0} instead of 1 Gbps"],["Conectado por cable ({0})","Connected by cable ({0})"],["Driver NVIDIA {0}","NVIDIA driver {0}"],["Plan de energía: {0}","Power plan: {0}"],["{0} juego{1} competitivo{2} detectado{3}","{0} competitive game{1} detected"],["Abierto ahora: {0}","Open now: {0}"],["Llevas {0} días sin reiniciar","You haven\u0027t restarted in {0} days"],["El driver de la gráfica tiene {0} meses","The graphics driver is {0} months old"],["El disco {0} tiene problemas","Disk {0} has problems"],["El disco {0} está muy desgastado ({1} %)","Disk {0} is very worn ({1}%)"],["La batería está al {0} % de su capacidad original","The battery is at {0}% of its original capacity"],["Windows tarda {0} s en arrancar","Windows takes {0} s to start"],["Tienes la compilación {0}. Actualiza a Windows 10 22H2 desde Windows Update: es la única versión que recibe parches de seguridad (ESU) y la que tiene todos los ajustes de esta app.","You have build {0}. Update to Windows 10 22H2 from Windows Update: it\u0027s the only version that gets security patches (ESU) and has all of this app\u0027s settings."],["El soporte normal terminó el 14 de octubre de 2025. Este PC recibió su última actualización hace {0} días, así que parece inscrito en ESU, que da parches gratis hasta el 12 de octubre de 2027.","Mainstream support ended on October 14, 2025. This PC got its last update {0} days ago, so it seems enrolled in ESU, which gives free patches until October 12, 2027."],["la última actualización instalada es de hace {0} días","the last installed update is from {0} days ago"],["El soporte terminó el 14 de octubre de 2025 y {0}. Inscríbete gratis en ESU desde Windows Update (parches hasta el 12 de octubre de 2027) o pasa a Windows 11: algunos anticheats y juegos nuevos ya lo exigen.","Support ended on October 14, 2025 and {0}. Enroll in ESU for free from Windows Update (patches until October 12, 2027) or move to Windows 11: some anti-cheats and new games already require it."],["TPM detectado{0}. El procesador también tiene que estar en la lista de Microsoft: compruébalo con la app «Comprobación de estado del PC».","TPM detected{0}. The processor also has to be on Microsoft\u0027s list: check it with the «PC Health Check» app."],["el driver de NVIDIA no respondió (código {0})","the NVIDIA driver didn\u0027t respond (code {0})"],["NVIDIA no guardó el perfil (código {0})","NVIDIA didn\u0027t save the profile (code {0})"],["✓ Cerrados para jugar: {0}","✓ Closed for gaming: {0}"],["✓ Descargas en pausa mientras juegas: {0}","✓ Downloads paused while you play: {0}"],["Activando {0}...","Activating {0}..."],["✓ Plan de energía: {0}","✓ Power plan: {0}"],["✓ Perfil de energía: {0}","✓ Power profile: {0}"],["· La pantalla no aceptó {0} Hz (código {1})","· The display didn\u0027t accept {0} Hz (code {1})"],["✓ Pantalla del portátil: {0} Hz → {1} Hz","✓ Laptop screen: {0} Hz → {1} Hz"],["✓ Pantalla del portátil: ya a {0} Hz","✓ Laptop screen: already at {0} Hz"],["✓ {0}: activa","✓ {0}: on"],["✓ {0}: en pausa","✓ {0}: paused"],["· {0}: no se pudo cambiar ({1})","· {0}: couldn\u0027t be changed ({1})"],["✓ Apps en segundo plano: {0}","✓ Background apps: {0}"],["· Descargas: {0}","· Downloads: {0}"],["· No se pudieron cerrar algunos programas: {0}","· Some programs couldn\u0027t be closed: {0}"],["{0} activado","{0} activated"],["el script descargado tiene {0} errores de sintaxis","the downloaded script has {0} syntax errors"],["Driver NVIDIA nuevo: {0} (tienes {1})","New NVIDIA driver: {0} (you have {1})"],["{0} actualizaciones de Windows pendientes","{0} pending Windows updates"],["Miki Tweaks {0} disponible","Miki Tweaks {0} available"],["[{0}] Aviso semanal: {1}","[{0}] Weekly check: {1}"],["Juego detectado ({0}): activando el Modo Juego","Game detected ({0}): activating Game Mode"],["Juego cerrado: volviendo al {0}","Game closed: going back to {0}"],["No se pudo cambiar de modo: {0}","Couldn\u0027t change mode: {0}"],["Solo Windows {0}","Windows {0} only"],["{0} mejora{1} pendiente{2}","{0} pending improvement{1}"],["{0} en la gráfica dedicada","{0} on the dedicated graphics card"],["Batería {0} %","Battery {0}%"],["{0} núcleos · {1} hilos","{0} cores · {1} threads"],["{0} GB libres de {1} GB","{0} GB free of {1} GB"],["  ·  del {0}","  ·  from {0}"],["Abierta la descarga: {0}","Download opened: {0}"],["· Driver: no se pudo comprobar ({0})","· Driver: couldn\u0027t check ({0})"],["Hay un driver nuevo: {0}  ·  publicado el {1}","There\u0027s a new driver: {0}  ·  released on {1}"],["Descargar {0}","Download {0}"],["Driver NVIDIA: hay versión nueva {0} (tienes {1})","NVIDIA driver: new version {0} available (you have {1})"],["✓ Tienes el último driver ({0})","✓ You have the latest driver ({0})"],["Driver NVIDIA: al día ({0})","NVIDIA driver: up to date ({0})"],["No se pudo consultar Windows Update ({0}). Prueba con «Abrir Windows Update».","Couldn\u0027t query Windows Update ({0}). Try «Open Windows Update»."],["{0} necesaria{1}  ·  {2} opcional{3}","{0} required  ·  {2} optional"],["Instalar {0} necesaria{1}","Install {0} required"],["Windows Update: {0} necesarias, {1} opcionales","Windows Update: {0} required, {1} optional"],["La instalación falló: {0}","The installation failed: {0}"],["✓ {0} actualizaciones instaladas. Reinicia el PC para terminar.","✓ {0} updates installed. Restart the PC to finish."],["✓ {0} actualizaciones instaladas.","✓ {0} updates installed."],["Windows Update: instalación terminada (código {0}, reinicio: {1})","Windows Update: installation finished (code {0}, restart: {1})"],["En total hay {0} en cachés y temporales. Marca lo que quieras limpiar.","In total there are {0} in caches and temporary files. Select what you want to clean."],["Liberar {0}","Free up {0}"],["Limpiando: {0}","Cleaning: {0}"],["Limpiando: {0}...","Cleaning: {0}..."],["✓ Liberados {0}. Lo que quede estaba en uso o es reciente.","✓ Freed {0}. Whatever is left was in use or is recent."],["✓ Caché y temporales: liberados {0}","✓ Cache & temp files: freed {0}"],["Muy caliente · {0} W","Very hot · {0} W"],["Caliente · {0} W","Hot · {0} W"],["{0:0.0} de {1:0.0} GB en uso","{0:0.0} of {1:0.0} GB in use"],["✓ Perfil guardado ({0} ajustes): {1}","✓ Profile saved ({0} settings): {1}"],["Perfil guardado: {0} ajustes","Profile saved: {0} settings"],["✗ Perfil no válido: {0}","✗ Invalid profile: {0}"],["Perfil cargado desde {0} ({1} ajustes marcados)","Profile loaded from {0} ({1} settings selected)"],[" En ese PC usabas el {0}: actívalo en Modos si quieres lo mismo."," On that PC you were using {0}: turn it on in Modes if you want the same."],["Perfil cargado: {0} ajustes marcados. Revisa y pulsa Aplicar cambios.{1}","Profile loaded: {0} settings selected. Review them and press Apply changes.{1}"],["✗ Punto de restauración: {0}","✗ Restore point: {0}"],["Devuelve a su valor original los {0} ajustes que esta app ha cambiado en este PC. Las apps quitadas no se reinstalan solas (están en la Microsoft Store).","Restores the original value of the {0} settings this app has changed on this PC. Removed apps don\u0027t reinstall by themselves (they\u0027re in the Microsoft Store)."],["Encontrado: {0}. Marca en este PC los mismos ajustes (los que existan aquí) para que los revises antes de aplicarlos.","Found: {0}. Selects the same settings on this PC (those that exist here) so you can review them before applying."],["Color cambiado a {0}","Color changed to {0}"],["✗ Icono en la bandeja: {0}","✗ Tray icon: {0}"],["✗ Aviso semanal: {0}","✗ Weekly check: {0}"],["Aviso de prueba: {0}","Test notification: {0}"],["✗ Preparar publicación: {0}","✗ Prepare release: {0}"],["✓ Publicación preparada en {0}","✓ Release prepared in {0}"],["Copias de seguridad de tus ajustes, registro y perfiles de este PC: {0}","Backups of your settings, log and profiles on this PC: {0}"],["Gratis para todo el mundo. Si te ha servido, puedes apoyar el proyecto para que siga mejorando. Instalada en {0}; para usarla en otro PC, copia al pen la carpeta que contiene «Abrir Miki Tweaks.cmd».","Free for everyone. If it\u0027s helped you, you can support the project so it keeps improving. Installed in {0}; to use it on another PC, copy the folder that contains «Abrir Miki Tweaks.cmd» to a USB stick."],["No se pudo comprobar: {0}","Couldn\u0027t check: {0}"],["Actualizar a {0}","Update to {0}"],["Hay una versión nueva: {0}{1}","There\u0027s a new version: {0}{1}"],["✓ Tienes la última versión ({0}).","✓ You have the latest version ({0})."],["Miki Tweaks {0} disponible: actualízala desde Ajustes","Miki Tweaks {0} available: update it from Settings"],["Hay una versión nueva de Miki Tweaks: {0}","There\u0027s a new version of Miki Tweaks: {0}"],["· Actualizaciones de la app: {0}","· App updates: {0}"],["Se descargará Miki Tweaks {0}, se comprobará su huella y la app se reiniciará. Tus ajustes y copias de seguridad se mantienen. ¿Seguir?","Miki Tweaks {0} will be downloaded, its fingerprint checked and the app will restart. Your settings and backups are kept. Continue?"],["✗ Actualización: {0}","✗ Update: {0}"],["No se pudo actualizar: {0}","Couldn\u0027t update: {0}"],["✓ Miki Tweaks actualizada a {0}. Reiniciando...","✓ Miki Tweaks updated to {0}. Restarting..."],["✗ Test de polling: {0}","✗ Polling test: {0}"],["✓ Tu ratón funciona a unos {0} Hz (pico medido: {1:0} Hz). Perfecto para jugar.","✓ Your mouse runs at about {0} Hz (measured peak: {1:0} Hz). Perfect for gaming."],["Tu ratón funciona a unos {0} Hz (pico: {1:0} Hz). Súbelo a 1000 Hz o más en el software de la marca: se nota en la puntería.","Your mouse runs at about {0} Hz (peak: {1:0} Hz). Raise it to 1000 Hz or more in the brand\u0027s software: you\u0027ll notice it in your aim."],["Test de polling rate: {0} Hz (pico {1:0} Hz)","Polling rate test: {0} Hz (peak {1:0} Hz)"],["✓ {0} instalado: ábrelo para comprobar si hay firmware nuevo.","✓ {0} installed: open it to check for new firmware."],["Software oficial: {0}. Ahí se configura y se actualiza el firmware.","Official software: {0}. That\u0027s where it\u0027s configured and the firmware is updated."],["De hace {0} meses","{0} months old"],["Versión {0}","Version {0}"],["Fecha: {0}  ·  Placa: {1}","Date: {0}  ·  Board: {1}"],["Encendido: {0} días","Powered on: {0} days"],["Desgaste: {0} %","Wear: {0}%"],["Temperatura: {0} °C","Temperature: {0} °C"],["Salud {0} %: algo gastada","Health {0}%: somewhat worn"],["Salud {0} %","Health {0}%"],["Salud {0} %: muy gastada","Health {0}%: very worn"],["Capacidad actual: {0:N0} mWh de {1:N0} mWh originales","Current capacity: {0:N0} mWh of {1:N0} mWh original"],["Ciclos de carga: {0}","Charge cycles: {0}"],["Arranque de Windows: {0} segundos","Windows startup: {0} seconds"],["Medido por Windows en el último arranque completo ({0}).","Measured by Windows on the last full startup ({0})."],["✗ Reparar Windows: {0}","✗ Repair Windows: {0}"],["Terminó con códigos DISM {0} / SFC {1}. Reinicia y, si sigues con problemas, vuelve a ejecutarlo.","Finished with codes DISM {0} / SFC {1}. Restart and, if you still have problems, run it again."],["no se encuentra {0}. ¿Hay conexión a internet?","{0} can\u0027t be found. Is there an internet connection?"],["Se pierden paquetes ({0} %) en tu propia red","Packets are being lost ({0}%) in your own network"],["Se pierden paquetes ({0} %) en tu operador","Packets are being lost ({0}%) at your ISP"],["Tu red de casa está bien, pero la pérdida empieza en el salto {0} ({1}), que ya es de tu operador. Si se repite en días y horas distintas, llama a tu operador con este resultado.","Your home network is fine, but the loss starts at hop {0} ({1}), which already belongs to your ISP. If it happens on different days and at different times, call your ISP with this result."],["Se pierden paquetes ({0} %) lejos de tu casa","Packets are being lost ({0}%) far from your home"],["Tu red y tu operador están bien: la pérdida empieza en el salto {0} ({1}), ya en internet o cerca del servidor. No depende de ti. Si te pasa a menudo con esta región, aquí es donde una app tipo ExitLag sí puede ayudar, porque usa otra ruta.","Your network and your ISP are fine: the loss starts at hop {0} ({1}), already on the internet or near the server. It doesn\u0027t depend on you. If it happens often with this region, this is where an app like ExitLag can actually help, because it uses another route."],["Ruta sana: llegas a {0} sin perder paquetes ({1} ms)","Healthy route: you reach {0} without losing packets ({1} ms)"],["Tu router tarda {0} ms en contestar. Por cable debería ser 1-2 ms; por Wi-Fi es normal algo más. Si vas por cable, reinicia el router.","Your router takes {0} ms to reply. On cable it should be 1-2 ms; on Wi-Fi a bit more is normal. If you\u0027re on cable, restart the router."],["El mayor aumento (+{0} ms) aparece en el salto {1} ({2}): suele ser el tramo largo hasta otro país o hasta la red del juego. Es normal y no depende de ti.","The biggest increase (+{0} ms) appears at hop {1} ({2}): it\u0027s usually the long stretch to another country or to the game\u0027s network. It\u0027s normal and doesn\u0027t depend on you."],["No se pudo hacer el test: {0}","The test couldn\u0027t run: {0}"],["Velocidad medida (aproximada): {0} Mbps de bajada  {1}  {2} Mbps de subida  {3}  pérdida {4} %  {5}  el test ha usado unos {6} MB de datos.","Measured speed (approximate): {0} Mbps down  {1}  {2} Mbps up  {3}  loss {4}%  {5}  the test used about {6} MB of data."],["Resultado: nota {0}. En reposo {1} ms; con la conexión ocupada sube hasta +{2} ms{3}.","Result: grade {0}. At rest {1} ms; with the connection busy it rises up to +{2} ms{3}."],["Test de bufferbloat: nota {0} (reposo {1} ms, descarga +{2} ms, subida +{3} ms, {4}/{5} Mbps)","Bufferbloat test: grade {0} (rest {1} ms, download +{2} ms, upload +{3} ms, {4}/{5} Mbps)"],["Siguiendo la ruta hasta {0}... tarda unos 15 segundos.","Following the route to {0}... it takes about 15 seconds."],["No se pudo analizar: {0}","Couldn\u0027t analyze: {0}"],["Ruta hasta {0}: {1} saltos. Cada salto es un router por el que pasan tus paquetes; la pérdida solo importa si sigue hasta el destino.","Route to {0}: {1} hops. Each hop is a router your packets go through; loss only matters if it continues to the destination."],["Tu router  {0}  {1}","Your router  {0}  {1}"],["Destino: {0}{1}","Destination: {0}{1}"],["Ruta hasta {0}: {1}","Route to {0}: {1}"],["HERRAMIENTAS DE CONEXI{0}N","CONNECTION TOOLS"],["No se pudo medir: {0}","Couldn\u0027t measure: {0}"],["Test de conexión: {0}","Connection test: {0}"],["INFORME DE MIKI TWEAKS {0}  ·  {1}","MIKI TWEAKS REPORT {0}  ·  {1}"],["Equipo: {0} {1}  ·  {2}","Computer: {0} {1}  ·  {2}"],["Procesador: {0} ({1} núcleos / {2} hilos)","Processor: {0} ({1} cores / {2} threads)"],["Gráfica: {0}  ·  Driver {1}","Graphics: {0}  ·  Driver {1}"],["RAM: {0} GB {1} ({2}x{3} GB a {4} MT/s)","RAM: {0} GB {1} ({2}x{3} GB at {4} MT/s)"],["Pantalla principal: {0} Hz  ·  Plan de energía: {1}","Main display: {0} Hz  ·  Power plan: {1}"],["BIOS: {0} ({1})  ·  Placa: {2}","BIOS: {0} ({1})  ·  Board: {2}"],["Disco: {0} {1} GB · {2} · desgaste {3} % · {4} °C","Disk: {0} {1} GB · {2} · wear {3}% · {4} °C"],["Batería: salud {0} % · {1} ciclos","Battery: health {0}% · {1} cycles"],["Arranque de Windows: {0} s","Windows startup: {0} s"],["PUNTUACIÓN: {0} / 100","SCORE: {0} / 100"],["✓ Informe guardado: {0}","✓ Report saved: {0}"],["No se pudo descargar PresentMon: {0}","Couldn\u0027t download PresentMon: {0}"],["✓ PresentMon {0} descargado y verificado (firma de Intel)","✓ PresentMon {0} downloaded and verified (Intel signature)"],["Benchmark: esperando a {0} ({1} s)","Benchmark: waiting for {0} ({1} s)"],["Esperando a que abras {0}... Puedes minimizar esta ventana: la medición empezará sola.","Waiting for you to open {0}... You can minimize this window: the measurement will start by itself."],["Medición terminada: {0} FPS medios, {1} en el 1 % más bajo","Measurement finished: {0} average FPS, {1} in the 1% lows"],["✓ Benchmark {0}: {1} FPS medios, 1 % bajos {2}, latencia {3} ms","✓ Benchmark {0}: {1} average FPS, 1% lows {2}, latency {3} ms"],["ÚLTIMA MEDICIÓN  ·  {0}  ·  {1}","LAST MEASUREMENT  ·  {0}  ·  {1}"],["{0} fotogramas en {1} s","{0} frames in {1} s"],["La gráfica va al límite ({0} % del tiempo ocupada): para más FPS, baja ajustes gráficos o la resolución 3D.","The graphics card is maxed out (busy {0}% of the time): for more FPS, lower graphics settings or 3D resolution."],["El procesador es el que limita (la gráfica solo va al {0} %): bajar gráficos casi no dará FPS; cierra programas en segundo plano.","The processor is the limit (the graphics card is only at {0}%): lowering graphics will barely give FPS; close background programs."],["Procesador y gráfica están equilibrados (gráfica al {0} %).","Processor and graphics card are balanced (graphics card at {0}%)."],["Presentación directa a la pantalla ({0}): la vía de menor latencia.","Direct presentation to the screen ({0}): the lowest-latency path."],["La imagen pasa por el compositor de Windows ({0}), que añade latencia: usa pantalla completa o activa las optimizaciones para juegos en ventana.","The image goes through the Windows compositor ({0}), which adds latency: use fullscreen or turn on the optimizations for windowed games."],["{0} en los mínimos (1 % más bajo)","{0} in the lows (1% lows)"],["Imagen del resultado guardada: {0}","Result image saved: {0}"],["{0}{1:0.#} % de FPS medios  ·  {2}{3:0.#} % en el 1 % más bajo","{0}{1:0.#}% average FPS  ·  {2}{3:0.#}% in the 1% lows"],["✗ Cambio automático: {0}","✗ Automatic switching: {0}"],["✗ Modo Juego automático: {0}","✗ Automatic Game Mode: {0}"],["Modo Juego cerrará: {0}","Game Mode will close: {0}"],["Abiertos ahora: {0}","Open now: {0}"],["Pausar descargas al jugar: {0}","Pause downloads while gaming: {0}"],["✓ {0} activado","✓ {0} activated"],["Instalado en {0}","Installed in {0}"],["Cach{0} y temporales","Cache and temporary files"],["Sección {0} no disponible","Section {0} not available"],["{0} cambio{1} pendiente{2} de aplicar","{0} pending change{1}"],["{0} mejora{1} recomendada{2} sin aplicar  ·  {3} ajustes ya activos","{0} recommended improvement{1} not applied  ·  {3} settings already active"],["Con los cambios marcados llegarías a {0} / 100","With the selected changes you\u0027d reach {0} / 100"],["Aplicar {0} cambio{1}","Apply {0} change{1}"],["Devuelve a su valor anterior los {0} ajustes de esta tanda que siguen activos","Restores the previous value of the {0} settings from this batch that are still active"],["· No se pudo crear el punto de restauración: {0}","· Couldn\u0027t create the restore point: {0}"],["↺ {0}: restaurado","↺ {0}: restored"],["· {0}: no había copia, se deja igual","· {0}: there was no backup, left as is"],["Aviso del escáner: {0}","Scanner warning: {0}"],["Escaneo completado: {0} ajustes analizados","Scan complete: {0} settings analyzed"],["Partes que fallaron en este PC: {0}","Parts that failed on this PC: {0}"],["{0}  ·  opcional: en tu perfil no juegas","{0}  ·  optional: your profile doesn\u0027t include gaming"],["{0}  ·  tu perfil prioriza {1}","{0}  ·  your profile prioritizes {1}"],["Los modos cambian bastante: un portátil cuida la batería y la temperatura; un sobremesa puede ir siempre a tope o en silencio. Hemos detectado un {0}.","Modes change quite a bit: a laptop looks after battery and temperature; a desktop can always run at full power or quietly. We\u0027ve detected a {0}."],["Activar ahora el {0}","Turn on {0} now"],["Perfil de uso: {0} (prioridad: {1})","Usage profile: {0} (priority: {1})"],["Perfil guardado: {0}","Profile saved: {0}"]],"map":[["Reiniciar ahora","Restart now"],["Buscando...","Searching..."],["Se actualiza sola: al abrir la app busca la versión nueva y la instala en segundo plano.","It updates itself: when you open the app it looks for a new version and installs it in the background."],["Devuelve a su valor original el ajuste que esta app ha cambiado en este PC. Las apps quitadas no se reinstalan solas (están en la Microsoft Store).","Restores the original value of the setting this app has changed on this PC. Removed apps don\u0027t reinstall by themselves (they\u0027re in the Microsoft Store)."],["Devuelve a su valor anterior el ajuste de esta tanda que sigue activo","Restores the previous value of the setting from this batch that is still active"],["Copiar informe","Copy report"],["No hay ningún error registrado en este PC.","No errors have been recorded on this PC."],["Informe copiado. Pégalo al reportar el fallo en GitHub.","Report copied. Paste it when reporting the bug on GitHub."],["Si vas sobrado de FPS, resolución 3D al 100 %; bájala solo si no llegas a los Hz del monitor","If you have FPS to spare, 3D resolution at 100%; only lower it if you can\u0027t reach your monitor\u0027s Hz"],["NVIDIA Reflex: Activado + Aumento","NVIDIA Reflex: On + Boost"],["Modo de renderizado: Rendimiento","Rendering mode: Performance"],["Sincronización vertical desactivada","Vertical sync off"],["Modo de pantalla: Pantalla completa","Window mode: Fullscreen"],["Limitar FPS a un valor fijo alto (por ejemplo 240) para que los frametimes sean estables","Cap FPS at a high fixed value (for example 240) so frametimes stay stable"],["Modo de ventana: Pantalla completa","Window mode: Fullscreen"],["Reducir búfer: Activado","Reduce buffering: On"],["One Frame Thread Lag: activado","One Frame Thread Lag: on"],["Esta sección no se ha podido mostrar en este PC. El resto de la app funciona con normalidad.\r\nPulsa «Copiar informe» y pégalo al reportar el fallo en GitHub para que se pueda arreglar.","This section couldn\u0027t be shown on this PC. The rest of the app works normally.\nPress «Copy report» and paste it when reporting the bug on GitHub so it can be fixed."],["No encuentro la configuración de Fortnite (abre el juego una vez).","Can\u0027t find the Fortnite settings (open the game once)."],["Fortnite está abierto. Ciérralo del todo y vuelve a aplicar.","Fortnite is open. Close it completely and apply again."],["GameUserSettings.ini está en solo lectura.","GameUserSettings.ini is read-only."],["Identificando el equipo","Identifying the computer"],["Analizando el procesador","Analyzing the processor"],["Analizando la memoria RAM","Analyzing RAM"],["Detectando gráficas y pantallas","Detecting graphics cards and displays"],["Comprobando energía y almacenamiento","Checking power and storage"],["Buscando juegos competitivos","Looking for competitive games"],["Revisando seguridad y servicios","Checking security and services"],["Analizando la red","Analyzing the network"],["Revisando apps y funciones de Windows","Checking Windows apps and features"],["Revisando programas de inicio","Checking startup programs"],["Detectando periféricos y salud del hardware","Detecting peripherals and hardware health"],["Ratón","Mouse"],["Micrófono","Microphone"],["Calculando recomendaciones","Calculating recommendations"],["Cliente de Steam. Se abre solo cuando lo necesites.","Steam client. It opens by itself when you need it."],["Vanguard sigue arrancando igual; solo se quita el launcher.","Vanguard still starts as usual; only the launcher is removed."],["Launcher que no hace falta nada más encender.","A launcher you don\u0027t need right at startup."],["App compañera de LoL/Valorant que consume recursos en segundo plano.","LoL/Valorant companion app that uses resources in the background."],["Gestor de mods; no hace falta al encender.","Mod manager; not needed at startup."],["Sincroniza en segundo plano y puede usar disco y red en mitad de una partida.","Syncs in the background and can use disk and network in the middle of a match."],["Navegador abierto en segundo plano.","Browser left open in the background."],["Proceso extra del navegador.","Extra browser process."],["Asistente de Opera GX","Opera GX assistant"],["Solo hace falta con Rocket League abierto.","Only needed while Rocket League is open."],["Lo necesitas para Fortnite, pero puede arrancar cuando lo abras tú.","You need it for Fortnite, but it can start when you open it."],["Déjalo si lo usas siempre al jugar.","Keep it if you always use it while gaming."],["Software del ratón. Quítalo solo si tu configuración está guardada en el ratón.","Mouse software. Remove it only if your settings are saved on the mouse."],["Cambiador de voz. Quítalo si no lo usas a diario.","Voice changer. Remove it if you don\u0027t use it daily."],["Ábrelo antes de jugar a CS2 si lo necesitas.","Open it before playing CS2 if you need it."],["Launcher de EA. Ábrelo cuando vayas a jugar.","EA launcher. Open it when you\u0027re going to play."],["Launcher de Blizzard. Ábrelo cuando vayas a jugar.","Blizzard launcher. Open it when you\u0027re going to play."],["Launcher de Ubisoft. Ábrelo cuando vayas a jugar.","Ubisoft launcher. Open it when you\u0027re going to play."],["Plataforma de overlays que consume recursos en segundo plano.","Overlay platform that uses resources in the background."],["Fondos animados: usan GPU. Se pausa sola en pantalla completa; quítalo si juegas en ventana.","Animated wallpapers: they use the GPU. It pauses itself in fullscreen; remove it if you play windowed."],["Quítalo solo si no lo usas al encender.","Remove it only if you don\u0027t use it at startup."],["Monitor en segundo plano de CCleaner.","CCleaner background monitor."],["Busca actualizaciones de Adobe en cada arranque.","Checks for Adobe updates at every startup."],["actualizador de Adobe","Adobe updater"],["Quítalo si no usas Adobe a diario.","Remove it if you don\u0027t use Adobe daily."],["Déjalo si lo usas para trabajar.","Keep it if you use it for work."],["Microsoft Teams (clásico)","Microsoft Teams (classic)"],["Servicio cerrado por Microsoft.","Service shut down by Microsoft."],["Solo sirve al conectar un iPhone.","Only needed when connecting an iPhone."],["Sincronización de archivos: déjalo si lo usas.","File sync: keep it if you use it."],["Asistente de Opera","Opera assistant"],["Quítalo si no tienes reuniones a diario.","Remove it if you don\u0027t have meetings every day."],["Editor de vídeo preinstalado.","Preinstalled video editor."],["App de noticias de Microsoft Start.","Microsoft Start news app."],["App del tiempo de Microsoft Start.","Microsoft Start weather app."],["El Tiempo","Weather"],["Componente que mete resultados de Bing en Windows.","Component that adds Bing results to Windows."],["Búsqueda de Bing","Bing Search"],["App de consejos y novedades de Windows.","Windows tips and news app."],["Juegos de cartas con anuncios.","Card games with ads."],["App de contactos antigua.","Old contacts app."],["App de mapas de Windows.","Windows maps app."],["Para enviar comentarios a Microsoft.","For sending feedback to Microsoft."],["Centro de opiniones","Feedback Hub"],["App de tareas.","To-do app."],["Reproductor de vídeo antiguo (el nuevo Reproductor multimedia se queda).","Old video player (the new Media Player stays)."],["Películas y TV","Movies \u0026 TV"],["Solo sirve con gafas de realidad mixta de Windows.","Only useful with Windows mixed reality headsets."],["Portal de realidad mixta","Mixed Reality Portal"],["Visor de modelos 3D.","3D model viewer."],["Visor 3D","3D Viewer"],["Asistente retirado por Microsoft.","Assistant retired by Microsoft."],["Panel para desarrolladores que Microsoft ha retirado. No afecta a Visual Studio, VS Code ni a tus herramientas.","Developer dashboard that Microsoft has retired. It doesn\u0027t affect Visual Studio, VS Code or your tools."],["Control parental.","Parental controls."],["Juegos promocionales preinstalados.","Preinstalled promotional games."],["juegos de King (Candy Crush...)","King games (Candy Crush...)"],["App promocional preinstalada.","Preinstalled promotional app."],["Alarmas, temporizador y cronómetro.","Alarms, timer and stopwatch."],["Alarmas y reloj","Alarms \u0026 Clock"],["Conecta el móvil con el PC. Quítalo solo si no lo usas.","Connects your phone to your PC. Remove it only if you don\u0027t use it."],["Enlace Móvil","Phone Link"],["Automatización de tareas. Quítalo solo si no lo usas.","Task automation. Remove it only if you don\u0027t use it."],["Quítalo solo si no lo usas para el trabajo o las clases.","Remove it only if you don\u0027t use it for work or school."],["Lanzador de Office. Word, Excel y compañía no se tocan.","Office launcher. Word, Excel and the rest aren\u0027t touched."],["Cliente de correo nuevo de Windows.","Windows\u0027 new mail client."],["Outlook (nuevo)","Outlook (new)"],["Asistente de IA de Microsoft.","Microsoft\u0027s AI assistant."],["Quítalo solo si no lo usas.","Remove it only if you don\u0027t use it."],["Editor 3D retirado por Microsoft (el Paint normal se queda).","3D editor retired by Microsoft (regular Paint stays)."],["App para impresoras 3D.","App for 3D printers."],["Editor de modelos 3D antiguo.","Old 3D model editor."],["Para comprar datos móviles en PC con SIM.","For buying mobile data on PCs with a SIM."],["Planes móviles","Mobile Plans"],["Cartera de pagos retirada.","Retired payment wallet."],["App de mensajes antigua.","Old messaging app."],["Versión antigua de OneNote. Quítala solo si no la usas.","Old version of OneNote. Remove it only if you don\u0027t use it."],["OneNote para Windows 10","OneNote for Windows 10"],["Apps antiguas de correo que Microsoft ha retirado. Quítalas solo si no las usas.","Old mail apps that Microsoft has retired. Remove them only if you don\u0027t use them."],["Correo y Calendario","Mail and Calendar"],["SERVICIOS Y SEGUNDO PLANO","SERVICES AND BACKGROUND"],["APPS PREINSTALADAS","PREINSTALLED APPS"],["Sin anuncios ni sugerencias de Windows","No Windows ads or suggestions"],["PRIVACIDAD Y ANUNCIOS","PRIVACY AND ADS"],["Quita las apps que Windows instala por su cuenta, los consejos, las recomendaciones del menú Inicio y el ID de publicidad.","Removes the apps Windows installs on its own, tips, Start menu recommendations and the advertising ID."],["Windows muestra contenido promocional por defecto","Windows shows promotional content by default"],["Telemetría y seguimiento al mínimo","Telemetry and tracking at minimum"],["Reduce los datos de diagnóstico que envía Windows y desactiva el historial de actividad y las experiencias personalizadas con esos datos.","Reduces the diagnostic data Windows sends and turns off activity history and experiences personalized with that data."],["Configuración de fábrica de Windows","Windows factory settings"],["Sin Bing en la búsqueda de Windows","No Bing in Windows search"],["La búsqueda del menú Inicio solo busca en tu PC: más rápida y sin resultados web.","Start menu search only searches your PC: faster and without web results."],["Windows mezcla resultados web en la búsqueda","Windows mixes web results into search"],["Sin Widgets","No Widgets"],["Quita el panel de Widgets (noticias, tiempo...) y el proceso que lo mantiene cargado en segundo plano.","Removes the Widgets panel (news, weather...) and the process that keeps it loaded in the background."],["Detectado: Windows 11","Detected: Windows 11"],["Detiene \"Experiencias del usuario y telemetría asociadas\" y el servicio de mensajes push WAP, que envían datos de uso en segundo plano.","Stops \"Connected User Experiences and Telemetry\" and the WAP push message service, which send usage data in the background."],["Servicios de telemetría desactivados","Telemetry services disabled"],["Administrador de mapas descargados, modo demo de tienda y fax. Si algún día los necesitas, los vuelves a activar aquí.","Downloaded maps manager, store demo mode and fax. If you ever need them, turn them back on here."],["Servicios que casi nadie usa","Services almost nobody uses"],["Solo si nunca imprimes desde este PC: sin ella no funcionan las impresoras ni \"Imprimir en PDF\".","Only if you never print from this PC: without it, printers and \"Print to PDF\" don\u0027t work."],["Sin cola de impresión","No print spooler"],["Limpiar temporales automáticamente cada semana","Clean temporary files automatically every week"],["MANTENIMIENTO AUTOMÁTICO","AUTOMATIC MAINTENANCE"],["Activa el Sensor de almacenamiento de Windows para que borre solo los archivos temporales que ya no usa ninguna app. No toca la papelera ni tus descargas.","Turns on Windows Storage Sense so it deletes only temporary files no app uses anymore. It doesn\u0027t touch the Recycle Bin or your downloads."],["Así la caché no vuelve a crecer sin que te des cuenta","So the cache doesn\u0027t grow again without you noticing"],["Tareas programadas de telemetría desactivadas","Telemetry scheduled tasks disabled"],["Tareas que recopilan datos de compatibilidad y de uso en segundo plano (pueden arrancar a mitad de partida).","Tasks that collect compatibility and usage data in the background (they can start in the middle of a match)."],["Edge sin precarga ni segundo plano","Edge without preloading or background"],["Edge deja de precargarse al encender el PC y de seguir abierto al cerrarlo. En su configuración verás \"administrado por tu organización\": es normal.","Edge stops preloading when the PC starts and stops staying open after you close it. In its settings you\u0027ll see \"managed by your organization\": that\u0027s normal."],["Detectado: Microsoft Edge","Detected: Microsoft Edge"],["Chrome se precarga al encender aunque no lo uses.","Chrome preloads at startup even if you don\u0027t use it."],["Google Chrome (precarga)","Google Chrome (preload)"],["Programa que arranca con Windows para todos los usuarios.","Program that starts with Windows for all users."],["Detectado en el inicio de Windows (todos los usuarios)","Detected at Windows startup (all users)"],["Monitor secundario","Secondary monitor"],["Monitor principal","Main monitor"],["Pone la pantalla a la frecuencia más alta que admite. Es de los cambios que más se notan: más imágenes por segundo y la imagen llega antes.","Sets the display to the highest refresh rate it supports. It\u0027s one of the most noticeable changes: more frames per second and the image arrives sooner."],["Sin avisos de Teclas especiales","No Sticky Keys prompts"],["Evita que pulsar Mayús cinco veces o mantenerla pulsada te saque del juego con el aviso de Teclas especiales, Teclas filtro o Teclas de alternancia.","Stops pressing Shift five times or holding it from kicking you out of the game with the Sticky Keys, Filter Keys or Toggle Keys prompt."],["Pasa mucho al correr o agacharse con Mayús","Happens a lot when running or crouching with Shift"],["Optimizaciones para juegos en ventana","Optimizations for windowed games"],["Los juegos DirectX 10/11 en ventana o ventana sin bordes usan el modo de presentación moderno de Windows 11: menos latencia, casi como en pantalla completa.","DirectX 10/11 games in windowed or borderless mode use Windows 11\u0027s modern presentation mode: less latency, almost like fullscreen."],["Detectado: Windows 11 22H2 o posterior","Detected: Windows 11 22H2 or later"],["Windows Update no reinicia mientras juegas","Windows Update doesn\u0027t restart while you play"],["Fija las horas activas de 10:00 a 4:00: Windows Update no reiniciará el PC por su cuenta en ese tramo. Las actualizaciones se siguen instalando.","Sets active hours from 10:00 to 4:00: Windows Update won\u0027t restart the PC on its own during that time. Updates still install."],["Evita reinicios automáticos en mitad de una partida","Prevents automatic restarts in the middle of a match"],["El botón Xbox del mando no abre la Game Bar","The controller\u0027s Xbox button doesn\u0027t open the Game Bar"],["Si juegas con mando, evita que la Game Bar se abra en mitad de la partida al tocar el botón Xbox.","If you play with a controller, stops the Game Bar from opening mid-match when you touch the Xbox button."],["Útil si juegas con mando","Useful if you play with a controller"],["Sin limitación de energía en segundo plano","No background power throttling"],["Windows deja de frenar los programas en segundo plano (Discord, Medal...) para ahorrar energía. Rendimiento más constante a cambio de algo más de consumo con batería.","Windows stops slowing down background programs (Discord, Medal...) to save power. More consistent performance in exchange for slightly higher battery use."],["Detectado: PC de sobremesa","Detected: desktop PC"],["Detectado: portátil (con batería durará algo menos)","Detected: laptop (battery will last a bit less)"],["Sin animaciones de ventanas","No window animations"],["Abrir, minimizar y maximizar ventanas sin animación: Windows se siente más rápido. Es solo estético.","Open, minimize and maximize windows without animation: Windows feels faster. It\u0027s purely cosmetic."],["Preferencia personal","Personal preference"],["Repetición de teclado más rápida","Faster keyboard repeat"],["Una tecla mantenida empieza a repetirse antes y más deprisa. Cómodo para chatear y editar; no cambia la latencia de cada pulsación.","A held key starts repeating sooner and faster. Handy for chatting and editing; it doesn\u0027t change the latency of each press."],["Sin retraso al arrancar programas de inicio","No delay for startup programs"],["Los programas que arrancan con Windows (como Medal o Discord) se abren sin la espera que Windows añade al encender.","Programs that start with Windows (like Medal or Discord) open without the wait Windows adds at startup."],["Windows retrasa los programas de inicio unos segundos","Windows delays startup programs by a few seconds"],["Desactivar MPO (solo si tienes parpadeos)","Disable MPO (only if you get flickering)"],["Arregla parpadeos, pantallazos negros o tirones raros que algunas gráficas tienen con juegos en ventana o con Discord y el navegador encima. Si no te pasa, déjalo como está.","Fixes flickering, black screens or odd stutters some graphics cards have with windowed games or with Discord and the browser on top. If it doesn\u0027t happen to you, leave it as is."],["Solución conocida para un fallo de algunos drivers","Known fix for a bug in some drivers"],["Windows no sube actualizaciones a otros PC","Windows doesn\u0027t upload updates to other PCs"],["Por defecto Windows puede usar tu conexión para enviar trozos de actualizaciones a otros equipos. Así tu subida queda libre para jugar.","By default Windows can use your connection to send pieces of updates to other computers. This keeps your upload free for gaming."],["Optimización de distribución activada por defecto","Delivery Optimization on by default"],["DNS rápido (Cloudflare 1.1.1.1)","Fast DNS (Cloudflare 1.1.1.1)"],["Usa el DNS de Cloudflare en vez del de tu operador. Puede acelerar la carga de webs y launchers; no cambia el ping dentro de las partidas.","Uses Cloudflare\u0027s DNS instead of your ISP\u0027s. It can speed up loading websites and launchers; it doesn\u0027t change in-game ping."],["Sin Recall (capturas de pantalla de la IA)","No Recall (AI screenshots)"],["Impide que Windows haga capturas periódicas de tu pantalla para la función Recall en los PC que la tienen. En los demás no cambia nada.","Stops Windows from taking periodic screenshots of your screen for the Recall feature on PCs that have it. On others nothing changes."],["Detectado: Windows 11 24H2 o posterior","Detected: Windows 11 24H2 or later"],["Borra el archivo hiberfil.sys. El PC se sigue pudiendo suspender igual; solo dejas de poder hibernar y se desactiva el inicio rápido (que a veces da problemas con drivers).","Deletes the hiberfil.sys file. The PC can still sleep as usual; you just can\u0027t hibernate anymore and Fast Startup is turned off (it sometimes causes driver problems)."],["Hibernación desactivada por esta app","Hibernation turned off by this app"],["Detectado: hiberfil.sys en el disco","Detected: hiberfil.sys on the disk"],["Actualizador de firmware de DualSense","DualSense firmware updater"],["Accesorios de Xbox","Xbox Accessories"],["Sin ahorro de energía en USB y Bluetooth","No power saving on USB and Bluetooth"],["Windows deja de poder «dormir» el ratón, el teclado, los concentradores USB y el adaptador Bluetooth para ahorrar energía. Evita microcortes, desconexiones y picos de retardo, también en los cascos Bluetooth.","Windows can no longer put the mouse, keyboard, USB hubs and Bluetooth adapter to sleep to save power. Prevents micro-cuts, disconnections and lag spikes, Bluetooth headsets included."],["La búsqueda del menú Inicio y de la barra de tareas solo busca en tu PC: más rápida y sin resultados web de Bing.","Start menu and taskbar search only searches your PC: faster and without Bing web results."],["Sin «Noticias e intereses» en la barra de tareas","No «News and interests» on the taskbar"],["Quita el widget del tiempo y las noticias de la barra de tareas de Windows 10 y el proceso de Edge que lo mantiene cargado en segundo plano.","Removes the weather and news widget from the Windows 10 taskbar and the Edge process that keeps it loaded in the background."],["Detectado: Windows 10","Detected: Windows 10"],["Cortana desactivada","Cortana disabled"],["Desactiva Cortana (Microsoft ya la ha retirado) y su botón en la barra de tareas. La búsqueda de Windows sigue funcionando igual.","Turns off Cortana (Microsoft has already retired it) and its taskbar button. Windows search keeps working the same."],["Sin el botón «Reunirse ahora»","No «Meet Now» button"],["Quita de la barra de tareas el acceso directo a las reuniones de Skype, que Microsoft ya no usa.","Removes the shortcut to Skype meetings from the taskbar, which Microsoft no longer uses."],["Pantalla completa exclusiva clásica en todos los juegos","Classic exclusive fullscreen in all games"],["En Windows 10 las «optimizaciones de pantalla completa» convierten muchos juegos en una ventana sin bordes, lo que puede añadir algo de latencia. Esto fuerza la pantalla completa exclusiva de verdad en todos. Si algún juego da problemas al cambiar de ventana, desactívalo.","On Windows 10, \"fullscreen optimizations\" turn many games into a borderless window, which can add some latency. This forces true exclusive fullscreen in all of them. If a game has trouble when switching windows, turn it off."],["Ajuste habitual en Windows 10 para juegos competitivos","Common Windows 10 setting for competitive games"],["Sincroniza procesador y gráfica para que cada fotograma llegue antes a la pantalla. Es lo que más baja la latencia en CS2 con una NVIDIA.","Syncs CPU and GPU so each frame reaches the screen sooner. It\u0027s what lowers latency the most in CS2 with an NVIDIA card."],["Con la sincronización vertical activa, cada fotograma espera al monitor y se nota el retraso al apuntar.","With vertical sync on, each frame waits for the monitor and you feel the delay when aiming."],["Quita la espera al monitor en cada fotograma: menos retraso al apuntar.","Removes the wait for the monitor on each frame: less delay when aiming."],["El motor no prepara fotogramas de más: el coche responde antes al mando o al teclado. Es el ajuste de latencia más importante de Rocket League.","The engine doesn\u0027t prepare extra frames: the car responds to the controller or keyboard sooner. It\u0027s the most important latency setting in Rocket League."],["One Frame Thread Lag activado","One Frame Thread Lag on"],["Quita la espera al monitor en cada fotograma: menos retraso al controlar el coche.","Removes the wait for the monitor on each frame: less delay when controlling the car."],["Imagen más nítida en los giros rápidos y algún FPS más.","Sharper image in fast turns and a few more FPS."],["Sin desenfoque de movimiento","No motion blur"],["Prioridad de red para tus juegos (QoS)","Network priority for your games (QoS)"],["Marca el tráfico de tus juegos como urgente (DSCP 46, como las videollamadas) para que el router lo deje pasar primero cuando la red está ocupada. Solo tiene efecto si tu router respeta estas marcas (QoS o WMM, habitual en routers Wi-Fi); si no, no cambia nada.","Marks your games\u0027 traffic as urgent (DSCP 46, like video calls) so the router lets it through first when the network is busy. It only works if your router honors these marks (QoS or WMM, common on Wi-Fi routers); otherwise nothing changes."],["busca otras redes lo mínimo","scans for other networks as little as possible"],["prefiere la banda de 5 GHz","prefers the 5 GHz band"],["Wi-Fi estable para jugar","Stable Wi-Fi for gaming"],["Modo de renderizado Rendimiento","Performance rendering mode"],["DirectX 12 con el nivel gráfico ligero (ES3.1), lo que Fortnite llama \"Rendimiento\". Es el modo que más FPS da y el que menos carga la CPU en portátiles, a cambio de gráficos más simples.","DirectX 12 with the light graphics level (ES3.1), what Fortnite calls \"Performance\". It\u0027s the mode that gives the most FPS and puts the least load on the CPU in laptops, in exchange for simpler graphics."],["Detectado: DirectX 12 con gráficos completos","Detected: DirectX 12 with full graphics"],["Detectado: ya usas el modo Rendimiento","Detected: you already use Performance mode"],["activado + aumento","on + boost"],["Sincroniza CPU y GPU para que cada fotograma llegue a la pantalla lo antes posible. Es lo que más baja la latencia en una tarjeta NVIDIA.","Syncs CPU and GPU so each frame reaches the screen as soon as possible. It\u0027s what lowers latency the most on an NVIDIA card."],["Pantalla completa exclusiva","Exclusive fullscreen"],["La pantalla completa real tiene menos latencia que ventana o ventana sin bordes.","True fullscreen has less latency than windowed or borderless."],["Detectado: modo ventana","Detected: windowed mode"],["Detectado: ya en pantalla completa","Detected: already fullscreen"],["Ajusta el tope de FPS a la frecuencia de tu monitor. Con Reflex no hace falta, pero da frametimes más estables y el portátil se calienta menos.","Sets the FPS cap to your monitor\u0027s refresh rate. With Reflex it isn\u0027t necessary, but it gives more stable frametimes and the laptop runs cooler."],["Prioridad de CPU alta","High CPU priority"],["Obliga a Windows a usar la gráfica dedicada y nunca la integrada.","Forces Windows to use the dedicated graphics card and never the integrated one."],["Detectado: portátil con gráfica integrada + dedicada","Detected: laptop with integrated + dedicated graphics"],["Panel de NVIDIA: máximo rendimiento y baja latencia","NVIDIA panel: maximum performance and low latency"],["Sin optimizaciones de pantalla completa","No fullscreen optimizations"],["Fuerza la pantalla completa exclusiva clásica en este juego DirectX 11. En algunos equipos baja un poco la latencia y en otros no cambia nada: pruébalo y quédate con lo que mejor te vaya.","Forces classic exclusive fullscreen in this DirectX 11 game. On some PCs it lowers latency a little and on others nothing changes: try it and keep whatever works best for you."],["Detectado: juego DirectX 11","Detected: DirectX 11 game"],["Modo Juego siempre activo","Game Mode always on"],["Activa el Modo Juego y añade una tarea que lo reactiva en cada inicio de sesión, para que no se apague solo tras reiniciar.","Turns on Game Mode and adds a task that turns it back on at every sign-in, so it doesn\u0027t switch off by itself after restarting."],["Windows a veces lo desactiva solo tras reiniciar","Windows sometimes turns it off by itself after restarting"],["Resolución de temporizador global","Global timer resolution"],["En Windows 11 la herramienta de resolución de temporizador no tiene efecto sin esta opción. Con ella, los frametimes son más estables.","On Windows 11 the timer resolution tool has no effect without this option. With it, frametimes are more stable."],["Detectado: SetTimerResolution arranca con Windows","Detected: SetTimerResolution starts with Windows"],["Prioridad multimedia para juegos","Multimedia priority for games"],["Sube la prioridad de programación de los juegos y quita el límite de red del planificador multimedia de Windows.","Raises the scheduling priority of games and removes the network limit of the Windows multimedia scheduler."],["Valores por defecto de Windows pensados para ofimática","Windows defaults designed for office work"],["Desactivar Integridad de memoria","Turn off Memory integrity"],["Suele dar algunos FPS más y algo menos de latencia, a cambio de menos protección frente a drivers maliciosos. Si un anticheat te la pide, vuelve a activarla aquí.","It usually gives a few more FPS and slightly less latency, in exchange for less protection against malicious drivers. If an anti-cheat asks for it, turn it back on here."],["Detectado: VBS apagado","Detected: VBS off"],["Detectado: virtualización de seguridad (VBS) en marcha","Detected: virtualization-based security (VBS) running"],["Sin grabación en segundo plano de Xbox","No Xbox background recording"],["Evita que Game DVR grabe en segundo plano. Tu programa de clips (Medal, Outplayed, NVIDIA...) sigue grabando igual.","Stops Game DVR from recording in the background. Your clip program (Medal, Outplayed, NVIDIA...) keeps recording as usual."],["Game DVR consume GPU mientras juegas","Game DVR uses the GPU while you play"],["Programación de GPU acelerada por hardware","Hardware-accelerated GPU scheduling"],["La GPU gestiona su propia memoria de vídeo. Necesaria para que Reflex rinda al máximo.","The GPU manages its own video memory. Needed for Reflex to perform at its best."],["Sin \"Mejorar precisión del puntero\"","No \"Enhance pointer precision\""],["Quita la aceleración de ratón de Windows para que el movimiento sea siempre 1:1.","Removes Windows mouse acceleration so movement is always 1:1."],["Afecta a todo el sistema, no solo a un juego","Affects the whole system, not just one game"],["Desactivar Nahimic (audio MSI)","Turn off Nahimic (MSI audio)"],["Se asocia a menudo con tirones y picos de DPC latency. Pierdes sus efectos de sonido; tus cascos funcionan igual.","It\u0027s often linked to stutters and DPC latency spikes. You lose its sound effects; your headset works the same."],["Detectado: servicio NahimicService instalado","Detected: NahimicService installed"],["Sin ahorro de energía en el Ethernet","No Ethernet power saving"],["Desactiva Ethernet de consumo eficiente, Ethernet ecológico, Power Saving y Gigabit Lite, que pueden provocar microcortes y picos de ping. La conexión se corta 2-3 s al aplicar.","Turns off Energy-Efficient Ethernet, Green Ethernet, Power Saving and Gigabit Lite, which can cause micro-cuts and ping spikes. The connection drops for 2-3 s when applied."],["Sin moderación de interrupciones","No interrupt moderation"],["Los paquetes se procesan al instante en vez de agruparse: algo menos de latencia de red a cambio de un poco más de CPU. La conexión se corta 2-3 s al aplicar.","Packets are processed instantly instead of being grouped: slightly lower network latency in exchange for a bit more CPU. The connection drops for 2-3 s when applied."],["Edge se precarga al encender aunque no lo uses.","Edge preloads at startup even if you don\u0027t use it."],["Microsoft Edge (precarga)","Microsoft Edge (preload)"],["Programa que arranca con Windows.","Program that starts with Windows."],["Detectado en el inicio de Windows","Detected at Windows startup"],["ajustes de los juegos","game settings"],["ajustes de red","network settings"],["Así la CPU y la GPU rinden al 100 %. Juega siempre enchufado.","This way the CPU and GPU run at 100%. Always play plugged in."],["Conectado al cargador","Connected to the charger"],["Con batería el portátil limita mucho la potencia. Enchúfalo antes de jugar.","On battery the laptop limits power a lot. Plug it in before playing."],["Es la pantalla con menos latencia: juega en ella. La pantalla del portátil pasa por la gráfica integrada y añade retardo.","It\u0027s the screen with the least latency: play on it. The laptop screen goes through the integrated graphics and adds delay."],["La imagen pasa por la gráfica integrada (Optimus) y añade latencia. Si el programa del fabricante (MSI Center, Armoury Crate...) tiene \"GPU Switch\" / modo solo dedicada, actívalo.","The image goes through the integrated graphics (Optimus) and adds latency. If the manufacturer\u0027s software (MSI Center, Armoury Crate...) has \"GPU Switch\" / dedicated-only mode, turn it on."],["Juegas en la pantalla del portátil","You\u0027re playing on the laptop screen"],["Con un solo módulo pierdes bastantes FPS en casi todos los juegos. Añadir un segundo módulo igual es la mejora de hardware más rentable.","With a single module you lose quite a few FPS in almost every game. Adding a second identical module is the most cost-effective hardware upgrade."],["RAM en un solo canal","RAM in single channel"],["En los portátiles es normal: el procesador o la BIOS fijan la velocidad máxima y no se puede cambiar.","On laptops this is normal: the processor or BIOS sets the maximum speed and it can\u0027t be changed."],["Activa el perfil XMP (Intel) o EXPO (AMD) en la BIOS. Es gratis y da FPS, sobre todo en el 1 % más bajo. Si el PC se vuelve inestable, desactívalo otra vez.","Turn on the XMP (Intel) or EXPO (AMD) profile in the BIOS. It\u0027s free and gives FPS, especially in the 1% lows. If the PC becomes unstable, turn it off again."],["Con menos de un 10-15 % libre Windows y las cachés de sombreado van peor. Libera espacio.","With less than 10-15% free, Windows and shader caches work worse. Free up space."],["Suficiente para cachés de sombreado y actualizaciones.","Enough for shader caches and updates."],["El cable de red da un ping mucho más estable.","A network cable gives a much more stable ping."],["Estás jugando por Wi-Fi","You\u0027re playing over Wi-Fi"],["Tu tarjeta es Gigabit, pero el enlace con el router se ha negociado a menos velocidad. Casi siempre es el cable (un hilo dañado o un cable antiguo) o el puerto del router: prueba otro cable Cat 5e o Cat 6 y otro puerto. A veces basta con desenchufarlo y volver a enchufarlo. Así tu conexión no pasa de 100 Mbps y el ping sube más cuando la red está ocupada.","Your card is Gigabit, but the link with the router negotiated a lower speed. It\u0027s almost always the cable (a damaged wire or an old cable) or the router port: try another Cat 5e or Cat 6 cable and another port. Sometimes unplugging it and plugging it back in is enough. This way your connection can\u0027t go above 100 Mbps and ping rises more when the network is busy."],["La mejor opción para un ping estable.","The best option for a stable ping."],["Busca actualizaciones de vez en cuando en la NVIDIA App (instalación limpia).","Check for updates now and then in the NVIDIA App (clean install)."],["La app no modifica tus planes: los Modos solo eligen cuál está activo.","The app doesn\u0027t modify your plans: Modes only choose which one is active."],["Si tienes alguno en una carpeta poco habitual, ábrelo y vuelve a escanear: la app también detecta los juegos que están en marcha.","If you have one in an unusual folder, open it and scan again: the app also detects games that are running."],["No se ha encontrado ningún juego competitivo","No competitive games found"],["La prioridad y la gráfica se aplican la próxima vez que lo abras. Los ajustes del archivo de Fortnite necesitan que el juego esté cerrado.","Priority and graphics card apply the next time you open it. Fortnite file settings need the game to be closed."],["Abre Fortnite una vez y vuelve a escanear para ver sus ajustes del juego.","Open Fortnite once and scan again to see its in-game settings."],["No se encontró la configuración de Fortnite","Fortnite settings not found"],["Lo exigen VALORANT (Vanguard), FACEIT y otros anticheats en Windows 11.","Required by VALORANT (Vanguard), FACEIT and other anti-cheats on Windows 11."],["Arranque seguro (Secure Boot) activado","Secure Boot enabled"],["VALORANT y otros anticheats lo exigen en Windows 11. Se activa desde la BIOS/UEFI del PC.","VALORANT and other anti-cheats require it on Windows 11. It\u0027s turned on from the PC\u0027s BIOS/UEFI."],["Arranque seguro (Secure Boot) desactivado","Secure Boot disabled"],["Windows tiene actualizaciones a medio instalar. Reinicia antes de jugar para que no te pille en mitad de una partida.","Windows has half-installed updates. Restart before playing so it doesn\u0027t catch you mid-match."],["Tienes un reinicio pendiente","You have a pending restart"],["Reiniciar de vez en cuando libera memoria y termina las actualizaciones. Ojo: con el inicio rápido de Windows, apagar no cuenta como reiniciar.","Restarting now and then frees memory and finishes updates. Note: with Windows Fast Startup, shutting down doesn\u0027t count as restarting."],["Los drivers nuevos suelen traer mejoras para juegos recientes. Mira la página Actualizaciones.","New drivers usually bring improvements for recent games. Check the Updates page."],["Windows lo marca como no saludable. Haz copia de seguridad de lo importante y mira la página Salud del PC.","Windows marks it as unhealthy. Back up anything important and check the PC Health page."],["Le queda poca vida útil. Plantéate cambiarlo y guarda copia de lo importante.","It has little lifespan left. Consider replacing it and back up anything important."],["Dura bastante menos que nueva. Si juegas siempre enchufado, limita la carga al 80 % en el software del portátil.","It lasts much less than when new. If you always play plugged in, limit charging to 80% in the laptop\u0027s software."],["Quitar programas de «Inicio de Windows» es lo que más lo acelera.","Removing programs from «Windows startup» is what speeds it up the most."],["Tu Windows 10 no es la última versión (22H2)","Your Windows 10 isn\u0027t the latest version (22H2)"],["Windows 10 con actualizaciones de seguridad extendidas","Windows 10 with extended security updates"],["no se ve ninguna actualización reciente","no recent update can be seen"],["Windows 10 sin actualizaciones de seguridad","Windows 10 without security updates"],[" y arranque seguro activo"," and Secure Boot enabled"],["; el arranque seguro se activa en la BIOS","; Secure Boot is turned on in the BIOS"],["Tu PC tiene lo básico para Windows 11","Your PC has the basics for Windows 11"],["Windows 11 lo necesita. En muchos PC viene desactivado en la BIOS (Intel PTT o AMD fTPM): actívalo ahí antes de dar por hecho que no es compatible.","Windows 11 needs it. On many PCs it comes disabled in the BIOS (Intel PTT or AMD fTPM): turn it on there before assuming it isn\u0027t compatible."],["No se detecta chip TPM","No TPM chip detected"],["gestión de energía al máximo rendimiento","power management at maximum performance"],["modo de baja latencia activado","low latency mode on"],["Modo Juego","Game Mode"],["Máximo rendimiento y mínima latencia para tus partidas.","Maximum performance and minimum latency for your matches."],["Apps en segundo plano bloqueadas","Background apps blocked"],["Descargas de Windows Update y OneDrive en pausa","Windows Update and OneDrive downloads paused"],["Indexación de búsqueda y SysMain en pausa","Search indexing and SysMain paused"],["Plan de energía: Alto rendimiento","Power plan: High performance"],["Pantalla del portátil a su frecuencia máxima","Laptop screen at its maximum refresh rate"],["Modo Trabajo","Work Mode"],["Windows ágil y completo: todo lo útil del día a día funcionando.","Snappy, complete Windows: everything useful for everyday work running."],["Apps en segundo plano permitidas (notificaciones y sincronización)","Background apps allowed (notifications and sync)"],["Búsqueda de Windows y SysMain activos","Windows Search and SysMain on"],["Plan de energía: Equilibrado","Power plan: Balanced"],["Batería","Battery"],["Ahorro de batería","Battery Saver"],["Más horas lejos del enchufe, con menos consumo y menos calor.","More hours away from the outlet, with lower power use and less heat."],["Pantalla del portátil a 60 Hz","Laptop screen at 60 Hz"],["Plan de energía: Equilibrado con máxima eficiencia","Power plan: Balanced with maximum efficiency"],["Creación","Creation"],["Modo Creación","Creation Mode"],["Toda la potencia para editar, renderizar o hacer streaming, sin cerrar ninguno de tus programas.","All the power for editing, rendering or streaming, without closing any of your programs."],["Modo Silencio","Quiet Mode"],["Menos ruido y temperatura: el procesador no apura al máximo. Ideal para trabajar, ver series o dejar el PC descargando.","Less noise and heat: the processor doesn\u0027t push to the max. Ideal for working, watching shows or leaving the PC downloading."],["Apps en segundo plano permitidas","Background apps allowed"],["crear contenido","creating content"],["navegar y ver series","browsing and watching shows"],["trabajar o estudiar","working or studying"],["jugar en competitivo","competitive gaming"],["jugar por diversión","casual gaming"],["Sin perfil","No profile"],["uso general","general use"],["Portátil","Laptop"],["Para navegar, ver series y el día a día: todo funcionando, sin gastar de más.","For browsing, watching shows and everyday use: everything running, without wasting power."],["Modo Diario","Everyday Mode"],["Cierra los programas que elijas","Closes the programs you choose"],["No se cierra ningún programa: OBS, editores y grabación siguen igual","No program is closed: OBS, editors and recording keep running"],["Búsqueda de Windows y SysMain activos (para tus archivos y proyectos)","Windows Search and SysMain on (for your files and projects)"],["Teams (clásico)","Teams (classic)"],["· Windows está instalando una actualización: no se pausan las descargas para no interrumpirla","· Windows is installing an update: downloads aren\u0027t paused so it isn\u0027t interrupted"],["✓ Descargas: no había ninguna en marcha","✓ Downloads: none were running"],["✓ Descargas reanudadas","✓ Downloads resumed"],["· No encontré tu plan de alto rendimiento; el plan se deja como está","· Couldn\u0027t find your high performance plan; the plan is left as is"],["máxima eficiencia","maximum efficiency"],["· El perfil de energía no se pudo cambiar en este equipo","· The power profile couldn\u0027t be changed on this computer"],["Indexación de búsqueda","Search indexing"],["la dirección del canal tiene que empezar por https://","the channel address has to start with https://"],["el version.json no tiene version, url y sha256","the version.json doesn\u0027t have version, url and sha256"],["la descarga tiene que ser https","the download has to be https"],["la huella del archivo no coincide con la del version.json (descarga dañada o manipulada)","the file\u0027s fingerprint doesn\u0027t match the version.json (damaged or tampered download)"],["la versión del script no coincide con la anunciada","the script version doesn\u0027t match the announced one"],["Miki Tweaks - publicar","Miki Tweaks - publish"],[". Ábrela y mira la página Actualizaciones.",". Open it and check the Updates page."],["todo al día","all up to date"],["Abrir Miki Tweaks","Open Miki Tweaks"],["Quitar el icono hasta el próximo inicio","Remove the icon until next startup"],["sin modo","no mode"],["Escanea y optimiza el PC para juegos competitivos","Scans and optimizes the PC for competitive games"],["Optimiza tu PC para jugar en competitivo.","Optimize your PC for competitive gaming."],["Analiza tu hardware, tu configuración de Windows y tus juegos, y te propone solo los ajustes que tienen sentido en tu equipo. Todo se puede deshacer.","It analyzes your hardware, your Windows settings and your games, and suggests only the settings that make sense on your computer. Everything can be undone."],["Escanear mi PC","Scan my PC"],["Tarda unos 15 segundos","Takes about 15 seconds"],["Modo rápido","Quick mode"],["No se toca","Never touched"],["Medal, Riot Vanguard, tus planes de energía, Xbox, Microsoft Store, Defender ni Windows Update.","Medal, Riot Vanguard, your power plans, Xbox, Microsoft Store, Defender or Windows Update."],["Al usar Miki Tweaks aceptas que cambie ajustes de Windows bajo tu responsabilidad. Todo se puede deshacer y nada se toca sin que lo marques.","By using Miki Tweaks you accept that it changes Windows settings at your own risk. Everything can be undone and nothing is touched unless you select it."],["Analizando tu PC","Analyzing your PC"],["Volver a escanear","Scan again"],["Puntuación de tu PC","Your PC score"],["Buscar en esta sección","Search this section"],["Marca todos los recomendados de esta sección","Select all recommended settings in this section"],["Deja esta sección como está ahora en tu PC","Leave this section as it is now on your PC"],["Aplicar cambios","Apply changes"],["Reiniciar ahora","Restart now"],["Impacto alto","High impact"],["Impacto medio","Medium impact"],["Impacto bajo","Low impact"],["Requiere reinicio","Requires restart"],["Ya estaba así antes de usar la app","It was already like this before using the app"],["OPCIONALES  ·  TIENEN ALGUNA CONTRAPARTIDA","OPTIONAL  ·  WITH SOME TRADE-OFF"],["DENTRO DEL JUEGO  ·  REVÍSALO EN SUS AJUSTES","IN THE GAME  ·  CHECK IT IN ITS SETTINGS"],["de 100","out of 100"],["Puntuación de optimización","Optimization score"],["Aplicar recomendados","Apply recommended"],["Revisar ajustes","Review settings"],["Liberar espacio","Free up space"],["Cambiar de modo","Change mode"],["Medir FPS","Measure FPS"],["TUS JUEGOS","YOUR GAMES"],["Todo optimizado","Fully optimized"],["TU EQUIPO","YOUR COMPUTER"],["Pantalla del portátil (integrada)","Laptop screen (integrated)"],["Gráfica","Graphics"],["Pantalla principal","Main display"],["Energía","Power"],["DIAGNÓSTICO","DIAGNOSTICS"],["Aún no hay actividad en esta sesión.","No activity in this session yet."],["No encontré tu gráfica en el catálogo de NVIDIA","Couldn\u0027t find your graphics card in NVIDIA\u0027s catalog"],["NVIDIA no devolvió ningún driver","NVIDIA didn\u0027t return any driver"],["DRIVER DE LA GRÁFICA","GRAPHICS DRIVER"],["Al instalarlo, elige \"Instalación personalizada\" y marca \"Instalación limpia\".","When installing, choose \"Custom installation\" and check \"Perform a clean installation\"."],["Comprobar otra vez","Check again"],["Actualizaciones de Windows","Windows updates"],["Busca las actualizaciones pendientes: seguridad, calidad y drivers que Windows considera necesarios.","Looks for pending updates: security, quality and drivers that Windows considers necessary."],["Abrir Windows Update","Open Windows Update"],["Buscando el último driver en nvidia.com...","Looking for the latest driver on nvidia.com..."],["Para tu gráfica, lo más fiable es la herramienta oficial del fabricante, que detecta el driver exacto.","For your graphics card, the most reliable option is the manufacturer\u0027s official tool, which detects the exact driver."],["Abrir web oficial","Open official website"],["No se pudo comprobar ahora (sin conexión o la web de NVIDIA no respondió).","Couldn\u0027t check right now (no connection or NVIDIA\u0027s website didn\u0027t respond)."],["Abrir web de NVIDIA","Open NVIDIA website"],["Buscando actualizaciones... puede tardar uno o dos minutos.","Looking for updates... it can take a minute or two."],["Buscar otra vez","Search again"],["✓ Windows está al día.","✓ Windows is up to date."],["Windows Update: al día","Windows Update: up to date"],["Descargando e instalando... puede tardar varios minutos. No apagues el PC.","Downloading and installing... it can take several minutes. Don\u0027t turn off the PC."],["Windows Update: instalando las actualizaciones necesarias...","Windows Update: installing required updates..."],["Terminó con errores; ábrelo en Windows Update para ver el detalle.","It finished with errors; open Windows Update to see the details."],["✓ No había nada pendiente.","✓ Nothing was pending."],["Archivos temporales","Temporary files"],["Temporales de Windows y de tus programas. Solo se borran los que llevan más de un día sin usarse.","Temporary files from Windows and your programs. Only those unused for more than a day are deleted."],["Descargas de Windows Update","Windows Update downloads"],["Instaladores de actualizaciones que ya se aplicaron. Windows los vuelve a descargar si hiciera falta.","Installers for updates that are already applied. Windows downloads them again if needed."],["Optimización de distribución","Delivery Optimization"],["Copias de actualizaciones que Windows guarda para compartir con otros PC.","Copies of updates Windows keeps to share with other PCs."],["Restos de instaladores de drivers","Driver installer leftovers"],["Carpetas que dejan los instaladores de NVIDIA y AMD al descomprimirse (pueden ocupar varios GB).","Folders left by NVIDIA and AMD installers when they unpack (they can take several GB)."],["Informes de errores y volcados","Error reports and dumps"],["Informes de fallos y volcados de memoria de cuelgues antiguos. No los necesitas salvo para depurar un problema concreto.","Crash reports and memory dumps from old crashes. You don\u0027t need them unless you\u0027re debugging a specific problem."],["Caché de miniaturas","Thumbnail cache"],["Vistas previas de fotos y vídeos del Explorador. Se regeneran solas (las carpetas con muchas fotos tardarán un poco la primera vez).","Explorer previews of photos and videos. They regenerate on their own (folders with lots of photos will take a moment the first time)."],["Caché de sombreadores (shaders)","Shader cache"],["Útil después de actualizar el driver o si un juego da tirones raros. Las primeras partidas tendrán algún tirón mientras se vuelve a generar.","Useful after updating the driver or if a game has odd stutters. The first matches will stutter a bit while it rebuilds."],["Papelera de reciclaje","Recycle Bin"],["Vacía la papelera. Revisa antes que no haya nada que quieras recuperar.","Empties the Recycle Bin. Check first that there\u0027s nothing you want to recover."],["Limpieza profunda de componentes de Windows","Deep cleanup of Windows components"],["Elimina versiones antiguas de componentes que dejan las actualizaciones (DISM). Puede tardar 5-15 minutos; el espacio que libera no se puede calcular antes.","Removes old versions of components that updates leave behind (DISM). It can take 5-15 minutes; the space it frees can\u0027t be calculated beforehand."],["Espacio que puedes liberar","Space you can free up"],["OPCIONAL  ·  MÍRALO ANTES DE MARCARLO","OPTIONAL  ·  CHECK IT BEFORE SELECTING"],["Midiendo cuánto ocupa cada cosa...","Measuring how much each thing takes up..."],["· Descargas de Windows Update: se salta porque hay una instalación en marcha","· Windows Update downloads: skipped because an installation is in progress"],["Comprobando cuánto se ha liberado...","Checking how much was freed..."],["Temperatura de la gráfica","Graphics card temperature"],["Memoria RAM","RAM"],["Ping a internet (1.1.1.1)","Internet ping (1.1.1.1)"],["Resolución del temporizador","Timer resolution"],["LO QUE MÁS PROCESADOR USA AHORA","WHAT\u0027S USING THE MOST CPU RIGHT NOW"],["Alto: revisa tu conexión","High: check your connection"],["Sin respuesta","No response"],["Sin conexión a internet","No internet connection"],["La de Windows por defecto","Windows default"],["Buena precisión","Good precision"],["Alta precisión: ideal para jugar","High precision: ideal for gaming"],["TU PERFIL","YOUR PROFILE"],["Cambiar perfil","Change profile"],["Decide qué modos tienes y qué ajustes se te recomiendan. Cámbialo si usas el equipo de otra forma.","Decides which modes you have and which settings are recommended. Change it if you use the computer differently."],["Crea un punto de restauración de Windows antes de cada tanda de cambios. Windows solo guarda uno cada 24 horas.","Creates a Windows restore point before each batch of changes. Windows only keeps one every 24 hours."],["Punto de restauración antes de aplicar","Restore point before applying"],["Ajuste: punto de restauración antes de aplicar desactivado","Setting: restore point before applying turned off"],["Ajuste: punto de restauración antes de aplicar activado","Setting: restore point before applying turned on"],["Crear ahora","Create now"],["Crear un punto de restauración ahora","Create a restore point now"],["Una copia del estado de Windows a la que volver desde «Restaurar sistema» si algo fallara.","A copy of Windows\u0027 state to go back to from «System Restore» if something went wrong."],["✓ Punto de restauración creado","✓ Restore point created"],["✓ Creado","✓ Created"],["No se pudo","Couldn\u0027t do it"],["Deshacer todos los cambios de la app","Undo all the app\u0027s changes"],["Deshacer todo","Undo everything"],["¿Seguro que quieres deshacer todos los ajustes que ha cambiado la app en este PC?","Are you sure you want to undo all the settings the app has changed on this PC?"],["Deshacer todos los cambios","Undo all changes"],["LLEVAR TU CONFIGURACIÓN A OTRO PC","TAKE YOUR SETUP TO ANOTHER PC"],["Guardar mi selección","Save my selection"],["Guarda qué ajustes tienes activos y tu modo en perfil.json: junto a la app (en el pen si la abriste desde ahí) y en Documentos.","Saves which settings you have on and your mode to perfil.json: next to the app (on the USB stick if you opened it from there) and in Documents."],["Guardar perfil","Save profile"],["No hay ningún perfil.json junto a la app ni en Documentos. Guarda uno en tu PC y cópialo al pen.","There\u0027s no perfil.json next to the app or in Documents. Save one on your PC and copy it to the USB stick."],["Cargar perfil","Load profile"],["Cargar un perfil","Load a profile"],["Elige el color de acento: botones, interruptores, gráficas y puntuación.","Choose the accent color: buttons, switches, charts and score."],["Color de la app","App color"],["AVISOS E INFORMES","NOTIFICATIONS AND REPORTS"],["Junto al reloj: cambia de modo con clic derecho, abre la app con doble clic y muestra la temperatura de la gráfica al pasar el ratón. Arranca solo al iniciar sesión.","Next to the clock: switch modes with a right-click, open the app with a double-click and see the graphics card temperature on hover. Starts on its own when you sign in."],["Icono en la bandeja del sistema","System tray icon"],["Icono en la bandeja activado","Tray icon turned on"],["✓ Icono en la bandeja activado","✓ Tray icon turned on"],["↺ Icono en la bandeja desactivado","↺ Tray icon turned off"],["Cada sábado comprueba en segundo plano si hay un driver NVIDIA nuevo o actualizaciones de Windows pendientes, y te avisa con una notificación. Si todo está al día, no molesta.","Every Saturday it checks in the background for a new NVIDIA driver or pending Windows updates, and lets you know with a notification. If everything is up to date, it stays quiet."],["Aviso semanal de drivers y actualizaciones","Weekly driver and update check"],["✓ Aviso semanal activado (sábados a las 18:00)","✓ Weekly check turned on (Saturdays at 18:00)"],["↺ Aviso semanal desactivado","↺ Weekly check turned off"],["Probar ahora","Test now"],["Todo al día: driver y Windows actualizados.","All up to date: driver and Windows updated."],["Exportar informe","Export report"],["Exportar informe del PC","Export PC report"],["Crea en el escritorio un archivo de texto con tu equipo, diagnóstico, periféricos, salud del hardware y todos los ajustes. Útil para pedir ayuda o guardarlo.","Creates a text file on the desktop with your computer, diagnostics, peripherals, hardware health and all settings. Useful for asking for help or keeping a record."],["ACTUALIZACIONES DE LA APP","APP UPDATES"],["Buscar ahora","Check now"],["Canal (dirección https de un version.json)","Channel (https address of a version.json)"],["Crea en el escritorio la carpeta «Miki Tweaks - publicar» con el script y su version.json para subirlos al canal","Creates the «Miki Tweaks - publicar» folder on the desktop with the script and its version.json to upload to the channel"],["Preparar publicación","Prepare release"],["La dirección tiene que empezar por https://","The address has to start with https://"],["Canal de actualizaciones guardado","Update channel saved"],["DATOS Y ACERCA DE","DATA AND ABOUT"],["Abrir carpeta","Open folder"],["Carpeta de datos","Data folder"],["Atajos de teclado","Keyboard shortcuts"],["F5: volver a escanear  ·  Ctrl+F: buscar en la sección  ·  Esc: cerrar el aviso de cambios aplicados  ·  Doble clic en la barra de título: maximizar.","F5: scan again  ·  Ctrl+F: search the section  ·  Esc: close the applied changes notice  ·  Double-click the title bar: maximize."],["Web del proyecto","Project website"],["Apoyar el proyecto","Support the project"],["Miki Tweaks cambia ajustes de Windows, de tus juegos y de tus dispositivos. Úsala bajo tu responsabilidad: antes de aplicar crea un punto de restauración, cada ajuste se puede deshacer y nada se toca sin que lo marques. La mejora depende de cada PC y no se garantiza una cifra concreta: mídela tú mismo con el Benchmark.","Miki Tweaks changes settings in Windows, your games and your devices. Use it at your own risk: it creates a restore point before applying, every setting can be undone and nothing is touched unless you select it. The improvement depends on each PC and no specific figure is guaranteed: measure it yourself with the Benchmark."],["Aviso de uso","Terms of use"],["Sin canal configurado. Si subes la app a internet (por ejemplo a GitHub), pon abajo la dirección de su version.json y todas las copias avisarán y se actualizarán solas.","No channel set up. If you upload the app to the internet (for example to GitHub), put the address of its version.json below and every copy will notify and update itself."],["Comprueba si hay una versión nueva cada vez que abres la app.","Checks for a new version every time you open the app."],["Descargando y comprobando...","Downloading and checking..."],["No se pudo iniciar el test en este equipo.","The test couldn\u0027t start on this computer."],["Mueve el ratón en círculos rápidos y amplios durante 6 segundos...","Move the mouse in fast, wide circles for 6 seconds..."],["Repetir test","Repeat test"],["No se ha detectado movimiento suficiente. Repite el test moviendo el ratón sin parar.","Not enough movement detected. Repeat the test moving the mouse without stopping."],["TUS PERIFÉRICOS","YOUR PERIPHERALS"],["Integrado en el portátil: se actualiza con la BIOS y Windows Update.","Built into the laptop: it updates with the BIOS and Windows Update."],["Marca no reconocida: busca el software oficial con el botón.","Brand not recognized: look for the official software with the button."],["Buscar firmware oficial","Search for official firmware"],["TEST DE POLLING RATE DEL RATÓN","MOUSE POLLING RATE TEST"],["¿A cuántos Hz va de verdad tu ratón?","How many Hz does your mouse really run at?"],["Muchos ratones vienen a 500 Hz de fábrica o se resetean tras una actualización. Pulsa «Iniciar test» y mueve el ratón en círculos rápidos.","Many mice ship at 500 Hz or reset after an update. Press «Start test» and move the mouse in fast circles."],["Iniciar test","Start test"],["Sin fecha","No date"],["Buscar BIOS oficial","Search for official BIOS"],["Las BIOS nuevas suelen mejorar estabilidad, compatibilidad y a veces temperaturas. Se instalan solo con la herramienta oficial del fabricante y con el cargador puesto.","New BIOS versions usually improve stability, compatibility and sometimes temperatures. Install them only with the manufacturer\u0027s official tool and with the charger plugged in."],["Buen estado","Good condition"],["Con problemas","Has problems"],["Windows no da datos SMART de este disco.","Windows doesn\u0027t provide SMART data for this disk."],["Haz copia de seguridad de lo importante cuanto antes.","Back up anything important as soon as possible."],["Para cuidarla: si juegas siempre enchufado, activa en el programa del fabricante (MSI Center, Armoury Crate, Lenovo Vantage...) el límite de carga al 80 %.","To look after it: if you always play plugged in, turn on the 80% charge limit in the manufacturer\u0027s software (MSI Center, Armoury Crate, Lenovo Vantage...)."],["Batería del portátil","Laptop battery"],["Rápido","Fast"],["Quitar programas de la sección «Inicio de Windows» es lo que más lo acelera.","Removing programs from the «Windows startup» section is what speeds it up the most."],["Reparar ahora","Repair now"],["Comprueba y repara los archivos del sistema con las herramientas oficiales de Microsoft (DISM y SFC). Útil si notas fallos raros, cuelgues o errores. Tarda entre 10 y 30 minutos y puedes seguir usando el PC.","Checks and repairs system files with Microsoft\u0027s official tools (DISM and SFC). Useful if you notice odd failures, freezes or errors. It takes 10 to 30 minutes and you can keep using the PC."],["Reparar Windows","Repair Windows"],["Se van a comprobar y reparar los archivos de Windows (DISM + SFC). Tarda entre 10 y 30 minutos. ¿Empezar?","Windows files will be checked and repaired (DISM + SFC). It takes 10 to 30 minutes. Start?"],["Reparando... (no apagues el PC)","Repairing... (don\u0027t turn off the PC)"],["Reparar Windows: DISM /RestoreHealth y SFC /scannow en marcha...","Repair Windows: DISM /RestoreHealth and SFC /scannow running..."],["Terminado con avisos","Finished with warnings"],["✓ Terminado","✓ Finished"],["Reparación terminada: Windows está en buen estado o se ha reparado. Reinicia cuando puedas.","Repair finished: Windows is in good condition or has been repaired. Restart when you can."],["Europa · París","Europe · Paris"],["Europa · Fráncfort","Europe · Frankfurt"],["Europa · Irlanda","Europe · Ireland"],["Europa · Estocolmo","Europe · Stockholm"],["EE. UU. · Oeste","US · West"],["EE. UU. · Este","US · East"],["no hay respuesta de internet ahora mismo.","there\u0027s no internet response right now."],["la conexión no responde de forma estable ni siquiera en reposo.","the connection doesn\u0027t respond steadily even at rest."],["los servidores de prueba de Cloudflare te han puesto un límite temporal por hacer varios tests seguidos. Espera unos 10 minutos y repítelo.","Cloudflare\u0027s test servers have temporarily limited you for running several tests in a row. Wait about 10 minutes and try again."],["no se pudo cargar la conexión con los servidores de prueba (puede que tu red los bloquee).","couldn\u0027t load the connection with the test servers (your network may block them)."],["tu red no deja hacer este diagnóstico (bloquea los pings). Usa la medición de latencia de Rendimiento en vivo.","your network doesn\u0027t allow this diagnosis (it blocks pings). Use the latency measurement in Live performance."],["El servidor de destino no responde","The destination server isn\u0027t responding"],["No se ha podido medir la latencia final. Prueba con otra región o vuelve a intentarlo en un rato.","The final latency couldn\u0027t be measured. Try another region or try again in a while."],["Los paquetes ya se pierden entre tu PC y el router. Por Wi-Fi: acércate al router, usa la banda de 5 GHz o, mejor, un cable. Por cable: prueba otro cable u otro puerto y reinicia el router.","Packets are already lost between your PC and the router. On Wi-Fi: move closer to the router, use the 5 GHz band or, better, a cable. On cable: try another cable or port and restart the router."],["Algunos saltos intermedios no contestan a todos los pings: es normal (los routers de internet dan poca prioridad a los pings) y no afecta a tu partida, porque al destino llega todo.","Some intermediate hops don\u0027t answer every ping: that\u0027s normal (internet routers give pings low priority) and it doesn\u0027t affect your match, because everything reaches the destination."],["Con una ruta así, una app tipo ExitLag apenas te mejoraría el ping.","With a route like this, an app like ExitLag would barely improve your ping."],["Ping con la conexión ocupada (bufferbloat)","Ping with the connection busy (bufferbloat)"],["La causa más común de los picos de lag en casa: alguien descarga, ve una serie o sube fotos y tu ping se dispara. Este test mide tu ping en reposo y con la conexión a tope, y te dice si tu router lo gestiona bien. En fibra rápida usa hasta 1 GB de datos: no lo hagas con datos móviles.","The most common cause of lag spikes at home: someone downloads, watches a show or uploads photos and your ping shoots up. This test measures your ping at rest and with the connection maxed out, and tells you whether your router handles it well. On fast fiber it uses up to 1 GB of data: don\u0027t run it on mobile data."],["Hacer el test","Run the test"],["Midiendo durante unos 25 segundos: primero en reposo, luego descargando y después subiendo a tope. Mientras tanto, no uses internet en este PC.","Measuring for about 25 seconds: first at rest, then downloading and then uploading at full speed. Meanwhile, don\u0027t use the internet on this PC."],["error desconocido","unknown error"],["sin medir","not measured"],["En reposo","At rest"],["Tu router gestiona muy bien el tráfico: aunque alguien en casa descargue o vea vídeos, tu ping apenas sube. Si notas lag, no viene de aquí: mira la ruta hasta el servidor más abajo.","Your router handles traffic very well: even if someone at home downloads or watches videos, your ping barely rises. If you notice lag, it doesn\u0027t come from here: check the route to the server below."],["Tu ping sube algo cuando la conexión está ocupada. Si notas tirones cuando otros usan internet, activa QoS o SQM en tu router (o pide a los demás que pausen las descargas grandes mientras juegas).","Your ping rises a bit when the connection is busy. If you notice stutters when others use the internet, turn on QoS or SQM on your router (or ask others to pause big downloads while you play)."],["Cuando la conexión está ocupada tu ping se dispara: esta es la causa típica de los picos de lag cuando alguien ve una serie, descarga juegos o sube fotos. Solución: en la configuración del router, activa «QoS», «SQM» o «Smart Queue» y limita la velocidad a un 90 % de la que tienes contratada. Si tu router no lo tiene, juega por cable y activa «Pausar descargas mientras juegas» en Modos.","When the connection is busy your ping shoots up: this is the typical cause of lag spikes when someone watches a show, downloads games or uploads photos. Fix: in the router settings, turn on «QoS», «SQM» or «Smart Queue» and limit the speed to 90% of your plan. If your router doesn\u0027t have it, play on cable and turn on «Pause downloads while gaming» in Modes."],[" (medido por TCP porque tu red bloquea los pings)"," (measured over TCP because your network blocks pings)"],["¿Dónde se pierde tu conexión?","Where is your connection failing?"],["Sigue el camino de tus paquetes salto a salto hasta una región de servidores y te dice si el problema está en tu casa, en tu operador o más lejos (donde ya no depende de ti).","It follows your packets hop by hop to a server region and tells you whether the problem is at your home, at your ISP or further away (where it no longer depends on you)."],["Analizar ruta","Analyze route"],["Analizar otra vez","Analyze again"],[" (medido por TCP)"," (measured over TCP)"],["Sin respuesta (normal en algunos routers)","No response (normal for some routers)"],["Latencia a las regiones de servidores","Latency to server regions"],["Mide la latencia, la estabilidad (jitter) y la pérdida de paquetes hasta los centros de datos donde se alojan muchos juegos online.","Measures latency, stability (jitter) and packet loss to the data centers where many online games are hosted."],["Medir conexión","Measure connection"],["Midiendo... tarda unos 15 segundos.","Measuring... it takes about 15 seconds."],["Medir otra vez","Measure again"],["Latencia media · jitter (variación) · pérdida. Para jugar: menos de 50 ms, jitter bajo y 0 % de pérdida.","Average latency · jitter (variation) · loss. For gaming: under 50 ms, low jitter and 0% loss."],["PERIFÉRICOS","PERIPHERALS"],[" (opcional)"," (optional)"],["Informe guardado en el escritorio","Report saved to the desktop"],["Sin modo elegido","No mode selected"],["Se registraron muy pocos fotogramas. ¿Estaba el juego en primer plano y en partida?","Very few frames were recorded. Was the game in the foreground and in a match?"],["PresentMon no devolvió tiempos de fotograma válidos.","PresentMon didn\u0027t return valid frame times."],["PresentMon no guardó datos. Comprueba que el juego estaba abierto y en primer plano; algún anticheat puede bloquear la medición.","PresentMon didn\u0027t save data. Check that the game was open and in the foreground; some anti-cheats can block the measurement."],["no encontré la versión de consola en GitHub","couldn\u0027t find the console version on GitHub"],["la firma digital no es de Intel; descarga descartada por seguridad","the digital signature isn\u0027t Intel\u0027s; download discarded for safety"],["Medición de FPS y latencia","FPS and latency measurement"],["Mide antes y después de aplicar los ajustes","Measure before and after applying the settings"],["Elige juego y duración, pulsa Empezar y entra en partida o en el campo de tiro. La medición empieza sola cuando el juego está abierto, con un aviso sonoro al empezar y al terminar.","Choose the game and duration, press Start and get into a match or the practice range. The measurement starts by itself when the game is open, with a sound at the start and at the end."],["DURACIÓN","DURATION"],["NOMBRE DE LA MEDICIÓN","MEASUREMENT NAME"],["Empezar medición","Start measurement"],["No se ha detectado ningún juego compatible en este PC.","No compatible game was detected on this PC."],["Antes de los ajustes","Before the settings"],["Después de los ajustes","After the settings"],["· PresentMon no tenía una firma válida de Intel: se vuelve a descargar","· PresentMon didn\u0027t have a valid Intel signature: downloading it again"],["Descargando PresentMon (menos de 1 MB) desde el GitHub oficial de Intel y comprobando su firma...","Downloading PresentMon (under 1 MB) from Intel\u0027s official GitHub and checking its signature..."],["Juego detectado. Ponte en la escena que quieras medir: la medición empieza en unos segundos.","Game detected. Go to the scene you want to measure: the measurement starts in a few seconds."],["Midiendo... juega con normalidad y no salgas del juego hasta oír el aviso.","Measuring... play normally and don\u0027t leave the game until you hear the sound."],["Analizando los fotogramas...","Analyzing the frames..."],["Medición cancelada.","Measurement canceled."],["Medición","Measurement"],["✓ Medición guardada. Aplica ajustes y vuelve a medir con la misma escena para ver la diferencia.","✓ Measurement saved. Apply settings and measure again in the same scene to see the difference."],["Medición guardada","Measurement saved"],["FPS medios","Average FPS"],["1 % más bajo","1% lows"],["Lo que notas en los tirones","What you notice in stutters"],["Los peores momentos","The worst moments"],["0,1 % más bajo","0.1% lows"],["Del ratón a la pantalla","From mouse to screen"],["Del fotograma a la pantalla","From frame to screen"],["Variación: ","Variation: "],["Hay tirones frecuentes: prueba a limpiar la caché de sombreadores (Caché y temporales), revisa la temperatura en Rendimiento en vivo y cierra lo que no uses.","There are frequent stutters: try clearing the shader cache (Cache & temp files), check the temperature in Live performance and close what you don\u0027t use."],["COMPARAR CON","COMPARE WITH"],["Medición borrada del historial","Measurement deleted from history"],["Antes y después","Before and after"],["Tirones por minuto","Stutters per minute"],["Latencia (ms)","Latency (ms)"],["Después","After"],["Imagen guardada en Imágenes \u003e Miki Tweaks y copiada: pégala en Discord o súbela a TikTok o Instagram.","Image saved in Pictures \u003e Miki Tweaks and copied: paste it in Discord or upload it to TikTok or Instagram."],["Diferencia pequeña: dentro de lo que varía entre partidas. Repite la medición para confirmarlo.","Small difference: within what varies between matches. Repeat the measurement to confirm it."],["Ha ido a peor: revisa si la escena era la misma o deshaz los últimos cambios.","It got worse: check that the scene was the same or undo the latest changes."],["Mejora clara respecto a la medición elegida.","Clear improvement over the selected measurement."],["Variación (ms)","Variation (ms)"],["Modos para tu perfil: ","Modes for your profile: "],["Modo activo","Active mode"],["Cambio automático","Automatic switching"],["Al desenchufar el cargador pasa a Ahorro de batería y, al volver a enchufarlo, recupera el modo que tenías. También mantiene tu modo después de reiniciar.","When you unplug the charger it switches to Battery Saver and, when you plug it back in, it restores the mode you had. It also keeps your mode after restarting."],["✓ Cambio automático de modo activado","✓ Automatic mode switching turned on"],["↺ Cambio automático de modo desactivado","↺ Automatic mode switching turned off"],["Modo Juego automático al abrir un juego","Automatic Game Mode when you open a game"],["En cuanto abres uno de tus juegos se activa el Modo Juego, y al cerrarlo vuelve solo al modo que tenías. Funciona en segundo plano con un consumo mínimo.","As soon as you open one of your games, Game Mode turns on, and when you close it, it goes back to the mode you had. It runs in the background with minimal resource use."],["✓ Modo Juego automático activado","✓ Automatic Game Mode turned on"],["Modo Juego automático activado","Automatic Game Mode turned on"],["↺ Modo Juego automático desactivado","↺ Automatic Game Mode turned off"],["Modo Juego automático desactivado","Automatic Game Mode turned off"],["Cerrar programas al activar el Modo Juego","Close programs when Game Mode turns on"],["Marca los que quieres que se cierren solos para liberar procesador, memoria y red. Los navegadores se cierran como si lo hicieras tú y recuperan sus pestañas al abrirlos.","Select the ones you want closed automatically to free up CPU, memory and network. Browsers close as if you did it yourself and restore their tabs when you open them."],["Cerrar ahora","Close now"],["  ·  abierto","  ·  open"],["Ahora mismo no hay ninguno abierto.","None are open right now."],["Programas marcados cerrados","Selected programs closed"],["Pausar descargas mientras juegas","Pause downloads while gaming"],["Al activar el Modo Juego se pausan Windows Update, la optimización de distribución y OneDrive para que no te quiten ancho de banda ni provoquen picos de ping. Vuelven solas al cambiar de modo o al cerrar el juego. Steam y Epic ya pausan sus descargas durante las partidas.","When Game Mode turns on, Windows Update, Delivery Optimization and OneDrive are paused so they don\u0027t take your bandwidth or cause ping spikes. They resume by themselves when you switch modes or close the game. Steam and Epic already pause their downloads during matches."],["Tarda unos segundos; la pantalla puede parpadear un momento.","It takes a few seconds; the screen may flicker for a moment."],["Hecho, con algún aviso","Done, with some warnings"],["Puedes cambiar de modo cuando quieras.","You can switch modes whenever you want."],["Hecho, con algún aviso (míralo en el Registro)","Done, with some warnings (check the Log)"],["Cambia el PC entero de un clic según lo que vayas a hacer. Puedes volver a cualquier modo cuando quieras.","Change the whole PC with one click depending on what you\u0027re going to do. You can go back to any mode whenever you want."],["Inicio de Windows","Windows startup"],["Procesador, gráfica, temperatura, memoria y conexión en tiempo real.","Processor, graphics card, temperature, memory and connection in real time."],["Rendimiento en vivo","Live performance"],["Seguridad, perfiles para llevar tu configuración a otro PC y datos de la app.","Safety, profiles to take your setup to another PC and app data."],["Tu ratón, teclado, mandos y audio: marca, software oficial, firmware y test de polling rate.","Your mouse, keyboard, controllers and audio: brand, official software, firmware and polling rate test."],["BIOS, discos, batería y arranque de Windows, más una reparación del sistema con las herramientas de Microsoft.","BIOS, disks, battery and Windows startup, plus a system repair with Microsoft\u0027s tools."],["Salud del PC","PC Health"],["Mide FPS, estabilidad y latencia con PresentMon de Intel, y compara antes y después de aplicar los ajustes.","Measures FPS, stability and latency with Intel\u0027s PresentMon, and compares before and after applying the settings."],["El driver de tu gráfica y las actualizaciones de Windows, comprobados en directo cada vez que abres la app.","Your graphics driver and Windows updates, checked live every time you open the app."],["Caché y temporales","Cache & temp files"],["Libera espacio borrando lo que Windows, los drivers y los juegos acumulan y ya no necesitan.","Frees up space by deleting what Windows, drivers and games pile up and no longer need."],["Quita lo que Windows trae y no necesitas para jugar. Nunca se tocan Xbox, Microsoft Store, Defender, Windows Update ni las funciones de desarrollo (Hyper-V, WSL, Docker).","Removes what Windows ships with that you don\u0027t need for gaming. Xbox, Microsoft Store, Defender, Windows Update and developer features (Hyper-V, WSL, Docker) are never touched."],["Limpieza de Windows","Windows Cleanup"],["Cierra Fortnite antes de aplicar sus ajustes; se guarda una copia de tu configuración original.","Close Fortnite before applying its settings; a copy of your original settings is saved."],["Ajustes del sistema que ayudan a todos tus juegos. Tus planes de energía no se modifican.","System settings that help all your games. Your power plans aren\u0027t modified."],["Programas que arrancan al encender. Medal y Riot Vanguard no aparecen: siguen como siempre.","Programs that start when the PC turns on. Medal and Riot Vanguard don\u0027t appear: they stay as always."],["Todo lo que ha hecho la app en esta sesión.","Everything the app has done in this session."],["Cada vez que aplicas cambios queda una tanda con fecha. Puedes deshacer una tanda concreta sin tocar las demás.","Every time you apply changes, a dated batch is kept. You can undo a specific batch without touching the others."],["● Se aplicará","● Will be applied"],["● Se revertirá","● Will be reverted"],["✓ Ya estaba así","✓ Already like this"],["✓ Activo","✓ Active"],["Todo al día  ·  sin cambios pendientes","All up to date  ·  no pending changes"],["Va bien, pero aún puede rendir más","Doing well, but it can still perform better"],["Hay bastante margen de mejora","There\u0027s plenty of room for improvement"],["Tu PC está listo para competir","Your PC is ready to compete"],["  (falló)","  (failed)"],["Deshacer esta tanda","Undo this batch"],["No queda nada activo de esta tanda que se pueda deshacer","Nothing from this batch is still active to undo"],["Deshacer una tanda anterior","Undo a previous batch"],["Cambios aplicados","Changes applied"],["No cierres la app, tarda unos segundos.","Don\u0027t close the app, it takes a few seconds."],["Aplicando cambios...","Applying changes..."],["Creando punto de restauración...","Creating restore point..."],["✓ Punto de restauración (Windows crea como máximo uno cada 24 h)","✓ Restore point (Windows creates at most one every 24 h)"],["Ya puedes jugar. Si mediste antes, vuelve a medir en Benchmark para ver la mejora.","You can play now. If you measured before, measure again in Benchmark to see the improvement."],["Algunos cambios necesitan reiniciar el PC para surtir efecto.","Some changes need a PC restart to take effect."],["Más tarde","Later"],["Escaneo iniciado","Scan started"],["Escaneo completado","Scan complete"],["Parte del análisis ha fallado en este PC. Puedes copiar el informe en Ajustes → Carpeta de datos.","Part of the analysis failed on this PC. You can copy the report in Settings → Data folder."],["Tu perfil: creas contenido (OBS, editores y renders no se frenan en segundo plano)","Your profile: you create content (OBS, editors and renders aren\u0027t slowed down in the background)"],["silencio y temperatura","quiet and temperature"],["batería y temperatura","battery and temperature"],["¿Qué ordenador es?","What kind of computer is it?"],["¿Para qué lo usas?","What do you use it for?"],["Marca todo lo que hagas a menudo. Con esto decidimos qué modos tienes y qué ajustes te recomendamos.","Select everything you do often. This decides which modes you have and which settings we recommend."],["¿Qué prefieres en el día a día?","What do you prefer day to day?"],["Cuando no estás jugando ni haciendo nada pesado.","When you\u0027re not gaming or doing anything heavy."],["¿Cómo lo usas normalmente?","How do you usually use it?"],["Así sabemos si cambiar de modo solo al desenchufarlo y cuánto cuidar la batería.","This tells us whether to switch modes when you unplug it and how much to look after the battery."],["Tu configuración","Your setup"],["Con batería. Modos para jugar enchufado, trabajar y alargar la batería.","With battery. Modes for gaming plugged in, working and making the battery last."],["Siempre enchufado. Modos para rendir al máximo o ir en silencio.","Always plugged in. Modes for maximum performance or running quietly."],["Fortnite, VALORANT, CS2... Máximos FPS y mínima latencia.","Fortnite, VALORANT, CS2... Maximum FPS and minimum latency."],["Juegos con amigos o de un jugador, sin obsesionarse con los FPS.","Games with friends or single-player, without obsessing over FPS."],["Office, navegador, videollamadas, clases.","Office, browser, video calls, classes."],["Editar vídeo o fotos, hacer streaming, grabar.","Editing video or photos, streaming, recording."],["Internet, YouTube, Netflix y poco más.","Internet, YouTube, Netflix and little else."],["Máximo rendimiento","Maximum performance"],["Que todo vaya lo más rápido posible, aunque gaste más y haga más ruido.","Everything as fast as possible, even if it uses more power and makes more noise."],["Rendimiento cuando hace falta y tranquilo el resto del tiempo.","Performance when needed and calm the rest of the time."],["Ventiladores tranquilos y el PC más fresco.","Quiet fans and a cooler PC."],["Más horas sin cargador y un portátil más fresco.","More hours without the charger and a cooler laptop."],["En la mesa, con el cargador puesto.","At the desk, with the charger plugged in."],["Casi siempre enchufado","Almost always plugged in"],["Clase, trabajo, sofá... lo desenchufas cada día.","Class, work, couch... you unplug it every day."],["A menudo con batería","Often on battery"],["Los ajustes de juegos pasan a opcionales y desaparece el Modo Juego.","Game settings become optional and Game Mode disappears."],["Nuevo Modo Creación, y Windows deja de frenar OBS y los editores en segundo plano.","New Creation Mode, and Windows stops slowing down OBS and editors in the background."],["Sin ahorro de batería: en su lugar tienes un Modo Silencio.","No battery saver: instead you get a Quiet Mode."],["Se recomienda limitar los FPS para que el equipo vaya más fresco.","Capping FPS is recommended so the computer runs cooler."],["El modo del día a día también usa el plan de alto rendimiento.","The everyday mode also uses the high performance plan."],["Qué cambia","What changes"],["Tus modos","Your modes"],["Automático","Automatic"],["Y volver a tu modo al enchufarlo.","And go back to your mode when you plug it in."],["Pasar a Ahorro de batería al desenchufar el cargador","Switch to Battery Saver when unplugging the charger"],["Al cerrarlo vuelve solo al modo que tenías.","When you close it, it goes back to the mode you had."],["Activar el Modo Juego al abrir un juego","Turn on Game Mode when opening a game"],["El modo que mejor encaja con tu perfil para el día a día.","The mode that best fits your profile for everyday use."],["Ahora no","Not now"],["Atrás","Back"],["Guardar y empezar","Save and start"],["Marca al menos una opción","Select at least one option"],["Reiniciando el PC...","Restarting the PC..."],["Hay una tarea en marcha (por ejemplo, Windows Update). Si cierras ahora se interrumpe. ¿Cerrar igualmente?","There\u0027s a task running (for example, Windows Update). If you close now it will be interrupted. Close anyway?"],["Algo ha fallado, pero la app sigue funcionando. Hay un informe en el escritorio.","Something failed, but the app keeps working. There\u0027s a report on the desktop."],["Resumen","Overview"],["Modos","Modes"],["Actualizaciones","Updates"],["Periféricos","Peripherals"],["Red","Network"],["Limpieza","Cleanup"],["Inicio","Startup"],["Historial","History"],["Registro","Log"],["Ajustes","Settings"],["Juegos","Games"],["JUEGOS","GAMES"],["SISTEMA","SYSTEM"],["Almacenamiento","Storage"],["Alto","High"],["Medio","Medium"],["Bajo","Low"],["Antes","Before"],["Siguiente","Next"],["Auriculares","Headset"],["Azul","Blue"],["Blanco","White"],["Naranja","Orange"],["Violeta","Violet"],["Lima","Lime"],["Bueno","Good"],["Excelente","Excellent"],["Lento","Slow"],["Buscar","Search"],["Cambiar","Change"],["Cambio","Change"],["Consejos","Tips"],["Contactos","People"],["Desactivado","Off"],["Activado","On"],["Activo","Active"],["ACTIVO","ACTIVE"],["Activar","Activate"],["Descargando","Downloading"],["Subiendo","Uploading"],["Descargar","Download"],["Descartar","Discard"],["Desgastado","Worn"],["Detectado","Detected"],["Diario","Everyday"],["Enchufado","Plugged in"],["Equilibrio","Balanced"],["Guardar","Save"],["Instalar","Install"],["Actualizar","Update"],["Integrado","Built-in"],["Juego","Game"],["JUEGO","GAME"],["Latencia","Latency"],["Limpiar","Clean"],["Listo","Done"],["Mando","Controller"],["Mantenimiento","Maintenance"],["Mapas","Maps"],["Memoria","Memory"],["Mensajes","Messages"],["Opcional","Optional"],["Sobremesa","Desktop"],["Procesador","Processor"],["Teclado","Keyboard"],["Reciente","Recent"],["Recomendado","Recommended"],["Recomendados","Recommended"],["RECOMENDADOS","RECOMMENDED"],["Rendimiento","Performance"],["Silencio","Quiet"],["Trabajo","Work"],["Tirones","Stutters"],["Cancelar","Cancel"],["Cerrar","Close"],["Aplicar","Apply"],["Deshacer","Undo"],["Abrir","Open"],["Empezar","Start"],["Aún no hay mediciones de este juego. Haz una ahora (antes de aplicar ajustes) y otra después: aquí verás la diferencia en FPS, estabilidad y latencia.","No measurements for this game yet. Take one now (before applying settings) and another one after: here you\u0027ll see the difference in FPS, stability and latency."],["Automático usa el idioma de Windows. Al cambiarlo, la app se reinicia.","Automatic uses the Windows language. Changing it restarts the app."],["CONEXIÓN","CONNECTION"],["HERRAMIENTAS DE CONEXIÓN","CONNECTION TOOLS"],["El firmware se actualiza siempre con el programa oficial de cada marca y sin desconectar el periférico mientras tanto. Ninguna app genérica puede hacerlo de forma segura.","Firmware is always updated with each brand\u0027s official program and without unplugging the peripheral meanwhile. No generic app can do it safely."],["Estas opciones las guarda el propio juego o tu cuenta, así que la app no las cambia por ti.","These options are saved by the game itself or your account, so the app doesn\u0027t change them for you."],["Las actualizaciones opcionales (normalmente drivers alternativos) se muestran pero no se instalan: el driver de la gráfica es mejor instalarlo desde arriba.","Optional updates (usually alternative drivers) are shown but not installed: it\u0027s better to install the graphics driver from above."],["Medal, el Bluetooth, el Modo Juego de Windows y los ajustes de las demás secciones no cambian con los modos. Tus planes de energía no se modifican: el modo solo elige cuál está activo.","Medal, Bluetooth, Windows Game Mode and the settings in other sections don\u0027t change with modes. Your power plans aren\u0027t modified: the mode only chooses which one is active."],["Nunca se tocan tus documentos, descargas, partidas guardadas ni clips de Medal. Si un archivo está en uso, simplemente se salta.","Your documents, downloads, saved games and Medal clips are never touched. If a file is in use, it\u0027s simply skipped."],["Para comparar de forma justa: misma escena (por ejemplo el campo de tiro o un mapa creativo), mismos gráficos, misma duración y nada más abierto. Usa PresentMon, la herramienta de Intel en la que se basan HWiNFO, FrameView u OCCT.","For a fair comparison: same scene (for example the practice range or a creative map), same graphics, same duration and nothing else open. It uses PresentMon, the Intel tool that HWiNFO, FrameView and OCCT are based on."],["Se actualiza cada segundo mientras tienes esta página abierta; al salir deja de medir para no gastar recursos. Truco: déjala abierta en otra pantalla mientras juegas en ventana para ver la temperatura.","It updates every second while this page is open; when you leave it stops measuring so it doesn\u0027t waste resources. Tip: leave it open on another screen while you play windowed to watch the temperature."],["Tu perfil","Your profile"],["portátil","laptop"],["sobremesa","desktop"],["AJUSTES","SETTINGS"],["APARIENCIA","APPEARANCE"],["BATERÍA","BATTERY"],["DISCOS","DISKS"],["HISTORIAL","HISTORY"],["RECOMENDADO","RECOMMENDED"],["SEGURIDAD","SAFETY"],["Temporizadores de Windows en automático","Windows timers on automatic"],["Algún programa o guía antigua dejó forzado el temporizador de Windows en el arranque (HPET u otros). Forzarlo resta rendimiento y añade latencia en muchos PC; sin forzar, Windows usa el temporizador más rápido de tu procesador. Es volver a lo que trae Windows de fábrica.","Some program or old guide left the Windows timer forced at boot (HPET or others). Forcing it lowers performance and adds latency on many PCs; when it isn\u0027t forced, Windows uses your processor\u0027s fastest timer. It\u0027s going back to Windows\u0027 factory setting."],["Temporizadores devueltos a automático por esta app","Timers set back to automatic by this app"],["Modo MSI para la gráfica","MSI mode for the graphics card"],["La gráfica avisa al procesador con interrupciones por mensaje (MSI) en vez de por línea compartida: menos latencia de interrupción y menos tirones raros en algunos equipos. NVIDIA no lo activa en todas sus gráficas y lo desactiva al reinstalar el driver; si eso pasa, la app te lo vuelve a proponer.","The graphics card signals the processor with message-signaled interrupts (MSI) instead of a shared line: lower interrupt latency and fewer odd stutters on some PCs. NVIDIA doesn\u0027t enable it on all its cards and turns it off when the driver is reinstalled; if that happens, the app will suggest it again."],["Sin parches automáticos tras cierres inesperados","No automatic patches after crashes"],["Si un juego se cierra de golpe varias veces, Windows le aplica en silencio una protección de memoria (Fault Tolerant Heap) que puede hacerlo ir más lento para siempre. Con esto deja de hacerlo; los juegos se ejecutan tal como los hizo su desarrollador.","If a game crashes several times, Windows silently applies a memory protection to it (Fault Tolerant Heap) that can make it run slower for good. With this it stops doing so; games run exactly as their developer made them."],["Documentado por Microsoft; activado por defecto","Documented by Microsoft; on by default"],["El juego no baja de volumen en las llamadas","Game volume doesn\u0027t drop during calls"],["Por defecto, Windows baja un 80 % el resto de sonidos cuando detecta una llamada, y en muchas partidas con Discord dejas de oír los pasos. Con esto el juego se oye siempre igual.","By default, Windows lowers other sounds by 80% when it detects a call, and in many matches with Discord you stop hearing footsteps. With this the game always sounds the same."],["Windows atenúa el audio en las llamadas por defecto","Windows lowers audio during calls by default"],["Sin inicio rápido (apagar es apagar de verdad)","No Fast Startup (shutting down really shuts down)"],["Con el inicio rápido, apagar el PC guarda el estado de Windows y de los drivers en el disco y lo recupera al encender, así que los fallos y fugas de memoria se arrastran días. Sin él, cada encendido es limpio. El arranque tarda unos segundos más.","With Fast Startup, shutting down saves the state of Windows and its drivers to disk and restores it at startup, so glitches and memory leaks carry over for days. Without it, every startup is clean. Booting takes a few seconds longer."],["Inicio rápido activado","Fast Startup on"],["Windows Update no cambia tus drivers","Windows Update doesn\u0027t change your drivers"],["Windows Update a veces sustituye el driver de la gráfica que instalaste tú por uno más antiguo o genérico, y pierdes rendimiento sin darte cuenta. Con esto deja de instalar drivers; las actualizaciones de seguridad siguen igual. Los drivers los actualizas tú desde la página Actualizaciones o la web del fabricante.","Windows Update sometimes replaces the graphics driver you installed with an older or generic one, and you lose performance without noticing. With this it stops installing drivers; security updates stay the same. You update drivers yourself from the Updates page or the manufacturer\u0027s website."],["Sin efectos de transparencia","No transparency effects"],["La barra de tareas, el menú Inicio y las ventanas dejan de ser translúcidos. Ahorra un poco de procesador y de gráfica en segundo plano; el cambio es sobre todo estético.","The taskbar, Start menu and windows stop being translucent. It saves a little CPU and GPU in the background; the change is mostly cosmetic."],["Transparencias activadas","Transparency on"],["Sin marca de último acceso en el disco","No last-access timestamps on the disk"],["Windows apunta la fecha de último acceso cada vez que se lee un archivo, lo que añade escrituras al disco al cargar juegos con miles de archivos. Microsoft indica que desactivarlo acelera el acceso a archivos; algún programa de copias de seguridad antiguo podría usar esa fecha.","Windows records the last-access date every time a file is read, which adds disk writes when loading games with thousands of files. Microsoft states that turning it off speeds up file access; some old backup programs might use that date."],["Detectado: marca de último acceso activada","Detected: last-access timestamps on"],["ajustes avanzados","advanced settings"]]}
'@
Initialize-I18n

# ======================= Registro =======================
function Get-RegValue($Path, $Name) { try { return (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name } catch { return $null } }
function Set-RegValue($Path, $Name, $Value, $Type = 'DWord') {
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null
    } catch {
        # Plan B: algunas claves (p. ej. políticas en builds recientes de Windows 11) rechazan el proveedor de PowerShell pero aceptan reg.exe
        $first = $_.Exception.Message
        $key = "$Path" -replace '^HKLM:\\?', 'HKLM\' -replace '^HKCU:\\?', 'HKCU\'
        $t = switch ($Type) { 'String' { 'REG_SZ' } 'Binary' { 'REG_BINARY' } 'QWord' { 'REG_QWORD' } default { 'REG_DWORD' } }
        $d = if ($Type -eq 'Binary') { (@($Value) | ForEach-Object { '{0:X2}' -f [byte]$_ }) -join '' }
             elseif ($t -eq 'REG_DWORD') { $n = [int64]$Value; if ($n -lt 0) { $n += 4294967296 }; '0x{0:x}' -f $n }
             else { "$Value" }
        $out = & { $ErrorActionPreference = 'Continue'; & reg.exe add $key /v $Name /t $t /d $d /f 2>&1 }
        if ($LASTEXITCODE -ne 0) {
            $why = (@($out) | ForEach-Object { "$_".Trim() } | Where-Object { $_ -and $_ -notmatch 'RemoteException' } | ForEach-Object { $_ -replace '^ERROR:\s*', '' }) -join ' '
            throw "Windows no deja cambiar $Name en este PC ($first / $why)"
        }
    }
}
function Remove-RegValue($Path, $Name) { Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue }

# ======================= Tareas programadas =======================
# Se consultan por COM: Get-ScheduledTask tarda ~0,7 s por tarea y esto apenas unos milisegundos.
$script:TaskSvc = $null
function Get-TaskCom($fullPath) {
    try {
        if (-not $script:TaskSvc) { $script:TaskSvc = New-Object -ComObject Schedule.Service; $script:TaskSvc.Connect() }
        $folder = Split-Path $fullPath; if (-not $folder) { $folder = '\' }
        return $script:TaskSvc.GetFolder($folder).GetTask((Split-Path $fullPath -Leaf))
    } catch { return $null }
}
function Test-TaskExists($name) { return [bool](Get-TaskCom "\$name") }

# ======================= INI de Fortnite =======================
function Read-Ini {
    $bytes = [IO.File]::ReadAllBytes($FnIni)
    $enc = New-Object Text.UTF8Encoding($false)
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) { $enc = [Text.Encoding]::Unicode }
    elseif ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { $enc = New-Object Text.UTF8Encoding($true) }
    $text = [IO.File]::ReadAllText($FnIni)
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($l in ($text -split "`r?`n")) { $lines.Add($l) }
    while ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -eq '') { $lines.RemoveAt($lines.Count - 1) }
    return @{ Lines = $lines; Encoding = $enc }
}
function Write-Ini($ini) { [IO.File]::WriteAllText($FnIni, (($ini.Lines -join "`r`n") + "`r`n"), $ini.Encoding) }
function Get-IniValue($Key) {
    if (-not (Test-Path $FnIni)) { return $null }
    $rx = '^' + [regex]::Escape($Key) + '=(.*)$'
    foreach ($l in (Read-Ini).Lines) { if ($l -match $rx) { return $Matches[1] } }
    return $null
}
function Set-IniValue($Key, $Value, $Section) {
    $ini = Read-Ini; $rx = '^' + [regex]::Escape($Key) + '='; $found = $false
    for ($i = 0; $i -lt $ini.Lines.Count; $i++) { if ($ini.Lines[$i] -match $rx) { $ini.Lines[$i] = "$Key=$Value"; $found = $true } }
    if (-not $found) {
        $idx = $ini.Lines.IndexOf("[$Section]")
        if ($idx -ge 0) { $ini.Lines.Insert($idx + 1, "$Key=$Value") }
        else { $ini.Lines.Add(''); $ini.Lines.Add("[$Section]"); $ini.Lines.Add("$Key=$Value") }
    }
    Write-Ini $ini
}
function Assert-FortniteClosed {
    if (-not (Test-Path $FnIni)) { throw 'No encuentro la configuración de Fortnite (abre el juego una vez).' }
    if (Get-Process -Name 'FortniteClient-Win64-Shipping' -ErrorAction SilentlyContinue) { throw 'Fortnite está abierto. Ciérralo del todo y vuelve a aplicar.' }
    if ((Get-Item $FnIni).IsReadOnly) { throw 'GameUserSettings.ini está en solo lectura.' }
    $copy = Join-Path $DataDir 'GameUserSettings.original.ini'
    if (-not (Test-Path $copy)) { Copy-Item $FnIni $copy }
}

# ======================= Logo de la app (Miki Tweaks) =======================
function New-LogoBitmap([int]$s) {
    # Dibuja el logo a 256 px y lo escala: «M» inclinada con líneas de velocidad sobre un degradado violeta-cian
    $big = New-Object Drawing.Bitmap 256, 256
    $g = [Drawing.Graphics]::FromImage($big); $g.SmoothingMode = 'AntiAlias'; $g.InterpolationMode = 'HighQualityBicubic'; $g.Clear([Drawing.Color]::Transparent)
    $rr = { param($x, $y, $w, $h, $r) $p = New-Object Drawing.Drawing2D.GraphicsPath; $p.AddArc($x, $y, $r, $r, 180, 90); $p.AddArc($x + $w - $r, $y, $r, $r, 270, 90); $p.AddArc($x + $w - $r, $y + $h - $r, $r, $r, 0, 90); $p.AddArc($x, $y + $h - $r, $r, $r, 90, 90); $p.CloseFigure(); $p }
    # Plano: cuadrado lima y «M» inclinada en casi negro con líneas de velocidad. Sin degradados ni brillos.
    $bg = & $rr 4 4 248 248 64
    $g.FillPath((New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(203, 242, 74))), $bg)
    $ink = [Drawing.Color]::FromArgb(12, 12, 13)
    $pts = @(@(58, 196), @(58, 62), @(100, 62), @(130, 120), @(160, 62), @(202, 62), @(202, 196), @(164, 196), @(164, 132), @(140, 176), @(120, 176), @(96, 132), @(96, 196))
    $mk = { param($dx, $dy) [Drawing.PointF[]]@($pts | ForEach-Object { New-Object Drawing.PointF ([float](134 + 0.88 * ($_[0] - 0.2 * $_[1] + 26 - 130) + $dx)), ([float](129 + 0.88 * ($_[1] - 129) + $dy)) }) }
    $g.FillPolygon((New-Object Drawing.SolidBrush $ink), (& $mk 0 0))
    $pen = New-Object Drawing.Pen $ink, 10
    $pen.StartCap = 'Round'; $pen.EndCap = 'Round'
    $g.DrawLine($pen, 30, 108, 56, 108); $g.DrawLine($pen, 22, 136, 50, 136); $g.DrawLine($pen, 28, 164, 44, 164)
    $g.Dispose()
    if ($s -eq 256) { return $big }
    $out = New-Object Drawing.Bitmap $s, $s
    $g2 = [Drawing.Graphics]::FromImage($out); $g2.InterpolationMode = 'HighQualityBicubic'; $g2.SmoothingMode = 'AntiAlias'; $g2.PixelOffsetMode = 'HighQuality'
    $g2.DrawImage($big, 0, 0, $s, $s); $g2.Dispose(); $big.Dispose()
    return $out
}
function New-AppIcon {
    $png = Join-Path $DataDir 'logo.png'; $ico = Join-Path $DataDir 'logo.ico'; $ver = Join-Path $DataDir 'logo.v2'
    if ((Test-Path $png) -and (Test-Path $ico) -and (Test-Path $ver)) { return }   # logo.v2: el logo plano nuevo ya está generado
    Set-Content -Path $ver -Value '2' -ErrorAction SilentlyContinue
    $b = New-LogoBitmap 256; $b.Save($png, [Drawing.Imaging.ImageFormat]::Png); $b.Dispose()
    # .ico con varios tamaños para que se vea nítido en el escritorio, la barra de tareas y el menú Inicio
    $sizes = @(256, 64, 48, 32, 24, 16); $imgs = @()
    foreach ($z in $sizes) { $bm = New-LogoBitmap $z; $ms0 = New-Object IO.MemoryStream; $bm.Save($ms0, [Drawing.Imaging.ImageFormat]::Png); $bm.Dispose(); $imgs += , $ms0.ToArray() }
    $ms = New-Object IO.MemoryStream; $bw = New-Object IO.BinaryWriter $ms
    $bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]$sizes.Count)
    $off = 6 + 16 * $sizes.Count
    for ($i = 0; $i -lt $sizes.Count; $i++) {
        $z = $sizes[$i]; $bw.Write([byte]$(if ($z -ge 256) { 0 } else { $z })); $bw.Write([byte]$(if ($z -ge 256) { 0 } else { $z }))
        $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([uint16]1); $bw.Write([uint16]32); $bw.Write([uint32]$imgs[$i].Length); $bw.Write([uint32]$off); $off += $imgs[$i].Length
    }
    foreach ($d in $imgs) { $bw.Write($d) }
    $bw.Flush(); [IO.File]::WriteAllBytes($ico, $ms.ToArray()); $bw.Dispose()
}

# ======================= Escáner (se ejecuta en segundo plano) =======================
$ScanScript = {
    param($sync)
    $ErrorActionPreference = 'SilentlyContinue'
    function Step($p, $msg) { $sync.Progress = $p; $sync.Step = $msg; [void]$sync.Steps.Add($msg); Start-Sleep -Milliseconds 90 }
    $f = @{}
    try {
        Step 4 'Identificando el equipo'
        $os = Get-CimInstance Win32_OperatingSystem; $cs = Get-CimInstance Win32_ComputerSystem
        $f.OS = "$($os.Caption -replace 'Microsoft ', '') · build $($os.BuildNumber)"
        $f.Maker = ("$($cs.Manufacturer)" -replace 'Micro-Star International Co\., Ltd\.', 'MSI' -replace ' Inc\.?| Corporation| Co\., Ltd\.', '').Trim()
        $f.Model = "$($cs.Model)".Trim()

        Step 14 'Analizando el procesador'
        $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
        $f.CPU = ("$($cpu.Name)" -replace '\(R\)|\(TM\)|\d+th Gen |CPU|@.*$', '' -replace '\s+', ' ').Trim()
        $f.Cores = $cpu.NumberOfCores; $f.Threads = $cpu.NumberOfLogicalProcessors

        Step 26 'Analizando la memoria RAM'
        $mods = @(Get-CimInstance Win32_PhysicalMemory)
        $f.RamGB = [math]::Round((($mods | Measure-Object Capacity -Sum).Sum) / 1GB)
        $f.RamModules = $mods.Count
        $f.RamModGB = if ($mods.Count) { [math]::Round($mods[0].Capacity / 1GB) } else { 0 }
        $f.RamSpeed = ($mods | Select-Object -First 1).ConfiguredClockSpeed
        $f.RamType = switch (($mods | Select-Object -First 1).SMBIOSMemoryType) { 34 { 'DDR5' } 26 { 'DDR4' } 24 { 'DDR3' } default { '' } }
        # Velocidad que admiten los módulos: la que da Windows o la del perfil XMP/EXPO deducida del modelo (F4-3600C16, CMK16GX4M2B3200C16, KF436C17...)
        $f.RamRated = [int](($mods | Measure-Object Speed -Maximum).Maximum)
        foreach ($pn in @($mods | ForEach-Object { "$($_.PartNumber)".Trim() })) {
            $x = 0
            if ($pn -match '(\d{4})C\d{2}') { $x = [int]$Matches[1] } elseif ($pn -match '^KF[45](\d{2})C') { $x = [int]$Matches[1] * 100 }
            if ($x -ge 1600 -and $x -le 10000 -and $x -gt $f.RamRated) { $f.RamRated = $x }
        }

        Step 40 'Detectando gráficas y pantallas'
        $vcs = @(Get-CimInstance Win32_VideoController)
        $d = $vcs | Where-Object { $_.Name -match 'NVIDIA|Radeon RX|Radeon Pro|Arc\(TM\) A' } | Select-Object -First 1
        $i = $vcs | Where-Object { $_.Name -match 'Intel.*(UHD|Iris|Graphics)|AMD Radeon\(TM\) Graphics|Radeon Graphics' } | Select-Object -First 1
        $main = if ($d) { $d } else { $i }
        $f.GPU = ("$($main.Name)" -replace '\(R\)|\(TM\)', '').Trim()
        $f.GPUDriver = "$($main.DriverVersion)"
        $f.GPUDriverDate = if ($main.DriverDate) { ([datetime]$main.DriverDate).ToString('dd/MM/yyyy') } else { '' }
        $f.IsNvidia = [bool]($d -and $d.Name -match 'NVIDIA')
        $f.Hybrid = [bool]($d -and $i)
        $f.dGPUHz = if ($d) { [int]$d.CurrentRefreshRate } else { 0 }
        $f.dGPURes = if ($d -and $d.CurrentHorizontalResolution) { "$($d.CurrentHorizontalResolution)x$($d.CurrentVerticalResolution)" } else { '' }
        $f.iGPUHz = if ($i) { [int]$i.CurrentRefreshRate } else { 0 }
        $f.MainHz = if ($main) { [int]$main.CurrentRefreshRate } else { 0 }
        if ($f.IsNvidia) {
            $smi = "$env:SystemRoot\System32\nvidia-smi.exe"
            if (Test-Path $smi) { $f.NvDriver = "$(& $smi --query-gpu=driver_version --format=csv,noheader | Select-Object -First 1)".Trim() }
        }

        Step 52 'Comprobando energía y almacenamiento'
        $bat = Get-CimInstance Win32_Battery | Select-Object -First 1
        $f.Laptop = [bool]$bat
        $f.OnAC = (-not $bat) -or ($bat.BatteryStatus -ne 1)
        $f.BatteryPct = if ($bat) { [int]$bat.EstimatedChargeRemaining } else { $null }
        $ap = (powercfg /getactivescheme) -join ' '
        if ($ap -match '\(([^)]+)\)') { $f.PowerPlan = $Matches[1] }
        $sd = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$env:SystemDrive'"
        $f.DiskFreeGB = [math]::Round($sd.FreeSpace / 1GB); $f.DiskSizeGB = [math]::Round($sd.Size / 1GB)
        $pd = Get-PhysicalDisk | Select-Object -First 1
        $f.Disk = ("$($pd.FriendlyName)" -replace '^NVMe ', '').Trim(); $f.DiskBus = "$($pd.BusType)"; $f.DiskType = "$($pd.MediaType)"

        Step 64 'Buscando juegos competitivos'
        $roots = New-Object System.Collections.Generic.List[string]
        $steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam').SteamPath
        if ($steam) {
            $steam = $steam -replace '/', '\'
            $roots.Add((Join-Path $steam 'steamapps\common'))
            $vdf = Join-Path $steam 'steamapps\libraryfolders.vdf'
            if (Test-Path $vdf) {
                foreach ($m in [regex]::Matches([IO.File]::ReadAllText($vdf), '"path"\s+"([^"]+)"')) { $roots.Add((Join-Path ($m.Groups[1].Value -replace '\\\\', '\') 'steamapps\common')) }
            }
        }
        foreach ($drv in @(Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free })) {
            foreach ($sub in 'Riot Games', 'Games', 'SteamLibrary\steamapps\common', 'Epic Games', 'Program Files\Epic Games', 'Program Files\EA Games',
                'Program Files\Electronic Arts', 'Program Files (x86)\Ubisoft\Ubisoft Game Launcher\games', 'Program Files (x86)', 'Program Files') { $roots.Add((Join-Path $drv.Root $sub)) }
        }
        $epic = @{}
        Get-ChildItem 'C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests\*.item' | ForEach-Object {
            try { $j = Get-Content $_.FullName -Raw | ConvertFrom-Json; $epic["$($j.DisplayName)"] = "$($j.InstallLocation)" } catch {} }
        $riot = @{}
        Get-ChildItem 'C:\ProgramData\Riot Games\Metadata\*\*.product_settings.yaml' | ForEach-Object {
            $m = Select-String -Path $_.FullName -Pattern 'product_install_full_path:\s*"?([^"]+)"?' | Select-Object -First 1
            if ($m) { $riot[$_.Directory.Name] = ($m.Matches[0].Groups[1].Value -replace '/', '\').Trim() } }
        $running = @{}
        Get-Process | Where-Object { $_.Path } | ForEach-Object { $running["$($_.Name).exe".ToLower()] = $_.Path }
        $games = New-Object System.Collections.Generic.List[object]
        foreach ($g in $sync.GameDefs) {
            $cand = New-Object System.Collections.Generic.List[string]
            foreach ($e in $g.Exes) { if ($running[$e.ToLower()]) { $cand.Add($running[$e.ToLower()]) } }
            if ($g.Epic) { foreach ($k in @($epic.Keys)) { if ($k -like "$($g.Epic)*") { foreach ($r in $g.EpicRel) { $cand.Add((Join-Path $epic[$k] $r)) } } } }
            if ($g.Riot -and $riot[$g.Riot]) { foreach ($r in $g.RiotRel) { $cand.Add((Join-Path $riot[$g.Riot] $r)) } }
            foreach ($root in $roots) { foreach ($r in $g.Rel) { $cand.Add((Join-Path $root $r)) } }
            $seen = @{}; $found = New-Object System.Collections.Generic.List[string]
            foreach ($c in $cand) {
                if ($seen[$c.ToLower()]) { continue }; $seen[$c.ToLower()] = $true
                if (Test-Path -LiteralPath $c) { $found.Add($c) }
            }
            if ($found.Count) {
                $isRun = $false; foreach ($e in $g.Exes) { if ($running[$e.ToLower()]) { $isRun = $true } }
                $games.Add(@{ Id = $g.Id; Paths = $found.ToArray(); Running = $isRun })
            }
        }
        $f.Games = $games.ToArray()
        $fnG = $games | Where-Object { $_.Id -eq 'fortnite' } | Select-Object -First 1
        $f.FnInstalled = [bool]$fnG
        $f.FnExe = if ($fnG) { $fnG.Paths[0] } else { 'C:\Program Files\Epic Games\Fortnite\FortniteGame\Binaries\Win64\FortniteClient-Win64-Shipping.exe' }
        $ini = Join-Path $env:LOCALAPPDATA 'FortniteGame\Saved\Config\WindowsClient\GameUserSettings.ini'
        $f.FnIni = Test-Path $ini
        $f.FnRunning = [bool](Get-Process -Name 'FortniteClient-Win64-Shipping' -ErrorAction SilentlyContinue)
        if ($f.FnIni) {
            $txt = [IO.File]::ReadAllText($ini)
            foreach ($k in 'PreferredRHI', 'PreferredFeatureLevel', 'bDisableMouseAcceleration', 'LatencyTweak2', 'FullscreenMode', 'FrameRateLimit') {
                if ($txt -match "(?m)^$k=(.*)$") { $f["Fn_$k"] = $Matches[1].Trim() }
            }
        }

        Step 76 'Revisando seguridad y servicios'
        $dg = Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard Win32_DeviceGuard
        $f.VBS = ($dg.VirtualizationBasedSecurityStatus -eq 2)
        $f.HVCI = ((Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity').Enabled -eq 1)
        $f.Nahimic = [bool](Get-Service NahimicService)
        $f.TimerTool = [bool](Get-Process | Where-Object Name -match 'TimerResolution|ISLC') -or [bool](Get-CimInstance Win32_StartupCommand | Where-Object Name -match 'TimerResolution|ISLC')

        Step 86 'Analizando la red'
        $up = @(Get-NetAdapter -Physical | Where-Object Status -eq 'Up')
        $wired = $up | Where-Object { $_.MediaType -eq '802.3' -and $_.InterfaceDescription -notmatch 'Virtual|Bluetooth' } | Select-Object -First 1
        if (-not $wired) { $wired = Get-NetAdapter -Physical | Where-Object { $_.MediaType -eq '802.3' -and $_.InterfaceDescription -notmatch 'Virtual|Bluetooth' } | Select-Object -First 1 }
        if ($wired) { $f.NicName = $wired.Name; $f.NicDesc = "$($wired.InterfaceDescription)"; $f.NicSpeed = "$($wired.LinkSpeed)"; $f.NicUp = ($wired.Status -eq 'Up') }
        $f.WifiOnly = (-not $f.NicUp) -and [bool]($up | Where-Object { "$($_.MediaType)" -match '802\.11' })

        Step 90 'Revisando apps y funciones de Windows'
        $f.Appx = @(Get-AppxPackage | ForEach-Object { $_.Name })
        $f.EdgeInstalled = (Test-Path "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe") -or (Test-Path "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe")
        $f.WinBuild = [Environment]::OSVersion.Version.Build

        Step 94 'Revisando programas de inicio'
        $f.StartupNames = @((Get-Item 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run').Property)
        $f.StartupNamesLM = @((Get-Item 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -ErrorAction SilentlyContinue).Property)
        $f.StartupNamesLM32 = @((Get-Item 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run' -ErrorAction SilentlyContinue).Property)

        Step 97 'Detectando periféricos y salud del hardware'
        # ---- Periféricos: ratones, teclados, mandos (USB y Bluetooth) ----
        $pnp = @(Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue)
        # Nombre que da cada USB (BusReportedDeviceDesc), leído UNA vez por CIM directo.
        # Antes se pedía con Get-PnpDeviceProperty dispositivo a dispositivo (y dentro de otro bucle): ~25 s de escaneo.
        $usbAll = @($pnp | Where-Object { "$($_.InstanceId)" -like 'USB\VID_*' })
        $busDesc = @{}
        foreach ($u in $usbAll) {
            try {
                $pr = @((Invoke-CimMethod -InputObject $u -MethodName GetDeviceProperties -Arguments @{ devicePropertyKeys = [string[]]@('DEVPKEY_Device_BusReportedDeviceDesc') } -ErrorAction Stop).deviceProperties)
                if ($pr.Count -and $pr[0].Data) { $busDesc["$($u.InstanceId)"] = "$($pr[0].Data)" }
            } catch {}
        }
        $devs = [ordered]@{}
        foreach ($d in $pnp) {
            $kind = switch ($d.Class) { 'Mouse' { 'Ratón' } 'Keyboard' { 'Teclado' } 'XnaComposite' { 'Mando' } 'XboxComposite' { 'Mando' } default { $null } }
            if (-not $kind -and $d.Class -eq 'HIDClass' -and "$($d.FriendlyName)" -match 'game controller|controlador de juego|gamepad|DualSense|Wireless Controller' -and $d.InstanceId -notmatch '^SWD\\') { $kind = 'Mando' }
            if (-not $kind) { continue }
            $vid = ''; $pid2 = ''
            if ($d.InstanceId -match 'VID_([0-9A-F]{4})&PID_([0-9A-F]{4})') { $vid = $Matches[1]; $pid2 = $Matches[2] }
            elseif ($d.InstanceId -match 'VID&02([0-9A-F]{4})_PID&([0-9A-F]{4})') { $vid = $Matches[1]; $pid2 = $Matches[2] }
            $bus = if ($d.InstanceId -match '\{0000[0-9A-F]{4}-0000-1000-8000-00805F9B34FB\}|BTH') { 'Bluetooth' } elseif ($vid) { 'USB' } else { 'Integrado' }
            $key = if ($vid) { "$vid`:$pid2" } else { "int:$kind" }
            if ($devs.Contains($key)) { if ($devs[$key].Kinds -notcontains $kind) { $devs[$key].Kinds += $kind }; continue }
            $name = $null
            if ($vid -and $bus -eq 'USB') {
                $usb = $usbAll | Where-Object { $_.InstanceId -like "USB\VID_$vid&PID_$pid2\*" } | Select-Object -First 1
                if ($usb -and $busDesc["$($usb.InstanceId)"]) { $name = $busDesc["$($usb.InstanceId)"] }
            }
            if ($bus -eq 'Bluetooth') {
                $bt = $pnp | Where-Object { $_.Class -eq 'Bluetooth' -and $_.InstanceId -match '^BTH(LE|ENUM)\\DEV_' -and $d.InstanceId -match ($_.InstanceId -replace '^.*DEV_([0-9A-F]{12}).*$', '$1') } | Select-Object -First 1
                if ($bt) { $name = "$($bt.FriendlyName)" }
            }
            if (-not $name) { $name = if ($bus -eq 'Integrado') { "$kind del portátil" } else { "$($d.FriendlyName)" } }
            $devs[$key] = @{ Vid = $vid; Pid = $pid2; Name = $name.Trim(); Kinds = @($kind); Bus = $bus }
        }
        # Audio externo: auriculares, cascos y micrófonos (sin los integrados ni los virtuales)
        $seenA = @{}
        foreach ($a in @($pnp | Where-Object { $_.Class -eq 'AudioEndpoint' })) {
            $fn = "$($a.FriendlyName)"
            $inner = if ($fn -match '\(([^()]+)\)\s*$') { $Matches[1] } else { $fn }
            $inner = ($inner -replace '^\d+-\s*', '' -replace '\s*Hands-Free$', '').Trim()
            if ($inner -match 'Realtek|Intel|NVIDIA|AMD High Definition|High Definition Audio|Virtual|WO Mic|Steam Streaming|Voicemod|Broadcast|Oculus|Smart Sound|^\d+\w+$') { continue }
            if ($seenA[$inner]) { continue }; $seenA[$inner] = $true
            $k2 = if ($fn -match 'Auricular|Headphone|Headset|Cascos') { 'Auriculares' } elseif ($fn -match 'Micr|Microphone') { 'Micrófono' } else { 'Audio' }
            $bus = if ($a.InstanceId -match 'BTH') { 'Bluetooth' } elseif (@($pnp | Where-Object { $_.Class -eq 'Bluetooth' -and "$($_.FriendlyName)" -eq $inner }).Count) { 'Bluetooth' } elseif ($a.InstanceId -match 'USB') { 'USB' } else { 'Audio' }
            $vid = ''; $usbN = $usbAll | Where-Object { "$($_.FriendlyName)" -ne '' -and $busDesc["$($_.InstanceId)"] -eq $inner } | Select-Object -First 1
            if ($usbN -and $usbN.InstanceId -match 'VID_([0-9A-F]{4})&PID_([0-9A-F]{4})') { $vid = $Matches[1]; $bus = 'USB' }
            $devs["audio:$inner"] = @{ Vid = $vid; Pid = ''; Name = $inner; Kinds = @($k2); Bus = $bus }
        }
        foreach ($v in @($devs.Values)) {
            # Los receptores y teclados gaming exponen varias interfaces (ratón + teclado): se muestra la principal
            if ($v.Kinds.Count -gt 1) {
                if ($v.Name -match 'Dongle|Mouse|Receiver|Receptor|Rat') { $v.Kinds = @('Ratón') }
                elseif ($v.Name -match 'Keyboard|Teclado|Wooting|TKL|\d+HE\b|Huntsman|Apex') { $v.Kinds = @('Teclado') }
            }
        }
        $f.Peripherals = @($devs.Values)
        $f.InstalledApps = @(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue | ForEach-Object { "$($_.DisplayName)" } | Where-Object { $_ })

        # ---- BIOS y placa ----
        $bios = Get-CimInstance Win32_BIOS
        $f.BiosVersion = "$($bios.SMBIOSBIOSVersion)"
        $f.BiosDate = if ($bios.ReleaseDate) { ([datetime]$bios.ReleaseDate).ToString('dd/MM/yyyy') } else { '' }
        $bb = Get-CimInstance Win32_BaseBoard; $f.Board = ("$($bb.Manufacturer -replace 'Micro-Star International Co\., Ltd\.', 'MSI') $($bb.Product)").Trim()

        # ---- Discos (SMART) ----
        $f.Disks = @(Get-PhysicalDisk | ForEach-Object {
            $rc = $_ | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
            @{ Name = ("$($_.FriendlyName)" -replace '^NVMe ', '').Trim(); Media = "$($_.MediaType)"; Bus = "$($_.BusType)"; SizeGB = [math]::Round($_.Size / 1GB)
               Health = "$($_.HealthStatus)"; Wear = $rc.Wear; Temp = $rc.Temperature; Hours = $rc.PowerOnHours; ReadErr = $rc.ReadErrorsUncorrected } })

        # ---- Batería ----
        $des = (Get-CimInstance -Namespace root\wmi -ClassName BatteryStaticData -ErrorAction SilentlyContinue | Select-Object -First 1).DesignedCapacity
        $full = (Get-CimInstance -Namespace root\wmi -ClassName BatteryFullChargedCapacity -ErrorAction SilentlyContinue | Select-Object -First 1).FullChargedCapacity
        if ($des -and $full) {
            $f.BatteryHealth = [math]::Min(100, [math]::Round(100 * $full / $des)); $f.BatteryDesign = $des; $f.BatteryFull = $full
            $f.BatteryCycles = (Get-CimInstance -Namespace root\wmi -ClassName BatteryCycleCount -ErrorAction SilentlyContinue | Select-Object -First 1).CycleCount
        }

        # ---- Tiempo de arranque ----
        $ev = Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Diagnostics-Performance/Operational'; Id = 100 } -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($ev) {
            try { $x = [xml]$ev.ToXml(); $bt = ($x.Event.EventData.Data | Where-Object { $_.Name -eq 'BootTime' }).'#text'; if ($bt) { $f.BootSeconds = [math]::Round([int]$bt / 1000); $f.BootDate = $ev.TimeCreated.ToString('dd/MM/yyyy') } } catch {}
        }

        Step 100 'Calculando recomendaciones'
    } catch { $sync.Error = $_.Exception.Message }
    $sync.Facts = $f
    $sync.Done = $true
}

# ======================= Motor de tweaks =======================
$script:Tweaks = New-Object System.Collections.Generic.List[object]
function Add-Tweak([hashtable]$h) {
    foreach ($k in @{ Reboot = $false; Group = $null; OS = $null; Why = ''; Tier = 'Recomendado'; Applied = $false; HasBackup = $false; Toggle = $null; StatusText = $null; Card = $null }.GetEnumerator()) {
        if (-not $h.ContainsKey($k.Key)) { $h[$k.Key] = $k.Value }
    }
    $script:Tweaks.Add([pscustomobject]$h)
}

$RegCheck = { param($t)
    foreach ($v in $t.Data) {
        $cur = Get-RegValue $v.Path $v.Name
        if ($null -eq $cur) { return $false }
        $a = "$cur"; $e = "$($v.Value)"
        if ($e -match '^-\d+$') { $e = "$([int64]$e + 4294967296)" }
        if ($cur -is [int] -and $cur -lt 0) { $a = "$([int64]$cur + 4294967296)" }
        if ($a -ne $e) { return $false }
    }
    return $true }
$RegApply = { param($t)
    $i = 0
    foreach ($v in $t.Data) {
        $cur = Get-RegValue $v.Path $v.Name
        Backup-Item "$($t.Id)#$i" @{ absent = ($null -eq $cur); value = $cur }
        Set-RegValue $v.Path $v.Name $v.Value $v.Type; $i++
    } }
$RegRevert = { param($t)
    $i = 0; $any = $false
    foreach ($v in $t.Data) {
        $b = Get-BackupItem "$($t.Id)#$i"
        if ($null -ne $b) {
            if ($b.absent) { Remove-RegValue $v.Path $v.Name } else { Set-RegValue $v.Path $v.Name $b.value $v.Type }
            Clear-BackupItem "$($t.Id)#$i"; $any = $true
        }
        $i++
    }
    return $any }
$IniCheck = { param($t)
    if (-not (Test-Path $FnIni)) { return $false }
    foreach ($v in $t.Data) { if ("$(Get-IniValue $v.Key)" -ne "$($v.Value)") { return $false } }
    return $true }
$IniApply = { param($t)
    Assert-FortniteClosed; $i = 0
    foreach ($v in $t.Data) {
        $cur = Get-IniValue $v.Key
        Backup-Item "$($t.Id)#$i" @{ absent = ($null -eq $cur); value = $cur }
        Set-IniValue $v.Key $v.Value $v.Section; $i++
    } }
$IniRevert = { param($t)
    Assert-FortniteClosed; $i = 0; $any = $false
    foreach ($v in $t.Data) {
        $b = Get-BackupItem "$($t.Id)#$i"
        if ($null -ne $b) { if (-not $b.absent) { Set-IniValue $v.Key $b.value $v.Section }; Clear-BackupItem "$($t.Id)#$i"; $any = $true }
        $i++
    }
    return $any }

function RegV($Path, $Name, $Value, $Type = 'DWord') { @{ Path = $Path; Name = $Name; Value = $Value; Type = $Type } }
function IniV($Key, $Value, $Section = '/Script/FortniteGame.FortGameUserSettings') { @{ Key = $Key; Value = $Value; Section = $Section } }
function New-RegTweak([hashtable]$h, $Data) { $h.Data = $Data; $h.Check = $RegCheck; $h.Apply = $RegApply; $h.Revert = $RegRevert; Add-Tweak $h }
function New-IniTweak([hashtable]$h, $Data) { $h.Category = 'fortnite'; $h.Data = $Data; $h.Check = $IniCheck; $h.Apply = $IniApply; $h.Revert = $IniRevert; Add-Tweak $h }

$StartupKnown = @{
    'Steam'                      = @('Steam', $true, 'Cliente de Steam. Se abre solo cuando lo necesites.')
    'RiotClient'                 = @('Riot Client', $true, 'Vanguard sigue arrancando igual; solo se quita el launcher.')
    'GalaxyClient'               = @('GOG Galaxy', $true, 'Launcher que no hace falta nada más encender.')
    'GogGalaxy'                  = @('GOG Galaxy', $true, 'Launcher que no hace falta nada más encender.')
    'com.blitz.app'              = @('Blitz', $true, 'App compañera de LoL/Valorant que consume recursos en segundo plano.')
    'electron.app.CurseForge'    = @('CurseForge', $true, 'Gestor de mods; no hace falta al encender.')
    'OneDrive'                   = @('OneDrive', $true, 'Sincroniza en segundo plano y puede usar disco y red en mitad de una partida.')
    'Opera GX Stable'            = @('Opera GX', $true, 'Navegador abierto en segundo plano.')
    'Opera GX Browser Assistant' = @('Asistente de Opera GX', $true, 'Proceso extra del navegador.')
    'BakkesMod'                  = @('BakkesMod', $true, 'Solo hace falta con Rocket League abierto.')
    'EpicGamesLauncher'          = @('Epic Games Launcher', $false, 'Lo necesitas para Fortnite, pero puede arrancar cuando lo abras tú.')
    'Discord'                    = @('Discord', $false, 'Déjalo si lo usas siempre al jugar.')
    'Pulsar Fusion'              = @('Pulsar Fusion', $false, 'Software del ratón. Quítalo solo si tu configuración está guardada en el ratón.')
    'VoicemodV3'                 = @('Voicemod', $false, 'Cambiador de voz. Quítalo si no lo usas a diario.')
    'FACEIT'                     = @('FACEIT', $false, 'Ábrelo antes de jugar a CS2 si lo necesitas.')
    'EADM'                       = @('EA app', $true, 'Launcher de EA. Ábrelo cuando vayas a jugar.')
    'EA Desktop'                 = @('EA app', $true, 'Launcher de EA. Ábrelo cuando vayas a jugar.')
    'Battle.net'                 = @('Battle.net', $true, 'Launcher de Blizzard. Ábrelo cuando vayas a jugar.')
    'UbisoftConnect'             = @('Ubisoft Connect', $true, 'Launcher de Ubisoft. Ábrelo cuando vayas a jugar.')
    'Ubisoft Game Launcher'      = @('Ubisoft Connect', $true, 'Launcher de Ubisoft. Ábrelo cuando vayas a jugar.')
    'Overwolf'                   = @('Overwolf', $true, 'Plataforma de overlays que consume recursos en segundo plano.')
    'Wallpaper Engine'           = @('Wallpaper Engine', $false, 'Fondos animados: usan GPU. Se pausa sola en pantalla completa; quítalo si juegas en ventana.')
    'Spotify'                    = @('Spotify', $false, 'Quítalo solo si no lo usas al encender.')
    'CCleaner Smart Cleaning'    = @('CCleaner', $true, 'Monitor en segundo plano de CCleaner.')
    'CCleanerMonitoring'         = @('CCleaner', $true, 'Monitor en segundo plano de CCleaner.')
    'AdobeAAMUpdater-1.0'        = @('actualizador de Adobe', $true, 'Busca actualizaciones de Adobe en cada arranque.')
    'Adobe Creative Cloud'       = @('Adobe Creative Cloud', $false, 'Quítalo si no usas Adobe a diario.')
    'Teams'                      = @('Microsoft Teams', $false, 'Déjalo si lo usas para trabajar.')
    'com.squirrel.Teams.Teams'   = @('Microsoft Teams (clásico)', $false, 'Déjalo si lo usas para trabajar.')
    'Skype for Desktop'          = @('Skype', $true, 'Servicio cerrado por Microsoft.')
    'iTunesHelper'               = @('iTunes Helper', $true, 'Solo sirve al conectar un iPhone.')
    'GoogleDriveFS'              = @('Google Drive', $false, 'Sincronización de archivos: déjalo si lo usas.')
    'Dropbox'                    = @('Dropbox', $false, 'Sincronización de archivos: déjalo si lo usas.')
    'Opera Browser Assistant'    = @('Asistente de Opera', $true, 'Proceso extra del navegador.')
    'Zoom'                       = @('Zoom', $false, 'Quítalo si no tienes reuniones a diario.')
}

# ======================= Limpieza de Windows =======================
# Lista basada en lo que quitan por defecto Win11Debloat y WinUtil, en su versión prudente.
# Nunca se tocan: Xbox, Microsoft Store, Defender, Windows Update, Hyper-V, WSL, Docker, Bluetooth.
$BloatApps = @(
    @{ Pkg = 'Clipchamp.Clipchamp'; Name = 'Clipchamp'; Desc = 'Editor de vídeo preinstalado.'; Rec = $true },
    @{ Pkg = 'Microsoft.BingNews'; Name = 'Noticias'; Desc = 'App de noticias de Microsoft Start.'; Rec = $true },
    @{ Pkg = 'Microsoft.BingWeather'; Name = 'El Tiempo'; Desc = 'App del tiempo de Microsoft Start.'; Rec = $true },
    @{ Pkg = 'Microsoft.BingSearch'; Name = 'Búsqueda de Bing'; Desc = 'Componente que mete resultados de Bing en Windows.'; Rec = $true },
    @{ Pkg = 'Microsoft.Getstarted'; Name = 'Consejos'; Desc = 'App de consejos y novedades de Windows.'; Rec = $true },
    @{ Pkg = 'Microsoft.MicrosoftSolitaireCollection'; Name = 'Solitaire Collection'; Desc = 'Juegos de cartas con anuncios.'; Rec = $true },
    @{ Pkg = 'Microsoft.People'; Name = 'Contactos'; Desc = 'App de contactos antigua.'; Rec = $true },
    @{ Pkg = 'Microsoft.WindowsMaps'; Name = 'Mapas'; Desc = 'App de mapas de Windows.'; Rec = $true },
    @{ Pkg = 'Microsoft.WindowsFeedbackHub'; Name = 'Centro de opiniones'; Desc = 'Para enviar comentarios a Microsoft.'; Rec = $true },
    @{ Pkg = 'Microsoft.Todos'; Name = 'Microsoft To Do'; Desc = 'App de tareas.'; Rec = $true },
    @{ Pkg = 'Microsoft.ZuneVideo'; Name = 'Películas y TV'; Desc = 'Reproductor de vídeo antiguo (el nuevo Reproductor multimedia se queda).'; Rec = $true },
    @{ Pkg = 'Microsoft.MixedReality.Portal'; Name = 'Portal de realidad mixta'; Desc = 'Solo sirve con gafas de realidad mixta de Windows.'; Rec = $true },
    @{ Pkg = 'Microsoft.Microsoft3DViewer'; Name = 'Visor 3D'; Desc = 'Visor de modelos 3D.'; Rec = $true },
    @{ Pkg = 'Microsoft.549981C3F5F10'; Name = 'Cortana'; Desc = 'Asistente retirado por Microsoft.'; Rec = $true },
    @{ Pkg = 'Microsoft.SkypeApp'; Name = 'Skype'; Desc = 'Servicio cerrado por Microsoft.'; Rec = $true },
    @{ Pkg = 'Microsoft.Windows.DevHome'; Name = 'Dev Home'; Desc = 'Panel para desarrolladores que Microsoft ha retirado. No afecta a Visual Studio, VS Code ni a tus herramientas.'; Rec = $true },
    @{ Pkg = 'MicrosoftCorporationII.MicrosoftFamily'; Name = 'Microsoft Family'; Desc = 'Control parental.'; Rec = $true },
    @{ Pkg = 'king.com.*'; Name = 'juegos de King (Candy Crush...)'; Desc = 'Juegos promocionales preinstalados.'; Rec = $true },
    @{ Pkg = '*TikTok*'; Name = 'TikTok'; Desc = 'App promocional preinstalada.'; Rec = $true },
    @{ Pkg = '*Disney*'; Name = 'Disney+'; Desc = 'App promocional preinstalada.'; Rec = $false },
    @{ Pkg = '*Instagram*'; Name = 'Instagram'; Desc = 'App promocional preinstalada.'; Rec = $false },
    @{ Pkg = '*Facebook*'; Name = 'Facebook'; Desc = 'App promocional preinstalada.'; Rec = $false },
    @{ Pkg = 'Microsoft.WindowsAlarms'; Name = 'Alarmas y reloj'; Desc = 'Alarmas, temporizador y cronómetro.'; Rec = $false },
    @{ Pkg = 'Microsoft.YourPhone'; Name = 'Enlace Móvil'; Desc = 'Conecta el móvil con el PC. Quítalo solo si no lo usas.'; Rec = $false },
    @{ Pkg = 'Microsoft.PowerAutomateDesktop'; Name = 'Power Automate'; Desc = 'Automatización de tareas. Quítalo solo si no lo usas.'; Rec = $false },
    @{ Pkg = 'MSTeams'; Name = 'Microsoft Teams'; Desc = 'Quítalo solo si no lo usas para el trabajo o las clases.'; Rec = $false },
    @{ Pkg = 'Microsoft.MicrosoftOfficeHub'; Name = 'App Microsoft 365'; Desc = 'Lanzador de Office. Word, Excel y compañía no se tocan.'; Rec = $false },
    @{ Pkg = 'Microsoft.OutlookForWindows'; Name = 'Outlook (nuevo)'; Desc = 'Cliente de correo nuevo de Windows.'; Rec = $false },
    @{ Pkg = 'Microsoft.Copilot'; Name = 'Copilot'; Desc = 'Asistente de IA de Microsoft.'; Rec = $false },
    @{ Pkg = 'SpotifyAB.SpotifyMusic'; Name = 'Spotify'; Desc = 'Quítalo solo si no lo usas.'; Rec = $false },
    @{ Pkg = 'Microsoft.MSPaint'; Name = 'Paint 3D'; Desc = 'Editor 3D retirado por Microsoft (el Paint normal se queda).'; Rec = $true },
    @{ Pkg = 'Microsoft.Print3D'; Name = 'Print 3D'; Desc = 'App para impresoras 3D.'; Rec = $true },
    @{ Pkg = 'Microsoft.3DBuilder'; Name = '3D Builder'; Desc = 'Editor de modelos 3D antiguo.'; Rec = $true },
    @{ Pkg = 'Microsoft.OneConnect'; Name = 'Planes móviles'; Desc = 'Para comprar datos móviles en PC con SIM.'; Rec = $true },
    @{ Pkg = 'Microsoft.Wallet'; Name = 'Microsoft Pay'; Desc = 'Cartera de pagos retirada.'; Rec = $true },
    @{ Pkg = 'Microsoft.Messaging'; Name = 'Mensajes'; Desc = 'App de mensajes antigua.'; Rec = $true },
    @{ Pkg = 'Microsoft.Office.OneNote'; Name = 'OneNote para Windows 10'; Desc = 'Versión antigua de OneNote. Quítala solo si no la usas.'; Rec = $false },
    @{ Pkg = 'microsoft.windowscommunicationsapps'; Name = 'Correo y Calendario'; Desc = 'Apps antiguas de correo que Microsoft ha retirado. Quítalas solo si no las usas.'; Rec = $false }
)
$TelemetryTasks = @(
    '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator',
    '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip',
    '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser',
    '\Microsoft\Windows\Application Experience\ProgramDataUpdater',
    '\Microsoft\Windows\Autochk\Proxy',
    '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector',
    '\Microsoft\Windows\Feedback\Siuf\DmClient',
    '\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload')

function Add-ServiceTweak($Id, $Name, $Desc, $Tier, $Services) {
    $present = @($Services | Where-Object { Get-Service $_ -ErrorAction SilentlyContinue })
    if ($present.Count -eq 0) { return }
    Add-Tweak @{ Id = $Id; Category = 'Limpieza'; Group = 'SERVICIOS Y SEGUNDO PLANO'; Name = $Name; Desc = $Desc; Impact = 'Bajo'; Tier = $Tier; Glyph = '&#xE713;'; Data = $present
        Why = "Servicios: $($present -join ', ')"
        Check = { param($t) foreach ($s in $t.Data) { if ("$(Get-RegValue "HKLM:\SYSTEM\CurrentControlSet\Services\$s" 'Start')" -ne '4') { return $false } }; return $true }
        Apply = { param($t)
            $i = 0
            foreach ($s in $t.Data) {
                $k = "HKLM:\SYSTEM\CurrentControlSet\Services\$s"
                Backup-Item "$($t.Id)#$i" @{ absent = $false; value = (Get-RegValue $k 'Start'); delayed = (Get-RegValue $k 'DelayedAutostart') }
                Stop-Service $s -Force -ErrorAction SilentlyContinue
                Set-RegValue $k 'Start' 4; $i++
            } }
        Revert = { param($t)
            $i = 0; $any = $false
            foreach ($s in $t.Data) {
                $k = "HKLM:\SYSTEM\CurrentControlSet\Services\$s"; $b = Get-BackupItem "$($t.Id)#$i"
                if ($null -ne $b) {
                    Set-RegValue $k 'Start' ([int]$b.value)
                    if ($null -ne $b.delayed) { Set-RegValue $k 'DelayedAutostart' ([int]$b.delayed) }
                    if ([int]$b.value -eq 2) { Start-Service $s -ErrorAction SilentlyContinue }
                    Clear-BackupItem "$($t.Id)#$i"; $any = $true
                }
                $i++
            }
            return $any }
    }
}

function Add-DebloatTweaks($f) {
    # ---- Apps preinstaladas (solo las que están instaladas en este PC) ----
    foreach ($a in $BloatApps) {
        $hit = @(@($f.Appx) | Where-Object { $_ -like $a.Pkg })
        if ($hit.Count -eq 0) { continue }
        Add-Tweak @{ Id = "app_$($a.Pkg -replace '[^A-Za-z0-9]', '')"; Category = 'Limpieza'; Group = 'APPS PREINSTALADAS'; Name = "Quitar $($a.Name)"; Impact = 'Bajo'
            Tier = $(if ($a.Rec) { 'Recomendado' } else { 'Opcional' }); Glyph = '&#xE74D;'; Data = $a.Pkg
            Desc = "$($a.Desc) Si algún día la quieres, se reinstala gratis desde la Microsoft Store."
            Why = "Detectado: $($hit[0])"
            Check = { param($t) return (-not (Get-AppxPackage -Name $t.Data -ErrorAction SilentlyContinue)) }
            Apply = { param($t)
                $pk = @(Get-AppxPackage -Name $t.Data)
                if ($pk.Count) { Backup-Item $t.Id @{ absent = $false; value = "$($pk[0].PackageFamilyName)" } }
                $pk | Remove-AppxPackage -ErrorAction Stop }
            Revert = { param($t)
                $b = Get-BackupItem $t.Id; if ($null -eq $b) { return $false }
                Start-Process "ms-windows-store://pdp/?PFN=$($b.value)"
                Log "· $($t.Name): se ha abierto la Microsoft Store para reinstalarla"
                Clear-BackupItem $t.Id; return $true }
        }
    }

    # ---- Privacidad y anuncios ----
    $cdm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    New-RegTweak @{ Id = 'deb_ads'; Category = 'Limpieza'; Group = 'PRIVACIDAD Y ANUNCIOS'; Name = 'Sin anuncios ni sugerencias de Windows'; Impact = 'Bajo'; Glyph = '&#xE72E;'
        Desc = 'Quita las apps que Windows instala por su cuenta, los consejos, las recomendaciones del menú Inicio y el ID de publicidad.'
        Why  = 'Windows muestra contenido promocional por defecto' } @(
        (RegV $cdm 'SilentInstalledAppsEnabled' 0), (RegV $cdm 'SystemPaneSuggestionsEnabled' 0), (RegV $cdm 'SoftLandingEnabled' 0),
        (RegV $cdm 'SubscribedContent-338388Enabled' 0), (RegV $cdm 'SubscribedContent-338389Enabled' 0),
        (RegV $cdm 'SubscribedContent-353694Enabled' 0), (RegV $cdm 'SubscribedContent-353696Enabled' 0),
        (RegV $cdm 'RotatingLockScreenOverlayEnabled' 0),
        (RegV 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0),
        (RegV 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_IrisRecommendations' 0))
    New-RegTweak @{ Id = 'deb_telemetry'; Category = 'Limpieza'; Group = 'PRIVACIDAD Y ANUNCIOS'; Name = 'Telemetría y seguimiento al mínimo'; Impact = 'Bajo'; Glyph = '&#xE72E;'
        Desc = 'Reduce los datos de diagnóstico que envía Windows y desactiva el historial de actividad y las experiencias personalizadas con esos datos.'
        Why  = 'Configuración de fábrica de Windows' } @(
        (RegV 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0),
        (RegV 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'PublishUserActivities' 0),
        (RegV 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'UploadUserActivities' 0),
        (RegV 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 0))
    New-RegTweak @{ Id = 'deb_bing'; Category = 'Limpieza'; Group = 'PRIVACIDAD Y ANUNCIOS'; Name = 'Sin Bing en la búsqueda de Windows'; Impact = 'Bajo'; Reboot = $true; Glyph = '&#xE721;'
        Desc = 'La búsqueda del menú Inicio solo busca en tu PC: más rápida y sin resultados web.'
        Why  = 'Windows mezcla resultados web en la búsqueda' } @(
        (RegV 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1),
        (RegV 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 0))
    if ($f.WinBuild -ge 22000) {
        New-RegTweak @{ Id = 'deb_widgets'; OS = '11'; Category = 'Limpieza'; Group = 'PRIVACIDAD Y ANUNCIOS'; Name = 'Sin Widgets'; Impact = 'Medio'; Reboot = $true; Glyph = '&#xE80A;'
            Desc = 'Quita el panel de Widgets (noticias, tiempo...) y el proceso que lo mantiene cargado en segundo plano.'
            Why  = 'Detectado: Windows 11' } @((RegV 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0))
        ($script:Tweaks | Where-Object Id -eq 'deb_widgets').Apply = { param($t)
            try { & $RegApply $t }
            catch {
                Clear-BackupItem "$($t.Id)#0"
                throw "esta versión de Windows (build $([Environment]::OSVersion.Version.Build)) bloquea la política de Widgets. Puedes ocultarlos a mano en Configuración > Personalización > Barra de tareas > Widgets."
            } }
    }

    # ---- Servicios y segundo plano ----
    Add-ServiceTweak 'deb_svc_telemetry' 'Servicios de telemetría desactivados' 'Detiene "Experiencias del usuario y telemetría asociadas" y el servicio de mensajes push WAP, que envían datos de uso en segundo plano.' 'Recomendado' @('DiagTrack', 'dmwappushservice')
    Add-ServiceTweak 'deb_svc_misc' 'Servicios que casi nadie usa' 'Administrador de mapas descargados, modo demo de tienda y fax. Si algún día los necesitas, los vuelves a activar aquí.' 'Recomendado' @('MapsBroker', 'RetailDemo', 'Fax')
    Add-ServiceTweak 'deb_svc_print' 'Sin cola de impresión' 'Solo si nunca imprimes desde este PC: sin ella no funcionan las impresoras ni "Imprimir en PDF".' 'Opcional' @('Spooler')
    New-RegTweak @{ Id = 'deb_storagesense'; Category = 'Limpieza'; Group = 'MANTENIMIENTO AUTOMÁTICO'; Name = 'Limpiar temporales automáticamente cada semana'; Impact = 'Bajo'; Glyph = '&#xEDA2;'
        Desc = 'Activa el Sensor de almacenamiento de Windows para que borre solo los archivos temporales que ya no usa ninguna app. No toca la papelera ni tus descargas.'
        Why  = 'Así la caché no vuelve a crecer sin que te des cuenta' } @(
        (RegV 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' '01' 1),
        (RegV 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' '04' 1),
        (RegV 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy' '2048' 7))
    $tasks = @($TelemetryTasks | Where-Object { Get-TaskCom $_ })
    if ($tasks.Count) {
        Add-Tweak @{ Id = 'deb_tasks'; Category = 'Limpieza'; Group = 'SERVICIOS Y SEGUNDO PLANO'; Name = 'Tareas programadas de telemetría desactivadas'; Impact = 'Bajo'; Glyph = '&#xE823;'; Data = $tasks
            Desc = 'Tareas que recopilan datos de compatibilidad y de uso en segundo plano (pueden arrancar a mitad de partida).'
            Why  = $(if ($tasks.Count -eq 1) { 'Detectada: 1 tarea' } else { "Detectadas: $($tasks.Count) tareas" })
            Check = { param($t) foreach ($p in $t.Data) { $s = Get-TaskCom $p; if ($s -and $s.Enabled) { return $false } }; return $true }
            Apply = { param($t)
                $was = @()
                foreach ($p in $t.Data) {
                    $s = Get-TaskCom $p
                    if ($s -and $s.Enabled) { $was += $p; [void](Disable-ScheduledTask -TaskPath ((Split-Path $p) + '\') -TaskName (Split-Path $p -Leaf) -ErrorAction SilentlyContinue) }
                }
                Backup-Item $t.Id @{ absent = $false; value = ($was -join '|') } }
            Revert = { param($t)
                $b = Get-BackupItem $t.Id; if ($null -eq $b) { return $false }
                foreach ($p in ("$($b.value)" -split '\|' | Where-Object { $_ })) { [void](Get-ScheduledTask -TaskPath ((Split-Path $p) + '\') -TaskName (Split-Path $p -Leaf) -ErrorAction SilentlyContinue | Enable-ScheduledTask -ErrorAction SilentlyContinue) }
                Clear-BackupItem $t.Id; return $true }
        }
    }
    if ($f.EdgeInstalled) {
        New-RegTweak @{ Id = 'deb_edge'; Category = 'Limpieza'; Group = 'SERVICIOS Y SEGUNDO PLANO'; Name = 'Edge sin precarga ni segundo plano'; Impact = 'Medio'; Glyph = '&#xE774;'
            Desc = 'Edge deja de precargarse al encender el PC y de seguir abierto al cerrarlo. En su configuración verás "administrado por tu organización": es normal.'
            Why  = 'Detectado: Microsoft Edge' } @((RegV 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'StartupBoostEnabled' 0), (RegV 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'BackgroundModeEnabled' 0))
    }
}

# ======================= Tweaks extra (v5) =======================
function Add-StartupTweakLM($name, $approvedKey, $idPrefix) {
    # Programas que arrancan para todos los usuarios. Nunca se tocan drivers, audio, seguridad ni Medal/Vanguard.
    if ($name -match 'Medal|Vanguard|SecurityHealth|RtkAud|Realtek|Nahimic|NVIDIA|NvBackend|Intel|igfx|IAStor|AMD|Radeon|Synaptics|ELAN|Defender|ctfmon|BTServer|Bluetooth|Logi|Razer|Corsair|SteelSeries|MSI') { return }
    $k = $StartupKnown[$name]
    if ($name -like 'GoogleChromeAutoLaunch*') { $k = @('Google Chrome (precarga)', $true, 'Chrome se precarga al encender aunque no lo uses.') }
    if (-not $k) { $k = @($name, $false, 'Programa que arranca con Windows para todos los usuarios.') }
    Add-Tweak @{ Id = "$idPrefix$name"; Category = 'Inicio'; Name = "No abrir $($k[0]) al encender"; Desc = $k[2]; Impact = 'Bajo'
        Tier = $(if ($k[1]) { 'Recomendado' } else { 'Opcional' }); Glyph = '&#xE768;'; Data = @{ Name = $name; Key = $approvedKey }
        Why = 'Detectado en el inicio de Windows (todos los usuarios)'
        Check = { param($t) $b = Get-RegValue $t.Data.Key $t.Data.Name; return (($null -ne $b) -and (($b[0] -band 1) -eq 1)) }
        Apply = { param($t)
            $b = Get-RegValue $t.Data.Key $t.Data.Name; Backup-Item $t.Id @{ absent = ($null -eq $b); value = 'enabled' }
            Set-RegValue $t.Data.Key $t.Data.Name ([byte[]](@(3, 0, 0, 0) + [BitConverter]::GetBytes([DateTime]::Now.ToFileTime()))) 'Binary' }
        Revert = { param($t)
            $b = Get-BackupItem $t.Id; if ($null -eq $b) { return $false }
            if ($b.absent) { Remove-RegValue $t.Data.Key $t.Data.Name } else { Set-RegValue $t.Data.Key $t.Data.Name ([byte[]](2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)) 'Binary' }
            Clear-BackupItem $t.Id; return $true }
    }
}

function Add-ExtraTweaks($f) {
    # ---------- Monitores a su frecuencia máxima ----------
    foreach ($ad in @(try { [CtNative]::ActiveDisplays() } catch { @() })) {
        $parts = "$ad" -split '\|'; $dev = $parts[0]; $adapter = $parts[1]; $primary = ($parts[2] -eq '1')
        if ($f.Hybrid -and $adapter -match 'Intel|AMD Radeon\(TM\)|Radeon Graphics') { continue }   # la pantalla del portátil la controlan los modos
        $rates = @([CtNative]::Rates($dev)); if ($rates.Count -lt 2) { continue }
        $max = ($rates | Measure-Object -Maximum).Maximum; $cur = [CtNative]::Current($dev)
        $mon = [CtNative]::MonitorName($dev); if (-not $mon -or $mon -match 'Generic|gen.rico') { $mon = if ($primary) { 'Monitor principal' } else { 'Monitor secundario' } }
        Add-Tweak @{ Id = "disp_$($dev -replace '[^A-Za-z0-9]', '')"; Category = 'Windows'; Name = "$(if ($primary) { 'Monitor principal' } else { 'Monitor secundario' }) a $max Hz"; Impact = 'Alto'; Glyph = '&#xE7F4;'
            Data = @{ Dev = $dev; Max = [int]$max }
            Desc = 'Pone la pantalla a la frecuencia más alta que admite. Es de los cambios que más se notan: más imágenes por segundo y la imagen llega antes.'
            Why  = "Detectado: $mon a $cur Hz (admite hasta $max Hz)"
            Check = { param($t) return ([CtNative]::Current($t.Data.Dev) -ge $t.Data.Max) }
            Apply = { param($t)
                Backup-Item $t.Id @{ absent = $false; value = [CtNative]::Current($t.Data.Dev) }
                $r = [CtNative]::SetRate($t.Data.Dev, [int]$t.Data.Max); if ($r -ne 0) { throw "la pantalla no aceptó $($t.Data.Max) Hz (código $r)" } }
            Revert = { param($t)
                $b = Get-BackupItem $t.Id; if ($null -eq $b) { return $false }
                [void][CtNative]::SetRate($t.Data.Dev, [int]$b.value); Clear-BackupItem $t.Id; return $true }
        }
    }

    # ---------- Windows ----------
    New-RegTweak @{ Id = 'win_stickykeys'; Category = 'Windows'; Name = 'Sin avisos de Teclas especiales'; Impact = 'Medio'; Glyph = '&#xE765;'
        Desc = 'Evita que pulsar Mayús cinco veces o mantenerla pulsada te saque del juego con el aviso de Teclas especiales, Teclas filtro o Teclas de alternancia.'
        Why  = 'Pasa mucho al correr o agacharse con Mayús' } @(
        (RegV 'HKCU:\Control Panel\Accessibility\StickyKeys' 'Flags' '506' 'String'),
        (RegV 'HKCU:\Control Panel\Accessibility\Keyboard Response' 'Flags' '122' 'String'),
        (RegV 'HKCU:\Control Panel\Accessibility\ToggleKeys' 'Flags' '58' 'String'))
    if ($f.WinBuild -ge 22621) {
        Add-Tweak @{ Id = 'win_windowedopt'; OS = '11'; Category = 'Windows'; Name = 'Optimizaciones para juegos en ventana'; Impact = 'Medio'; Glyph = '&#xE740;'; Data = $null
            Desc = 'Los juegos DirectX 10/11 en ventana o ventana sin bordes usan el modo de presentación moderno de Windows 11: menos latencia, casi como en pantalla completa.'
            Why  = 'Detectado: Windows 11 22H2 o posterior'
            Check = { param($t) return ("$(Get-RegValue 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' 'DirectXUserGlobalSettings')" -match 'SwapEffectUpgradeEnable=1') }
            Apply = { param($t)
                $k = 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'; $cur = Get-RegValue $k 'DirectXUserGlobalSettings'
                Backup-Item $t.Id @{ absent = ($null -eq $cur); value = $cur }
                $rest = ("$cur" -replace 'SwapEffectUpgradeEnable=\d;?', '').Trim()
                Set-RegValue $k 'DirectXUserGlobalSettings' ('SwapEffectUpgradeEnable=1;' + $rest) 'String' }
            Revert = { param($t)
                $k = 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'; $b = Get-BackupItem $t.Id; if ($null -eq $b) { return $false }
                if ($b.absent) { Remove-RegValue $k 'DirectXUserGlobalSettings' } else { Set-RegValue $k 'DirectXUserGlobalSettings' $b.value 'String' }
                Clear-BackupItem $t.Id; return $true }
        }
    }
    New-RegTweak @{ Id = 'win_activehours'; Category = 'Windows'; Name = 'Windows Update no reinicia mientras juegas'; Impact = 'Medio'; Glyph = '&#xE777;'
        Desc = 'Fija las horas activas de 10:00 a 4:00: Windows Update no reiniciará el PC por su cuenta en ese tramo. Las actualizaciones se siguen instalando.'
        Why  = 'Evita reinicios automáticos en mitad de una partida' } @(
        (RegV 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' 'SmartActiveHoursState' 0),
        (RegV 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' 'ActiveHoursStart' 10),
        (RegV 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' 'ActiveHoursEnd' 4))
    New-RegTweak @{ Id = 'win_gamebarpad'; Category = 'Windows'; Name = 'El botón Xbox del mando no abre la Game Bar'; Impact = 'Bajo'; Tier = 'Opcional'; Glyph = '&#xE7FC;'
        Desc = 'Si juegas con mando, evita que la Game Bar se abra en mitad de la partida al tocar el botón Xbox.'
        Why  = 'Útil si juegas con mando' } @((RegV 'HKCU:\Software\Microsoft\GameBar' 'UseNexusForGameBarEnabled' 0))
    New-RegTweak @{ Id = 'win_powerthrottle'; Category = 'Windows'; Name = 'Sin limitación de energía en segundo plano'; Impact = 'Bajo'; Tier = 'Opcional'; Reboot = $true; Glyph = '&#xE945;'
        Desc = 'Windows deja de frenar los programas en segundo plano (Discord, Medal...) para ahorrar energía. Rendimiento más constante a cambio de algo más de consumo con batería.'
        Why  = $(if ($f.Laptop) { 'Detectado: portátil (con batería durará algo menos)' } else { 'Detectado: PC de sobremesa' }) } @((RegV 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' 'PowerThrottlingOff' 1))
    New-RegTweak @{ Id = 'win_animations'; Category = 'Windows'; Name = 'Sin animaciones de ventanas'; Impact = 'Bajo'; Tier = 'Opcional'; Reboot = $true; Glyph = '&#xE7C4;'
        Desc = 'Abrir, minimizar y maximizar ventanas sin animación: Windows se siente más rápido. Es solo estético.'
        Why  = 'Preferencia personal' } @(
        (RegV 'HKCU:\Control Panel\Desktop\WindowMetrics' 'MinAnimate' '0' 'String'),
        (RegV 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAnimations' 0))
    New-RegTweak @{ Id = 'win_keyrepeat'; Category = 'Windows'; Name = 'Repetición de teclado más rápida'; Impact = 'Bajo'; Tier = 'Opcional'; Reboot = $true; Glyph = '&#xE765;'
        Desc = 'Una tecla mantenida empieza a repetirse antes y más deprisa. Cómodo para chatear y editar; no cambia la latencia de cada pulsación.'
        Why  = 'Preferencia personal' } @((RegV 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '0' 'String'), (RegV 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' '31' 'String'))
    New-RegTweak @{ Id = 'win_startupdelay'; Category = 'Windows'; Name = 'Sin retraso al arrancar programas de inicio'; Impact = 'Bajo'; Tier = 'Opcional'; Glyph = '&#xE768;'
        Desc = 'Los programas que arrancan con Windows (como Medal o Discord) se abren sin la espera que Windows añade al encender.'
        Why  = 'Windows retrasa los programas de inicio unos segundos' } @((RegV 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize' 'StartupDelayInMSec' 0))
    New-RegTweak @{ Id = 'win_mpo'; Category = 'Windows'; Name = 'Desactivar MPO (solo si tienes parpadeos)'; Impact = 'Bajo'; Tier = 'Opcional'; Reboot = $true; Glyph = '&#xE7F4;'
        Desc = 'Arregla parpadeos, pantallazos negros o tirones raros que algunas gráficas tienen con juegos en ventana o con Discord y el navegador encima. Si no te pasa, déjalo como está.'
        Why  = 'Solución conocida para un fallo de algunos drivers' } @((RegV 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'OverlayTestMode' 5))

    # ---------- Red ----------
    New-RegTweak @{ Id = 'net_dosvc'; Category = 'Red'; Name = 'Windows no sube actualizaciones a otros PC'; Impact = 'Bajo'; Glyph = '&#xE839;'
        Desc = 'Por defecto Windows puede usar tu conexión para enviar trozos de actualizaciones a otros equipos. Así tu subida queda libre para jugar.'
        Why  = 'Optimización de distribución activada por defecto' } @((RegV 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' 'DODownloadMode' 0))
    $route = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Sort-Object RouteMetric | Select-Object -First 1
    $alias = if ($route) { (Get-NetAdapter -InterfaceIndex $route.ifIndex -ErrorAction SilentlyContinue).Name } else { $null }
    if ($alias) {
        Add-Tweak @{ Id = 'net_dns'; Category = 'Red'; Name = 'DNS rápido (Cloudflare 1.1.1.1)'; Impact = 'Bajo'; Tier = 'Opcional'; Glyph = '&#xE774;'; Data = $alias
            Desc = 'Usa el DNS de Cloudflare en vez del de tu operador. Puede acelerar la carga de webs y launchers; no cambia el ping dentro de las partidas.'
            Why  = "Conexión activa: $alias"
            Check = { param($t)
                $ni = @([Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | Where-Object { $_.Name -eq $t.Data }) | Select-Object -First 1
                if ($ni) { return (@($ni.GetIPProperties().DnsAddresses | ForEach-Object { "$_" }) -contains '1.1.1.1') }
                return (@((Get-DnsClientServerAddress -InterfaceAlias $t.Data -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses) -contains '1.1.1.1') }
            Apply = { param($t)
                $cur = @((Get-DnsClientServerAddress -InterfaceAlias $t.Data -AddressFamily IPv4).ServerAddresses)
                $guid = (Get-NetAdapter -Name $t.Data).InterfaceGuid
                $static = "$(Get-RegValue "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$guid" 'NameServer')"
                Backup-Item $t.Id @{ absent = (-not $static); value = ($cur -join ',') }
                Set-DnsClientServerAddress -InterfaceAlias $t.Data -ServerAddresses @('1.1.1.1', '1.0.0.1'); Clear-DnsClientCache }
            Revert = { param($t)
                $b = Get-BackupItem $t.Id; if ($null -eq $b) { return $false }
                if ($b.absent) { Set-DnsClientServerAddress -InterfaceAlias $t.Data -ResetServerAddresses } else { Set-DnsClientServerAddress -InterfaceAlias $t.Data -ServerAddresses @("$($b.value)" -split ',') }
                Clear-DnsClientCache; Clear-BackupItem $t.Id; return $true }
        }
    }

    # ---------- Limpieza: privacidad y mantenimiento ----------
    if ($f.WinBuild -ge 26100) {
        New-RegTweak @{ Id = 'deb_recall'; OS = '11'; Category = 'Limpieza'; Group = 'PRIVACIDAD Y ANUNCIOS'; Name = 'Sin Recall (capturas de pantalla de la IA)'; Impact = 'Bajo'; Tier = 'Opcional'; Glyph = '&#xE72E;'
            Desc = 'Impide que Windows haga capturas periódicas de tu pantalla para la función Recall en los PC que la tienen. En los demás no cambia nada.'
            Why  = 'Detectado: Windows 11 24H2 o posterior' } @(
            (RegV 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis' 1),
            (RegV 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis' 1))
    }
    $hib = Get-Item "$env:SystemDrive\hiberfil.sys" -Force -ErrorAction SilentlyContinue
    if ($hib -or (Test-HasBackup 'deb_hibernate')) {
        $gb = if ($hib) { ' (libera {0:0.0} GB)' -f ($hib.Length / 1GB) } else { '' }
        Add-Tweak @{ Id = 'deb_hibernate'; Category = 'Limpieza'; Group = 'MANTENIMIENTO AUTOMÁTICO'; Name = "Desactivar la hibernación$gb"; Impact = 'Bajo'; Tier = 'Opcional'; Glyph = '&#xEDA2;'; Data = $null
            Desc = 'Borra el archivo hiberfil.sys. El PC se sigue pudiendo suspender igual; solo dejas de poder hibernar y se desactiva el inicio rápido (que a veces da problemas con drivers).'
            Why  = $(if ($hib) { 'Detectado: hiberfil.sys en el disco' } else { 'Hibernación desactivada por esta app' })
            Check = { param($t) return ((Get-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'HibernateEnabled') -eq 0) }
            Apply = { param($t) Backup-Item $t.Id @{ absent = $false; value = 1 }; powercfg /h off | Out-Null }
            Revert = { param($t) if ($null -eq (Get-BackupItem $t.Id)) { return $false }; powercfg /h on | Out-Null; Clear-BackupItem $t.Id; return $true }
        }
    }

    # ---------- Inicio: programas para todos los usuarios ----------
    foreach ($n in @($f.StartupNamesLM)) { if ($n) { Add-StartupTweakLM $n 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run' 'startupm_' } }
    foreach ($n in @($f.StartupNamesLM32)) { if ($n) { Add-StartupTweakLM $n 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32' 'startupw_' } }
}

# ======================= Periféricos (marcas y ajustes) =======================
$VendorDefs = @{
    '046D' = @('Logitech', 'Logitech G HUB', 'G HUB');           '1532' = @('Razer', 'Razer Synapse', 'Synapse')
    '1038' = @('SteelSeries', 'SteelSeries GG', 'SteelSeries');   '1B1C' = @('Corsair', 'Corsair iCUE', 'iCUE')
    '0951' = @('HyperX', 'HyperX NGENUITY', 'NGENUITY');          '03F0' = @('HyperX', 'HyperX NGENUITY', 'NGENUITY')
    '3554' = @('Pulsar', 'Pulsar Fusion', 'Pulsar');              '1E7D' = @('ROCCAT', 'ROCCAT Swarm', 'Swarm')
    '0B05' = @('ASUS ROG', 'Armoury Crate', 'Armoury');           '1462' = @('MSI', 'MSI Center', 'MSI Center')
    '31E3' = @('Wooting', 'Wootility', 'Wootility');              '3367' = @('Endgame Gear', 'Endgame Gear Software', 'Endgame')
    '361D' = @('Finalmouse', 'Finalmouse (web)', 'Finalmouse');   '2516' = @('Cooler Master', 'MasterPlus+', 'MasterPlus')
    '3434' = @('Keychron', 'Keychron Launcher (web)', 'Keychron'); '054C' = @('Sony PlayStation', 'Actualizador de firmware de DualSense', 'DualSense')
    '045E' = @('Microsoft / Xbox', 'Accesorios de Xbox', 'Xbox Accessories'); '2DC8' = @('8BitDo', '8BitDo Ultimate Software', '8BitDo')
    '1395' = @('EPOS / Sennheiser', 'EPOS Gaming Suite', 'EPOS'); '10F5' = @('Turtle Beach', 'Turtle Beach Audio Hub', 'Turtle Beach')
    '1AF3' = @('ZOWIE', '', '');                                  '057E' = @('Nintendo', '', '')
}
$BrandByName = [ordered]@{
    'Logitech|^G\d{3}|^G PRO|^PRO X' = @('Logitech', 'Logitech G HUB', 'G HUB'); 'Razer|DeathAdder|Viper|BlackShark|Huntsman' = @('Razer', 'Razer Synapse', 'Synapse')
    'SteelSeries|Arctis|Aerox|Apex Pro' = @('SteelSeries', 'SteelSeries GG', 'SteelSeries'); 'HyperX|Cloud' = @('HyperX', 'HyperX NGENUITY', 'NGENUITY')
    'Corsair|Virtuoso|HS\d{2}' = @('Corsair', 'Corsair iCUE', 'iCUE'); 'Wooting' = @('Wooting', 'Wootility', 'Wootility')
    'Pulsar|Xlite|X2' = @('Pulsar', 'Pulsar Fusion', 'Pulsar'); 'Sennheiser|^HD \d|^Momentum|^PXC' = @('Sennheiser', 'Sennheiser Smart Control', 'Smart Control')
    'Sony|WH-1000|DualSense' = @('Sony', 'Sony Headphones Connect', 'Headphones Connect'); 'Astro' = @('Astro', 'ASTRO Command Center', 'ASTRO')
    'Elgato|Wave' = @('Elgato', 'Elgato Wave Link', 'Wave Link'); 'Rode|RØDE' = @('RØDE', 'RØDE Central', 'Central'); 'Yeti|Blue' = @('Logitech (Blue)', 'Logitech G HUB', 'G HUB')
}
function Get-DeviceBrand($dev) {
    if ($dev.Vid -and $VendorDefs.ContainsKey($dev.Vid)) { return $VendorDefs[$dev.Vid] }
    foreach ($k in $BrandByName.Keys) { if ($dev.Name -match $k) { return $BrandByName[$k] } }
    return $null
}

function Add-PeripheralTweaks($f) {
    # Ahorro de energía de Windows en ratón, teclado, concentradores USB y Bluetooth
    $ids = @(Get-PnpDevice -PresentOnly -Class Mouse, Keyboard, HIDClass, USB, Bluetooth -ErrorAction SilentlyContinue | ForEach-Object { "$($_.InstanceId)".ToUpper() })
    $all = @(Get-CimInstance -Namespace root\wmi -ClassName MSPower_DeviceEnable -ErrorAction SilentlyContinue)
    $inst = @(foreach ($o in $all) { $n = "$($o.InstanceName)".ToUpper(); foreach ($id in $ids) { if ($n.StartsWith($id)) { $o.InstanceName; break } } })
    if ($inst.Count -eq 0) { return }
    Add-Tweak @{ Id = 'per_usbpower'; Category = 'Perifericos'; Name = 'Sin ahorro de energía en USB y Bluetooth'; Impact = 'Medio'; Glyph = '&#xE88E;'; Data = $inst
        Desc = 'Windows deja de poder «dormir» el ratón, el teclado, los concentradores USB y el adaptador Bluetooth para ahorrar energía. Evita microcortes, desconexiones y picos de retardo, también en los cascos Bluetooth.'
        Why  = "Detectados: $($inst.Count) dispositivos que Windows puede apagar"
        Check = { param($t)
            $m = @{}; foreach ($o in @(Get-CimInstance -Namespace root\wmi -ClassName MSPower_DeviceEnable -ErrorAction SilentlyContinue)) { $m[$o.InstanceName] = $o.Enable }
            foreach ($n in $t.Data) { if ($m[$n] -eq $true) { return $false } }; return $true }
        Apply = { param($t)
            $was = @()
            foreach ($o in @(Get-CimInstance -Namespace root\wmi -ClassName MSPower_DeviceEnable -ErrorAction SilentlyContinue)) {
                if ($t.Data -contains $o.InstanceName -and $o.Enable) { $was += $o.InstanceName; Set-CimInstance -InputObject $o -Property @{ Enable = $false } -ErrorAction SilentlyContinue }
            }
            Backup-Item $t.Id @{ absent = $false; value = ($was -join '|') } }
        Revert = { param($t)
            $b = Get-BackupItem $t.Id; if ($null -eq $b) { return $false }
            $on = @("$($b.value)" -split '\|' | Where-Object { $_ })
            foreach ($o in @(Get-CimInstance -Namespace root\wmi -ClassName MSPower_DeviceEnable -ErrorAction SilentlyContinue)) { if ($on -contains $o.InstanceName) { Set-CimInstance -InputObject $o -Property @{ Enable = $true } -ErrorAction SilentlyContinue } }
            Clear-BackupItem $t.Id; return $true }
    }
}

# ======================= Ajustes propios de Windows 10 =======================
function Add-Win10Tweaks($f) {
    if (-not $f.WinBuild -or $f.WinBuild -ge 22000) { return }
    if ($f.WinBuild -lt 19041 -and -not (Test-HasBackup 'win_hags')) { [void]$script:Tweaks.RemoveAll([Predicate[object]] { param($x) $x.Id -eq 'win_hags' }) }
    # En Windows 10: quitar de cada ajuste lo que solo existe en Windows 11 y añadir su equivalente de Windows 10
    $ads = $script:Tweaks | Where-Object { $_.Id -eq 'deb_ads' } | Select-Object -First 1
    if ($ads) { $ads.Data = @($ads.Data | Where-Object { $_.Name -ne 'Start_IrisRecommendations' }) }
    $bing = $script:Tweaks | Where-Object { $_.Id -eq 'deb_bing' } | Select-Object -First 1
    if ($bing -and -not (@($bing.Data) | Where-Object { $_.Name -eq 'CortanaConsent' })) {
        $bing.Data = @($bing.Data) + @(RegV 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' 'CortanaConsent' 0)
        $bing.Desc = 'La búsqueda del menú Inicio y de la barra de tareas solo busca en tu PC: más rápida y sin resultados web de Bing.'
    }
    # Ajustes que necesitan una versión mínima de Windows 10
    $minBuild = @{ 'win_gamebarpad' = 18362; 'win_powerthrottle' = 16299; 'deb_storagesense' = 17763; 'net_dosvc' = 16299; 'deb_bing' = 18362; 'win_activehours' = 18362 }
    foreach ($id in @($minBuild.Keys)) {
        if ($f.WinBuild -lt $minBuild[$id] -and -not (Test-HasBackup $id)) { [void]$script:Tweaks.RemoveAll([Predicate[object]] { param($x) $x.Id -eq $id }) }
    }
    New-RegTweak @{ Id = 'w10_feeds'; Category = 'Limpieza'; Group = 'PRIVACIDAD Y ANUNCIOS'; Name = 'Sin «Noticias e intereses» en la barra de tareas'; Impact = 'Medio'; Reboot = $true; OS = '10'; Glyph = '&#xE80A;'
        Desc = 'Quita el widget del tiempo y las noticias de la barra de tareas de Windows 10 y el proceso de Edge que lo mantiene cargado en segundo plano.'
        Why  = 'Detectado: Windows 10' } @(
        (RegV 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds' 'EnableFeeds' 0),
        (RegV 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds' 'ShellFeedsTaskbarViewMode' 2))
    New-RegTweak @{ Id = 'w10_cortana'; Category = 'Limpieza'; Group = 'PRIVACIDAD Y ANUNCIOS'; Name = 'Cortana desactivada'; Impact = 'Bajo'; Reboot = $true; OS = '10'; Glyph = '&#xE72E;'
        Desc = 'Desactiva Cortana (Microsoft ya la ha retirado) y su botón en la barra de tareas. La búsqueda de Windows sigue funcionando igual.'
        Why  = 'Detectado: Windows 10' } @(
        (RegV 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'AllowCortana' 0),
        (RegV 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowCortanaButton' 0))
    New-RegTweak @{ Id = 'w10_meetnow'; Category = 'Limpieza'; Group = 'PRIVACIDAD Y ANUNCIOS'; Name = 'Sin el botón «Reunirse ahora»'; Impact = 'Bajo'; OS = '10'; Glyph = '&#xE714;'
        Desc = 'Quita de la barra de tareas el acceso directo a las reuniones de Skype, que Microsoft ya no usa.'
        Why  = 'Detectado: Windows 10' } @((RegV 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'HideSCAMeetNow' 1))
    New-RegTweak @{ Id = 'w10_fse'; Category = 'Windows'; Name = 'Pantalla completa exclusiva clásica en todos los juegos'; Impact = 'Medio'; Tier = 'Opcional'; Reboot = $true; OS = '10'; Glyph = '&#xE740;'
        Desc = 'En Windows 10 las «optimizaciones de pantalla completa» convierten muchos juegos en una ventana sin bordes, lo que puede añadir algo de latencia. Esto fuerza la pantalla completa exclusiva de verdad en todos. Si algún juego da problemas al cambiar de ventana, desactívalo.'
        Why  = 'Ajuste habitual en Windows 10 para juegos competitivos' } @(
        (RegV 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 2),
        (RegV 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehavior' 2),
        (RegV 'HKCU:\System\GameConfigStore' 'GameDVR_HonorUserFSEBehaviorMode' 1),
        (RegV 'HKCU:\System\GameConfigStore' 'GameDVR_DXGIHonorFSEWindowsCompatible' 1))
}

# ======================= Configuración dentro del juego (CS2, Apex, Rocket League, Rainbow Six) =======================
# Solo se cambian claves que YA existen en el archivo del juego: si una no está, ese ajuste no se ofrece.
function Read-CfgFile($path) {
    $b = [IO.File]::ReadAllBytes($path)
    $enc = if ($b.Length -ge 2 -and $b[0] -eq 0xFF -and $b[1] -eq 0xFE) { [Text.Encoding]::Unicode }
           elseif ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) { New-Object Text.UTF8Encoding($true) }
           else { New-Object Text.UTF8Encoding($false) }
    $text = [IO.File]::ReadAllText($path)
    return @{ Lines = [Collections.Generic.List[string]]@($text -split "`r?`n"); Enc = $enc; NL = $(if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }) }
}
function Find-CfgLine($lines, $fmt, $section, $key) {
    # Devuelve los índices de las líneas con esa clave (en la sección indicada, si es un .ini)
    $out = @(); $cur = ''
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $l = $lines[$i]
        if ($fmt -eq 'ini') {
            if ($l -match '^\s*\[(.+)\]\s*$') { $cur = $Matches[1]; continue }
            if ((-not $section -or $cur -eq $section) -and $l -match ('^\s*' + [regex]::Escape($key) + '\s*=')) { $out += $i }
        } elseif ($l -match ('^\s*"' + [regex]::Escape($key) + '"\s')) { $out += $i }
    }
    return $out
}
function Get-CfgValue($path, $fmt, $section, $key) {
    $c = Read-CfgFile $path; $idx = @(Find-CfgLine $c.Lines $fmt $section $key); if (-not $idx.Count) { return $null }
    $l = $c.Lines[$idx[0]]
    if ($fmt -eq 'ini') { return ($l -replace '^[^=]*=', '').Trim() }
    if ($l -match '^\s*"[^"]+"\s+"([^"]*)"') { return $Matches[1] }; return $null
}
function Set-CfgValue($path, $fmt, $section, $key, $value) {
    $c = Read-CfgFile $path; $idx = @(Find-CfgLine $c.Lines $fmt $section $key); if (-not $idx.Count) { return }
    foreach ($i in $idx) {
        if ($fmt -eq 'ini') { $c.Lines[$i] = ($c.Lines[$i] -replace '=.*$', "=$value") }
        else { $c.Lines[$i] = [regex]::Replace($c.Lines[$i], '^(\s*"[^"]+"\s+")[^"]*(")', { param($m) $m.Groups[1].Value + $value + $m.Groups[2].Value }) }
    }
    if ((Get-Item $path).IsReadOnly) { throw "$(Split-Path $path -Leaf) está en solo lectura" }
    [IO.File]::WriteAllText($path, ($c.Lines -join $c.NL), $c.Enc)
}
$GameCfgDefs = @{
    cs2  = @{ Fmt = 'kv'; Section = $null; Files = { param($f) $s = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction SilentlyContinue).SteamPath; if ($s) { @(Get-ChildItem (Join-Path ($s -replace '/', '\') 'userdata\*\730\local\cfg\cs2_video.txt') -ErrorAction SilentlyContinue | ForEach-Object FullName) } }
              Settings = @(
                @{ Key = 'setting.r_low_latency'; Value = '2'; Nvidia = $true; Name = 'NVIDIA Reflex: Activado + Aumento'; Impact = 'Alto'; Desc = 'Sincroniza procesador y gráfica para que cada fotograma llegue antes a la pantalla. Es lo que más baja la latencia en CS2 con una NVIDIA.' },
                @{ Key = 'setting.mat_vsync'; Value = '0'; Name = 'Sincronización vertical desactivada'; Impact = 'Medio'; Desc = 'Con la sincronización vertical activa, cada fotograma espera al monitor y se nota el retraso al apuntar.' }) }
    apex = @{ Fmt = 'kv'; Section = $null; Files = { param($f) @(Get-ChildItem "$env:USERPROFILE\Saved Games\Respawn\Apex\local\videoconfig.txt" -ErrorAction SilentlyContinue | ForEach-Object FullName) }
              Settings = @(@{ Key = 'setting.mat_vsync_mode'; Value = '0'; Name = 'Sincronización vertical desactivada'; Impact = 'Medio'; Desc = 'Quita la espera al monitor en cada fotograma: menos retraso al apuntar.' }) }
    rl   = @{ Fmt = 'ini'; Section = 'SystemSettings'; Files = { param($f) @(Get-ChildItem (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'My Games\Rocket League\TAGame\Config\TASystemSettings.ini') -ErrorAction SilentlyContinue | ForEach-Object FullName) }
              Settings = @(
                @{ Key = 'OneFrameThreadLag'; Value = 'True'; Name = 'One Frame Thread Lag activado'; Impact = 'Alto'; Desc = 'El motor no prepara fotogramas de más: el coche responde antes al mando o al teclado. Es el ajuste de latencia más importante de Rocket League.' },
                @{ Key = 'UseVsync'; Value = 'False'; Name = 'Sincronización vertical desactivada'; Impact = 'Medio'; Desc = 'Quita la espera al monitor en cada fotograma: menos retraso al controlar el coche.' },
                @{ Key = 'MotionBlur'; Value = 'False'; Name = 'Sin desenfoque de movimiento'; Impact = 'Bajo'; Desc = 'Imagen más nítida en los giros rápidos y algún FPS más.' }) }
    r6   = @{ Fmt = 'ini'; Section = 'DISPLAY'; Files = { param($f) @(Get-ChildItem (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'My Games\Rainbow Six - Siege\*\GameSettings.ini') -ErrorAction SilentlyContinue | ForEach-Object FullName) }
              Settings = @(@{ Key = 'VSync'; Value = '0'; Name = 'Sincronización vertical desactivada'; Impact = 'Medio'; Desc = 'Quita la espera al monitor en cada fotograma: menos retraso al apuntar.' }) }
}
function Add-GameCfgTweaks($f) {
    foreach ($gid in $GameCfgDefs.Keys) {
        if (-not (@($f.Games) | Where-Object { $_.Id -eq $gid })) { continue }
        $cd = $GameCfgDefs[$gid]; $files = @(& $cd.Files $f | Where-Object { $_ }); if (-not $files.Count) { continue }
        foreach ($s in $cd.Settings) {
            if ($s.Nvidia -and -not $f.IsNvidia) { continue }
            $have = @($files | Where-Object { $null -ne (Get-CfgValue $_ $cd.Fmt $cd.Section $s.Key) })
            if (-not $have.Count) { continue }
            $cur = Get-CfgValue $have[0] $cd.Fmt $cd.Section $s.Key
            Add-Tweak @{ Id = "cfg_$($gid)_$($s.Key -replace '[^A-Za-z0-9]', '')"; Category = $gid; Name = $s.Name; Desc = "$($s.Desc) Se cambia en el archivo de configuración del juego; ciérralo antes de aplicar."; Impact = $s.Impact; Glyph = '&#xE7FC;'
                Why = "Detectado en $(Split-Path $have[0] -Leaf): $($s.Key) = $cur"
                Data = @{ Game = $gid; Files = $have; Fmt = $cd.Fmt; Section = $cd.Section; Key = $s.Key; Value = $s.Value }
                Check = { param($t) foreach ($p in $t.Data.Files) { if (-not (Test-Path $p) -or "$(Get-CfgValue $p $t.Data.Fmt $t.Data.Section $t.Data.Key)" -ne $t.Data.Value) { return $false } }; return $true }
                Apply = { param($t)
                    $names = @($GameDefById[$t.Data.Game].Exes | ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_) })
                    if (Get-Process -Name $names -ErrorAction SilentlyContinue) { throw "$($GameDefById[$t.Data.Game].Name) está abierto. Ciérralo del todo y vuelve a aplicar." }
                    $i = 0
                    foreach ($p in $t.Data.Files) {
                        # Copia del archivo original (una sola vez por archivo)
                        $dir = Join-Path $DataDir "copias-juegos\$($t.Data.Game)"; New-Item -ItemType Directory -Force $dir | Out-Null
                        $copy = Join-Path $dir ("{0}-{1}" -f ([BitConverter]::ToString([Security.Cryptography.MD5]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($p.ToLower()))) -replace '-', '').Substring(0, 8), (Split-Path $p -Leaf))
                        if (-not (Test-Path $copy)) { Copy-Item $p $copy }
                        Backup-Item "$($t.Id)#$i" @{ absent = $false; value = (Get-CfgValue $p $t.Data.Fmt $t.Data.Section $t.Data.Key) }
                        Set-CfgValue $p $t.Data.Fmt $t.Data.Section $t.Data.Key $t.Data.Value; $i++
                    } }
                Revert = { param($t)
                    $names = @($GameDefById[$t.Data.Game].Exes | ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_) })
                    if (Get-Process -Name $names -ErrorAction SilentlyContinue) { throw "$($GameDefById[$t.Data.Game].Name) está abierto. Ciérralo del todo y vuelve a intentarlo." }
                    $i = 0; $any = $false
                    foreach ($p in $t.Data.Files) {
                        $b = Get-BackupItem "$($t.Id)#$i"
                        if ($null -ne $b -and (Test-Path $p)) { Set-CfgValue $p $t.Data.Fmt $t.Data.Section $t.Data.Key "$($b.value)"; Clear-BackupItem "$($t.Id)#$i"; $any = $true }
                        $i++
                    }
                    return $any }
            }
        }
    }
}

# ======================= Red: prioridad para los juegos y Wi-Fi estable =======================
$QosNla = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\QoS'
function Add-NetPlusTweaks($f) {
    # Prioridad (QoS/DSCP) para el tráfico de los juegos detectados
    $exes = @(@($f.Games) | ForEach-Object { $GameDefById["$($_.Id)"].Exes } | Where-Object { $_ } | ForEach-Object { [IO.Path]::GetFileName("$_") } | Select-Object -Unique)
    $names = @(@($f.Games) | ForEach-Object { $GameDefById["$($_.Id)"].Name } | Where-Object { $_ })
    if (($exes.Count -or (Test-HasBackup 'net_qos')) -and (Get-Command New-NetQosPolicy -ErrorAction SilentlyContinue)) {
        Add-Tweak @{ Id = 'net_qos'; Category = 'Red'; Name = 'Prioridad de red para tus juegos (QoS)'; Impact = 'Bajo'; Tier = 'Opcional'; Reboot = $true; Glyph = '&#xE7FC;'; Data = $exes
            Desc = 'Marca el tráfico de tus juegos como urgente (DSCP 46, como las videollamadas) para que el router lo deje pasar primero cuando la red está ocupada. Solo tiene efecto si tu router respeta estas marcas (QoS o WMM, habitual en routers Wi-Fi); si no, no cambia nada.'
            Why  = "Juegos detectados: $($names -join ', ')"
            Check = { param($t)
                if ("$(Get-RegValue $QosNla 'Do not use NLA')" -ne '1') { return $false }
                $have = @(Get-NetQosPolicy -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
                foreach ($e in @($t.Data)) { if ($have -notcontains "MikiTweaks - $e") { return $false } }
                return $true }
            Apply = { param($t)
                $cur = Get-RegValue $QosNla 'Do not use NLA'
                Backup-Item $t.Id @{ absent = ($null -eq $cur); value = $cur }
                Set-RegValue $QosNla 'Do not use NLA' '1' 'String'
                $have = @(Get-NetQosPolicy -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
                foreach ($e in @($t.Data)) { if ($have -notcontains "MikiTweaks - $e") { New-NetQosPolicy -Name "MikiTweaks - $e" -AppPathNameMatchCondition $e -DSCPAction 46 -NetworkProfile All -IPProtocolMatchCondition Both | Out-Null } } }
            Revert = { param($t)
                $b = Get-BackupItem $t.Id; if ($null -eq $b) { return $false }
                @(Get-NetQosPolicy -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'MikiTweaks - *' }) | ForEach-Object { Remove-NetQosPolicy -Name $_.Name -Confirm:$false -ErrorAction SilentlyContinue }
                if ($b.absent) { Remove-RegValue $QosNla 'Do not use NLA' } else { Set-RegValue $QosNla 'Do not use NLA' "$($b.value)" 'String' }
                Clear-BackupItem $t.Id; return $true }
        }
    }

    # Wi-Fi: menos búsquedas de otras redes (causan picos periódicos) y preferencia por 5 GHz
    $wifi = @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { "$($_.MediaType) $($_.PhysicalMediaType)" -match '802\.11' } | Sort-Object { $_.Status -ne 'Up' }) | Select-Object -First 1
    if (-not $wifi) { return }
    $onWifi = ($wifi.Status -eq 'Up') -and -not $f.NicUp
    if (-not $onWifi -and -not (Test-HasBackup 'net_wifi')) { return }
    $props = @(Get-NetAdapterAdvancedProperty -Name $wifi.Name -AllProperties -ErrorAction SilentlyContinue)
    $items = @()
    $roam = $props | Where-Object { $_.RegistryKeyword -match '^Roam(ing)?Aggressiveness$' } | Select-Object -First 1
    if ($roam -and @($roam.ValidRegistryValues).Count) {
        $low = @(@($roam.ValidRegistryValues) | ForEach-Object { [int]"$_" } | Sort-Object)[0]
        $items += @{ Kw = $roam.RegistryKeyword; Value = "$low"; Label = 'busca otras redes lo mínimo' }
    }
    $band = $props | Where-Object { $_.RegistryKeyword -match 'PreferredBand|BandPreference|PreferBand' } | Select-Object -First 1
    if ($band -and @($band.ValidDisplayValues).Count) {
        $dv = @($band.ValidDisplayValues); $rv = @($band.ValidRegistryValues)
        for ($i = 0; $i -lt [math]::Min($dv.Count, $rv.Count); $i++) {
            if ("$($dv[$i])" -match '5\s?G' -and "$($dv[$i])" -notmatch '2[\.,]4|6\s?G') { $items += @{ Kw = $band.RegistryKeyword; Value = "$($rv[$i])"; Label = 'prefiere la banda de 5 GHz' }; break }
        }
    }
    if (-not $items.Count) { return }
    Add-Tweak @{ Id = 'net_wifi'; Category = 'Red'; Name = 'Wi-Fi estable para jugar'; Impact = 'Medio'; Glyph = '&#xE701;'; Data = @{ Nic = $wifi.Name; Items = $items }
        Desc = "Evita los picos de ping periódicos de la Wi-Fi: la tarjeta $(($items | ForEach-Object { $_.Label }) -join ' y '). Al aplicarlo, la Wi-Fi se desconecta un par de segundos."
        Why  = "Conectado por Wi-Fi: $($wifi.InterfaceDescription)"
        Check = { param($t)
            foreach ($it in @($t.Data.Items)) {
                $p = Get-NetAdapterAdvancedProperty -Name $t.Data.Nic -RegistryKeyword $it.Kw -AllProperties -ErrorAction SilentlyContinue
                if (-not $p -or "$(@($p.RegistryValue)[0])" -ne "$($it.Value)") { return $false }
            }
            return $true }
        Apply = { param($t)
            $i = 0
            foreach ($it in @($t.Data.Items)) {
                $p = Get-NetAdapterAdvancedProperty -Name $t.Data.Nic -RegistryKeyword $it.Kw -AllProperties -ErrorAction Stop
                Backup-Item "$($t.Id)#$i" @{ value = "$(@($p.RegistryValue)[0])" }
                Set-NetAdapterAdvancedProperty -Name $t.Data.Nic -RegistryKeyword $it.Kw -RegistryValue $it.Value -ErrorAction Stop; $i++
            } }
        Revert = { param($t)
            $i = 0; $any = $false
            foreach ($it in @($t.Data.Items)) {
                $b = Get-BackupItem "$($t.Id)#$i"
                # Si falla, la copia se conserva para poder reintentar (antes se borraba y el valor original se perdía)
                if ($null -ne $b) { try { Set-NetAdapterAdvancedProperty -Name $t.Data.Nic -RegistryKeyword $it.Kw -RegistryValue "$($b.value)" -ErrorAction Stop; Clear-BackupItem "$($t.Id)#$i" } catch { Write-CrashLog $_ "deshacer $($t.Id) ($($it.Kw))" }; $any = $true }
                $i++
            }
            return $any }
    }
}

# ======================= Ajustes avanzados con pruebas (Windows 10 y 11) =======================
# Fuentes: guía PC-Tuning (valleyofdoom), documentación de Microsoft y pruebas publicadas. Solo se proponen si aplican al PC.
function Get-BcdTimers {
    $o = @{}
    try { $out = & bcdedit.exe /enum '{current}' 2>$null } catch { $out = @() }
    foreach ($l in @($out)) { if ("$l" -match '^\s*(useplatformclock|useplatformtick|disabledynamictick|tscsyncpolicy)\s+(\S+)') { $o[$Matches[1]] = $Matches[2] } }
    return $o
}
function Add-AdvancedTweaks($f) {
    # 1) Temporizadores forzados en el arranque (HPET y similares): Windows elige solo el mejor si no se fuerza
    $bcd = Get-BcdTimers
    if ($bcd.Count -or (Test-HasBackup 'adv_bcdtimers')) {
        Add-Tweak @{ Id = 'adv_bcdtimers'; Category = 'Windows'; Name = 'Temporizadores de Windows en automático'; Impact = 'Medio'; Reboot = $true; Glyph = '&#xE916;'
            Desc = 'Algún programa o guía antigua dejó forzado el temporizador de Windows en el arranque (HPET u otros). Forzarlo resta rendimiento y añade latencia en muchos PC; sin forzar, Windows usa el temporizador más rápido de tu procesador. Es volver a lo que trae Windows de fábrica.'
            Why  = $(if ($bcd.Count) { "Detectado en el arranque: $(($bcd.Keys | Sort-Object) -join ', ')" } else { 'Temporizadores devueltos a automático por esta app' })
            Check = { param($t) (Get-BcdTimers).Count -eq 0 }
            Apply = { param($t)
                $cur = Get-BcdTimers
                Backup-Item $t.Id @{ values = $cur }
                foreach ($k in @($cur.Keys)) { & bcdedit.exe /deletevalue '{current}' $k 2>&1 | Out-Null; if ($LASTEXITCODE) { throw "bcdedit no pudo quitar $k" } } }
            Revert = { param($t)
                $b = Get-BackupItem $t.Id; if ($null -eq $b) { return $false }
                foreach ($pp in @($b.values.PSObject.Properties)) {
                    $v = "$($pp.Value)"; $v = if ($pp.Name -eq 'tscsyncpolicy') { $v.ToLower() } elseif ($v -match '^(Yes|S.?|Ja|Oui|1|On|True)$' -and $v -notmatch '^No') { 'yes' } else { 'no' }
                    & bcdedit.exe /set '{current}' $pp.Name $v 2>&1 | Out-Null
                }
                Clear-BackupItem $t.Id; return $true }
        }
    }

    # 2) Modo MSI de la gráfica dedicada (interrupciones más rápidas), solo si el dispositivo lo admite y no está activo
    $gpu = @(Get-PnpDevice -Class Display -PresentOnly -ErrorAction SilentlyContinue | Where-Object { "$($_.FriendlyName)" -match 'NVIDIA|Radeon RX|Radeon Pro|Arc\(TM\) A' }) | Select-Object -First 1
    if ($gpu) {
        $mk = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($gpu.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
        if ((Test-Path $mk) -and ("$(Get-RegValue $mk 'MSISupported')" -ne '1' -or (Test-HasBackup 'adv_msi'))) {
            New-RegTweak @{ Id = 'adv_msi'; Category = 'Windows'; Name = 'Modo MSI para la gráfica'; Impact = 'Bajo'; Tier = 'Opcional'; Reboot = $true; Glyph = '&#xE950;'
                Desc = 'La gráfica avisa al procesador con interrupciones por mensaje (MSI) en vez de por línea compartida: menos latencia de interrupción y menos tirones raros en algunos equipos. NVIDIA no lo activa en todas sus gráficas y lo desactiva al reinstalar el driver; si eso pasa, la app te lo vuelve a proponer.'
                Why  = "Detectado: $($gpu.FriendlyName) sin modo MSI" } @((RegV $mk 'MSISupported' 1))
        }
    }

    # 3) Fault Tolerant Heap: Windows "parchea" a escondidas los programas que se cierran de golpe, y eso puede frenarlos
    New-RegTweak @{ Id = 'adv_fth'; Category = 'Windows'; Name = 'Sin parches automáticos tras cierres inesperados'; Impact = 'Bajo'; Tier = 'Opcional'; Glyph = '&#xE90F;'
        Desc = 'Si un juego se cierra de golpe varias veces, Windows le aplica en silencio una protección de memoria (Fault Tolerant Heap) que puede hacerlo ir más lento para siempre. Con esto deja de hacerlo; los juegos se ejecutan tal como los hizo su desarrollador.'
        Why  = 'Documentado por Microsoft; activado por defecto' } @((RegV 'HKLM:\SOFTWARE\Microsoft\FTH' 'Enabled' 0))

    # 4) Windows baja el volumen del juego al detectar una llamada (Discord, Teams...)
    New-RegTweak @{ Id = 'adv_ducking'; Category = 'Windows'; Name = 'El juego no baja de volumen en las llamadas'; Impact = 'Bajo'; Glyph = '&#xE767;'
        Desc = 'Por defecto, Windows baja un 80 % el resto de sonidos cuando detecta una llamada, y en muchas partidas con Discord dejas de oír los pasos. Con esto el juego se oye siempre igual.'
        Why  = 'Windows atenúa el audio en las llamadas por defecto' } @((RegV 'HKCU:\Software\Microsoft\Multimedia\Audio' 'UserDuckingPreference' 3))

    # 5) Inicio rápido: al apagar no se reinicia de verdad el núcleo de Windows ni los drivers
    if ((Test-Path "$env:SystemDrive\hiberfil.sys") -or (Test-HasBackup 'adv_faststartup')) {
        New-RegTweak @{ Id = 'adv_faststartup'; Category = 'Windows'; Name = 'Sin inicio rápido (apagar es apagar de verdad)'; Impact = 'Bajo'; Glyph = '&#xE7E8;'
            Desc = 'Con el inicio rápido, apagar el PC guarda el estado de Windows y de los drivers en el disco y lo recupera al encender, así que los fallos y fugas de memoria se arrastran días. Sin él, cada encendido es limpio. El arranque tarda unos segundos más.'
            Why  = 'Inicio rápido activado' } @((RegV 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled' 0))
    }

    # 6) Windows Update no instala drivers (evita que cambie el de la gráfica por uno más antiguo)
    if ("$($f.GPU)" -match 'NVIDIA|AMD|Radeon' -or (Test-HasBackup 'adv_wudrivers')) {
        New-RegTweak @{ Id = 'adv_wudrivers'; Category = 'Windows'; Name = 'Windows Update no cambia tus drivers'; Impact = 'Medio'; Tier = 'Opcional'; Glyph = '&#xE895;'
            Desc = 'Windows Update a veces sustituye el driver de la gráfica que instalaste tú por uno más antiguo o genérico, y pierdes rendimiento sin darte cuenta. Con esto deja de instalar drivers; las actualizaciones de seguridad siguen igual. Los drivers los actualizas tú desde la página Actualizaciones o la web del fabricante.'
            Why  = "Gráfica dedicada: $($f.GPU)" } @((RegV 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'ExcludeWUDriversInQualityUpdate' 1))
    }

    # 7) Transparencias del escritorio
    New-RegTweak @{ Id = 'adv_transparency'; Category = 'Windows'; Name = 'Sin efectos de transparencia'; Impact = 'Bajo'; Tier = 'Opcional'; Glyph = '&#xE790;'
        Desc = 'La barra de tareas, el menú Inicio y las ventanas dejan de ser translúcidos. Ahorra un poco de procesador y de gráfica en segundo plano; el cambio es sobre todo estético.'
        Why  = 'Transparencias activadas' } @((RegV 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0))

    # 8) Marca de último acceso en NTFS (solo si está activa: en la mayoría de PC modernos Windows ya la tiene apagada)
    $la = Get-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'NtfsDisableLastAccessUpdate'
    if (($null -ne $la -and (([int64]$la -band 1) -eq 0)) -or (Test-HasBackup 'adv_lastaccess')) {
        New-RegTweak @{ Id = 'adv_lastaccess'; Category = 'Windows'; Name = 'Sin marca de último acceso en el disco'; Impact = 'Bajo'; Tier = 'Opcional'; Glyph = '&#xEDA2;'
            Desc = 'Windows apunta la fecha de último acceso cada vez que se lee un archivo, lo que añade escrituras al disco al cargar juegos con miles de archivos. Microsoft indica que desactivarlo acelera el acceso a archivos; algún programa de copias de seguridad antiguo podría usar esa fecha.'
            Why  = 'Detectado: marca de último acceso activada' } @((RegV 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'NtfsDisableLastAccessUpdate' (-2147483647)))
    }
}

function Build-Catalog($f) {
    $script:Tweaks = New-Object System.Collections.Generic.List[object]

    # ---------- FORTNITE (archivo de configuración del juego) ----------
    if ($f.FnIni -and $f.FnInstalled) {
        $perf = ("$($f.Fn_PreferredFeatureLevel)" -eq 'es31') -and ("$($f.Fn_PreferredRHI)" -ne 'dx11')
        New-IniTweak @{ Id = 'fn_perfmode'; Name = 'Modo de renderizado Rendimiento'; Impact = 'Alto'; Glyph = '&#xE945;'
            Desc = 'DirectX 12 con el nivel gráfico ligero (ES3.1), lo que Fortnite llama "Rendimiento". Es el modo que más FPS da y el que menos carga la CPU en portátiles, a cambio de gráficos más simples.'
            Why  = $(if ($perf) { 'Detectado: ya usas el modo Rendimiento' } else { 'Detectado: DirectX 12 con gráficos completos' }) } @((IniV 'PreferredRHI' 'dx12' 'D3DRHIPreference'), (IniV 'PreferredFeatureLevel' 'es31' 'D3DRHIPreference'))
        ($script:Tweaks | Where-Object Id -eq 'fn_perfmode').Check = { param($t) if (-not (Test-Path $FnIni)) { return $false }; ("$(Get-IniValue 'PreferredFeatureLevel')" -eq 'es31') -and ("$(Get-IniValue 'PreferredRHI')" -ne 'dx11') }
        if ($f.IsNvidia) {
            $rm = @{ '0' = 'desactivado'; '1' = 'activado'; '2' = 'activado + aumento' }["$($f.Fn_LatencyTweak2)"]
            New-IniTweak @{ Id = 'fn_reflex'; Name = 'NVIDIA Reflex: Activado + Aumento'; Impact = 'Alto'; Glyph = '&#xE945;'
                Desc = 'Sincroniza CPU y GPU para que cada fotograma llegue a la pantalla lo antes posible. Es lo que más baja la latencia en una tarjeta NVIDIA.'
                Why  = "Detectado: Reflex $rm" } @((IniV 'LatencyTweak2' '2'))
        }
        New-IniTweak @{ Id = 'fn_fullscreen'; Name = 'Pantalla completa exclusiva'; Impact = 'Medio'; Glyph = '&#xE740;'
            Desc = 'La pantalla completa real tiene menos latencia que ventana o ventana sin bordes.'
            Why  = $(if ($f.Fn_FullscreenMode -eq '0') { 'Detectado: ya en pantalla completa' } else { 'Detectado: modo ventana' }) } @((IniV 'FullscreenMode' '0'), (IniV 'LastConfirmedFullscreenMode' '0'), (IniV 'PreferredFullscreenMode' '0'))
        if ($f.MainHz -gt 0) {
            $cap = (@(60, 75, 120, 144, 165, 170, 180, 240, 280, 360) | Sort-Object { [math]::Abs($_ - $f.MainHz) } | Select-Object -First 1)
            $curCap = "$($f.Fn_FrameRateLimit)" -replace '\.0+$', ''
            New-IniTweak @{ Id = 'fn_fpscap'; Name = "Limitar FPS a $cap"; Impact = 'Bajo'; Tier = 'Opcional'; Glyph = '&#xE7F4;'
                Desc = "Ajusta el tope de FPS a la frecuencia de tu monitor. Con Reflex no hace falta, pero da frametimes más estables y el portátil se calienta menos."
                Why  = "Detectado: tope en $(if ($curCap -eq '0' -or -not $curCap) { 'ilimitado' } else { $curCap }) · monitor a $($f.MainHz) Hz" } @((IniV 'FrameRateLimit' ("{0}.000000" -f $cap)))
        }
    }
    # ---------- AJUSTES POR JUEGO ----------
    $gpuShort = ($f.GPU -replace 'NVIDIA GeForce |AMD Radeon |Laptop GPU', '').Trim()
    foreach ($g in @($f.Games)) {
        $def = $GameDefById[$g.Id]
        $prioId = if ($g.Id -eq 'fortnite') { 'fn_priority' } else { "g_$($g.Id)_priority" }
        New-RegTweak @{ Id = $prioId; Category = $g.Id; Name = 'Prioridad de CPU alta'; Impact = 'Medio'; Glyph = '&#xE9D9;'
            Desc = "Windows le da prioridad alta a $($def.Name) cada vez que se abre, para que Discord, Medal o el navegador no le roben CPU."
            Why  = "Detectado: $(Split-Path $g.Paths[0] -Leaf) · $($f.CPU)" } @($def.Exes | ForEach-Object { RegV "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$_\PerfOptions" 'CpuPriorityClass' 3 })
        if ($f.Hybrid) {
            $gpuId = if ($g.Id -eq 'fortnite') { 'fn_gpu' } else { "g_$($g.Id)_gpu" }
            New-RegTweak @{ Id = $gpuId; Category = $g.Id; Name = "Siempre en la $gpuShort"; Impact = 'Alto'; Glyph = '&#xE7F4;'
                Desc = 'Obliga a Windows a usar la gráfica dedicada y nunca la integrada.'
                Why  = 'Detectado: portátil con gráfica integrada + dedicada' } @($g.Paths | ForEach-Object { RegV 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' $_ 'GpuPreference=2;' 'String' })
        }
        if ($f.IsNvidia -and ('CtNvDrs' -as [type])) {
            Add-Tweak @{ Id = "g_$($g.Id)_nvcp"; Category = $g.Id; Name = 'Panel de NVIDIA: máximo rendimiento y baja latencia'; Impact = 'Medio'; Glyph = '&#xE7F4;'
                Data = @{ Exes = @($def.Exes); Friendly = $def.Name }
                Desc = "Ajusta el perfil de $($def.Name) en el panel de control de NVIDIA: la gráfica no baja de frecuencia en mitad de la partida y el procesador no prepara fotogramas de más. Solo afecta a este juego."
                Why  = "Detectado: $($f.GPU) · driver $($f.NvDriver)"
                Check = { param($t)
                    Invoke-NvDrs {
                        foreach ($exe in $t.Data.Exes) {
                            $p = [CtNvDrs]::ProfileFor($exe, $t.Data.Friendly, $false); if ($p -eq [IntPtr]::Zero) { return $false }
                            foreach ($s in $NvSettings) { $v = [CtNvDrs]::Get($p, $s.Id); if ($v[0] -ne 0 -or $v[2] -ne $s.Value) { return $false } }
                        }
                        return $true } }
                Apply = { param($t)
                    Invoke-NvDrs -Save {
                        foreach ($exe in $t.Data.Exes) {
                            $p = [CtNvDrs]::ProfileFor($exe, $t.Data.Friendly, $true)
                            foreach ($s in $NvSettings) {
                                $v = [CtNvDrs]::Get($p, $s.Id)
                                # Si el valor ya estaba en el perfil del juego se guarda; si lo heredaba del global, al deshacer se quita
                                Backup-Item "$($t.Id)#$exe#$($s.Id)" @{ absent = -not ($v[0] -eq 0 -and $v[1] -eq 0); value = [uint32]$v[2] }
                                $r = [CtNvDrs]::Set($p, $s.Id, [uint32]$s.Value); if ($r -ne 0) { throw "NVIDIA rechazó el ajuste «$($s.Label)» (código $r)" }
                            }
                        } } }
                Revert = { param($t)
                    if (-not (Test-HasBackup $t.Id)) { return $false }
                    Invoke-NvDrs -Save {
                        foreach ($exe in $t.Data.Exes) {
                            $p = [CtNvDrs]::ProfileFor($exe, $t.Data.Friendly, $false); if ($p -eq [IntPtr]::Zero) { continue }
                            foreach ($s in $NvSettings) {
                                $b = Get-BackupItem "$($t.Id)#$exe#$($s.Id)"; if ($null -eq $b) { continue }
                                if ($b.absent) { [void][CtNvDrs]::Delete($p, $s.Id) } else { [void][CtNvDrs]::Set($p, $s.Id, [uint32]$b.value) }
                                Clear-BackupItem "$($t.Id)#$exe#$($s.Id)"
                            }
                        } }
                    return $true }
            }
        }
        if ($def.Api -eq 'dx11') {
            Add-Tweak @{ Id = "g_$($g.Id)_fso"; Category = $g.Id; Name = 'Sin optimizaciones de pantalla completa'; Impact = 'Bajo'; Tier = 'Opcional'; Glyph = '&#xE740;'
                Desc = 'Fuerza la pantalla completa exclusiva clásica en este juego DirectX 11. En algunos equipos baja un poco la latencia y en otros no cambia nada: pruébalo y quédate con lo que mejor te vaya.'
                Why  = 'Detectado: juego DirectX 11'
                Data = @($g.Paths)
                Check = { param($t) foreach ($p in $t.Data) { if ("$(Get-RegValue $FsoKey $p)" -notmatch 'DISABLEDXMAXIMIZEDWINDOWEDMODE') { return $false } }; return $true }
                Apply = { param($t)
                    $i = 0
                    foreach ($p in $t.Data) {
                        $cur = Get-RegValue $FsoKey $p
                        Backup-Item "$($t.Id)#$i" @{ absent = ($null -eq $cur); value = $cur }
                        $rest = if ($cur) { ("$cur" -replace '^~\s*', '').Trim() } else { '' }
                        Set-RegValue $FsoKey $p ('~ ' + ("$rest DISABLEDXMAXIMIZEDWINDOWEDMODE").Trim()) 'String'; $i++
                    } }
                Revert = { param($t)
                    $i = 0; $any = $false
                    foreach ($p in $t.Data) {
                        $b = Get-BackupItem "$($t.Id)#$i"
                        if ($null -ne $b) { if ($b.absent) { Remove-RegValue $FsoKey $p } else { Set-RegValue $FsoKey $p $b.value 'String' }; Clear-BackupItem "$($t.Id)#$i"; $any = $true }
                        $i++
                    }
                    return $any }
            }
        }
    }

    # ---------- WINDOWS ----------
    Add-Tweak @{ Id = 'win_gamemode'; Category = 'Windows'; Name = 'Modo Juego siempre activo'; Impact = 'Medio'; Glyph = '&#xE7FC;'; Data = $null
        Desc = 'Activa el Modo Juego y añade una tarea que lo reactiva en cada inicio de sesión, para que no se apague solo tras reiniciar.'
        Why  = 'Windows a veces lo desactiva solo tras reiniciar'
        Check = { param($t) ((Get-RegValue $GameBarKey 'AutoGameModeEnabled') -eq 1) -and (Test-TaskExists $GmTask) }
        Apply = { param($t)
            Set-RegValue $GameBarKey 'AutoGameModeEnabled' 1; Set-RegValue $GameBarKey 'AllowAutoGameMode' 1
            $ps = Join-Path $DataDir 'modo-juego.ps1'
            Set-Content -Path $ps -Encoding ASCII -Value @(
                '$k=''HKCU:\Software\Microsoft\GameBar'''
                'if(-not(Test-Path $k)){New-Item $k -Force|Out-Null}'
                'New-ItemProperty $k -Name AutoGameModeEnabled -Value 1 -PropertyType DWord -Force|Out-Null'
                'New-ItemProperty $k -Name AllowAutoGameMode -Value 1 -PropertyType DWord -Force|Out-Null')
            $user = [Security.Principal.WindowsIdentity]::GetCurrent().Name
            $act = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ps`""
            $trg = New-ScheduledTaskTrigger -AtLogOn -User $user; $trg.Delay = 'PT20S'
            $pri = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
            $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 2)
            Register-ScheduledTask -TaskName $GmTask -Action $act -Trigger $trg -Principal $pri -Settings $set -Force | Out-Null }
        Revert = { param($t)
            if (Test-TaskExists $GmTask) { Unregister-ScheduledTask -TaskName $GmTask -Confirm:$false; return $true }
            return $false }
    }
    if (($f.TimerTool -and $f.WinBuild -ge 22000) -or (Test-HasBackup 'win_timer')) {
        New-RegTweak @{ Id = 'win_timer'; OS = '11'; Category = 'Windows'; Name = 'Resolución de temporizador global'; Impact = 'Medio'; Reboot = $true; Glyph = '&#xE916;'
            Desc = 'En Windows 11 la herramienta de resolución de temporizador no tiene efecto sin esta opción. Con ella, los frametimes son más estables.'
            Why  = 'Detectado: SetTimerResolution arranca con Windows' } @((RegV 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel' 'GlobalTimerResolutionRequests' 1))
    }
    New-RegTweak @{ Id = 'win_mmcss'; Category = 'Windows'; Name = 'Prioridad multimedia para juegos'; Impact = 'Bajo'; Glyph = '&#xE7FC;'
        Desc = 'Sube la prioridad de programación de los juegos y quita el límite de red del planificador multimedia de Windows.'
        Why  = 'Valores por defecto de Windows pensados para ofimática' } @(
        (RegV 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' -1),
        (RegV 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'GPU Priority' 8),
        (RegV 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'Priority' 6),
        (RegV 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'Scheduling Category' 'High' 'String'),
        (RegV 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' 'SFIO Priority' 'High' 'String'))
    if ($f.HVCI -or (Test-HasBackup 'win_hvci')) {
        New-RegTweak @{ Id = 'win_hvci'; Category = 'Windows'; Name = 'Desactivar Integridad de memoria'; Impact = 'Medio'; Tier = 'Opcional'; Reboot = $true; Glyph = '&#xE72E;'
            Desc = 'Suele dar algunos FPS más y algo menos de latencia, a cambio de menos protección frente a drivers maliciosos. Si un anticheat te la pide, vuelve a activarla aquí.'
            Why  = $(if ($f.VBS) { 'Detectado: virtualización de seguridad (VBS) en marcha' } else { 'Detectado: VBS apagado' }) } @((RegV 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' 'Enabled' 0))
    }
    New-RegTweak @{ Id = 'win_gamedvr'; Category = 'Windows'; Name = 'Sin grabación en segundo plano de Xbox'; Impact = 'Medio'; Glyph = '&#xE714;'
        Desc = 'Evita que Game DVR grabe en segundo plano. Tu programa de clips (Medal, Outplayed, NVIDIA...) sigue grabando igual.'
        Why  = 'Game DVR consume GPU mientras juegas' } @((RegV 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0), (RegV 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0))
    New-RegTweak @{ Id = 'win_hags'; Category = 'Windows'; Name = 'Programación de GPU acelerada por hardware'; Impact = 'Medio'; Reboot = $true; Glyph = '&#xE7F4;'
        Desc = 'La GPU gestiona su propia memoria de vídeo. Necesaria para que Reflex rinda al máximo.'
        Why  = "Detectado: $($f.GPU)" } @((RegV 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2))
    New-RegTweak @{ Id = 'win_mouse'; Category = 'Windows'; Name = 'Sin "Mejorar precisión del puntero"'; Impact = 'Medio'; Glyph = '&#xE962;'
        Desc = 'Quita la aceleración de ratón de Windows para que el movimiento sea siempre 1:1.'
        Why  = 'Afecta a todo el sistema, no solo a un juego' } @((RegV 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' 'String'), (RegV 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' 'String'), (RegV 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' 'String'))
    if ($f.Nahimic) {
        Add-Tweak @{ Id = 'win_nahimic'; Category = 'Windows'; Name = 'Desactivar Nahimic (audio MSI)'; Impact = 'Bajo'; Tier = 'Opcional'; Glyph = '&#xE767;'; Data = $null
            Desc = 'Se asocia a menudo con tirones y picos de DPC latency. Pierdes sus efectos de sonido; tus cascos funcionan igual.'
            Why  = 'Detectado: servicio NahimicService instalado'
            Check = { param($t) (Get-Service NahimicService).StartType -eq 'Disabled' }
            Apply = { param($t)
                Backup-Item 'win_nahimic' @{ absent = $false; value = "$((Get-Service NahimicService).StartType)" }
                Stop-Service NahimicService -Force -ErrorAction SilentlyContinue
                Set-Service NahimicService -StartupType Disabled }
            Revert = { param($t)
                $b = Get-BackupItem 'win_nahimic'; if ($null -eq $b) { return $false }
                $st = "$($b.value)"; if ($st -notin @('Automatic', 'Manual', 'Disabled')) { $st = 'Automatic' }
                Set-Service NahimicService -StartupType $st; Start-Service NahimicService -ErrorAction SilentlyContinue
                Clear-BackupItem 'win_nahimic'; return $true }
        }
    }

    # ---------- RED ----------
    if ($f.NicName) {
        $nicTweaks = @(
            @{ Id = 'net_power'; Name = 'Sin ahorro de energía en el Ethernet'; Impact = 'Bajo'; Tier = 'Recomendado'
               Desc = 'Desactiva Ethernet de consumo eficiente, Ethernet ecológico, Power Saving y Gigabit Lite, que pueden provocar microcortes y picos de ping. La conexión se corta 2-3 s al aplicar.'
               Keys = @('*EEE', 'EnableGreenEthernet', 'PowerSavingMode', 'GigaLite', 'AdvancedEEE') },
            @{ Id = 'net_intmod'; Name = 'Sin moderación de interrupciones'; Impact = 'Bajo'; Tier = 'Opcional'
               Desc = 'Los paquetes se procesan al instante en vez de agruparse: algo menos de latencia de red a cambio de un poco más de CPU. La conexión se corta 2-3 s al aplicar.'
               Keys = @('*InterruptModeration') })
        foreach ($nt in $nicTweaks) {
            $present = @($nt.Keys | Where-Object { Get-NetAdapterAdvancedProperty -Name $f.NicName -RegistryKeyword $_ -ErrorAction SilentlyContinue })
            if ($present.Count -eq 0) { continue }
            Add-Tweak @{ Id = $nt.Id; Category = 'Red'; Name = $nt.Name; Desc = $nt.Desc; Impact = $nt.Impact; Tier = $nt.Tier; Glyph = '&#xE839;'
                Why = "Detectado: $($f.NicDesc)"
                Data = @{ Adapter = $f.NicName; Keywords = $present }
                Check = { param($t)
                    foreach ($k in $t.Data.Keywords) {
                        $p = Get-NetAdapterAdvancedProperty -Name $t.Data.Adapter -RegistryKeyword $k
                        foreach ($rv in @($p | ForEach-Object { $_.RegistryValue })) { if ("$rv" -ne '0') { return $false } }
                    }
                    return $true }
                Apply = { param($t)
                    $i = 0
                    foreach ($k in $t.Data.Keywords) {
                        $p = Get-NetAdapterAdvancedProperty -Name $t.Data.Adapter -RegistryKeyword $k
                        Backup-Item "$($t.Id)#$i" @{ absent = $false; value = "$($p.RegistryValue)" }
                        Set-NetAdapterAdvancedProperty -Name $t.Data.Adapter -RegistryKeyword $k -RegistryValue '0' -NoRestart; $i++
                    }
                    Restart-NetAdapter -Name $t.Data.Adapter -Confirm:$false }
                Revert = { param($t)
                    $i = 0; $any = $false
                    foreach ($k in $t.Data.Keywords) {
                        $b = Get-BackupItem "$($t.Id)#$i"
                        if ($null -ne $b) { Set-NetAdapterAdvancedProperty -Name $t.Data.Adapter -RegistryKeyword $k -RegistryValue (("$($b.value)" -split ' ')[0]) -NoRestart; Clear-BackupItem "$($t.Id)#$i"; $any = $true }
                        $i++
                    }
                    if ($any) { Restart-NetAdapter -Name $t.Data.Adapter -Confirm:$false }
                    return $any }
            }
        }
    }

    # ---------- INICIO (Medal y Vanguard nunca aparecen) ----------
    foreach ($name in @($f.StartupNames)) {
        if ($name -match 'Medal|Vanguard|SecurityHealth') { continue }
        $k = $StartupKnown[$name]
        if ($name -like 'MicrosoftEdgeAutoLaunch*') { $k = @('Microsoft Edge (precarga)', $true, 'Edge se precarga al encender aunque no lo uses.') }
        if (-not $k) { $k = @($name, $false, 'Programa que arranca con Windows.') }
        Add-Tweak @{ Id = "startup_$name"; Category = 'Inicio'; Name = "No abrir $($k[0]) al encender"; Desc = $k[2]; Impact = 'Bajo'
            Tier = $(if ($k[1]) { 'Recomendado' } else { 'Opcional' }); Glyph = '&#xE768;'; Data = $name
            Why = 'Detectado en el inicio de Windows'
            Check = { param($t) $b = Get-RegValue $ApprovedRun $t.Data; return (($null -ne $b) -and (($b[0] -band 1) -eq 1)) }
            Apply = { param($t)
                $b = Get-RegValue $ApprovedRun $t.Data
                Backup-Item $t.Id @{ absent = ($null -eq $b); value = 'enabled' }
                $new = [byte[]](@(3, 0, 0, 0) + [BitConverter]::GetBytes([DateTime]::Now.ToFileTime()))
                Set-RegValue $ApprovedRun $t.Data $new 'Binary' }
            Revert = { param($t)
                $b = Get-BackupItem $t.Id; if ($null -eq $b) { return $false }
                if ($b.absent) { Remove-RegValue $ApprovedRun $t.Data } else { Set-RegValue $ApprovedRun $t.Data ([byte[]](2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)) 'Binary' }
                Clear-BackupItem $t.Id; return $true }
        }
    }
    Invoke-Safe 'ajustes de los juegos' { Add-GameCfgTweaks $f }
    Invoke-Safe 'ajustes Debloat' { Add-DebloatTweaks $f }
    Invoke-Safe 'ajustes Extra' { Add-ExtraTweaks $f }
    Invoke-Safe 'ajustes Peripheral' { Add-PeripheralTweaks $f }
    Invoke-Safe 'ajustes Win10' { Add-Win10Tweaks $f }
    Invoke-Safe 'ajustes de red' { Add-NetPlusTweaks $f }
    Invoke-Safe 'ajustes avanzados' { Add-AdvancedTweaks $f }
}

function Test-Tweak($t) {
    $ok = $false; try { $ok = [bool](& $t.Check $t) } catch {}
    $t.Applied = $ok
    $t.HasBackup = if ($t.Id -eq 'win_gamemode') { Test-TaskExists $GmTask } else { Test-HasBackup $t.Id }
}

# ======================= Diagnóstico =======================
function Build-Diagnostics($f) {
    $d = New-Object System.Collections.Generic.List[object]
    function D($lvl, $title, $text) { $d.Add(@{ Level = $lvl; Title = $title; Text = $text }) }
    if ($f.Laptop) {
        if ($f.OnAC) { D 'ok' 'Conectado al cargador' 'Así la CPU y la GPU rinden al 100 %. Juega siempre enchufado.' }
        else { D 'warn' "Estás usando la batería ($($f.BatteryPct) %)" 'Con batería el portátil limita mucho la potencia. Enchúfalo antes de jugar.' }
    }
    if ($f.Hybrid) {
        if ($f.dGPUHz -gt 0) { D 'ok' "Monitor de $($f.dGPUHz) Hz conectado a la gráfica dedicada" 'Es la pantalla con menos latencia: juega en ella. La pantalla del portátil pasa por la gráfica integrada y añade retardo.' }
        else { D 'warn' 'Juegas en la pantalla del portátil' 'La imagen pasa por la gráfica integrada (Optimus) y añade latencia. Si el programa del fabricante (MSI Center, Armoury Crate...) tiene "GPU Switch" / modo solo dedicada, actívalo.' }
    }
    if ($f.RamModules -ge 2) { D 'ok' "RAM en doble canal ($($f.RamModules)x$($f.RamModGB) GB)" "Funciona a $($f.RamSpeed) MT/s." }
    elseif ($f.RamModules -eq 1) { D 'warn' 'RAM en un solo canal' 'Con un solo módulo pierdes bastantes FPS en casi todos los juegos. Añadir un segundo módulo igual es la mejora de hardware más rentable.' }
    if ($f.RamRated -and $f.RamSpeed -and [int]$f.RamSpeed -lt 0.95 * [int]$f.RamRated) {
        if ($f.Laptop) { D 'info' "La RAM va a $($f.RamSpeed) MT/s (los módulos admiten $($f.RamRated))" 'En los portátiles es normal: el procesador o la BIOS fijan la velocidad máxima y no se puede cambiar.' }
        else { D 'warn' "La RAM va más lenta de lo que admite ($($f.RamSpeed) de $($f.RamRated) MT/s)" 'Activa el perfil XMP (Intel) o EXPO (AMD) en la BIOS. Es gratis y da FPS, sobre todo en el 1 % más bajo. Si el PC se vuelve inestable, desactívalo otra vez.' }
    }
    $pct = if ($f.DiskSizeGB) { [math]::Round(100 * $f.DiskFreeGB / $f.DiskSizeGB) } else { 100 }
    if ($pct -lt 12) { D 'warn' "Disco casi lleno ($($f.DiskFreeGB) GB libres)" 'Con menos de un 10-15 % libre Windows y las cachés de sombreado van peor. Libera espacio.' }
    else { D 'ok' "Espacio en disco correcto ($($f.DiskFreeGB) GB libres)" 'Suficiente para cachés de sombreado y actualizaciones.' }
    if ($f.WifiOnly) { D 'warn' 'Estás jugando por Wi-Fi' 'El cable de red da un ping mucho más estable.' }
    elseif ($f.NicUp -and "$($f.NicDesc)" -match 'GbE|Gigabit|2\.5G|1000' -and "$($f.NicSpeed)" -match '^(10|100) Mbps$') { D 'warn' "Tu cable de red va a $($f.NicSpeed) en vez de 1 Gbps" 'Tu tarjeta es Gigabit, pero el enlace con el router se ha negociado a menos velocidad. Casi siempre es el cable (un hilo dañado o un cable antiguo) o el puerto del router: prueba otro cable Cat 5e o Cat 6 y otro puerto. A veces basta con desenchufarlo y volver a enchufarlo. Así tu conexión no pasa de 100 Mbps y el ping sube más cuando la red está ocupada.' }
    elseif ($f.NicUp) { D 'ok' "Conectado por cable ($($f.NicSpeed))" 'La mejor opción para un ping estable.' }
    if ($f.NvDriver) { D 'info' "Driver NVIDIA $($f.NvDriver)" 'Busca actualizaciones de vez en cuando en la NVIDIA App (instalación limpia).' }
    if ($f.PowerPlan) { D 'info' "Plan de energía: $($f.PowerPlan)" 'La app no modifica tus planes: los Modos solo eligen cuál está activo.' }
    $gc = @($f.Games).Count
    if ($gc -eq 0) { D 'warn' 'No se ha encontrado ningún juego competitivo' 'Si tienes alguno en una carpeta poco habitual, ábrelo y vuelve a escanear: la app también detecta los juegos que están en marcha.' }
    else { D 'ok' "$gc juego$(if ($gc -ne 1) { 's' }) competitivo$(if ($gc -ne 1) { 's' }) detectado$(if ($gc -ne 1) { 's' })" ((@($f.Games) | ForEach-Object { $GameDefById[$_.Id].Name }) -join '  ·  ') }
    $run = @(@($f.Games) | Where-Object { $_.Running } | ForEach-Object { $GameDefById[$_.Id].Name })
    if ($run.Count) { D 'info' "Abierto ahora: $($run -join ', ')" 'La prioridad y la gráfica se aplican la próxima vez que lo abras. Los ajustes del archivo de Fortnite necesitan que el juego esté cerrado.' }
    if ($f.FnInstalled -and -not $f.FnIni) { D 'warn' 'No se encontró la configuración de Fortnite' 'Abre Fortnite una vez y vuelve a escanear para ver sus ajustes del juego.' }
    # ---- Arranque seguro, reinicios y antigüedad del driver ----
    $sb = $null; try { $sb = Confirm-SecureBootUEFI -ErrorAction Stop } catch {}
    if ($sb -eq $true) { D 'ok' 'Arranque seguro (Secure Boot) activado' 'Lo exigen VALORANT (Vanguard), FACEIT y otros anticheats en Windows 11.' }
    elseif ($sb -eq $false) { D 'warn' 'Arranque seguro (Secure Boot) desactivado' 'VALORANT y otros anticheats lo exigen en Windows 11. Se activa desde la BIOS/UEFI del PC.' }
    if ((Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') -or (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')) {
        D 'warn' 'Tienes un reinicio pendiente' 'Windows tiene actualizaciones a medio instalar. Reinicia antes de jugar para que no te pille en mitad de una partida.'
    }
    try {
        $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime; $days = [int]((Get-Date) - $boot).TotalDays
        if ($days -ge 7) { D 'info' "Llevas $days días sin reiniciar" 'Reiniciar de vez en cuando libera memoria y termina las actualizaciones. Ojo: con el inicio rápido de Windows, apagar no cuenta como reiniciar.' }
    } catch {}
    if ($f.GPUDriverDate -and -not $f.IsNvidia) {
        try {
            $dd = [datetime]::ParseExact($f.GPUDriverDate, 'dd/MM/yyyy', $null); $mo = [int](((Get-Date) - $dd).TotalDays / 30)
            if ($mo -ge 6) { D 'warn' "El driver de la gráfica tiene $mo meses" 'Los drivers nuevos suelen traer mejoras para juegos recientes. Mira la página Actualizaciones.' }
        } catch {}
    }
    # ---- Salud del hardware ----
    foreach ($dk in @($f.Disks)) {
        if ($dk.Health -and $dk.Health -ne 'Healthy') { D 'warn' "El disco $($dk.Name) tiene problemas" 'Windows lo marca como no saludable. Haz copia de seguridad de lo importante y mira la página Salud del PC.' }
        elseif ($null -ne $dk.Wear -and [int]$dk.Wear -ge 80) { D 'warn' "El disco $($dk.Name) está muy desgastado ($($dk.Wear) %)" 'Le queda poca vida útil. Plantéate cambiarlo y guarda copia de lo importante.' }
    }
    if ($f.BatteryHealth -and [int]$f.BatteryHealth -lt 70) { D 'warn' "La batería está al $($f.BatteryHealth) % de su capacidad original" 'Dura bastante menos que nueva. Si juegas siempre enchufado, limita la carga al 80 % en el software del portátil.' }
    if ($f.BootSeconds -and [int]$f.BootSeconds -gt 60) { D 'info' "Windows tarda $($f.BootSeconds) s en arrancar" 'Quitar programas de «Inicio de Windows» es lo que más lo acelera.' }
    # ---- Windows 10: soporte y paso a Windows 11 ----
    if ($f.WinBuild -and $f.WinBuild -lt 22000) {
        if ($f.WinBuild -lt 19045) {
            D 'warn' 'Tu Windows 10 no es la última versión (22H2)' "Tienes la compilación $($f.WinBuild). Actualiza a Windows 10 22H2 desde Windows Update: es la única versión que recibe parches de seguridad (ESU) y la que tiene todos los ajustes de esta app."
        }
        $last = $null; try { $last = (Get-HotFix -ErrorAction Stop | Where-Object { $_.InstalledOn } | Sort-Object InstalledOn -Descending | Select-Object -First 1).InstalledOn } catch {}
        $days = if ($last) { [int]((Get-Date) - $last).TotalDays } else { $null }
        if ($null -ne $days -and $days -le 60) {
            D 'info' 'Windows 10 con actualizaciones de seguridad extendidas' "El soporte normal terminó el 14 de octubre de 2025. Este PC recibió su última actualización hace $days días, así que parece inscrito en ESU, que da parches gratis hasta el 12 de octubre de 2027."
        } else {
            D 'warn' 'Windows 10 sin actualizaciones de seguridad' "El soporte terminó el 14 de octubre de 2025 y $(if ($null -ne $days) { "la última actualización instalada es de hace $days días" } else { 'no se ve ninguna actualización reciente' }). Inscríbete gratis en ESU desde Windows Update (parches hasta el 12 de octubre de 2027) o pasa a Windows 11: algunos anticheats y juegos nuevos ya lo exigen."
        }
        $tpm = $null; try { $tpm = Get-Tpm -ErrorAction Stop } catch {}
        $tpmDev = @(Get-PnpDevice -PresentOnly -Class SecurityDevices -ErrorAction SilentlyContinue | Where-Object { "$($_.InstanceId)" -match 'MSFT0101|PNP0C31' -or "$($_.FriendlyName)" -match 'TPM|Trusted Platform|plataforma segura' }).Count -gt 0
        $tpmOk = $tpmDev -or ($tpm -and $tpm.TpmPresent); $sbOk = $false; try { $sbOk = [bool](Confirm-SecureBootUEFI -ErrorAction Stop) } catch {}
        if ($tpmOk -and $f.RamGB -ge 4) {
            D 'info' 'Tu PC tiene lo básico para Windows 11' "TPM detectado$(if ($sbOk) { ' y arranque seguro activo' } else { '; el arranque seguro se activa en la BIOS' }). El procesador también tiene que estar en la lista de Microsoft: compruébalo con la app «Comprobación de estado del PC»."
        } elseif (-not $tpmOk -and $tpm) {
            D 'info' 'No se detecta chip TPM' 'Windows 11 lo necesita. En muchos PC viene desactivado en la BIOS (Intel PTT o AMD fTPM): actívalo ahí antes de dar por hecho que no es compatible.'
        }
    }
    return $d
}

# ======================= Modos (Juego / Trabajo / Ahorro de batería) =======================
if (-not ('CtNative' -as [type])) {
    Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices; using System.Collections.Generic;
public static class CtNative {
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
  public struct DISPLAY_DEVICE { public int cb; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string DeviceName; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceString; public int StateFlags; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceID; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceKey; }
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
  public struct DEVMODE { [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmDeviceName; public short dmSpecVersion; public short dmDriverVersion; public short dmSize; public short dmDriverExtra; public int dmFields; public int dmPositionX; public int dmPositionY; public int dmDisplayOrientation; public int dmDisplayFixedOutput; public short dmColor; public short dmDuplex; public short dmYResolution; public short dmTTOption; public short dmCollate; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmFormName; public short dmLogPixels; public int dmBitsPerPel; public int dmPelsWidth; public int dmPelsHeight; public int dmDisplayFlags; public int dmDisplayFrequency; public int dmICMMethod; public int dmICMIntent; public int dmMediaType; public int dmDitherType; public int dmReserved1; public int dmReserved2; public int dmPanningWidth; public int dmPanningHeight; }
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern bool EnumDisplayDevices(string lpDevice, uint iDevNum, ref DISPLAY_DEVICE dd, uint flags);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern bool EnumDisplaySettings(string dev, int mode, ref DEVMODE dm);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int ChangeDisplaySettingsEx(string dev, ref DEVMODE dm, IntPtr hwnd, uint flags, IntPtr lParam);
  [DllImport("powrprof.dll")] static extern uint PowerSetActiveOverlayScheme(Guid overlay);
  [DllImport("powrprof.dll")] static extern uint PowerGetEffectiveOverlayScheme(out Guid overlay);
  static DEVMODE NewMode() { DEVMODE m = new DEVMODE(); m.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE)); return m; }
  public static string FindDisplay(string adapterRegex) {
    DISPLAY_DEVICE d = new DISPLAY_DEVICE(); d.cb = Marshal.SizeOf(d);
    for (uint i = 0; EnumDisplayDevices(null, i, ref d, 0); i++) {
      if ((d.StateFlags & 1) != 0 && System.Text.RegularExpressions.Regex.IsMatch(d.DeviceString, adapterRegex)) return d.DeviceName;
      d = new DISPLAY_DEVICE(); d.cb = Marshal.SizeOf(d);
    }
    return null;
  }
  public static int Current(string dev) { DEVMODE m = NewMode(); return EnumDisplaySettings(dev, -1, ref m) ? m.dmDisplayFrequency : 0; }
  public static int[] Rates(string dev) {
    DEVMODE cur = NewMode(); EnumDisplaySettings(dev, -1, ref cur);
    List<int> l = new List<int>(); DEVMODE m = NewMode();
    for (int i = 0; EnumDisplaySettings(dev, i, ref m); i++) {
      if (m.dmPelsWidth == cur.dmPelsWidth && m.dmPelsHeight == cur.dmPelsHeight && m.dmDisplayFrequency > 1 && !l.Contains(m.dmDisplayFrequency)) l.Add(m.dmDisplayFrequency);
      m = NewMode();
    }
    l.Sort(); return l.ToArray();
  }
  public static int SetRate(string dev, int hz) { DEVMODE m = NewMode(); EnumDisplaySettings(dev, -1, ref m); m.dmDisplayFrequency = hz; m.dmFields = 0x400000; return ChangeDisplaySettingsEx(dev, ref m, IntPtr.Zero, 0x01, IntPtr.Zero); }
  public static uint SetOverlay(string guid) { return PowerSetActiveOverlayScheme(new Guid(guid)); }
  public static string[] ActiveDisplays() {
    List<string> r = new List<string>(); DISPLAY_DEVICE d = new DISPLAY_DEVICE(); d.cb = Marshal.SizeOf(d);
    for (uint i = 0; EnumDisplayDevices(null, i, ref d, 0); i++) {
      if ((d.StateFlags & 1) != 0) r.Add(d.DeviceName + "|" + d.DeviceString + "|" + (((d.StateFlags & 4) != 0) ? "1" : "0"));
      d = new DISPLAY_DEVICE(); d.cb = Marshal.SizeOf(d);
    }
    return r.ToArray();
  }
  public static string MonitorName(string dev) { DISPLAY_DEVICE m = new DISPLAY_DEVICE(); m.cb = Marshal.SizeOf(m); return EnumDisplayDevices(dev, 0, ref m, 0) ? m.DeviceString : ""; }
  [DllImport("ntdll.dll")] static extern int NtQueryTimerResolution(out uint min, out uint max, out uint cur);
  public static double TimerResolutionMs() { uint a, b, c; NtQueryTimerResolution(out a, out b, out c); return c / 10000.0; }
}
'@
}

# ======================= Panel de control de NVIDIA (NvAPI DRS, la API oficial del driver) =======================
# Perfiles por juego como los del panel de NVIDIA, sin herramientas externas. IDs de función de nvapi_interface.h.
if (-not ('CtNvDrs' -as [type])) {
    try {
        Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public static class CtNvDrs {
  [DllImport("nvapi64.dll", EntryPoint = "nvapi_QueryInterface", CallingConvention = CallingConvention.Cdecl)] static extern IntPtr QI(uint id);
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)] struct PROFILE { public uint version; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 2048)] public string profileName; public uint gpuSupport; public uint isPredefined; public uint numOfApps; public uint numOfSettings; }
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)] struct APP { public uint version; public uint isPredefined; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 2048)] public string appName; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 2048)] public string userFriendlyName; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 2048)] public string launcher; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 2048)] public string fileInFolder; public uint flags; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 2048)] public string commandLine; }
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)] struct SETTING { public uint version; [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 2048)] public string settingName; public uint settingId; public int settingType; public int settingLocation; public uint isCurrentPredefined; public uint isPredefinedValid; public uint predefinedValue; [MarshalAs(UnmanagedType.ByValArray, SizeConst = 4096)] public byte[] predefinedRest; public uint currentValue; [MarshalAs(UnmanagedType.ByValArray, SizeConst = 4096)] public byte[] currentRest; }
  [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int D0();
  [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int DOutPtr(out IntPtr s);
  [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int DSess(IntPtr s);
  [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int DFindApp(IntPtr s, ushort[] app, out IntPtr p, ref APP a);
  [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int DFindProf(IntPtr s, ushort[] name, out IntPtr p);
  [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int DCreateProf(IntPtr s, ref PROFILE pi, out IntPtr p);
  [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int DCreateApp(IntPtr s, IntPtr p, ref APP a);
  [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int DGet(IntPtr s, IntPtr p, uint id, ref SETTING st);
  [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int DSet(IntPtr s, IntPtr p, ref SETTING st);
  [UnmanagedFunctionPointer(CallingConvention.Cdecl)] delegate int DDel(IntPtr s, IntPtr p, uint id);
  static T F<T>(uint id) where T : class { IntPtr f = QI(id); if (f == IntPtr.Zero) throw new Exception("NvAPI: función 0x" + id.ToString("X8") + " no disponible en este driver"); return Marshal.GetDelegateForFunctionPointer(f, typeof(T)) as T; }
  static ushort[] U(string s) { ushort[] b = new ushort[2048]; for (int i = 0; i < s.Length && i < 2047; i++) b[i] = s[i]; return b; }
  static uint Ver(Type t, uint v) { return (uint)Marshal.SizeOf(t) | (v << 16); }
  static IntPtr Session = IntPtr.Zero;
  public static int Open() {
    int r = F<D0>(0x0150E828)(); if (r != 0) return r;                       // NvAPI_Initialize
    IntPtr s; r = F<DOutPtr>(0x0694D52E)(out s); if (r != 0) return r;       // DRS_CreateSession
    Session = s; return F<DSess>(0x375DBD6B)(Session);                       // DRS_LoadSettings
  }
  public static int Save() { return F<DSess>(0xFCBC7E14)(Session); }        // DRS_SaveSettings
  public static void Close() { if (Session != IntPtr.Zero) { F<DSess>(0xDAD9CFF8)(Session); Session = IntPtr.Zero; } }
  // Perfil del driver para ese .exe. Si no existe y create=true, crea «Miki Tweaks - nombre» y le añade el .exe
  public static IntPtr ProfileFor(string exe, string friendly, bool create) {
    APP a = new APP(); a.version = Ver(typeof(APP), 4); IntPtr p;          // NVDRS_APPLICATION_V4
    if (F<DFindApp>(0xEEE566B2)(Session, U(exe), out p, ref a) == 0) return p;
    if (!create) return IntPtr.Zero;
    string name = "Miki Tweaks - " + friendly;
    if (F<DFindProf>(0x7E4A9A0B)(Session, U(name), out p) != 0) {
      PROFILE pi = new PROFILE(); pi.version = Ver(typeof(PROFILE), 1); pi.profileName = name;
      int r1 = F<DCreateProf>(0xCC176068)(Session, ref pi, out p); if (r1 != 0) throw new Exception("NvAPI CreateProfile " + r1);
    }
    APP n = new APP(); n.version = Ver(typeof(APP), 4); n.appName = exe; n.userFriendlyName = friendly;
    int r2 = F<DCreateApp>(0x4347A9DE)(Session, p, ref n); if (r2 != 0) throw new Exception("NvAPI CreateApplication " + r2);
    return p;
  }
  // Devuelve {estado, ubicación (0 = en este perfil), valor}
  public static long[] Get(IntPtr p, uint id) {
    SETTING st = new SETTING(); st.version = Ver(typeof(SETTING), 1); st.predefinedRest = new byte[4096]; st.currentRest = new byte[4096];
    int r = F<DGet>(0x73BF8338)(Session, p, id, ref st);
    return new long[] { r, st.settingLocation, st.currentValue };
  }
  public static int Set(IntPtr p, uint id, uint v) {
    SETTING st = new SETTING(); st.version = Ver(typeof(SETTING), 1); st.settingId = id; st.settingType = 0; st.currentValue = v; st.settingName = ""; st.predefinedRest = new byte[4096]; st.currentRest = new byte[4096];
    return F<DSet>(0x577DD202)(Session, p, ref st);
  }
  public static int Delete(IntPtr p, uint id) { return F<DDel>(0xE4A26362)(Session, p, id); }   // vuelve al valor del perfil global
}
'@
    } catch {}
}
$NvSettings = @(
    @{ Id = [uint32]0x1057EB71; Value = 1; Label = 'gestión de energía al máximo rendimiento' },
    @{ Id = [uint32]0x007BA09E; Value = 1; Label = 'modo de baja latencia activado' })
function Invoke-NvDrs([scriptblock]$code, [switch]$Save) {
    $r = [CtNvDrs]::Open(); if ($r -ne 0) { [CtNvDrs]::Close(); throw "el driver de NVIDIA no respondió (código $r)" }
    try { $out = & $code; if ($Save) { $s = [CtNvDrs]::Save(); if ($s -ne 0) { throw "NVIDIA no guardó el perfil (código $s)" } }; return $out } finally { [CtNvDrs]::Close() }
}

$ModeFile     = Join-Path $DataDir 'modo.json'
$AutoTask     = 'MikiTweaks - Modo automatico'
$BalancedPlan = '381b4222-f694-41f0-9685-ff5bb260df2e'
$OverlayGuids = @{ balanced = '00000000-0000-0000-0000-000000000000'; efficiency = '961cc777-2547-4f9d-8174-7d86181b8a7a' }
$ModeOrder    = @('juego', 'trabajo', 'bateria')
$ModeDefs = @{
    juego   = @{ Name = 'Modo Juego'; Short = 'Juego'; Glyph = '&#xE7FC;'; Color = '{DynamicResource AccentBrush}'; Soft = '{DynamicResource AccentSoft}'; Fg = '{DynamicResource AccentBrush}'
                 Desc = 'Máximo rendimiento y mínima latencia para tus partidas.'
                 Items = @('Plan de energía: Alto rendimiento', 'Pantalla del portátil a su frecuencia máxima', 'Indexación de búsqueda y SysMain en pausa', 'Apps en segundo plano bloqueadas', 'Descargas de Windows Update y OneDrive en pausa')
                 Plan = 'game'; Overlay = $null; Hz = 'max'; Search = $false; SysMain = $false; BgApps = $false }
    trabajo = @{ Name = 'Modo Trabajo'; Short = 'Trabajo'; Glyph = '&#xE821;'; Color = '#3B82F6'; Soft = '#1C1C1F'; Fg = '#A0A0A7'
                 Desc = 'Windows ágil y completo: todo lo útil del día a día funcionando.'
                 Items = @('Plan de energía: Equilibrado', 'Pantalla del portátil a su frecuencia máxima', 'Búsqueda de Windows y SysMain activos', 'Apps en segundo plano permitidas (notificaciones y sincronización)')
                 Plan = 'balanced'; Overlay = 'balanced'; Hz = 'max'; Search = $true; SysMain = $true; BgApps = $true }
    bateria = @{ Name = 'Ahorro de batería'; Short = 'Batería'; Glyph = '&#xE859;'; Color = '#10B981'; Soft = '#1C1C1F'; Fg = '#A0A0A7'
                 Desc = 'Más horas lejos del enchufe, con menos consumo y menos calor.'
                 Items = @('Plan de energía: Equilibrado con máxima eficiencia', 'Pantalla del portátil a 60 Hz', 'Indexación de búsqueda y SysMain en pausa', 'Apps en segundo plano bloqueadas')
                 Plan = 'balanced'; Overlay = 'efficiency'; Hz = 'min'; Search = $false; SysMain = $false; BgApps = $false }
    creacion = @{ Name = 'Modo Creación'; Short = 'Creación'; Glyph = '&#xE714;'; Color = '#E0B954'; Soft = '#1C1C1F'; Fg = '#A0A0A7'
                 Desc = 'Toda la potencia para editar, renderizar o hacer streaming, sin cerrar ninguno de tus programas.'
                 Items = @(); Plan = 'game'; Overlay = $null; Hz = 'max'; Search = $true; SysMain = $true; BgApps = $true }
    silencio = @{ Name = 'Modo Silencio'; Short = 'Silencio'; Glyph = '&#xE708;'; Color = '#7FA6E0'; Soft = '#1C1C1F'; Fg = '#A0A0A7'
                 Desc = 'Menos ruido y temperatura: el procesador no apura al máximo. Ideal para trabajar, ver series o dejar el PC descargando.'
                 Items = @('Plan de energía: Equilibrado con máxima eficiencia', 'Búsqueda de Windows y SysMain activos', 'Apps en segundo plano permitidas')
                 Plan = 'balanced'; Overlay = 'efficiency'; Hz = 'max'; Search = $true; SysMain = $true; BgApps = $true }
}

# ======================= Perfil de uso (asistente inicial) =======================
# type: portatil | sobremesa · uses: competitivo, casual, trabajo, creacion, basico · priority: rendimiento | equilibrio | silencio · battery: enchufado | bateria
$UseLabels = [ordered]@{ competitivo = 'jugar en competitivo'; casual = 'jugar por diversión'; trabajo = 'trabajar o estudiar'; creacion = 'crear contenido'; basico = 'navegar y ver series' }
function Get-UseProfile {
    $p = Get-Setting 'perfil' $null
    if (-not $p -or -not "$($p.type)") { return $null }
    return @{ Type = "$($p.type)"; Uses = @(@($p.uses) | Where-Object { $_ } | ForEach-Object { "$_" }); Priority = "$($p.priority)"; Battery = "$($p.battery)" }
}
function Test-Gamer($p) { return (-not $p) -or [bool](@($p.Uses) | Where-Object { $_ -in @('competitivo', 'casual') }) }
function Get-ProfileText($p) {
    if (-not $p) { return 'Sin perfil' }
    $u = @($p.Uses | ForEach-Object { $UseLabels[$_] } | Where-Object { $_ })
    $u = if ($u.Count -gt 1) { ($u[0..($u.Count - 2)] -join ', ') + ' y ' + $u[-1] } elseif ($u.Count) { $u[0] } else { 'uso general' }
    if ($script:Lang -eq 'en') { $ue = @($p.Uses | ForEach-Object { Tr $UseLabels[$_] } | Where-Object { $_ }); $ue = if ($ue.Count -gt 1) { ($ue[0..($ue.Count - 2)] -join ', ') + ' and ' + $ue[-1] } elseif ($ue.Count) { $ue[0] } else { 'general use' }; return "$(if ($p.Type -eq 'portatil') { 'Laptop' } else { 'Desktop' }) for $ue" }
    return "$(if ($p.Type -eq 'portatil') { 'Portátil' } else { 'Sobremesa' }) para $u"
}
function Update-ModesForProfile {
    # Decide qué modos existen y ajusta sus textos al tipo de equipo y al uso
    $p = Get-UseProfile
    $lap = if ($p) { $p.Type -eq 'portatil' } else { $true }
    $hz = if ($lap) { 'Pantalla del portátil a su frecuencia máxima' } else { $null }
    $t = $ModeDefs.trabajo
    if (-not $p -or @($p.Uses) -contains 'trabajo') { $t.Name = 'Modo Trabajo'; $t.Short = 'Trabajo'; $t.Glyph = '&#xE821;'; $t.Desc = 'Windows ágil y completo: todo lo útil del día a día funcionando.' }
    else { $t.Name = 'Modo Diario'; $t.Short = 'Diario'; $t.Glyph = '&#xE80F;'; $t.Desc = 'Para navegar, ver series y el día a día: todo funcionando, sin gastar de más.' }
    $fast = $p -and $p.Type -eq 'sobremesa' -and $p.Priority -eq 'rendimiento'
    $t.Plan = $(if ($fast) { 'game' } else { 'balanced' }); $t.Overlay = $(if ($fast) { $null } else { 'balanced' })
    $t.Items = @(@($(if ($fast) { 'Plan de energía: Alto rendimiento' } else { 'Plan de energía: Equilibrado' }), $hz, 'Búsqueda de Windows y SysMain activos', 'Apps en segundo plano permitidas (notificaciones y sincronización)') | Where-Object { $_ })
    $ModeDefs.juego.Items = @(@('Plan de energía: Alto rendimiento', $hz, 'Indexación de búsqueda y SysMain en pausa', 'Apps en segundo plano bloqueadas', 'Cierra los programas que elijas') | Where-Object { $_ })
    $ModeDefs.creacion.Items = @(@('Plan de energía: Alto rendimiento', $hz, 'Búsqueda de Windows y SysMain activos (para tus archivos y proyectos)', 'No se cierra ningún programa: OBS, editores y grabación siguen igual') | Where-Object { $_ })
    $order = @()
    if (Test-Gamer $p) { $order += 'juego' }
    if ($p -and @($p.Uses) -contains 'creacion') { $order += 'creacion' }
    $order += 'trabajo'
    $order += $(if ($lap) { 'bateria' } else { 'silencio' })
    $script:ModeOrder = $order
}
Update-ModesForProfile

function Get-ModeState {
    $s = @{ current = ''; lastAC = 'juego'; autoSwitched = $false; gamePlan = '' }
    if (Test-Path $ModeFile) { try { $o = Get-Content $ModeFile -Raw -Encoding UTF8 | ConvertFrom-Json; foreach ($p in $o.PSObject.Properties) { $s[$p.Name] = $p.Value } } catch {} }
    return $s
}
function Save-ModeState($s) { ($s | ConvertTo-Json) | Set-Content -Path $ModeFile -Encoding UTF8 }
function Write-ModeLog($msg) {
    if (Get-Command Log -ErrorAction SilentlyContinue) { Log $msg }
    else { try { Add-Content -Path $LogFile -Value ("[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $msg) -Encoding UTF8 } catch {} }
}
function Get-PlanName($guid) { $l = (powercfg /list) -join "`n"; if ($l -match "$guid\s+\(([^)]+)\)") { return $Matches[1] }; return $guid }
function Test-PlanExists($guid) { return ($guid -and (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\$guid")) }
function Get-GamePlan([switch]$Create) {
    # Ojo: en portátiles con suspensión moderna, Windows oculta de «powercfg /list» los planes que no están activos.
    # Por eso se comprueba en el registro y no en esa lista.
    $s = Get-ModeState
    if (Test-PlanExists $s.gamePlan) { return $s.gamePlan }
    $g = $null
    $l = (powercfg /list) -join "`n"
    if ($l -match '([0-9a-f\-]{36})\s+\((Alto rendimiento|High performance|Rendimiento máximo|Máximo rendimiento|Ultimate Performance)\)') { $g = $Matches[1] }
    if (-not $g) {
        # Planes ocultos con nombre propio (creados por el usuario) que sean de alto rendimiento
        foreach ($k in @(Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes' -ErrorAction SilentlyContinue)) {
            $n = "$((Get-ItemProperty $k.PSPath -ErrorAction SilentlyContinue).FriendlyName)"
            if ($n -match '^(Alto rendimiento|High performance)$') { $g = $k.PSChildName; break }
        }
    }
    if (-not $g -and $Create) {
        # Último recurso en un PC sin plan de alto rendimiento: se crea UNA vez el «Máximo rendimiento» de Windows y se recuerda
        $o = (powercfg /duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61) -join ' '
        if ($o -match '([0-9a-f\-]{36})') { $g = $Matches[1] }
    }
    if ($g) { $s.gamePlan = $g; Save-ModeState $s }
    return $g
}
function Get-InternalDisplay { try { return [CtNative]::FindDisplay('Intel|AMD Radeon\(TM\)|Radeon Graphics') } catch { return $null } }
function Test-OnAC { $b = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select-Object -First 1; return (-not $b) -or ($b.BatteryStatus -ne 1) }

# Programas que se pueden cerrar al activar el Modo Juego (el usuario elige cuáles en Modos).
# Nunca aparecen: Steam, Epic, Discord, Battle.net, Medal, Vanguard ni el software del ratón/teclado.
$CloseApps = [ordered]@{
    'chrome' = 'Google Chrome'; 'msedge' = 'Microsoft Edge'; 'firefox' = 'Firefox'; 'opera' = 'Opera / Opera GX'; 'brave' = 'Brave'
    'OneDrive' = 'OneDrive'; 'Dropbox' = 'Dropbox'; 'GoogleDriveFS' = 'Google Drive'; 'ms-teams' = 'Microsoft Teams'; 'Teams' = 'Teams (clásico)'
    'Spotify' = 'Spotify'; 'Overwolf' = 'Overwolf'; 'wallpaper64' = 'Wallpaper Engine'; 'Creative Cloud' = 'Adobe Creative Cloud'
    'PhoneExperienceHost' = 'Enlace Móvil'; 'Zoom' = 'Zoom'
}
function Close-GameNuisances {
    $sel = @(Get-Setting 'closeOnGame' @()) | Where-Object { $CloseApps.Contains("$_") }
    if (-not $sel.Count) { return }
    $closed = @()
    foreach ($n in $sel) {
        $ps = @(Get-Process -Name $n -ErrorAction SilentlyContinue); if (-not $ps.Count) { continue }
        # Primero se pide cerrar la ventana (los navegadores guardan las pestañas); lo que siga abierto se termina
        foreach ($p in $ps) { try { if ($p.MainWindowHandle -ne [IntPtr]::Zero) { [void]$p.CloseMainWindow() } } catch {} }
        Start-Sleep -Milliseconds 1500
        Get-Process -Name $n -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        $closed += $CloseApps[$n]
    }
    if ($closed.Count) { Write-ModeLog "✓ Cerrados para jugar: $($closed -join ', ')" }
}

# ---------- Descargas en pausa mientras juegas ----------
# Solo se paran servicios que estaban en marcha (su tipo de inicio no cambia) y vuelven a arrancar al salir del Modo Juego
$DlServices = @('wuauserv', 'UsoSvc', 'DoSvc', 'BITS')
function Suspend-Downloads {
    $st = Get-ModeState; $paused = @(@($st.dlPaused) | Where-Object { $_ })
    if (@(Get-Service TrustedInstaller -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' }).Count) {
        Write-ModeLog '· Windows está instalando una actualización: no se pausan las descargas para no interrumpirla'; return
    }
    foreach ($n in $DlServices) {
        try { $sv = Get-Service $n -ErrorAction Stop; if ($sv.Status -eq 'Running') { Stop-Service $n -Force -ErrorAction Stop; if ($paused -notcontains $n) { $paused += $n } } } catch {}
    }
    $odPath = $st.odPath
    $od = @(Get-Process OneDrive -ErrorAction SilentlyContinue | Where-Object { $_.Path }) | Select-Object -First 1
    if ($od) {
        $odPath = $od.Path
        # Primero se le pide que se cierre; si sigue abierto, se termina (OneDrive retoma la sincronización al volver a abrirse)
        try { & taskkill.exe /im OneDrive.exe 2>&1 | Out-Null } catch {}
        Start-Sleep -Seconds 3
        Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
    $st.dlPaused = @($paused); $st.odPath = $odPath; Save-ModeState $st
    $what = @(); if ($paused.Count) { $what += 'Windows Update' }; if ($od) { $what += 'OneDrive' }
    if ($what.Count) { Write-ModeLog "✓ Descargas en pausa mientras juegas: $($what -join ' y ')" } else { Write-ModeLog '✓ Descargas: no había ninguna en marcha' }
}
function Resume-Downloads {
    $st = Get-ModeState
    $paused = @(@($st.dlPaused) | Where-Object { $_ })
    if (-not $paused.Count -and -not $st.odPath) { return }
    foreach ($n in $paused) { try { $sv = Get-Service $n -ErrorAction Stop; if ("$($sv.StartType)" -ne 'Disabled' -and $sv.Status -ne 'Running') { Start-Service $n -ErrorAction Stop } } catch { Write-ModeLog "· No pude reanudar el servicio $n; Windows lo volverá a arrancar cuando lo necesite" } }
    # OneDrive se vuelve a abrir a través del Explorador para que no se ejecute como administrador
    if ($st.odPath -and (Test-Path $st.odPath) -and -not (Get-Process OneDrive -ErrorAction SilentlyContinue)) { try { Start-Process explorer.exe -ArgumentList "`"$($st.odPath)`"" } catch {} }
    $st.dlPaused = @(); $st.odPath = $null; Save-ModeState $st
    Write-ModeLog '✓ Descargas reanudadas'
}

function Invoke-Mode($id) {
    $m = $ModeDefs[$id]
    Write-ModeLog "Activando $($m.Name)..."
    # Plan de energía (solo se elige cuál está activo; ninguno se modifica)
    $guid = if ($m.Plan -eq 'game') { Get-GamePlan -Create } else { $BalancedPlan }
    if ($guid) { powercfg /setactive $guid | Out-Null; Write-ModeLog "✓ Plan de energía: $(Get-PlanName $guid)" }
    else { Write-ModeLog '· No encontré tu plan de alto rendimiento; el plan se deja como está' }
    if ($m.Overlay) {
        try { [void][CtNative]::SetOverlay($OverlayGuids[$m.Overlay]); Write-ModeLog "✓ Perfil de energía: $(if ($m.Overlay -eq 'efficiency') { 'máxima eficiencia' } else { 'equilibrado' })" }
        catch { Write-ModeLog '· El perfil de energía no se pudo cambiar en este equipo' }
    }
    # Frecuencia de la pantalla del portátil
    $dev = Get-InternalDisplay
    if ($dev) {
        $rates = @([CtNative]::Rates($dev))
        if ($rates.Count) {
            $target = if ($m.Hz -eq 'max') { ($rates | Measure-Object -Maximum).Maximum } elseif ($rates -contains 60) { 60 } else { ($rates | Measure-Object -Minimum).Minimum }
            $cur = [CtNative]::Current($dev)
            if ($cur -ne $target) {
                $r = [CtNative]::SetRate($dev, [int]$target)
                if ($r -eq 0) { Write-ModeLog "✓ Pantalla del portátil: $cur Hz → $target Hz" } else { Write-ModeLog "· La pantalla no aceptó $target Hz (código $r)" }
            } else { Write-ModeLog "✓ Pantalla del portátil: ya a $cur Hz" }
        }
    }
    # Servicios: solo se paran o se arrancan; su tipo de inicio no cambia
    foreach ($sv in @(@{ N = 'WSearch'; On = $m.Search; L = 'Indexación de búsqueda' }, @{ N = 'SysMain'; On = $m.SysMain; L = 'SysMain' })) {
        try {
            $s = Get-Service $sv.N -ErrorAction Stop
            if ($sv.On) { if ($s.StartType -ne 'Disabled' -and $s.Status -ne 'Running') { Start-Service $sv.N -ErrorAction Stop }; Write-ModeLog "✓ $($sv.L): activa" }
            else { if ($s.Status -eq 'Running') { Stop-Service $sv.N -Force -ErrorAction Stop }; Write-ModeLog "✓ $($sv.L): en pausa" }
        } catch { Write-ModeLog "· $($sv.L): no se pudo cambiar ($($_.Exception.Message))" }
    }
    # Apps en segundo plano
    Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' 'GlobalUserDisabled' $(if ($m.BgApps) { 0 } else { 1 })
    Write-ModeLog "✓ Apps en segundo plano: $(if ($m.BgApps) { 'permitidas' } else { 'bloqueadas' })"
    try { if ($id -eq 'juego') { if (Get-Setting 'pauseDownloads' $true) { Suspend-Downloads } } else { Resume-Downloads } } catch { Write-ModeLog "· Descargas: $($_.Exception.Message)" }
    if ($id -eq 'juego') { try { Close-GameNuisances } catch { Write-ModeLog "· No se pudieron cerrar algunos programas: $($_.Exception.Message)" } }
    $st = Get-ModeState; $st.current = $id; Save-ModeState $st
    Write-ModeLog "$($m.Name) activado"
}

function Test-AutoMode { Test-TaskExists $AutoTask }
function Set-AutoMode($on) {
    if (-not $on) { if (Test-AutoMode) { Unregister-ScheduledTask -TaskName $AutoTask -Confirm:$false }; return }
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $script = if (Test-Path $AppPath) { $AppPath } else { $PSCommandPath }
    $q = "&lt;QueryList&gt;&lt;Query Id=`"0`" Path=`"System`"&gt;&lt;Select Path=`"System`"&gt;*[System[Provider[@Name='Microsoft-Windows-Kernel-Power'] and EventID=105]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;"
    $xml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo><Description>Miki Tweaks: Ahorro de batería al desenchufar, vuelve al modo anterior al enchufar y mantiene el modo tras reiniciar.</Description></RegistrationInfo>
  <Triggers>
    <EventTrigger><Enabled>true</Enabled><Subscription>$q</Subscription></EventTrigger>
    <LogonTrigger><Enabled>true</Enabled><UserId>$sid</UserId><Delay>PT30S</Delay></LogonTrigger>
  </Triggers>
  <Principals><Principal id="Author"><UserId>$sid</UserId><LogonType>InteractiveToken</LogonType><RunLevel>HighestAvailable</RunLevel></Principal></Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <ExecutionTimeLimit>PT2M</ExecutionTimeLimit>
    <Enabled>true</Enabled>
  </Settings>
  <Actions Context="Author"><Exec><Command>powershell.exe</Command><Arguments>-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$script" -Auto</Arguments></Exec></Actions>
</Task>
"@
    Register-ScheduledTask -TaskName $AutoTask -Xml $xml -Force | Out-Null
}

# Ejecución sin ventana (tarea automática o acceso directo con -Mode)
if ($Auto) {
    Start-Sleep -Seconds 3
    $st = Get-ModeState
    if (-not $st.current) { exit }
    if (-not (Test-OnAC)) {
        if ($st.current -ne 'bateria') { $st.lastAC = $st.current; $st.autoSwitched = $true; Save-ModeState $st }
        Invoke-Mode 'bateria'
    } else {
        if ($st.current -eq 'bateria' -and $st.autoSwitched) {
            $back = if ($st.lastAC) { $st.lastAC } else { 'juego' }
            $st.autoSwitched = $false; Save-ModeState $st; Invoke-Mode $back
        } else { Invoke-Mode $st.current }
    }
    exit
}
# ======================= Actualizaciones de la propia app =======================
function Get-UpdateUrl { return $UpdateUrlDefault }   # siempre el canal oficial (antes se podía cambiar en Ajustes)
# Se ejecuta en segundo plano: descarga y valida el version.json del canal
$UpdateCheckWork = {
    param($url, $current)
    $r = @{}
    try {
        if ($url -notmatch '^https://') { $r.Error = 'la dirección del canal tiene que empezar por https://'; return $r }
        $ProgressPreference = 'SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $m = Invoke-RestMethod $url -TimeoutSec 20 -Headers @{ 'Cache-Control' = 'no-cache' }
        # GitHub (raw) y otros servidores lo envían como texto plano: entonces llega como cadena, a veces con BOM
        if ($m -is [string]) { $m = $m.TrimStart([char]0xFEFF) | ConvertFrom-Json }
        if (-not $m.version -or -not $m.url -or -not $m.sha256) { $r.Error = 'el version.json no tiene version, url y sha256'; return $r }
        $r.Version = "$($m.version)"; $r.Url = "$($m.url)"; $r.Sha = "$($m.sha256)".ToUpper(); $r.Notes = "$($m.notes)"
        $r.Newer = ([version]$r.Version -gt [version]$current)
    } catch { $r.Error = $_.Exception.Message }
    return $r
}
$UpdateInstallWork = {
    param($info, $appPath)
    $r = @{}
    try {
        if ($info.Url -notmatch '^https://') { throw 'la descarga tiene que ser https' }
        $ProgressPreference = 'SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $tmp = Join-Path $env:TEMP ('MikiTweaks-' + $info.Version + '.ps1')
        Invoke-WebRequest $info.Url -OutFile $tmp -UseBasicParsing -TimeoutSec 120
        $h = (Get-FileHash $tmp -Algorithm SHA256).Hash
        if ($h -ne $info.Sha) { Remove-Item $tmp -Force; throw "la huella del archivo no coincide con la del version.json (descarga dañada o manipulada)" }
        $e = $null; [void][Management.Automation.Language.Parser]::ParseFile($tmp, [ref]$null, [ref]$e)
        if ($e.Count) { Remove-Item $tmp -Force; throw "el script descargado tiene $($e.Count) error$(if ($e.Count -ne 1) { 'es' }) de sintaxis" }
        if ((Get-Content $tmp -Raw) -notmatch "\`$AppVersion\s*=\s*'([^']+)'" -or $Matches[1] -ne $info.Version) { Remove-Item $tmp -Force; throw 'la versión del script no coincide con la anunciada' }
        Copy-Item $appPath "$appPath.anterior" -Force
        Copy-Item $tmp $appPath -Force; Unblock-File $appPath -ErrorAction SilentlyContinue; Remove-Item $tmp -Force
        $r.Ok = $true
    } catch { $r.Error = $_.Exception.Message }
    return $r
}

# ======================= Aviso semanal (driver y Windows Update) =======================
$WeeklyTask = 'MikiTweaks - Aviso semanal'
function Show-Toast($title, $text) {
    try {
        [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
        $x = New-Object Windows.Data.Xml.Dom.XmlDocument
        $x.LoadXml("<toast><visual><binding template='ToastGeneric'><text>$([Security.SecurityElement]::Escape($title))</text><text>$([Security.SecurityElement]::Escape($text))</text></binding></visual></toast>")
        $aumid = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($aumid).Show([Windows.UI.Notifications.ToastNotification]::new($x))
        return $true
    } catch { return $false }
}
function Get-WeeklyStatus {
    # Devuelve los avisos pendientes: driver NVIDIA nuevo y actualizaciones necesarias de Windows
    $msgs = @()
    try {
        $gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -match 'NVIDIA' } | Select-Object -First 1
        $smi = "$env:SystemRoot\System32\nvidia-smi.exe"
        if ($gpu -and (Test-Path $smi)) {
            $ProgressPreference = 'SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $inst = "$(& $smi --query-gpu=driver_version --format=csv,noheader | Select-Object -First 1)".Trim()
            $x = [xml](Invoke-WebRequest 'https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=3' -UseBasicParsing -TimeoutSec 30).Content
            $name = ("$($gpu.Name)" -replace '^NVIDIA ', '').Trim()
            # Copia de $DriverCheckWork: esta función tiene que ser autónoma (se serializa al segundo plano y corre con -Check)
            $all = @($x.LookupValueSearch.LookupValues.LookupValue)
            $hit = $all | Where-Object { $_.Name -eq $name } | Select-Object -First 1
            if (-not $hit) { $hit = $all | Where-Object { $_.Name -like "*$name*" } | Select-Object -First 1 }
            if ($hit) {
                $os = if ([Environment]::OSVersion.Version.Build -ge 22000) { 135 } else { 57 }
                $j = Invoke-RestMethod "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&pfid=$($hit.Value)&osID=$os&languageCode=1033&isWHQL=1&dch=1&sort1=0&numberOfResults=1" -TimeoutSec 30
                $latest = "$($j.IDS[0].downloadInfo.Version)"
                if ($latest -and ([version]$latest -gt [version]$inst)) { $msgs += "Driver NVIDIA nuevo: $latest (tienes $inst)" }
            }
        }
    } catch {}
    try {
        $res = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher().Search('IsInstalled=0 and IsHidden=0 and BrowseOnly=0')
        if ($res.Updates.Count -gt 0) { $msgs += $(if ($res.Updates.Count -eq 1) { '1 actualización de Windows pendiente' } else { "$($res.Updates.Count) actualizaciones de Windows pendientes" }) }
    } catch {}
    try {
        # Versión nueva de Miki Tweaks (autónomo: también se ejecuta en segundo plano sin el resto de la app)
        $u = $UpdateUrlDefault
        if ($u -match '^https://') { $m = Invoke-RestMethod $u -TimeoutSec 20; if ($m -is [string]) { $m = $m.TrimStart([char]0xFEFF) | ConvertFrom-Json }; if ($m.version -and [version]"$($m.version)" -gt [version]$AppVersion) { $msgs += "Miki Tweaks $($m.version) disponible" } }
    } catch {}
    return $msgs
}
function Invoke-WeeklyCheck {
    $m = @(Get-WeeklyStatus)
    if ($m.Count) { [void](Show-Toast 'Miki Tweaks' (($m -join ' · ') + '. Ábrela y mira la página Actualizaciones.')) }
    try { Add-Content -Path $LogFile -Value ("[{0}] Aviso semanal: {1}" -f (Get-Date -Format 'dd/MM HH:mm'), $(if ($m.Count) { $m -join ' · ' } else { 'todo al día' })) -Encoding UTF8 } catch {}
}
function Test-WeeklyCheck { Test-TaskExists $WeeklyTask }
function Set-WeeklyCheck($on) {
    if (-not $on) { if (Test-WeeklyCheck) { Unregister-ScheduledTask -TaskName $WeeklyTask -Confirm:$false }; return }
    $script = if (Test-Path $AppPath) { $AppPath } else { $PSCommandPath }
    $user = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    $act = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`" -Check"
    $trg = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Saturday -At '18:00'
    $pri = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
    $set = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
    Register-ScheduledTask -TaskName $WeeklyTask -Action $act -Trigger $trg -Principal $pri -Settings $set -Force | Out-Null
}

# ======================= Modo Juego automático al abrir un juego =======================
$WatchTask = 'MikiTweaks - Modo Juego automatico'
function Test-GameWatch { Test-TaskExists $WatchTask }
function Set-GameWatch($on) {
    if (-not $on) {
        if (Test-GameWatch) { Stop-ScheduledTask -TaskName $WatchTask -ErrorAction SilentlyContinue; Unregister-ScheduledTask -TaskName $WatchTask -Confirm:$false }
        return
    }
    $script = if (Test-Path $AppPath) { $AppPath } else { $PSCommandPath }
    $user = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    $act = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`" -Watch"
    $trg = New-ScheduledTaskTrigger -AtLogOn -User $user; $trg.Delay = 'PT45S'
    $pri = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest
    $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew
    Register-ScheduledTask -TaskName $WatchTask -Action $act -Trigger $trg -Principal $pri -Settings $set -Force | Out-Null
    Start-ScheduledTask -TaskName $WatchTask -ErrorAction SilentlyContinue
}
function Invoke-GameWatch {
    # Comprueba cada 5 s si hay un juego abierto. Al abrirlo activa el Modo Juego; al cerrarlo (20 s sin juego) vuelve al modo anterior.
    $names = @($GameDefs | ForEach-Object { $_.Exes } | ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_) })
    $idle = 0
    while ($true) {
        try {
            $run = @(Get-Process -Name $names -ErrorAction SilentlyContinue)
            $st = Get-ModeState
            if ($run.Count) {
                $idle = 0
                if ($st.current -ne 'juego' -and -not $st.watchActive) {
                    $st.watchPrev = $(if ($st.current) { $st.current } else { 'trabajo' }); $st.watchActive = $true; Save-ModeState $st
                    Write-ModeLog "Juego detectado ($($run[0].Name)): activando el Modo Juego"; Invoke-Mode 'juego'
                }
            } elseif ($st.watchActive) {
                $idle++
                if ($idle -ge 4) {
                    $prev = if ($st.watchPrev -and $ModeDefs.ContainsKey("$($st.watchPrev)")) { "$($st.watchPrev)" } else { 'trabajo' }
                    $st.watchActive = $false; Save-ModeState $st
                    Write-ModeLog "Juego cerrado: volviendo al $($ModeDefs[$prev].Name)"; Invoke-Mode $prev; $idle = 0
                }
            }
        } catch {}
        Start-Sleep -Seconds 5
    }
}

# ======================= Icono en la bandeja del sistema =======================
$TrayTask = 'MikiTweaks - Bandeja'
function Test-TrayIcon { Test-TaskExists $TrayTask }
function Set-TrayIcon($on) {
    if (-not $on) {
        if (Test-TrayIcon) { Stop-ScheduledTask -TaskName $TrayTask -ErrorAction SilentlyContinue; Unregister-ScheduledTask -TaskName $TrayTask -Confirm:$false }
        return
    }
    $script = if (Test-Path $AppPath) { $AppPath } else { $PSCommandPath }
    $user = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    $act = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$script`" -Tray"
    $trg = New-ScheduledTaskTrigger -AtLogOn -User $user; $trg.Delay = 'PT20S'
    $pri = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest
    $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew
    Register-ScheduledTask -TaskName $TrayTask -Action $act -Trigger $trg -Principal $pri -Settings $set -Force | Out-Null
    Start-ScheduledTask -TaskName $TrayTask -ErrorAction SilentlyContinue
}
function Open-MainApp {
    $exe = Join-Path $AppDir 'MikiTweaks.exe'
    if (Test-Path $exe) { Start-Process $exe }
    else { Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$(if (Test-Path $AppPath) { $AppPath } else { $PSCommandPath })`"" }
}
function Invoke-Tray([int]$ExitAfterSeconds = 0) {
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    $script:TrayMutex = New-Object Threading.Mutex($false, 'Local\MikiTweaksTray')
    if (-not $script:TrayMutex.WaitOne(0)) { return }   # ya hay un icono en marcha
    [Windows.Forms.Application]::EnableVisualStyles()
    $ni = New-Object Windows.Forms.NotifyIcon; $script:TrayIcon = $ni
    $ico = Join-Path $DataDir 'logo.ico'
    $ni.Icon = if (Test-Path $ico) { New-Object Drawing.Icon($ico, 16, 16) } else { [Drawing.SystemIcons]::Application }
    $menu = New-Object Windows.Forms.ContextMenuStrip
    $hdr = $menu.Items.Add('Miki Tweaks'); $hdr.Enabled = $false
    [void]$menu.Items.Add('-')
    $script:TrayModeItems = @{}
    foreach ($id in $ModeOrder) {
        $it = New-Object Windows.Forms.ToolStripMenuItem($ModeDefs[$id].Name); $it.Tag = $id
        $it.Add_Click({ param($s, $e)
            $st = Get-ModeState; $st.autoSwitched = $false; $st.watchActive = $false; Save-ModeState $st
            try { Invoke-Mode $s.Tag; $script:TrayIcon.ShowBalloonTip(2500, 'Miki Tweaks', "$($ModeDefs[$s.Tag].Name) activado", 'Info') }
            catch { $script:TrayIcon.ShowBalloonTip(4000, 'Miki Tweaks', "No se pudo cambiar de modo: $($_.Exception.Message)", 'Warning') }
            Update-TrayState })
        [void]$menu.Items.Add($it); $script:TrayModeItems[$id] = $it
    }
    [void]$menu.Items.Add('-')
    $open = $menu.Items.Add('Abrir Miki Tweaks'); $open.Font = New-Object Drawing.Font($open.Font, [Drawing.FontStyle]::Bold); $open.Add_Click({ Open-MainApp })
    $quit = $menu.Items.Add('Quitar el icono hasta el próximo inicio'); $quit.Add_Click({ $script:TrayIcon.Visible = $false; [Windows.Forms.Application]::Exit() })
    $ni.ContextMenuStrip = $menu
    $ni.Add_MouseDoubleClick({ Open-MainApp })
    $script:TrayTick = 0
    function script:Update-TrayState {
        $cur = (Get-ModeState).current
        foreach ($k in $script:TrayModeItems.Keys) { $script:TrayModeItems[$k].Checked = ($k -eq $cur) }
        $txt = 'Miki Tweaks · ' + $(if ($cur -and $ModeDefs.ContainsKey($cur)) { $ModeDefs[$cur].Name } else { 'sin modo' })
        # Temperatura solo en Modo Juego: preguntar a nvidia-smi despierta la gráfica dedicada y en un portátil gastaría batería
        $smi = "$env:SystemRoot\System32\nvidia-smi.exe"
        if ($cur -eq 'juego' -and (Test-Path $smi)) {
            try { $tc = 0.0; $raw = "$(& $smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | Select-Object -First 1)".Trim()
                  if ([double]::TryParse($raw, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$tc)) { $txt += " · GPU $([math]::Round($tc)) °C" } } catch {}
        }
        $script:TrayIcon.Text = $txt.Substring(0, [Math]::Min(63, $txt.Length))   # Windows limita el texto a 63 caracteres
        $script:TrayLastText = $script:TrayIcon.Text
    }
    Update-TrayState
    $timer = New-Object Windows.Forms.Timer; $timer.Interval = 10000
    $timer.Add_Tick({ Update-TrayState; if ($ExitAfterSeconds -and ((++$script:TrayTick) * 10 -ge $ExitAfterSeconds)) { $script:TrayIcon.Visible = $false; [Windows.Forms.Application]::Exit() } })
    $timer.Start()
    $ni.Visible = $true
    [Windows.Forms.Application]::Run()
    $ni.Visible = $false; $ni.Dispose(); $script:TrayMutex.ReleaseMutex()
}

if ($Tray) { Invoke-Tray; exit }
if ($Mode -and $ModeDefs.ContainsKey($Mode)) { $st = Get-ModeState; $st.autoSwitched = $false; Save-ModeState $st; Invoke-Mode $Mode; exit }
if ($Check) { Invoke-WeeklyCheck; exit }
if ($Watch) { Invoke-GameWatch; exit }
function Invoke-OldInstallCleanup {
    # Pasa a Miki Tweaks lo que dejaron las versiones anteriores (Fortnite Tweaks y Competitive Tweaks) y las retira
    try {
        # 1) Tareas programadas con nombre antiguo: se vuelven a crear con el nombre y las rutas nuevas
        [void](Get-TaskCom '\_')   # inicializa el servicio COM
        $oldNames = @(try { @($script:TaskSvc.GetFolder('\').GetTasks(1)) | ForEach-Object { $_.Name } | Where-Object { $_ -match '^(FortniteTweaks|CompetitiveTweaks) - ' } } catch { })
        foreach ($old in @($oldNames | ForEach-Object { Get-ScheduledTask -TaskName $_ -TaskPath '\' -ErrorAction SilentlyContinue })) {
            $xml = [string](Export-ScheduledTask -TaskName $old.TaskName -TaskPath $old.TaskPath)
            $xml = $xml -replace '\\(FortniteTweaks|CompetitiveTweaks)\\', '\MikiTweaks\' -replace 'CompetitiveTweaks\.ps1', 'MikiTweaks.ps1'
            $newName = $old.TaskName -replace '^(FortniteTweaks|CompetitiveTweaks) - ', 'MikiTweaks - '
            Register-ScheduledTask -TaskName $newName -Xml $xml -Force | Out-Null
            Unregister-ScheduledTask -TaskName $old.TaskName -TaskPath $old.TaskPath -Confirm:$false
        }
        # 2) Accesos directos antiguos
        foreach ($dir in @([Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Programs'))) {
            foreach ($n in 'Competitive Tweaks.lnk', 'Fortnite Tweaks.lnk') { Remove-Item (Join-Path $dir $n) -Force -ErrorAction SilentlyContinue }
        }
        # 3) Carpetas de datos antiguas: a la Papelera, solo si sus copias de seguridad ya están en Miki Tweaks
        Add-Type -AssemblyName Microsoft.VisualBasic
        foreach ($od in $OldDataDirs) {
            if (-not (Test-Path $od)) { continue }
            if ((Test-Path (Join-Path $od 'backup.json')) -and -not (Test-Path (Join-Path $DataDir 'backup.json'))) { continue }
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($od, 'OnlyErrorDialogs', 'SendToRecycleBin')
        }
    } catch {}
}
# ======================= MikiTweaks.exe =======================
# Lanzador propio: aloja PowerShell dentro del proceso (en el Administrador de tareas sale «Miki Tweaks»),
# lleva el logo como icono y pide administrador por sí mismo. Se compila en cada PC con el compilador de .NET de Windows.
function Build-Launcher([string]$OutExe, [string]$Level = 'requireAdministrator') {
    $v = ($AppVersion -replace '[^\d\.]', '') + '.0.0'; $v = (($v -split '\.')[0..3]) -join '.'
    $src = @"
using System; using System.IO; using System.Reflection; using System.Windows.Forms;
using System.Management.Automation; using System.Management.Automation.Runspaces;
[assembly: AssemblyTitle("Miki Tweaks")] [assembly: AssemblyProduct("Miki Tweaks")] [assembly: AssemblyDescription("Optimiza el PC para juegos competitivos")]
[assembly: AssemblyVersion("$v")] [assembly: AssemblyFileVersion("$v")]
static class MikiTweaksLauncher {
  [STAThread] static int Main(string[] args) {
    string script = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "MikiTweaks.ps1");
    if (!File.Exists(script)) { MessageBox.Show("No encuentro MikiTweaks.ps1 junto a este programa. Vuelve a abrir la app desde el pen o la carpeta original para reinstalarla.", "Miki Tweaks", MessageBoxButtons.OK, MessageBoxIcon.Error); return 1; }
    try {
      InitialSessionState iss = InitialSessionState.CreateDefault();
      iss.ExecutionPolicy = Microsoft.PowerShell.ExecutionPolicy.Bypass;
      iss.ApartmentState = System.Threading.ApartmentState.STA;
      iss.ThreadOptions = PSThreadOptions.UseCurrentThread;
      using (Runspace rs = RunspaceFactory.CreateRunspace(iss)) {
        rs.Open();
        using (PowerShell ps = PowerShell.Create()) {
          ps.Runspace = rs; ps.AddCommand(script); ps.Invoke();
          if (ps.Streams.Error.Count > 0 && Environment.GetEnvironmentVariable("FT_TEST") == "1") { foreach (ErrorRecord e in ps.Streams.Error) Console.Error.WriteLine(e.ToString()); }
        }
      }
      return 0;
    } catch (Exception ex) {
      try { string d = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "MikiTweaks"); Directory.CreateDirectory(d); File.AppendAllText(Path.Combine(d, "errores.log"), DateTime.Now.ToString("dd/MM/yyyy HH:mm:ss") + "  |  lanzador\r\n" + ex.ToString() + "\r\n" + new string('-', 70) + "\r\n"); } catch { }
      MessageBox.Show("Miki Tweaks no ha podido arrancar: " + ex.Message, "Miki Tweaks", MessageBoxButtons.OK, MessageBoxIcon.Error); return 1;
    }
  }
}
"@
    $tmp = Join-Path $env:TEMP ("mt_build_" + [guid]::NewGuid().ToString('N')); New-Item -ItemType Directory -Force $tmp | Out-Null
    try {
        $man = Join-Path $tmp 'app.manifest'
        Set-Content -Path $man -Encoding UTF8 -Value @"
<?xml version="1.0" encoding="utf-8"?>
<assembly manifestVersion="1.0" xmlns="urn:schemas-microsoft-com:asm.v1">
  <assemblyIdentity version="$v" name="MikiTweaks"/>
  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v2"><security><requestedPrivileges xmlns="urn:schemas-microsoft-com:asm.v3"><requestedExecutionLevel level="$Level" uiAccess="false"/></requestedPrivileges></security></trustInfo>
  <application xmlns="urn:schemas-microsoft-com:asm.v3"><windowsSettings><dpiAware xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings">true/pm</dpiAware></windowsSettings></application>
</assembly>
"@
        $ico = Join-Path $DataDir 'logo.ico'
        $cp = New-Object CodeDom.Compiler.CompilerParameters
        $cp.GenerateExecutable = $true; $cp.OutputAssembly = $OutExe; $cp.IncludeDebugInformation = $false
        foreach ($r in 'System.dll', 'System.Core.dll', 'System.Windows.Forms.dll', ([PSObject].Assembly.Location)) { [void]$cp.ReferencedAssemblies.Add($r) }
        $cp.CompilerOptions = "/target:winexe /optimize /win32manifest:`"$man`"" + $(if (Test-Path $ico) { " /win32icon:`"$ico`"" } else { '' })
        $res = (New-Object Microsoft.CSharp.CSharpCodeProvider).CompileAssemblyFromSource($cp, $src)
        if ($res.Errors.HasErrors) { throw (($res.Errors | Where-Object { -not $_.IsWarning } | ForEach-Object { $_.ToString() }) -join "`n") }
    } finally { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
}

function Protect-DataDir {
    # La app y sus tareas se ejecutan como admin y cargan scripts, PresentMon y copias de esta carpeta:
    # si el usuario normal pudiera escribir aquí, cualquier programa podría conseguir admin sin aviso de UAC
    $ok = {
        $a = Get-Acl $DataDir
        $w = [Security.AccessControl.FileSystemRights]'Write, Delete, ChangePermissions, TakeOwnership'
        # Nadie salvo Administradores y SYSTEM puede tener permisos de escritura (p. ej. la carpeta puede traer «mikim: control total» explícito)
        $writers = @($a.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]) | Where-Object { $_.AccessControlType -eq 'Allow' -and ($_.FileSystemRights -band $w) -and $_.IdentityReference.Value -notin 'S-1-5-32-544', 'S-1-5-18' })
        $a.AreAccessRulesProtected -and $a.GetOwner([Security.Principal.SecurityIdentifier]).Value -eq 'S-1-5-32-544' -and -not $writers.Count
    }
    if (& $ok) { return }
    # El dueño también pasa a Administradores: el dueño puede cambiar los permisos aunque no tenga escritura
    & icacls.exe $DataDir /setowner '*S-1-5-32-544' /T /C /Q | Out-Null
    # Solo en la raíz (con /T los archivos se quedarían sin permisos) y luego todo lo de dentro hereda de ella.
    # El /reset previo quita permisos explícitos que /grant:r no toca (como «usuario: control total»)
    & icacls.exe $DataDir /reset /Q | Out-Null
    & icacls.exe $DataDir /inheritance:r /grant:r '*S-1-5-32-544:(OI)(CI)F' '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-545:(OI)(CI)RX' /Q | Out-Null
    & icacls.exe (Join-Path $DataDir '*') /reset /T /C /Q | Out-Null
    if (-not (& $ok)) { throw 'icacls no pudo proteger la carpeta de datos' }   # icacls con /C devuelve 0 aunque falle
}

function Install-App {
    try {
        New-Item -ItemType Directory -Force -Path $AppDir | Out-Null
        if (([Security.Principal.WindowsPrincipal]$me).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            try { Protect-DataDir } catch { Write-CrashLog $_ 'proteger la carpeta de datos' }
        }
        if ($PSCommandPath -and ($PSCommandPath -ne $AppPath)) {
            $same = (Test-Path $AppPath) -and ((Get-FileHash $AppPath).Hash -eq (Get-FileHash $PSCommandPath).Hash)
            if (-not $same) { Copy-Item $PSCommandPath $AppPath -Force; Unblock-File $AppPath -ErrorAction SilentlyContinue }
            # Juegos personalizados del pen: se copian a la carpeta de datos para que la app instalada también los vea
            $gj = Join-Path $PSScriptRoot 'juegos.json'; $gjDst = Join-Path $DataDir 'juegos.json'
            if ((Test-Path $gj) -and (-not (Test-Path $gjDst) -or (Get-Item $gj).LastWriteTime -gt (Get-Item $gjDst).LastWriteTime)) { Copy-Item $gj $gjDst -Force }
        }
        New-AppIcon
        $ico = Join-Path $DataDir 'logo.ico'
        # MikiTweaks.exe: se (re)compila si falta o es de otra versión. Un .exe en uso no se puede sobrescribir, pero sí renombrar.
        $exe = Join-Path $AppDir 'MikiTweaks.exe'
        Remove-Item "$exe.old" -Force -ErrorAction SilentlyContinue
        $want = (((($AppVersion -replace '[^\d\.]', '') + '.0.0') -split '\.')[0..3]) -join '.'
        if (-not (Test-Path $exe) -or "$((Get-Item $exe).VersionInfo.FileVersion)" -ne $want) {
            try {
                if (Test-Path $exe) { Move-Item $exe "$exe.old" -Force }
                Build-Launcher $exe
            } catch { Write-CrashLog $_ 'compilar MikiTweaks.exe'; if (-not (Test-Path $exe) -and (Test-Path "$exe.old")) { Move-Item "$exe.old" $exe -Force } }
        }
        $useExe = Test-Path $exe
        $ws = New-Object -ComObject WScript.Shell
        foreach ($l in (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Miki Tweaks.lnk'), (Join-Path ([Environment]::GetFolderPath('Programs')) 'Miki Tweaks.lnk')) {
            if (Test-Path $l) {
                $o = $ws.CreateShortcut($l)
                if ($useExe -and $o.TargetPath -eq $exe) { continue }
                if (-not $useExe -and $o.Arguments -like "*$AppPath*") { continue }
            }
            $s = $ws.CreateShortcut($l)
            if ($useExe) { $s.TargetPath = $exe; $s.Arguments = '' }
            else { $s.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"; $s.Arguments = "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$AppPath`"" }
            $s.WorkingDirectory = $AppDir; $s.IconLocation = "$ico,0"; $s.WindowStyle = 1; $s.Description = 'Escanea y optimiza el PC para juegos competitivos'
            $s.Save()
            # Con PowerShell, el acceso directo se marca «Ejecutar como administrador»; el .exe ya lo pide por su manifiesto
            if (-not $useExe) { $b = [IO.File]::ReadAllBytes($l); $b[0x15] = $b[0x15] -bor 0x20; [IO.File]::WriteAllBytes($l, $b) }
        }
    } catch {}
}
if ($env:FT_TEST -ne '1') { Invoke-OldInstallCleanup; Install-App }

# ======================= Interfaz =======================
[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Miki Tweaks" Width="1160" Height="780" WindowStyle="None" AllowsTransparency="True"
        Background="Transparent" ResizeMode="CanResize" MinWidth="1000" MinHeight="660" WindowStartupLocation="CenterScreen"
        FontFamily="Segoe UI Variable Text, Segoe UI" TextOptions.TextFormattingMode="Ideal" UseLayoutRounding="True">
  <WindowChrome.WindowChrome>
    <WindowChrome CaptionHeight="58" ResizeBorderThickness="10" GlassFrameThickness="0" CornerRadius="0" UseAeroCaptionButtons="False"/>
  </WindowChrome.WindowChrome>
  <Window.Resources>
    <!-- Un único color de acento, plano. Set-Accent cambia estos tres colores. -->
    <Color x:Key="AccentA">#CBF24A</Color><Color x:Key="AccentSoftC">#22270F</Color><Color x:Key="AccentFgC">#0B0B0C</Color>
    <SolidColorBrush x:Key="AccentGrad" Color="{DynamicResource AccentA}"/>
    <SolidColorBrush x:Key="AccentBrush" Color="{DynamicResource AccentA}"/>
    <SolidColorBrush x:Key="AccentSoft" Color="{DynamicResource AccentSoftC}"/>
    <SolidColorBrush x:Key="AccentFg" Color="{DynamicResource AccentFgC}"/>

    <Style x:Key="Primary" TargetType="Button">
      <Setter Property="Foreground" Value="{DynamicResource AccentFg}"/><Setter Property="FontSize" Value="13"/><Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Padding" Value="18,9"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template"><Setter.Value>
        <ControlTemplate TargetType="Button">
          <Border x:Name="b" CornerRadius="4" Padding="{TemplateBinding Padding}" Background="{DynamicResource AccentBrush}">
            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.88"/></Trigger>
            <Trigger Property="IsPressed" Value="True"><Setter TargetName="b" Property="Opacity" Value="0.75"/></Trigger>
            <Trigger Property="IsEnabled" Value="False"><Setter TargetName="b" Property="Opacity" Value="0.3"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value></Setter>
    </Style>

    <Style x:Key="Ghost" TargetType="Button">
      <Setter Property="Foreground" Value="#E4E4E7"/><Setter Property="FontSize" Value="13"/><Setter Property="FontWeight" Value="Medium"/>
      <Setter Property="Padding" Value="14,9"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template"><Setter.Value>
        <ControlTemplate TargetType="Button">
          <Border x:Name="b" CornerRadius="4" Padding="{TemplateBinding Padding}" Background="#1A1A1D" BorderBrush="#2A2A2E" BorderThickness="1">
            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
          </Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="#222226"/></Trigger>
            <Trigger Property="IsEnabled" Value="False"><Setter TargetName="b" Property="Opacity" Value="0.35"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value></Setter>
    </Style>

    <Style x:Key="TitleBtn" TargetType="Button">
      <Setter Property="Foreground" Value="#A0A0A7"/><Setter Property="FontFamily" Value="Segoe Fluent Icons, Segoe MDL2 Assets"/>
      <Setter Property="FontSize" Value="10"/><Setter Property="Width" Value="46"/><Setter Property="Height" Value="38"/>
      <Setter Property="Template"><Setter.Value>
        <ControlTemplate TargetType="Button">
          <Border x:Name="b" Background="Transparent" CornerRadius="6"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="#222226"/><Setter Property="Foreground" Value="White"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value></Setter>
    </Style>
    <Style x:Key="CloseBtn" TargetType="Button" BasedOn="{StaticResource TitleBtn}">
      <Setter Property="Template"><Setter.Value>
        <ControlTemplate TargetType="Button">
          <Border x:Name="b" Background="Transparent" CornerRadius="6"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="#E5484D"/><Setter Property="Foreground" Value="White"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value></Setter>
    </Style>

    <Style x:Key="Toggle" TargetType="CheckBox">
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template"><Setter.Value>
        <ControlTemplate TargetType="CheckBox">
          <Grid Width="40" Height="22" Background="Transparent">
            <Border x:Name="track" CornerRadius="11" Background="#2A2A2E"/>
            <Ellipse x:Name="thumb" Width="16" Height="16" Fill="#8E8E93" HorizontalAlignment="Left" Margin="3,0,0,0">
              <Ellipse.RenderTransform><TranslateTransform x:Name="tt" X="0"/></Ellipse.RenderTransform>
            </Ellipse>
          </Grid>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="track" Property="Background" Value="#36363C"/></Trigger>
            <Trigger Property="IsChecked" Value="True">
              <Trigger.EnterActions><BeginStoryboard><Storyboard>
                <DoubleAnimation Storyboard.TargetName="tt" Storyboard.TargetProperty="X" To="18" Duration="0:0:0.15"><DoubleAnimation.EasingFunction><CubicEase EasingMode="EaseOut"/></DoubleAnimation.EasingFunction></DoubleAnimation>
              </Storyboard></BeginStoryboard></Trigger.EnterActions>
              <Trigger.ExitActions><BeginStoryboard><Storyboard>
                <DoubleAnimation Storyboard.TargetName="tt" Storyboard.TargetProperty="X" To="0" Duration="0:0:0.15"><DoubleAnimation.EasingFunction><CubicEase EasingMode="EaseOut"/></DoubleAnimation.EasingFunction></DoubleAnimation>
              </Storyboard></BeginStoryboard></Trigger.ExitActions>
              <Setter TargetName="track" Property="Background" Value="{DynamicResource AccentBrush}"/>
              <Setter TargetName="thumb" Property="Fill" Value="{DynamicResource AccentFg}"/>
            </Trigger>
            <Trigger Property="IsEnabled" Value="False"><Setter Property="Opacity" Value="0.45"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value></Setter>
    </Style>

    <Style x:Key="Nav" TargetType="RadioButton">
      <Setter Property="Foreground" Value="#9A9AA1"/><Setter Property="Cursor" Value="Hand"/><Setter Property="Margin" Value="0,1"/>
      <Setter Property="Template"><Setter.Value>
        <ControlTemplate TargetType="RadioButton">
          <Grid>
            <Border x:Name="bg" CornerRadius="4" Padding="10,7" Background="Transparent"><ContentPresenter/></Border>
            <Border x:Name="bar" Width="2" Height="14" CornerRadius="1" HorizontalAlignment="Left" Background="{DynamicResource AccentBrush}" Visibility="Collapsed"/>
          </Grid>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="bg" Property="Background" Value="#161618"/></Trigger>
            <Trigger Property="IsChecked" Value="True">
              <Setter TargetName="bg" Property="Background" Value="#1C1C1F"/>
              <Setter TargetName="bar" Property="Visibility" Value="Visible"/>
              <Setter Property="Foreground" Value="White"/>
            </Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value></Setter>
    </Style>

    <Style TargetType="ScrollBar">
      <Setter Property="Width" Value="8"/>
      <Setter Property="Template"><Setter.Value>
        <ControlTemplate TargetType="ScrollBar">
          <Track x:Name="PART_Track" IsDirectionReversed="True">
            <Track.Thumb><Thumb><Thumb.Template><ControlTemplate TargetType="Thumb">
              <Border x:Name="t" CornerRadius="3" Background="#26262B" Margin="2,0"/>
              <ControlTemplate.Triggers>
                <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="t" Property="Background" Value="#3A3A40"/></Trigger>
                <Trigger Property="IsDragging" Value="True"><Setter TargetName="t" Property="Background" Value="#4A4A51"/></Trigger>
              </ControlTemplate.Triggers>
            </ControlTemplate></Thumb.Template></Thumb></Track.Thumb>
          </Track>
        </ControlTemplate>
      </Setter.Value></Setter>
    </Style>
    <Style x:Key="Chip" TargetType="RadioButton">
      <Setter Property="Foreground" Value="#C8C8CD"/><Setter Property="Cursor" Value="Hand"/><Setter Property="FontSize" Value="12.5"/><Setter Property="Margin" Value="0,0,6,6"/>
      <Setter Property="Template"><Setter.Value>
        <ControlTemplate TargetType="RadioButton">
          <Border x:Name="b" CornerRadius="4" Padding="11,6" Background="#1A1A1D" BorderBrush="#2A2A2E" BorderThickness="1"><ContentPresenter/></Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="#222226"/></Trigger>
            <Trigger Property="IsChecked" Value="True"><Setter TargetName="b" Property="Background" Value="{DynamicResource AccentSoft}"/><Setter TargetName="b" Property="BorderBrush" Value="{DynamicResource AccentBrush}"/><Setter Property="Foreground" Value="{DynamicResource AccentBrush}"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value></Setter>
    </Style>
    <Style x:Key="ChipCheck" TargetType="CheckBox">
      <Setter Property="Foreground" Value="#C8C8CD"/><Setter Property="Cursor" Value="Hand"/><Setter Property="FontSize" Value="12.5"/><Setter Property="Margin" Value="0,0,6,6"/>
      <Setter Property="Template"><Setter.Value>
        <ControlTemplate TargetType="CheckBox">
          <Border x:Name="b" CornerRadius="6" Padding="11,6" Background="#1A1A1D" BorderBrush="#2A2A2E" BorderThickness="1"><ContentPresenter/></Border>
          <ControlTemplate.Triggers>
            <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="b" Property="Background" Value="#222226"/></Trigger>
            <Trigger Property="IsChecked" Value="True"><Setter TargetName="b" Property="Background" Value="{DynamicResource AccentSoft}"/><Setter TargetName="b" Property="BorderBrush" Value="{DynamicResource AccentBrush}"/><Setter Property="Foreground" Value="{DynamicResource AccentBrush}"/></Trigger>
          </ControlTemplate.Triggers>
        </ControlTemplate>
      </Setter.Value></Setter>
    </Style>
  </Window.Resources>

  <Border x:Name="Root" CornerRadius="6" BorderThickness="1" BorderBrush="#26262A" Margin="12" Background="#0C0C0D">
    <Border.Effect><DropShadowEffect BlurRadius="20" ShadowDepth="2" Opacity="0.5"/></Border.Effect>
    <Grid>
      <Grid.RowDefinitions><RowDefinition Height="46"/><RowDefinition Height="*"/></Grid.RowDefinitions>

      <!-- Barra de título -->
      <Grid x:Name="TitleBar" Background="Transparent">
        <StackPanel Orientation="Horizontal" Margin="18,0,0,0" VerticalAlignment="Center">
          <Image x:Name="TitleIcon" Width="20" Height="20"/>
          <TextBlock Text="Miki Tweaks" Foreground="#EDEDEF" FontWeight="SemiBold" FontSize="13" Margin="10,0,0,0" VerticalAlignment="Center"/>
          <Border Background="#1A1A1D" CornerRadius="4" Padding="7,2" Margin="10,0,0,0" VerticalAlignment="Center">
            <TextBlock x:Name="PcName" Text="" Foreground="#8E8E95" FontSize="11"/>
          </Border>
          <Border x:Name="ModeChip" CornerRadius="4" Padding="8,2" Margin="8,0,0,0" VerticalAlignment="Center" Visibility="Collapsed"><StackPanel Orientation="Horizontal"><Ellipse x:Name="ModeDot" Width="7" Height="7" VerticalAlignment="Center"/><TextBlock x:Name="ModeChipText" FontSize="11" Margin="6,0,0,0" VerticalAlignment="Center"/></StackPanel></Border>
        </StackPanel>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,4,6,0" VerticalAlignment="Top">
          <Button x:Name="BtnMin" WindowChrome.IsHitTestVisibleInChrome="True" Style="{StaticResource TitleBtn}" Content="&#xE921;"/>
          <Button x:Name="BtnMax" WindowChrome.IsHitTestVisibleInChrome="True" Style="{StaticResource TitleBtn}" Content="&#xE922;"/>
          <Button x:Name="BtnClose" WindowChrome.IsHitTestVisibleInChrome="True" Style="{StaticResource CloseBtn}" Content="&#xE8BB;"/>
        </StackPanel>
      </Grid>

      <Grid Grid.Row="1">
        <!-- ===== Bienvenida ===== -->
        <Grid x:Name="WelcomeView">
          <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" Width="620" Margin="0,0,0,30">
            <Image x:Name="BigLogo" Width="44" Height="44" HorizontalAlignment="Left" RenderOptions.BitmapScalingMode="HighQuality"/>
            <TextBlock FontSize="32" FontWeight="SemiBold" Foreground="#EDEDEF" Margin="0,26,0,0" TextWrapping="Wrap" LineHeight="38"
                       Text="Optimiza tu PC para jugar en competitivo."/>
            <TextBlock FontSize="14.5" Foreground="#9A9AA1" TextWrapping="Wrap" Margin="0,12,0,0" LineHeight="22"
                       Text="Analiza tu hardware, tu configuración de Windows y tus juegos, y te propone solo los ajustes que tienen sentido en tu equipo. Todo se puede deshacer."/>
            <StackPanel Orientation="Horizontal" Margin="0,28,0,0">
              <Button x:Name="BtnScan" Style="{StaticResource Primary}" Padding="20,11" FontSize="14">
                <StackPanel Orientation="Horizontal">
                  <TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="&#xE721;" FontSize="13" VerticalAlignment="Center"/>
                  <TextBlock Text="Escanear mi PC" Margin="9,0,0,0" VerticalAlignment="Center"/>
                </StackPanel>
              </Button>
              <TextBlock Text="Tarda unos 15 segundos" Foreground="#6E6E75" FontSize="12.5" VerticalAlignment="Center" Margin="16,0,0,0"/>
            </StackPanel>
            <Border Height="1" Background="#1F1F23" Margin="0,40,0,22"/>
            <Grid>
              <Grid.ColumnDefinitions><ColumnDefinition Width="120"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
              <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
              <TextBlock Text="Tu perfil" FontSize="12.5" Foreground="#6E6E75" VerticalAlignment="Center"/>
              <StackPanel Grid.Column="1" Orientation="Horizontal">
                <TextBlock x:Name="WelcomeProfile" FontSize="12.5" Foreground="#EDEDEF" VerticalAlignment="Center"/>
                <Button x:Name="BtnProfile" Style="{StaticResource Ghost}" Content="Cambiar" Padding="10,4" FontSize="12" Margin="12,0,0,0"/>
              </StackPanel>
              <TextBlock Grid.Row="1" Text="Juegos" FontSize="12.5" Foreground="#6E6E75" Margin="0,22,0,0"/>
              <TextBlock x:Name="WelcomeGamesText" Grid.Row="1" Grid.Column="1" FontSize="12.5" Foreground="#B4B4BA" TextWrapping="Wrap" LineHeight="20" Margin="0,22,0,0"/>
              <WrapPanel x:Name="WelcomeGames" Grid.Row="1" Grid.Column="1" Visibility="Collapsed"/>
              <TextBlock Grid.Row="2" Text="Modo rápido" FontSize="12.5" Foreground="#6E6E75" Margin="0,24,0,0" VerticalAlignment="Center"/>
              <StackPanel Grid.Row="2" Grid.Column="1" Orientation="Horizontal" Margin="0,18,0,0">
                <WrapPanel x:Name="WelcomeModes"/>
                <TextBlock x:Name="WelcomeModeStatus" FontSize="12" Foreground="#8E8E95" VerticalAlignment="Center" Margin="6,0,0,0"/>
              </StackPanel>
              <TextBlock Grid.Row="3" Text="No se toca" FontSize="12.5" Foreground="#6E6E75" Margin="0,22,0,0"/>
              <TextBlock Grid.Row="3" Grid.Column="1" FontSize="12.5" Foreground="#B4B4BA" Margin="0,22,0,0" TextWrapping="Wrap"
                         Text="Medal, Riot Vanguard, tus planes de energía, Xbox, Microsoft Store, Defender ni Windows Update."/>
            </Grid>
            <TextBlock Text="Al usar Miki Tweaks aceptas que cambie ajustes de Windows bajo tu responsabilidad. Todo se puede deshacer y nada se toca sin que lo marques." FontSize="11.5" Foreground="#82828A" Margin="0,18,0,0" TextWrapping="Wrap"/>
          </StackPanel>
        </Grid>

        <!-- ===== Asistente: perfil de uso ===== -->
        <Grid x:Name="SetupView" Visibility="Collapsed">
          <StackPanel x:Name="SetupHost" VerticalAlignment="Center" HorizontalAlignment="Center" Width="640" Margin="0,0,0,24"/>
        </Grid>

        <!-- ===== Escaneo ===== -->
        <Grid x:Name="ScanView" Visibility="Collapsed">
          <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" Width="620" Margin="0,0,0,30">
            <TextBlock Text="Analizando tu PC" FontSize="13" Foreground="#8E8E95"/>
            <Grid Margin="0,6,0,0">
              <TextBlock x:Name="ScanStep" Text="Preparando..." FontSize="24" FontWeight="SemiBold" Foreground="#EDEDEF" VerticalAlignment="Bottom" TextTrimming="CharacterEllipsis" Margin="0,0,90,0"/>
              <TextBlock x:Name="ScanPct" Text="0%" FontSize="24" FontWeight="SemiBold" Foreground="#6E6E75" HorizontalAlignment="Right" VerticalAlignment="Bottom"/>
            </Grid>
            <Border Height="2" Background="#1F1F23" Margin="0,18,0,0">
              <Border x:Name="ScanBar" HorizontalAlignment="Left" Width="0" Background="{DynamicResource AccentBrush}"/>
            </Border>
            <StackPanel x:Name="ScanSteps" Margin="0,22,0,0"/>
          </StackPanel>
        </Grid>

        <!-- ===== Resultados ===== -->
        <Grid x:Name="ResultsView" Visibility="Collapsed">
          <Grid.ColumnDefinitions><ColumnDefinition Width="236"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <Border BorderBrush="#1A1A1D" BorderThickness="0,0,1,0">
            <DockPanel Margin="14,6,14,18">
              <Button x:Name="BtnRescan" DockPanel.Dock="Bottom" Style="{StaticResource Ghost}" HorizontalAlignment="Stretch">
                <StackPanel Orientation="Horizontal">
                  <TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="&#xE72C;" FontSize="13" VerticalAlignment="Center"/>
                  <TextBlock Text="Volver a escanear" Margin="9,0,0,0" VerticalAlignment="Center"/>
                </StackPanel>
              </Button>
              <Border DockPanel.Dock="Bottom" CornerRadius="6" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="12,10" Margin="0,0,0,10">
                <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                  <Grid Width="38" Height="38"><Ellipse Stroke="#232326" StrokeThickness="4"/><Path x:Name="SideArc" StrokeThickness="4" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Stroke="{StaticResource AccentGrad}"/><TextBlock x:Name="SideScore" FontSize="11.5" FontWeight="SemiBold" Foreground="White" HorizontalAlignment="Center" VerticalAlignment="Center"/></Grid>
                  <StackPanel Grid.Column="1" Margin="10,0,0,0" VerticalAlignment="Center"><TextBlock Text="Puntuación de tu PC" FontSize="11" Foreground="#82828A"/><TextBlock x:Name="SideMode" FontSize="12.5" FontWeight="SemiBold" Foreground="#C8C8CD" TextTrimming="CharacterEllipsis"/></StackPanel>
                </Grid>
              </Border>
              <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled"><StackPanel x:Name="NavPanel"/></ScrollViewer>
            </DockPanel>
          </Border>

          <Grid Grid.Column="1">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
            <Grid Margin="34,8,34,16">
              <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
              <StackPanel>
                <TextBlock x:Name="SecTitle" FontSize="24" FontWeight="SemiBold" Foreground="White"/>
                <TextBlock x:Name="SecSub" FontSize="13" Foreground="#8E8E95" Margin="0,5,0,0" TextWrapping="Wrap"/>
              </StackPanel>
              <StackPanel x:Name="SecTools" Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Bottom" Margin="20,0,0,0" Visibility="Collapsed">
                <Border CornerRadius="6" Background="#161618" BorderBrush="#2A2A2E" BorderThickness="1" Padding="12,0" Width="220" Height="38">
                  <Grid>
                    <TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="&#xE721;" FontSize="12" Foreground="#82828A" VerticalAlignment="Center"/>
                    <TextBlock x:Name="SecSearchHint" Text="Buscar en esta sección" Margin="24,0,0,0" FontSize="13" Foreground="#82828A" VerticalAlignment="Center" IsHitTestVisible="False"/>
                    <TextBox x:Name="SecSearch" Margin="22,0,0,0" Background="Transparent" BorderThickness="0" Foreground="#EDEDEF" CaretBrush="White" SelectionBrush="{DynamicResource AccentBrush}" FontSize="13" VerticalAlignment="Center"/>
                  </Grid>
                </Border>
                <Button x:Name="BtnSelRec" Style="{StaticResource Ghost}" Margin="8,0,0,0" Padding="14,9" ToolTip="Marca todos los recomendados de esta sección">
                  <StackPanel Orientation="Horizontal"><TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="&#xE73A;" FontSize="12" VerticalAlignment="Center"/><TextBlock Text="Recomendados" Margin="8,0,0,0"/></StackPanel>
                </Button>
                <Button x:Name="BtnSelNone" Style="{StaticResource Ghost}" Margin="8,0,0,0" Padding="12,9" ToolTip="Deja esta sección como está ahora en tu PC">
                  <TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="&#xE7A7;" FontSize="12" VerticalAlignment="Center"/>
                </Button>
              </StackPanel>
            </Grid>
            <ScrollViewer x:Name="MainScroll" Grid.Row="1" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Padding="34,0,26,18">
              <ContentControl x:Name="SecHost"/>
            </ScrollViewer>
            <Border Grid.Row="2" Background="#0E0E10" BorderBrush="#1A1A1D" BorderThickness="0,1,0,0" Padding="34,14" CornerRadius="0,0,9,0">
              <DockPanel>
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                  <Ellipse x:Name="PendingDot" Width="9" Height="9" Fill="{DynamicResource AccentBrush}" Margin="0,0,10,0"/>
                  <TextBlock x:Name="PendingText" Foreground="#C8C8CD" FontSize="13.5" VerticalAlignment="Center"/>
                </StackPanel>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                  <Button x:Name="BtnDiscard" Style="{StaticResource Ghost}" Content="Descartar"/>
                  <Button x:Name="BtnApply" Style="{StaticResource Primary}" Content="Aplicar cambios" Margin="10,0,0,0"/>
                </StackPanel>
              </DockPanel>
            </Border>

            <!-- Capa de aplicación -->
            <Grid x:Name="Overlay" Grid.RowSpan="3" Background="#F20C0C0D" Visibility="Collapsed">
              <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center" Width="560">
                <Grid Width="96" Height="96" HorizontalAlignment="Center">
                  <Ellipse x:Name="OvRing" Stroke="#1A1A1D" StrokeThickness="8" Margin="4"/>
                  <Path x:Name="OvSpin" Stroke="{StaticResource AccentGrad}" StrokeThickness="8" StrokeStartLineCap="Round" StrokeEndLineCap="Round"
                        Data="M 48,8 A 40,40 0 0 1 88,48" RenderTransformOrigin="0.5,0.5">
                    <Path.RenderTransform><RotateTransform/></Path.RenderTransform>
                    <Path.Triggers>
                      <EventTrigger RoutedEvent="Loaded"><BeginStoryboard><Storyboard>
                        <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(RotateTransform.Angle)" From="0" To="360" Duration="0:0:1" RepeatBehavior="Forever"/>
                      </Storyboard></BeginStoryboard></EventTrigger>
                    </Path.Triggers>
                  </Path>
                  <TextBlock x:Name="OvDone" FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="&#xE73E;" FontSize="36" Foreground="#4CC38A" HorizontalAlignment="Center" VerticalAlignment="Center" Visibility="Collapsed"/>
                </Grid>
                <TextBlock x:Name="OvTitle" Text="Aplicando cambios..." FontSize="22" FontWeight="SemiBold" Foreground="White" HorizontalAlignment="Center" Margin="0,22,0,0"/>
                <TextBlock x:Name="OvSub" FontSize="13" Foreground="#8E8E95" HorizontalAlignment="Center" TextWrapping="Wrap" TextAlignment="Center" Margin="0,6,0,0"/>
                <Border Background="#0F0F11" CornerRadius="6" Padding="16,12" Margin="0,20,0,0" BorderBrush="#232326" BorderThickness="1">
                  <ScrollViewer x:Name="OvScroll" MaxHeight="240" VerticalScrollBarVisibility="Auto">
                    <TextBlock x:Name="OvLog" FontFamily="Cascadia Mono, Consolas" FontSize="12" Foreground="#C8C8CD" TextWrapping="Wrap" LineHeight="20"/>
                  </ScrollViewer>
                </Border>
                <StackPanel x:Name="OvButtons" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,20,0,0" Visibility="Collapsed">
                  <Button x:Name="BtnLater" Style="{StaticResource Ghost}" Content="Listo"/>
                  <Button x:Name="BtnReboot" Style="{StaticResource Primary}" Content="Reiniciar ahora" Margin="10,0,0,0"/>
                </StackPanel>
              </StackPanel>
            </Grid>
          </Grid>
        </Grid>
      </Grid>
      <Border x:Name="Toast" Grid.Row="1" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,28,92" CornerRadius="6" Background="#1A1A1D" BorderBrush="#2E2E33" BorderThickness="1" Padding="16,12" Visibility="Collapsed" MaxWidth="440" IsHitTestVisible="False">
        <Border.Effect><DropShadowEffect BlurRadius="22" ShadowDepth="0" Opacity="0.55"/></Border.Effect>
        <StackPanel Orientation="Horizontal"><TextBlock x:Name="ToastIcon" FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="&#xE73E;" Foreground="#4CC38A" FontSize="15" VerticalAlignment="Center"/><TextBlock x:Name="ToastText" Foreground="#EDEDEF" FontSize="13" Margin="12,0,0,0" TextWrapping="Wrap" MaxWidth="380" VerticalAlignment="Center"/></StackPanel>
      </Border>
    </Grid>
  </Border>
</Window>
'@

$window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
if ('MtI18n' -as [type]) {
    if ([MtI18n]::On) {
        [MtI18n]::Walk($window)
        $script:I18nTimer = New-Object Windows.Threading.DispatcherTimer
        $script:I18nTimer.Interval = [TimeSpan]::FromMilliseconds(250)
        $script:I18nTimer.Add_Tick({ try { [MtI18n]::Walk($window) } catch {} })
        $script:I18nTimer.Start()
        $window.Add_ContentRendered({ try { [MtI18n]::Walk($window) } catch {} })
    }
}
$UI = @{}
foreach ($n in 'TitleBar', 'TitleIcon', 'BtnMin', 'BtnClose', 'WelcomeView', 'ScanView', 'ResultsView', 'BtnScan', 'ScanPct', 'ScanStep', 'ScanBar', 'ScanSteps',
    'NavPanel', 'BtnRescan', 'SecTitle', 'SecSub', 'MainScroll', 'SecHost', 'PendingDot', 'PendingText', 'BtnDiscard', 'BtnApply',
    'PcName', 'BigLogo', 'Toast', 'ToastIcon', 'ToastText', 'SideArc', 'SideScore', 'SideMode', 'Root', 'BtnMax', 'SecTools', 'SecSearch', 'SecSearchHint', 'BtnSelRec', 'BtnSelNone', 'WelcomeGames', 'WelcomeGamesText', 'WelcomeModes', 'SetupView', 'SetupHost', 'WelcomeProfile', 'BtnProfile', 'WelcomeModeStatus', 'ModeChip', 'ModeDot', 'ModeChipText', 'Overlay', 'OvSpin', 'OvDone', 'OvTitle', 'OvSub', 'OvScroll', 'OvLog', 'OvButtons', 'BtnLater', 'BtnReboot') { $UI[$n] = $window.FindName($n) }

$NS = 'xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"'
function New-El([string]$x) { $__el = [Windows.Markup.XamlReader]::Parse($x.Replace('{NS}', $NS)); if (($script:Lang -eq 'en') -and ('MtI18n' -as [type])) { try { [MtI18n]::Walk($__el) } catch {} }; return $__el }
function Esc($s) { [Security.SecurityElement]::Escape((([string]$s) -replace '[\x00-\x08\x0B\x0C\x0E-\x1F\x7F\uFFFE\uFFFF]', '')) }
$bc = New-Object Windows.Media.BrushConverter
function Br($hex) {
    # Acepta un color (#RRGGBB) o un recurso del tema: '{DynamicResource AccentBrush}'
    if ("$hex" -match '^\{DynamicResource\s+(\w+)\}$') { return $window.Resources[$Matches[1]] }
    $bc.ConvertFromString($hex)
}
function DoEvents {
    $fr = New-Object Windows.Threading.DispatcherFrame
    [void][Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke([Windows.Threading.DispatcherPriority]::Background, [Func[object, object]] { param($o) $o.Continue = $false; $null }, $fr)
    [Windows.Threading.Dispatcher]::PushFrame($fr)
}
function Fade($el) {
    $a = New-Object Windows.Media.Animation.DoubleAnimation(0, 1, (New-Object Windows.Duration([TimeSpan]::FromMilliseconds(320))))
    $el.BeginAnimation([Windows.UIElement]::OpacityProperty, $a)
}
function Show-View($name) {
    foreach ($v in 'WelcomeView', 'SetupView', 'ScanView', 'ResultsView') { $UI[$v].Visibility = $(if ($v -eq $name) { 'Visible' } else { 'Collapsed' }) }
    Fade $UI[$name]
}

$script:LogLines = New-Object System.Collections.Generic.List[string]
function Log($msg) {
    $msg = Tr "$msg"
    $line = "[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $msg
    $script:LogLines.Add($line)
    try { Add-Content -Path $LogFile -Value $line -Encoding UTF8 } catch {}
    if ($UI.Overlay.Visibility -eq 'Visible') { $UI.OvLog.Text += "$msg`n"; $UI.OvScroll.ScrollToEnd() }
    DoEvents
}

# ---------- Puntuación ----------
$Weights = @{ Alto = 3; Medio = 2; Bajo = 1 }
function Get-Score([switch]$Projected) {
    $tot = 0.0; $got = 0.0
    foreach ($t in @($script:Tweaks | Where-Object Tier -eq 'Recomendado')) {
        $w = $Weights[$t.Impact]; if ($t.Category -eq 'Inicio') { $w = 0.5 }
        $tot += $w
        $on = if ($Projected -and $t.Toggle) { [bool]$t.Toggle.IsChecked } else { $t.Applied }
        if ($on) { $got += $w }
    }
    $warn = @($script:Diags | Where-Object { $_.Level -eq 'warn' }).Count
    if ($tot -eq 0) { return 100 }
    return [int][math]::Round([math]::Max(0, 100 * $got / $tot - 5 * $warn))
}
function Set-Gauge($v) {
    if (-not $script:Arc) { return }
    $script:ScoreNum.Text = "$([int][math]::Round($v))"
    $p = [math]::Min([double]$v, 99.99)
    if ($p -le 0.5) { $script:Arc.Data = $null; return }
    $a = [math]::PI * 2 * $p / 100 - [math]::PI / 2
    $x = 75 + 66 * [math]::Cos($a); $y = 75 + 66 * [math]::Sin($a)
    $large = if ($p -gt 50) { 1 } else { 0 }
    $script:Arc.Data = [Windows.Media.Geometry]::Parse([string]::Format($Inv, 'M 75,9 A 66,66 0 {0} 1 {1:0.##},{2:0.##}', $large, $x, $y))
}
$script:ScoreCur = 0.0; $script:ScoreTarget = 0
$script:ScoreTimer = New-Object Windows.Threading.DispatcherTimer
$script:ScoreTimer.Interval = [TimeSpan]::FromMilliseconds(16)
$script:ScoreTimer.Add_Tick({
    $diff = $script:ScoreTarget - $script:ScoreCur
    if ([math]::Abs($diff) -lt 0.6) { $script:ScoreCur = [double]$script:ScoreTarget; $script:ScoreTimer.Stop() }
    else { $step = $diff * 0.07; if ([math]::Abs($step) -lt 0.5) { $step = 0.5 * [math]::Sign($diff) }; $script:ScoreCur += $step }
    Set-Gauge $script:ScoreCur
})
function Animate-Score { $script:ScoreTarget = Get-Score; Set-Gauge $script:ScoreCur; $script:ScoreTimer.Start() }

# ---------- Tarjetas ----------
function Chip($text, $bg, $fg) { "<Border CornerRadius=`"4`" Background=`"$bg`" Padding=`"7,2`" Margin=`"0,0,6,4`" VerticalAlignment=`"Center`"><TextBlock Text=`"$(Esc $text)`" FontSize=`"11`" Foreground=`"$fg`"/></Border>" }
$ImpactStyle = @{ Alto = @('Impacto alto', '{DynamicResource AccentSoft}', '{DynamicResource AccentBrush}'); Medio = @('Impacto medio', '#1C1C1F', '#A0A0A7'); Bajo = @('Impacto bajo', '#1C1C1F', '#8E8E95') }

function New-TweakCard($t) {
    $is = $ImpactStyle[$t.Impact]
    $chips = Chip $is[0] $is[1] $is[2]
    if ($t.Tier -eq 'Opcional') { $chips += Chip 'Opcional' '#1C1C1F' '#E0B954' }
    if ($t.Reboot) { $chips += Chip 'Requiere reinicio' '#1C1C1F' '#8E8E95' }
    if ($t.OS) { $chips += Chip "Solo Windows $($t.OS)" '#1C1C1F' '#A0A0A7' }
    $card = New-El @"
<Border {NS} CornerRadius="8" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="18,16" Margin="0,0,0,10">
 <Grid>
  <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
  <Border Width="42" Height="42" CornerRadius="6" Background="$($is[1])" VerticalAlignment="Top">
   <TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="$($t.Glyph)" FontSize="17" Foreground="$($is[2])" HorizontalAlignment="Center" VerticalAlignment="Center"/>
  </Border>
  <StackPanel Grid.Column="1" Margin="16,0,18,0">
   <WrapPanel><TextBlock Text="$(Esc $t.Name)" FontSize="15" FontWeight="SemiBold" Foreground="#EDEDEF" Margin="0,0,10,4" VerticalAlignment="Center"/>$chips</WrapPanel>
   <TextBlock Text="$(Esc $t.Desc)" FontSize="12.5" Foreground="#8E8E95" TextWrapping="Wrap" LineHeight="19" Margin="0,3,0,0"/>
   <StackPanel Orientation="Horizontal" Margin="0,9,0,0">
    <TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="&#xE721;" FontSize="11" Foreground="#5F5F66" VerticalAlignment="Center"/>
    <TextBlock Text="$(Esc $t.Why)" FontSize="12" Foreground="#82828A" Margin="7,0,0,0"/>
   </StackPanel>
  </StackPanel>
  <StackPanel Grid.Column="2" VerticalAlignment="Center" MinWidth="110">
   <CheckBox x:Name="Tg" Style="{DynamicResource Toggle}" HorizontalAlignment="Right"/>
   <TextBlock x:Name="St" FontSize="11.5" FontWeight="SemiBold" Margin="0,9,0,0" HorizontalAlignment="Right"/>
  </StackPanel>
 </Grid>
</Border>
"@
    $tg = $card.FindName('Tg')
    $t.Toggle = $tg; $t.StatusText = $card.FindName('St'); $t.Card = $card
    $tg.IsChecked = $(if ($t.Applied) { $true } elseif ($script:PreselectRecommended -and $t.Tier -eq 'Recomendado') { $true } else { $false })
    if ($t.Applied -and -not $t.HasBackup) { $tg.IsEnabled = $false; $tg.ToolTip = 'Ya estaba así antes de usar la app' }
    $tg.Add_Checked({ Update-Pending }); $tg.Add_Unchecked({ Update-Pending })
    $card.Tag = ("$($t.Name) $($t.Desc) $($t.Why)").ToLower()
    $card.Add_MouseEnter({ param($s, $e) $s.Background = Br '#17171A' }); $card.Add_MouseLeave({ param($s, $e) $s.Background = Br '#131315' })
    return $card
}

function New-Header($text, $top = 6) { New-El "<TextBlock {NS} Text=`"$(Esc $text)`" FontSize=`"11.5`" FontWeight=`"SemiBold`" Foreground=`"#82828A`" Margin=`"2,$top,0,12`"/>" }

function Build-CategoryPanel($c) {
    $sp = New-Object Windows.Controls.StackPanel
    if ($c -eq 'Red') { Invoke-Safe 'herramientas de red' { Add-NetToolCards $sp } }
    $grp = @(@($script:Tweaks | Where-Object { $_.Category -eq $c }) | ForEach-Object { $_.Group } | Where-Object { $_ } | Select-Object -Unique)
    if ($grp.Count) {
        foreach ($g in $grp) {
            [void]$sp.Children.Add((New-Header $g $(if ($sp.Children.Count) { 18 } else { 4 })))
            foreach ($tier in 'Recomendado', 'Opcional') { foreach ($t in @($script:Tweaks | Where-Object { $_.Category -eq $c -and $_.Group -eq $g -and $_.Tier -eq $tier })) { [void]$sp.Children.Add((New-TweakCard $t)) } }
        }
        return $sp
    }
    foreach ($tier in 'Recomendado', 'Opcional') {
        $items = @($script:Tweaks | Where-Object { $_.Category -eq $c -and $_.Tier -eq $tier })
        if ($items.Count -eq 0) { continue }
        $title = if ($tier -eq 'Recomendado') { 'RECOMENDADOS' } else { 'OPCIONALES  ·  TIENEN ALGUNA CONTRAPARTIDA' }
        [void]$sp.Children.Add((New-Header $title $(if ($sp.Children.Count) { 18 } else { 4 })))
        foreach ($t in $items) { [void]$sp.Children.Add((New-TweakCard $t)) }
    }
    if ($GameDefById.ContainsKey($c)) {
        $tips = @($GameDefById[$c].Tips | Where-Object { $script:Facts.IsNvidia -or $_ -notmatch 'Reflex' })
        if ($tips.Count) {
            [void]$sp.Children.Add((New-Header 'DENTRO DEL JUEGO  ·  REVÍSALO EN SUS AJUSTES' 18))
            $rows = ($tips | ForEach-Object { "<StackPanel Orientation=`"Horizontal`" Margin=`"0,5`"><TextBlock FontFamily=`"Segoe Fluent Icons, Segoe MDL2 Assets`" Text=`"&#xE73E;`" FontSize=`"12`" Foreground=`"#4CC38A`" VerticalAlignment=`"Center`"/><TextBlock Text=`"$(Esc $_)`" FontSize=`"13`" Foreground=`"#C8C8CD`" Margin=`"12,0,0,0`" TextWrapping=`"Wrap`"/></StackPanel>" }) -join ''
            [void]$sp.Children.Add((New-El "<Border {NS} CornerRadius=`"8`" Background=`"#131315`" BorderBrush=`"#232326`" BorderThickness=`"1`" Padding=`"20,14`" Margin=`"0,0,0,10`"><StackPanel>$rows<TextBlock Text=`"Estas opciones las guarda el propio juego o tu cuenta, así que la app no las cambia por ti.`" FontSize=`"12`" Foreground=`"#82828A`" Margin=`"0,10,0,0`" TextWrapping=`"Wrap`"/></StackPanel></Border>"))
        }
    }
    return $sp
}

function New-HwCard($tag, $tagBg, $tagFg, $label, $value, $sub, $tip = $value) {
    New-El @"
<Border {NS} Width="256" Height="100" CornerRadius="8" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="16,14" Margin="0,0,12,12">
 <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
  <Border Width="44" Height="44" CornerRadius="6" Background="$tagBg" VerticalAlignment="Top">
   <TextBlock Text="$tag" FontSize="11.5" FontWeight="SemiBold" Foreground="$tagFg" HorizontalAlignment="Center" VerticalAlignment="Center"/>
  </Border>
  <StackPanel Grid.Column="1" Margin="14,0,0,0">
   <TextBlock Text="$(Esc $label)" FontSize="11.5" Foreground="#82828A"/>
   <TextBlock Text="$(Esc $value)" ToolTip="$(Esc $tip)" FontSize="14.5" FontWeight="SemiBold" Foreground="#EDEDEF" TextTrimming="CharacterEllipsis" Margin="0,3,0,0"/>
   <TextBlock Text="$(Esc $sub)" FontSize="12" Foreground="#8E8E95" TextTrimming="CharacterEllipsis" Margin="0,3,0,0"/>
  </StackPanel>
 </Grid>
</Border>
"@
}

function Build-Summary {
    $f = $script:Facts
    $sp = New-Object Windows.Controls.StackPanel
    $hero = New-El @"
<Border {NS} CornerRadius="6" Padding="24,22" Margin="0,0,0,18" Background="#131315" BorderBrush="#232326" BorderThickness="1">
 <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
  <Grid Width="150" Height="150">
   <Ellipse Stroke="#232326" StrokeThickness="6" Margin="6"/>
   <Path x:Name="Arc" StrokeThickness="6" StrokeStartLineCap="Round" StrokeEndLineCap="Round" Stroke="{DynamicResource AccentBrush}"/>
   <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
    <TextBlock x:Name="ScoreNum" Text="0" FontSize="42" FontWeight="SemiBold" Foreground="#EDEDEF" HorizontalAlignment="Center"/>
    <TextBlock Text="de 100" FontSize="12" Foreground="#82828A" HorizontalAlignment="Center" Margin="0,-4,0,0"/>
   </StackPanel>
  </Grid>
  <StackPanel Grid.Column="1" Margin="28,0,0,0" VerticalAlignment="Center">
   <TextBlock Text="Puntuación de optimización" FontSize="12.5" Foreground="#8E8E95"/>
   <TextBlock x:Name="HeroTitle" FontSize="21" FontWeight="SemiBold" Foreground="#EDEDEF" TextWrapping="Wrap" Margin="0,4,0,0"/>
   <TextBlock x:Name="HeroText" FontSize="13" Foreground="#A0A0A7" TextWrapping="Wrap" Margin="0,6,0,0"/>
   <TextBlock x:Name="HeroProj" FontSize="13" Foreground="{DynamicResource AccentBrush}" Margin="0,4,0,0"/>
   <StackPanel Orientation="Horizontal" Margin="0,16,0,0">
    <Button x:Name="HeroApply" Style="{DynamicResource Primary}" Content="Aplicar recomendados"/>
    <Button x:Name="HeroSee" Style="{DynamicResource Ghost}" Content="Revisar ajustes" Margin="10,0,0,0"/>
   </StackPanel>
  </StackPanel>
 </Grid>
</Border>
"@
    foreach ($n in 'Arc', 'ScoreNum', 'HeroTitle', 'HeroText', 'HeroProj', 'HeroApply', 'HeroSee') { Set-Variable -Scope Script -Name $n -Value $hero.FindName($n) }
    $script:HeroApply.Add_Click({ Invoke-Apply })
    $script:HeroSee.Add_Click({
        $first = @($script:Tweaks | Where-Object { $_.Tier -eq 'Recomendado' -and -not $_.Applied } | Select-Object -First 1)
        Select-Nav $(if ($first.Count) { $first[0].Category } else { 'resumen' }) })
    [void]$sp.Children.Add($hero)
    $qa = New-El @"
<WrapPanel {NS} Margin="0,-8,0,24">
 <Button x:Name="Q1" Style="{DynamicResource Ghost}" Margin="0,0,10,8"><StackPanel Orientation="Horizontal"><TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="&#xE9D9;" VerticalAlignment="Center"/><TextBlock Text="Rendimiento en vivo" Margin="9,0,0,0"/></StackPanel></Button>
 <Button x:Name="Q2" Style="{DynamicResource Ghost}" Margin="0,0,10,8"><StackPanel Orientation="Horizontal"><TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="&#xEDA2;" VerticalAlignment="Center"/><TextBlock Text="Liberar espacio" Margin="9,0,0,0"/></StackPanel></Button>
 <Button x:Name="Q3" Style="{DynamicResource Ghost}" Margin="0,0,10,8"><StackPanel Orientation="Horizontal"><TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="&#xE777;" VerticalAlignment="Center"/><TextBlock Text="Actualizaciones" Margin="9,0,0,0"/></StackPanel></Button>
 <Button x:Name="Q4" Style="{DynamicResource Ghost}" Margin="0,0,10,8"><StackPanel Orientation="Horizontal"><TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="&#xE945;" VerticalAlignment="Center"/><TextBlock Text="Cambiar de modo" Margin="9,0,0,0"/></StackPanel></Button>
 <Button x:Name="Q5" Style="{DynamicResource Ghost}" Margin="0,0,10,8"><StackPanel Orientation="Horizontal"><TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="&#xE916;" VerticalAlignment="Center"/><TextBlock Text="Medir FPS" Margin="9,0,0,0"/></StackPanel></Button>
</WrapPanel>
"@
    $qa.FindName('Q1').Add_Click({ Select-Nav 'monitor' }); $qa.FindName('Q2').Add_Click({ Select-Nav 'cache' })
    $qa.FindName('Q3').Add_Click({ Select-Nav 'actualizaciones' }); $qa.FindName('Q4').Add_Click({ Select-Nav 'modos' }); $qa.FindName('Q5').Add_Click({ Select-Nav 'benchmark' })
    [void]$sp.Children.Add($qa)

    $gs = @($script:Facts.Games)
    if ($gs.Count) {
        [void]$sp.Children.Add((New-Header 'TUS JUEGOS' 0))
        $gw = New-Object Windows.Controls.WrapPanel
        foreach ($g in $gs) {
            $d = $GameDefById[$g.Id]
            $pend = @($script:Tweaks | Where-Object { $_.Category -eq $g.Id -and $_.Tier -eq 'Recomendado' -and -not $_.Applied }).Count
            $sub = if ($pend) { "$pend mejora$(if ($pend -ne 1) { 's' }) pendiente$(if ($pend -ne 1) { 's' })" } else { 'Todo optimizado' }
            $subCol = if ($pend) { '{DynamicResource AccentBrush}' } else { '#4CC38A' }
            $card = New-El @"
<Border {NS} Width="256" Height="72" CornerRadius="8" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="14,12" Margin="0,0,12,12" Cursor="Hand">
 <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
  <Border Width="40" Height="40" CornerRadius="6" Background="#4D$($d.Color.TrimStart('#'))" BorderBrush="#8C$($d.Color.TrimStart('#'))" BorderThickness="1"><TextBlock Text="$(Esc $d.Abbr)" FontSize="12" FontWeight="Bold" Foreground="#F4F4F6" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
  <StackPanel Grid.Column="1" Margin="14,0,0,0" VerticalAlignment="Center">
   <TextBlock Text="$(Esc $d.Name)" FontSize="14.5" FontWeight="SemiBold" Foreground="#EDEDEF" TextTrimming="CharacterEllipsis"/>
   <TextBlock Text="$sub" FontSize="12" Foreground="$subCol" Margin="0,3,0,0"/>
  </StackPanel>
  <TextBlock Grid.Column="2" FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="&#xE76C;" FontSize="12" Foreground="#5F5F66" VerticalAlignment="Center"/>
 </Grid>
</Border>
"@
            $card.Tag = $g.Id
            $card.Add_MouseLeftButtonUp({ param($s, $e) Select-Nav $s.Tag })
            [void]$gw.Children.Add($card)
        }
        [void]$sp.Children.Add($gw)
    }
    [void]$sp.Children.Add((New-Header 'TU EQUIPO' 0))
    $wp = New-Object Windows.Controls.WrapPanel
    $drv = if ($f.NvDriver) { "Driver $($f.NvDriver)" } else { "Driver $($f.GPUDriver)" }
    $scr = if ($f.Hybrid -and $f.dGPUHz -gt 0) { "$($f.dGPURes) en la gráfica dedicada" } elseif ($f.Hybrid) { 'Pantalla del portátil (integrada)' } else { '' }
    $pwr = if ($f.OnAC) { 'Enchufado' } else { "Batería $($f.BatteryPct) %" }
    $ramSub = "$($f.RamModules)x$($f.RamModGB) GB" + $(if ($f.RamSpeed) { " · $($f.RamSpeed) MT/s" } else { '' })
    [void]$wp.Children.Add((New-HwCard 'CPU' '#1C1C1F' '#A0A0A7' 'Procesador' $f.CPU "$($f.Cores) núcleos · $($f.Threads) hilos"))
    # «NVIDIA GeForce RTX 4060 Laptop GPU» no cabe en la tarjeta: la marca va en la línea del driver y el nombre completo en el tooltip
    $gpuVendor = if ("$($f.GPU)" -match '^(NVIDIA|AMD)\s') { $Matches[1] } else { '' }
    $gpuShort = ("$($f.GPU)" -replace '^NVIDIA\s+(GeForce\s+)?', '' -replace '^AMD\s+', '').Trim()
    if (-not $gpuShort) { $gpuShort = "$($f.GPU)" }
    [void]$wp.Children.Add((New-HwCard 'GPU' '#1C1C1F' '#A0A0A7' 'Gráfica' $gpuShort "$(if ($gpuVendor) { "$gpuVendor · " })$drv" $f.GPU))
    [void]$wp.Children.Add((New-HwCard 'RAM' '#1C1C1F' '#A0A0A7' 'Memoria' "$($f.RamGB) GB $($f.RamType)" $ramSub))
    [void]$wp.Children.Add((New-HwCard 'HZ' '#1C1C1F' '#E0B954' 'Pantalla principal' "$($f.MainHz) Hz" $scr))
    [void]$wp.Children.Add((New-HwCard 'SSD' '#1C1C1F' '#C8C8CD' 'Almacenamiento' $f.Disk "$($f.DiskFreeGB) GB libres de $($f.DiskSizeGB) GB"))
    [void]$wp.Children.Add((New-HwCard $(if ($f.OnAC) { 'AC' } else { 'BAT' }) '#1C1C1F' '#A0A0A7' 'Energía' $pwr "$($f.PowerPlan)"))
    [void]$sp.Children.Add($wp)

    [void]$sp.Children.Add((New-Header 'DIAGNÓSTICO' 14))
    $lv = @{ ok = @('&#xE73E;', '#4CC38A'); warn = @('&#xE7BA;', '#E8B23E'); info = @('&#xE946;', '#7FA6E0') }
    foreach ($d in $script:Diags) {
        $g = $lv[$d.Level]
        [void]$sp.Children.Add((New-El @"
<Border {NS} CornerRadius="6" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="16,13" Margin="0,0,0,8">
 <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
  <TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="$($g[0])" Foreground="$($g[1])" FontSize="16" VerticalAlignment="Top" Margin="0,1,0,0"/>
  <StackPanel Grid.Column="1" Margin="14,0,0,0">
   <TextBlock Text="$(Esc $d.Title)" FontSize="13.5" FontWeight="SemiBold" Foreground="#EDEDEF"/>
   <TextBlock Text="$(Esc $d.Text)" FontSize="12.5" Foreground="#8E8E95" TextWrapping="Wrap" Margin="0,3,0,0"/>
  </StackPanel>
 </Grid>
</Border>
"@))
    }
    return $sp
}

function Build-LogPanel {
    $txt = if ($script:LogLines.Count) { ($script:LogLines -join "`n") } else { 'Aún no hay actividad en esta sesión.' }
    New-El "<Border {NS} CornerRadius=`"8`" Background=`"#0F0F11`" BorderBrush=`"#232326`" BorderThickness=`"1`" Padding=`"18,14`"><TextBlock Text=`"$((Esc $txt).Replace("`n",'&#10;'))`" FontFamily=`"Cascadia Mono, Consolas`" FontSize=`"12`" Foreground=`"#C8C8CD`" TextWrapping=`"Wrap`" LineHeight=`"20`"/></Border>"
}

# ---------- Tareas en segundo plano (red, Windows Update) ----------
$script:AsyncJobs = New-Object System.Collections.ArrayList
$script:AsyncTimer = New-Object Windows.Threading.DispatcherTimer
$script:AsyncTimer.Interval = [TimeSpan]::FromMilliseconds(300)
$script:AsyncTimer.Add_Tick({
    foreach ($j in $script:AsyncJobs.ToArray()) {
        if ($j.H.IsCompleted) {
            $script:AsyncJobs.Remove($j)
            $res = $null
            try { $out = $j.Ps.EndInvoke($j.H); if ($out.Count) { $res = $out[$out.Count - 1] } } catch { $res = @{ Error = $_.Exception.Message } }
            $j.Ps.Dispose()
            try { & $j.Done $res } catch { Log "✗ $($_.Exception.Message)" }
        }
    }
    if ($script:AsyncJobs.Count -eq 0) { $script:AsyncTimer.Stop() }
})
function Start-Async($Work, $ArgList, $Done) {
    $ps = [powershell]::Create(); [void]$ps.AddScript($Work)
    if ($null -ne $ArgList) { foreach ($a in @($ArgList)) { [void]$ps.AddArgument($a) } }
    [void]$script:AsyncJobs.Add(@{ Ps = $ps; H = $ps.BeginInvoke(); Done = $Done })
    $script:AsyncTimer.Start()
}

$DriverCheckWork = {
    param($gpuName)
    $ProgressPreference = 'SilentlyContinue'; $r = @{}
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $x = [xml](Invoke-WebRequest 'https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=3' -UseBasicParsing -TimeoutSec 30).Content
        $name = ($gpuName -replace '^NVIDIA ', '').Trim()
        $all = @($x.LookupValueSearch.LookupValues.LookupValue)
        $hit = $all | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        if (-not $hit) { $hit = $all | Where-Object { $_.Name -like "*$name*" } | Select-Object -First 1 }
        if (-not $hit) { $r.Error = 'No encontré tu gráfica en el catálogo de NVIDIA'; return $r }
        $os = if ([Environment]::OSVersion.Version.Build -ge 22000) { 135 } else { 57 }
        $j = Invoke-RestMethod "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&pfid=$($hit.Value)&osID=$os&languageCode=1033&isWHQL=1&dch=1&sort1=0&numberOfResults=1" -TimeoutSec 30
        $d = $j.IDS[0].downloadInfo
        if (-not $d.Version) { $r.Error = 'NVIDIA no devolvió ningún driver'; return $r }
        $r.Latest = "$($d.Version)"; $r.Date = "$($d.ReleaseDateTime)"; $r.Url = "$($d.DownloadURL)"; $r.Size = "$($d.DownloadURLFileSize)"
    } catch { $r.Error = $_.Exception.Message }
    return $r
}
$WuSearchWork = {
    $r = @{}
    try {
        $s = New-Object -ComObject Microsoft.Update.Session
        $res = $s.CreateUpdateSearcher().Search('IsInstalled=0 and IsHidden=0')
        $list = @()
        foreach ($u in $res.Updates) { $list += @{ Title = "$($u.Title)"; MB = [math]::Round($u.MaxDownloadSize / 1MB); Optional = [bool]$u.BrowseOnly; Driver = ($u.Type -eq 2) } }
        $r.Updates = $list
    } catch { $r.Error = $_.Exception.Message }
    return $r
}
$WuInstallWork = {
    $r = @{}
    try {
        $s = New-Object -ComObject Microsoft.Update.Session
        $res = $s.CreateUpdateSearcher().Search('IsInstalled=0 and IsHidden=0 and BrowseOnly=0')
        $col = New-Object -ComObject Microsoft.Update.UpdateColl
        foreach ($u in $res.Updates) { if (-not $u.EulaAccepted) { $u.AcceptEula() }; [void]$col.Add($u) }
        $r.Count = $col.Count
        if ($col.Count -gt 0) {
            $dl = $s.CreateUpdateDownloader(); $dl.Updates = $col; [void]$dl.Download()
            $in = $s.CreateUpdateInstaller(); $in.Updates = $col; $ir = $in.Install()
            $r.Result = [int]$ir.ResultCode; $r.Reboot = [bool]$ir.RebootRequired
        }
    } catch { $r.Error = $_.Exception.Message }
    return $r
}

# ---------- Página de actualizaciones ----------
function Build-UpdatesPanel {
    $f = $script:Facts
    $sp = New-Object Windows.Controls.StackPanel
    $inst = if ($f.NvDriver) { $f.NvDriver } else { $f.GPUDriver }
    if ($f.GPUDriverDate) { $inst += "  ·  del $($f.GPUDriverDate)" }
    [void]$sp.Children.Add((New-Header 'DRIVER DE LA GRÁFICA' 4))
    $drv = New-El @"
<Border {NS} CornerRadius="8" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="20,16" Margin="0,0,0,10">
 <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
  <Border Width="44" Height="44" CornerRadius="6" Background="#1C1C1F" VerticalAlignment="Top"><TextBlock Text="GPU" FontSize="11.5" FontWeight="SemiBold" Foreground="#A0A0A7" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
  <StackPanel Grid.Column="1" Margin="16,0,16,0">
   <TextBlock Text="$(Esc $f.GPU)" FontSize="15" FontWeight="SemiBold" Foreground="#EDEDEF"/>
   <TextBlock Text="Instalado: $(Esc $inst)" FontSize="12.5" Foreground="#8E8E95" Margin="0,4,0,0"/>
   <TextBlock x:Name="DrvState" FontSize="13" FontWeight="SemiBold" Foreground="#8E8E95" Margin="0,8,0,0" TextWrapping="Wrap"/>
   <TextBlock x:Name="DrvHint" FontSize="12" Foreground="#82828A" Margin="0,4,0,0" TextWrapping="Wrap" Visibility="Collapsed" Text="Al instalarlo, elige &quot;Instalación personalizada&quot; y marca &quot;Instalación limpia&quot;."/>
  </StackPanel>
  <StackPanel Grid.Column="2" VerticalAlignment="Center" MinWidth="150">
   <Button x:Name="DrvBtn" Style="{DynamicResource Primary}" Content="Descargar" Visibility="Collapsed"/>
   <Button x:Name="DrvRecheck" Style="{DynamicResource Ghost}" Content="Comprobar otra vez" Margin="0,8,0,0"/>
  </StackPanel>
 </Grid>
</Border>
"@
    [void]$sp.Children.Add($drv)
    [void]$sp.Children.Add((New-Header 'WINDOWS UPDATE' 18))
    $wu = New-El @"
<Border {NS} CornerRadius="8" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="20,16" Margin="0,0,0,10">
 <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
  <Border Width="44" Height="44" CornerRadius="6" Background="#1C1C1F" VerticalAlignment="Top"><TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="&#xE777;" FontSize="18" Foreground="#A0A0A7" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
  <StackPanel Grid.Column="1" Margin="16,0,16,0">
   <TextBlock Text="Actualizaciones de Windows" FontSize="15" FontWeight="SemiBold" Foreground="#EDEDEF"/>
   <TextBlock x:Name="WuState" FontSize="12.5" Foreground="#8E8E95" Margin="0,4,0,0" TextWrapping="Wrap" Text="Busca las actualizaciones pendientes: seguridad, calidad y drivers que Windows considera necesarios."/>
   <StackPanel x:Name="WuList" Margin="0,8,0,0"/>
  </StackPanel>
  <StackPanel Grid.Column="2" VerticalAlignment="Top" MinWidth="150">
   <Button x:Name="WuSearch" Style="{DynamicResource Primary}" Content="Buscar"/>
   <Button x:Name="WuInstall" Style="{DynamicResource Primary}" Content="Instalar" Margin="0,8,0,0" Visibility="Collapsed"/>
   <Button x:Name="WuOpen" Style="{DynamicResource Ghost}" Content="Abrir Windows Update" Margin="0,8,0,0"/>
  </StackPanel>
 </Grid>
</Border>
"@
    [void]$sp.Children.Add($wu)
    [void]$sp.Children.Add((New-El "<TextBlock {NS} Text=`"Las actualizaciones opcionales (normalmente drivers alternativos) se muestran pero no se instalan: el driver de la gráfica es mejor instalarlo desde arriba.`" FontSize=`"12`" Foreground=`"#82828A`" TextWrapping=`"Wrap`" Margin=`"2,4,0,0`"/>"))

    $script:Upd = @{}
    foreach ($n in 'DrvState', 'DrvHint', 'DrvBtn', 'DrvRecheck') { $script:Upd[$n] = $drv.FindName($n) }
    foreach ($n in 'WuState', 'WuList', 'WuSearch', 'WuInstall', 'WuOpen') { $script:Upd[$n] = $wu.FindName($n) }
    $script:Upd.DrvBtn.Add_Click({ param($s, $e) if ($s.Tag) { Start-Process "$($s.Tag)"; Log "Abierta la descarga: $($s.Tag)" } })
    $script:Upd.DrvRecheck.Add_Click({ Start-DriverCheck })
    $script:Upd.WuOpen.Add_Click({ Start-Process 'ms-settings:windowsupdate' })
    $script:Upd.WuSearch.Add_Click({ Start-WuSearch })
    $script:Upd.WuInstall.Add_Click({ Start-WuInstall })
    if ($script:DriverResult) { Show-DriverResult $script:DriverResult } else { Start-DriverCheck }
    if ($script:WuResult) { Show-WuResult $script:WuResult }
    return $sp
}

function Start-DriverCheck {
    $f = $script:Facts; $u = $script:Upd
    $u.DrvBtn.Visibility = 'Collapsed'; $u.DrvHint.Visibility = 'Collapsed'
    if ($f.IsNvidia) {
        $u.DrvState.Text = 'Buscando el último driver en nvidia.com...'; $u.DrvState.Foreground = Br '#8E8E95'
        Start-Async $DriverCheckWork @($f.GPU) { param($r) Show-DriverResult $r }
    } else {
        $url = if ($f.GPU -match 'AMD|Radeon') { 'https://www.amd.com/es/support/download/drivers.html' } elseif ($f.GPU -match 'Intel') { 'https://www.intel.com/content/www/es/es/support/detect.html' } else { '' }
        $u.DrvState.Text = 'Para tu gráfica, lo más fiable es la herramienta oficial del fabricante, que detecta el driver exacto.'
        if ($url) { $u.DrvBtn.Content = 'Abrir web oficial'; $u.DrvBtn.Tag = $url; $u.DrvBtn.Visibility = 'Visible' }
    }
}
function Show-DriverResult($r) {
    $script:DriverResult = $r; $u = $script:Upd; if (-not $u) { return }
    if (-not $r -or $r.Error) {
        $u.DrvState.Text = 'No se pudo comprobar ahora (sin conexión o la web de NVIDIA no respondió).'; $u.DrvState.Foreground = Br '#E8B23E'
        $u.DrvBtn.Content = 'Abrir web de NVIDIA'; $u.DrvBtn.Tag = 'https://www.nvidia.com/es-es/drivers/'; $u.DrvBtn.Visibility = 'Visible'
        Log "· Driver: no se pudo comprobar ($($r.Error))"; return
    }
    $inst = "$($script:Facts.NvDriver)"; $newer = $false
    try { $newer = ([version]$r.Latest) -gt ([version]$inst) } catch { $newer = ($r.Latest -ne $inst) }
    if ($newer) {
        $u.DrvState.Text = "Hay un driver nuevo: $($r.Latest)  ·  publicado el $($r.Date)"; $u.DrvState.Foreground = Br '{DynamicResource AccentBrush}'
        $u.DrvBtn.Content = "Descargar $($r.Latest)"; $u.DrvBtn.Tag = $r.Url; $u.DrvBtn.Visibility = 'Visible'
        $u.DrvBtn.ToolTip = "$($r.Size)"; $u.DrvHint.Visibility = 'Visible'
        Log "Driver NVIDIA: hay versión nueva $($r.Latest) (tienes $inst)"
    } else {
        $u.DrvState.Text = "✓ Tienes el último driver ($($r.Latest))"; $u.DrvState.Foreground = Br '#4CC38A'
        Log "Driver NVIDIA: al día ($inst)"
    }
}
function Start-WuSearch {
    $u = $script:Upd
    $u.WuSearch.IsEnabled = $false; $u.WuInstall.Visibility = 'Collapsed'; $u.WuList.Children.Clear()
    $u.WuState.Text = 'Buscando actualizaciones... puede tardar uno o dos minutos.'; $u.WuState.Foreground = Br '#8E8E95'
    Start-Async $WuSearchWork $null { param($r) Show-WuResult $r }
}
function Show-WuResult($r) {
    $script:WuResult = $r; $u = $script:Upd; if (-not $u) { return }
    $u.WuSearch.IsEnabled = $true; $u.WuSearch.Content = 'Buscar otra vez'; $u.WuList.Children.Clear()
    if (-not $r -or $r.Error) { $u.WuState.Text = "No se pudo consultar Windows Update ($($r.Error)). Prueba con «Abrir Windows Update»."; $u.WuState.Foreground = Br '#E8B23E'; return }
    $all = @($r.Updates); $need = @($all | Where-Object { -not $_.Optional })
    if ($all.Count -eq 0) { $u.WuState.Text = '✓ Windows está al día.'; $u.WuState.Foreground = Br '#4CC38A'; Log 'Windows Update: al día'; return }
    $u.WuState.Text = "$($need.Count) necesaria$(if ($need.Count -ne 1) { 's' })  ·  $($all.Count - $need.Count) opcional$(if (($all.Count - $need.Count) -ne 1) { 'es' })"
    $u.WuState.Foreground = Br $(if ($need.Count) { '{DynamicResource AccentBrush}' } else { '#4CC38A' })
    foreach ($x in $all) {
        $tag = if ($x.Optional) { "<Border CornerRadius=`"4`" Background=`"#1C1C1F`" Padding=`"6,1`" Margin=`"8,0,0,0`" VerticalAlignment=`"Center`"><TextBlock Text=`"Opcional`" FontSize=`"10.5`" Foreground=`"#E0B954`"/></Border>" } else { '' }
        $mb = if ($x.MB -gt 0) { "  ·  $($x.MB) MB" } else { '' }
        [void]$u.WuList.Children.Add((New-El "<WrapPanel {NS} Margin=`"0,4,0,0`"><TextBlock Text=`"$(Esc ($x.Title + $mb))`" FontSize=`"12.5`" Foreground=`"#C8C8CD`" TextWrapping=`"Wrap`" MaxWidth=`"520`"/>$tag</WrapPanel>"))
    }
    if ($need.Count) { $u.WuInstall.Content = "Instalar $($need.Count) necesaria$(if ($need.Count -ne 1) { 's' })"; $u.WuInstall.Visibility = 'Visible' }
    Log "Windows Update: $($need.Count) necesarias, $($all.Count - $need.Count) opcionales"
}
function Start-WuInstall {
    $u = $script:Upd
    $u.WuInstall.IsEnabled = $false; $u.WuSearch.IsEnabled = $false; $script:WuBusy = $true
    $u.WuState.Text = 'Descargando e instalando... puede tardar varios minutos. No apagues el PC.'; $u.WuState.Foreground = Br '{DynamicResource AccentBrush}'
    Log 'Windows Update: instalando las actualizaciones necesarias...'
    Start-Async $WuInstallWork $null {
        param($r)
        $u = $script:Upd; $u.WuInstall.IsEnabled = $true; $u.WuSearch.IsEnabled = $true; $u.WuInstall.Visibility = 'Collapsed'; $script:WuBusy = $false
        if (-not $r -or $r.Error) { $u.WuState.Text = "La instalación falló: $($r.Error)"; $u.WuState.Foreground = Br '#E8B23E'; Log "✗ Windows Update: $($r.Error)"; return }
        $ok = ($r.Result -eq 2 -or $r.Result -eq 3)
        $u.WuState.Text = if ($r.Count -eq 0) { '✓ No había nada pendiente.' } elseif ($r.Reboot) { "✓ $(if ($r.Count -eq 1) { '1 actualización instalada' } else { "$($r.Count) actualizaciones instaladas" }). Reinicia el PC para terminar." } elseif ($ok) { "✓ $(if ($r.Count -eq 1) { '1 actualización instalada' } else { "$($r.Count) actualizaciones instaladas" })." } else { 'Terminó con errores; ábrelo en Windows Update para ver el detalle.' }
        $u.WuState.Foreground = Br $(if ($ok -or $r.Count -eq 0) { '#4CC38A' } else { '#E8B23E' })
        $u.WuList.Children.Clear(); $script:WuResult = $null
        Log "Windows Update: instalación terminada (código $($r.Result), reinicio: $($r.Reboot))"
    }
}

# ---------- Caché y temporales ----------
$CacheDefs = @(
    @{ Id = 'temp'; Name = 'Archivos temporales'; Rec = $true; Glyph = '&#xE74D;'
       Desc = 'Temporales de Windows y de tus programas. Solo se borran los que llevan más de un día sin usarse.'
       Paths = @('%TEMP%', '%SystemRoot%\Temp'); MinAgeHours = 24 },
    @{ Id = 'wu'; Name = 'Descargas de Windows Update'; Rec = $true; Glyph = '&#xE777;'
       Desc = 'Instaladores de actualizaciones que ya se aplicaron. Windows los vuelve a descargar si hiciera falta.'
       Paths = @('%SystemRoot%\SoftwareDistribution\Download'); Special = 'wu' },
    @{ Id = 'do'; Name = 'Optimización de distribución'; Rec = $true; Glyph = '&#xE895;'
       Desc = 'Copias de actualizaciones que Windows guarda para compartir con otros PC.'
       Paths = @('%SystemRoot%\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache'); Special = 'do' },
    @{ Id = 'gpuinst'; Name = 'Restos de instaladores de drivers'; Rec = $true; Glyph = '&#xE7F4;'
       Desc = 'Carpetas que dejan los instaladores de NVIDIA y AMD al descomprimirse (pueden ocupar varios GB).'
       Paths = @('%SystemDrive%\NVIDIA', '%SystemDrive%\AMD') },
    @{ Id = 'dumps'; Name = 'Informes de errores y volcados'; Rec = $true; Glyph = '&#xE7BA;'
       Desc = 'Informes de fallos y volcados de memoria de cuelgues antiguos. No los necesitas salvo para depurar un problema concreto.'
       Paths = @('%ProgramData%\Microsoft\Windows\WER\ReportArchive', '%ProgramData%\Microsoft\Windows\WER\ReportQueue', '%LOCALAPPDATA%\Microsoft\Windows\WER\ReportArchive', '%LOCALAPPDATA%\Microsoft\Windows\WER\ReportQueue', '%LOCALAPPDATA%\CrashDumps', '%SystemRoot%\Minidump', '%SystemRoot%\LiveKernelReports', '%SystemRoot%\MEMORY.DMP') },
    @{ Id = 'thumbs'; Name = 'Caché de miniaturas'; Rec = $false; Glyph = '&#xE8B9;'
       Desc = 'Vistas previas de fotos y vídeos del Explorador. Se regeneran solas (las carpetas con muchas fotos tardarán un poco la primera vez).'
       Paths = @('%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db', '%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*.db') },
    @{ Id = 'shaders'; Name = 'Caché de sombreadores (shaders)'; Rec = $false; Glyph = '&#xE7FC;'
       Desc = 'Útil después de actualizar el driver o si un juego da tirones raros. Las primeras partidas tendrán algún tirón mientras se vuelve a generar.'
       Paths = @('%LOCALAPPDATA%\D3DSCache', '%LOCALAPPDATA%\NVIDIA\DXCache', '%LOCALAPPDATA%\NVIDIA\GLCache', '%USERPROFILE%\AppData\LocalLow\NVIDIA\PerDriverVersion\DXCache', '%USERPROFILE%\AppData\LocalLow\NVIDIA\PerDriverVersion\GLCache', '%LOCALAPPDATA%\AMD\DxCache', '%LOCALAPPDATA%\AMD\DxcCache', '%LOCALAPPDATA%\AMD\VkCache', '%LOCALAPPDATA%\AMD\GLCache', '%USERPROFILE%\AppData\LocalLow\Intel\ShaderCache') },
    @{ Id = 'recycle'; Name = 'Papelera de reciclaje'; Rec = $false; Glyph = '&#xE74D;'
       Desc = 'Vacía la papelera. Revisa antes que no haya nada que quieras recuperar.'
       Paths = @(); Special = 'recycle' },
    @{ Id = 'dism'; Name = 'Limpieza profunda de componentes de Windows'; Rec = $false; Glyph = '&#xE713;'
       Desc = 'Elimina versiones antiguas de componentes que dejan las actualizaciones (DISM). Puede tardar 5-15 minutos; el espacio que libera no se puede calcular antes.'
       Paths = @(); Special = 'dism' }
)

$CacheFilesFn = {
    # Devuelve SOLO archivos dentro de rutas que existen. Nunca usa -Path con -Recurse sobre rutas inexistentes
    # (en PowerShell 5.1 eso buscaría por todo el disco).
    param($x)
    if ($x -match '[\*\?]') {
        $parent = Split-Path $x; $leaf = Split-Path $x -Leaf
        if ($parent -and (Test-Path -LiteralPath $parent -PathType Container)) { Get-ChildItem -LiteralPath $parent -Filter $leaf -Force -File -ErrorAction SilentlyContinue }
    } elseif (Test-Path -LiteralPath $x) {
        $it = Get-Item -LiteralPath $x -Force -ErrorAction SilentlyContinue
        if ($it.PSIsContainer) { Get-ChildItem -LiteralPath $x -Recurse -Force -File -ErrorAction SilentlyContinue } else { $it }
    }
}
$CacheSizeWork = {
    param($defs, $filesFn)
    $files = [scriptblock]::Create($filesFn)
    $r = @{}
    foreach ($d in $defs) {
        $sum = 0L
        foreach ($p in $d.Paths) { try { $sum += [long](& $files ([Environment]::ExpandEnvironmentVariables($p)) | Measure-Object Length -Sum).Sum } catch {} }
        if ($d.Special -eq 'recycle') {
            $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
            foreach ($drv in @(Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free })) {
                try { $sum += [long](& $files (Join-Path $drv.Root "`$Recycle.Bin\$sid") | Where-Object { $_.Name -ne 'desktop.ini' } | Measure-Object Length -Sum).Sum } catch {}
            }
        }
        $r[$d.Id] = $sum
    }
    return $r
}
$CacheCleanWork = {
    param($defs, $ids, $sync, $filesFn)
    $files = [scriptblock]::Create($filesFn)
    $r = @{ Done = @() }
    foreach ($d in $defs) {
        if ($ids -notcontains $d.Id) { continue }
        $sync.Step = $d.Name
        try {
            switch ($d.Special) {
                'wu' { Stop-Service wuauserv, bits -Force -ErrorAction SilentlyContinue }
                'do' { try { Delete-DeliveryOptimizationCache -Force -ErrorAction SilentlyContinue } catch {} }
                'recycle' { Clear-RecycleBin -Force -ErrorAction SilentlyContinue }
                'dism' { Start-Process dism.exe -ArgumentList '/Online /Cleanup-Image /StartComponentCleanup /Quiet' -Wait -WindowStyle Hidden }
            }
            $cut = if ($d.MinAgeHours) { (Get-Date).AddHours(-$d.MinAgeHours) } else { Get-Date }
            foreach ($p in $d.Paths) {
                $x = [Environment]::ExpandEnvironmentVariables($p)
                & $files $x | Where-Object { $_.LastWriteTime -lt $cut } | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
                if (($x -notmatch '[\*\?]') -and (Test-Path -LiteralPath $x -PathType Container)) {
                    Get-ChildItem -LiteralPath $x -Recurse -Force -Directory -ErrorAction SilentlyContinue | Sort-Object { $_.FullName.Length } -Descending |
                        Where-Object { -not (Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue) } |
                        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
                }
            }
            if ($d.Special -eq 'wu') { Start-Service bits, wuauserv -ErrorAction SilentlyContinue }
            $r.Done += $d.Id
        } catch { $r["err_$($d.Id)"] = $_.Exception.Message }
    }
    $sync.Step = ''
    return $r
}

function Format-Size($b) {
    if ($b -ge 1GB) { return ('{0:0.0} GB' -f ($b / 1GB)) }
    if ($b -ge 1MB) { return ('{0:0} MB' -f ($b / 1MB)) }
    if ($b -gt 0) { return ('{0:0} KB' -f [math]::Max(1, $b / 1KB)) }
    return '0 MB'
}

function Build-CachePanel {
    $sp = New-Object Windows.Controls.StackPanel
    $top = New-El @"
<Border {NS} CornerRadius="10" Padding="26,22" Margin="0,0,0,22" Background="#131315" BorderBrush="#232326" BorderThickness="1">
 <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
  <StackPanel VerticalAlignment="Center">
   <TextBlock Text="Espacio que puedes liberar" FontSize="12.5" Foreground="#8E8E95"/>
   <TextBlock x:Name="CTotal" Text="Calculando..." FontSize="34" FontWeight="SemiBold" Foreground="White" Margin="0,4,0,0"/>
   <TextBlock x:Name="CState" FontSize="13" Foreground="#A0A0A7" Margin="0,4,0,0" TextWrapping="Wrap" Text="Midiendo cuánto ocupa cada cosa..."/>
  </StackPanel>
  <StackPanel Grid.Column="1" VerticalAlignment="Center" MinWidth="170">
   <Button x:Name="CClean" Style="{DynamicResource Primary}" Content="Liberar espacio" IsEnabled="False"/>
   <Button x:Name="CRescan" Style="{DynamicResource Ghost}" Content="Analizar otra vez" Margin="0,8,0,0"/>
  </StackPanel>
 </Grid>
</Border>
"@
    [void]$sp.Children.Add($top)
    $script:Cache = @{ Total = $top.FindName('CTotal'); State = $top.FindName('CState'); Clean = $top.FindName('CClean'); Rescan = $top.FindName('CRescan'); Rows = @{} }
    foreach ($tier in @($true, $false)) {
        $items = @($CacheDefs | Where-Object { $_.Rec -eq $tier })
        [void]$sp.Children.Add((New-Header $(if ($tier) { 'RECOMENDADO' } else { 'OPCIONAL  ·  MÍRALO ANTES DE MARCARLO' }) $(if ($tier) { 0 } else { 18 })))
        foreach ($d in $items) {
            $card = New-El @"
<Border {NS} CornerRadius="8" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="18,14" Margin="0,0,0,10">
 <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
  <Border Width="40" Height="40" CornerRadius="6" Background="#1C1C1F" VerticalAlignment="Top"><TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="$($d.Glyph)" FontSize="16" Foreground="#A0A0A7" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
  <StackPanel Grid.Column="1" Margin="16,0,16,0">
   <TextBlock Text="$(Esc $d.Name)" FontSize="15" FontWeight="SemiBold" Foreground="#EDEDEF"/>
   <TextBlock Text="$(Esc $d.Desc)" FontSize="12.5" Foreground="#8E8E95" TextWrapping="Wrap" Margin="0,3,0,0"/>
  </StackPanel>
  <TextBlock x:Name="Sz" Grid.Column="2" Text="..." FontSize="14" FontWeight="SemiBold" Foreground="#C8C8CD" VerticalAlignment="Center" Margin="0,0,18,0" MinWidth="70" TextAlignment="Right"/>
  <CheckBox x:Name="Tg" Grid.Column="3" Style="{DynamicResource Toggle}" VerticalAlignment="Center"/>
 </Grid>
</Border>
"@
            $tg = $card.FindName('Tg'); $tg.IsChecked = [bool]$d.Rec
            $tg.Add_Checked({ Update-CacheTotal }); $tg.Add_Unchecked({ Update-CacheTotal })
            $script:Cache.Rows[$d.Id] = @{ Tg = $tg; Sz = $card.FindName('Sz') }
            [void]$sp.Children.Add($card)
        }
    }
    [void]$sp.Children.Add((New-El "<TextBlock {NS} Text=`"Nunca se tocan tus documentos, descargas, partidas guardadas ni clips de Medal. Si un archivo está en uso, simplemente se salta.`" FontSize=`"12`" Foreground=`"#82828A`" TextWrapping=`"Wrap`" Margin=`"2,4,0,0`"/>"))
    $script:Cache.Clean.Add_Click({ Start-CacheClean })
    $script:Cache.Rescan.Add_Click({ Start-CacheScan })
    if ($script:CacheSizes) { Show-CacheSizes $script:CacheSizes } else { Start-CacheScan }
    return $sp
}
function Start-CacheScan {
    $c = $script:Cache; $c.Clean.IsEnabled = $false; $c.Total.Text = 'Calculando...'; $c.State.Text = 'Midiendo cuánto ocupa cada cosa...'
    foreach ($row in $c.Rows.Values) { $row.Sz.Text = '...' }
    Start-Async $CacheSizeWork @($CacheDefs, "$CacheFilesFn") { param($r) Show-CacheSizes $r }
}
function Show-CacheSizes($r) {
    $script:CacheSizes = $r; $c = $script:Cache; if (-not $c) { return }
    foreach ($d in $CacheDefs) { $c.Rows[$d.Id].Sz.Text = $(if ($d.Special -eq 'dism') { '—' } else { Format-Size ([long]$r[$d.Id]) }) }
    Update-CacheTotal
    $all = 0L; foreach ($d in $CacheDefs) { $all += [long]$r[$d.Id] }
    $c.State.Text = "En total hay $(Format-Size $all) en cachés y temporales. Marca lo que quieras limpiar."
}
function Update-CacheTotal {
    $c = $script:Cache; if (-not $c -or -not $script:CacheSizes) { return }
    $sel = 0L; $n = 0
    foreach ($d in $CacheDefs) { if ($c.Rows[$d.Id].Tg.IsChecked) { $sel += [long]$script:CacheSizes[$d.Id]; $n++ } }
    $c.Total.Text = Format-Size $sel
    $c.Clean.IsEnabled = ($n -gt 0); $c.Clean.Content = if ($sel -gt 0) { "Liberar $(Format-Size $sel)" } else { 'Limpiar' }
}
function Start-CacheClean {
    $c = $script:Cache
    $ids = @($CacheDefs | Where-Object { $c.Rows[$_.Id].Tg.IsChecked } | ForEach-Object { $_.Id })
    if ($script:WuBusy -and ($ids -contains 'wu')) { $ids = @($ids | Where-Object { $_ -ne 'wu' }); Log '· Descargas de Windows Update: se salta porque hay una instalación en marcha' }
    if (-not $ids.Count) { return }
    $before = 0L; foreach ($i in $ids) { $before += [long]$script:CacheSizes[$i] }
    $script:CacheBefore = $before
    $c.Clean.IsEnabled = $false; $c.Rescan.IsEnabled = $false
    $script:CacheSync = [hashtable]::Synchronized(@{ Step = '' })
    Log "Limpiando: $(($CacheDefs | Where-Object { $ids -contains $_.Id } | ForEach-Object { $_.Name }) -join ', ')"
    $script:CacheTimer = New-Object Windows.Threading.DispatcherTimer; $script:CacheTimer.Interval = [TimeSpan]::FromMilliseconds(300)
    $script:CacheTimer.Add_Tick({ if ($script:CacheSync.Step) { $script:Cache.State.Text = "Limpiando: $($script:CacheSync.Step)..." } })
    $script:CacheTimer.Start()
    Start-Async $CacheCleanWork @($CacheDefs, $ids, $script:CacheSync, "$CacheFilesFn") {
        param($r)
        $script:CacheTimer.Stop()
        $c = $script:Cache; $c.Rescan.IsEnabled = $true
        $c.State.Text = 'Comprobando cuánto se ha liberado...'
        Start-Async $CacheSizeWork @($CacheDefs, "$CacheFilesFn") {
            param($sz)
            $prevSel = $script:CacheBefore
            $nowSel = 0L; foreach ($d in $CacheDefs) { if ($script:Cache.Rows[$d.Id].Tg.IsChecked) { $nowSel += [long]$sz[$d.Id] } }
            $freed = [math]::Max(0, $prevSel - $nowSel)
            Show-CacheSizes $sz
            $script:Cache.State.Text = "✓ Liberados $(Format-Size $freed). Lo que quede estaba en uso o es reciente."
            Log "✓ Caché y temporales: liberados $(Format-Size $freed)"
        }
    }
}

# ---------- Ventana, transiciones, buscador ----------
function Update-WindowChrome {
    if ($window.WindowState -eq 'Maximized') {
        $UI.Root.Margin = New-Object Windows.Thickness(0); $UI.Root.CornerRadius = New-Object Windows.CornerRadius(0); $UI.Root.BorderThickness = New-Object Windows.Thickness(0)
        $UI.BtnMax.Content = [string][char]0xE923
    } else {
        $UI.Root.Margin = New-Object Windows.Thickness(12); $UI.Root.CornerRadius = New-Object Windows.CornerRadius(10); $UI.Root.BorderThickness = New-Object Windows.Thickness(1)
        $UI.BtnMax.Content = [string][char]0xE922
    }
}
function Slide($el) {
    $tt = New-Object Windows.Media.TranslateTransform; $el.RenderTransform = $tt
    $a = New-Object Windows.Media.Animation.DoubleAnimation(18, 0, (New-Object Windows.Duration([TimeSpan]::FromMilliseconds(300))))
    $ez = New-Object Windows.Media.Animation.CubicEase; $ez.EasingMode = 'EaseOut'; $a.EasingFunction = $ez
    $tt.BeginAnimation([Windows.Media.TranslateTransform]::YProperty, $a)
}
function Set-SectionTools($key) {
    $isCat = (Get-Categories) -contains $key
    $UI.SecTools.Visibility = $(if ($isCat) { 'Visible' } else { 'Collapsed' })
    $script:SuppressSearch = $true; $UI.SecSearch.Text = ''; $script:SuppressSearch = $false; $UI.SecSearchHint.Visibility = 'Visible'
}
function Invoke-SectionFilter {
    $q = "$($UI.SecSearch.Text)".Trim().ToLower()
    $UI.SecSearchHint.Visibility = $(if ($q) { 'Collapsed' } else { 'Visible' })
    $panel = $UI.SecHost.Content
    if (-not ($panel -is [Windows.Controls.Panel])) { return }
    $kids = @($panel.Children)
    foreach ($ch in $kids) {
        if ($ch -is [Windows.Controls.Border] -and $ch.Tag -is [string]) { $ch.Visibility = $(if (-not $q -or $ch.Tag.Contains($q)) { 'Visible' } else { 'Collapsed' }) }
    }
    # Oculta los títulos de grupo que se quedan sin resultados
    for ($i = 0; $i -lt $kids.Count; $i++) {
        if ($kids[$i] -isnot [Windows.Controls.TextBlock]) { continue }
        $any = $false
        for ($j = $i + 1; $j -lt $kids.Count -and $kids[$j] -isnot [Windows.Controls.TextBlock]; $j++) { if ($kids[$j].Visibility -eq 'Visible') { $any = $true } }
        $kids[$i].Visibility = $(if (-not $q -or $any) { 'Visible' } else { 'Collapsed' })
    }
}
$UI.SecSearch.Add_TextChanged({ if (-not $script:SuppressSearch) { Invoke-SectionFilter } })
$UI.BtnSelRec.Add_Click({ foreach ($t in @($script:Tweaks | Where-Object { $_.Category -eq $script:CurrentKey -and $_.Tier -eq 'Recomendado' -and $_.Toggle -and $_.Toggle.IsEnabled })) { $t.Toggle.IsChecked = $true }; Update-Pending })
$UI.BtnSelNone.Add_Click({ foreach ($t in @($script:Tweaks | Where-Object { $_.Category -eq $script:CurrentKey -and $_.Toggle -and $_.Toggle.IsEnabled })) { $t.Toggle.IsChecked = $t.Applied }; Update-Pending })

# ---------- Rendimiento en vivo ----------
$MonitorWork = {
    param($sync)
    $ping = New-Object System.Net.NetworkInformation.Ping
    $smi = "$env:SystemRoot\System32\nvidia-smi.exe"; $hasSmi = Test-Path $smi
    $cores = [Environment]::ProcessorCount; $n = 0
    while ($sync.Run) {
        try {
            $sync.Cpu = [int](Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'").PercentProcessorTime
            $os = Get-CimInstance Win32_OperatingSystem
            $sync.RamTotal = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
            $sync.RamUsed = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 1)
            if ($hasSmi) {
                $g = "$(& $smi --query-gpu=utilization.gpu,temperature.gpu,clocks.gr,power.draw,memory.used,memory.total --format=csv,noheader,nounits | Select-Object -First 1)" -split ',\s*'
                if ($g.Count -ge 6) { $sync.Gpu = [int]$g[0]; $sync.GpuTemp = [int]$g[1]; $sync.GpuClock = [int]$g[2]; try { $sync.GpuPower = [math]::Round([double]::Parse("$($g[3])".Trim(), [Globalization.CultureInfo]::InvariantCulture)) } catch { $sync.GpuPower = '?' }; $sync.VramUsed = [int]$g[4]; $sync.VramTotal = [int]$g[5] }
            }
            try { $rep = $ping.Send('1.1.1.1', 1000); $sync.Ping = $(if ($rep.Status -eq 'Success') { [int]$rep.RoundtripTime } else { -1 }) } catch { $sync.Ping = -1 }
            $sync.TimerMs = [CtNative]::TimerResolutionMs()
            if (($n % 3) -eq 0) {
                $sync.Top = @(Get-CimInstance Win32_PerfFormattedData_PerfProc_Process | Where-Object { $_.Name -notin '_Total', 'Idle' } |
                    Group-Object { $_.Name -replace '#\d+$', '' } | ForEach-Object { [pscustomobject]@{ N = $_.Name; C = ($_.Group | Measure-Object PercentProcessorTime -Sum).Sum / $cores } } |
                    Sort-Object C -Descending | Select-Object -First 6 | ForEach-Object { '{0}|{1:0}' -f $_.N, $_.C })
            }
            $sync.Tick++
        } catch { $sync.Err = $_.Exception.Message }
        $n++; Start-Sleep -Milliseconds 1000
    }
}
$script:MonHist = @{}
function New-Tile($key, $label, $color, $glyph) {
    $t = New-El @"
<Border {NS} Width="256" Height="146" CornerRadius="8" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="16,14" Margin="0,0,12,12">
 <Grid><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
  <StackPanel Orientation="Horizontal"><Ellipse Width="7" Height="7" Fill="$color" VerticalAlignment="Center"/><TextBlock Text="$(Esc $label)" FontSize="11.5" Foreground="#82828A" Margin="8,0,0,0"/></StackPanel>
  <TextBlock x:Name="V" Grid.Row="1" Text="..." FontSize="26" FontWeight="SemiBold" Foreground="White" Margin="0,4,0,0"/>
  <TextBlock x:Name="S" Grid.Row="2" Text=" " FontSize="11.5" Foreground="#8E8E95" TextTrimming="CharacterEllipsis"/>
  <Polyline x:Name="L" Grid.Row="3" Stroke="$color" StrokeThickness="2" StrokeLineJoin="Round" VerticalAlignment="Bottom" Margin="0,6,0,0"/>
 </Grid>
</Border>
"@
    $script:Mon.Tiles[$key] = @{ V = $t.FindName('V'); S = $t.FindName('S'); L = $t.FindName('L') }
    return $t
}
function Build-MonitorPanel {
    $script:Mon = @{ Tiles = @{} }
    $sp = New-Object Windows.Controls.StackPanel
    $wp = New-Object Windows.Controls.WrapPanel
    [void]$wp.Children.Add((New-Tile 'cpu' 'Procesador' '{DynamicResource AccentBrush}' ''))
    if ($script:Facts.IsNvidia) {
        [void]$wp.Children.Add((New-Tile 'gpu' 'Gráfica' '#A0A0A7' ''))
        [void]$wp.Children.Add((New-Tile 'temp' 'Temperatura de la gráfica' '#F97316' ''))
    }
    [void]$wp.Children.Add((New-Tile 'ram' 'Memoria RAM' '#A0A0A7' ''))
    [void]$wp.Children.Add((New-Tile 'ping' 'Ping a internet (1.1.1.1)' '#4CC38A' ''))
    [void]$wp.Children.Add((New-Tile 'timer' 'Resolución del temporizador' '#E0B954' ''))
    [void]$sp.Children.Add($wp)
    [void]$sp.Children.Add((New-Header 'LO QUE MÁS PROCESADOR USA AHORA' 12))
    $top = New-El "<Border {NS} CornerRadius=`"8`" Background=`"#131315`" BorderBrush=`"#232326`" BorderThickness=`"1`" Padding=`"18,12`" Margin=`"0,0,12,0`"><StackPanel x:Name=`"Top`"><TextBlock Text=`"Midiendo...`" FontSize=`"13`" Foreground=`"#82828A`"/></StackPanel></Border>"
    $script:Mon.Top = $top.FindName('Top')
    [void]$sp.Children.Add($top)
    [void]$sp.Children.Add((New-Header "CONEXI$([char]0xD3)N" 18))
    [void]$sp.Children.Add((New-ConnTestCard))
    [void]$sp.Children.Add((New-El "<TextBlock {NS} Text=`"Se actualiza cada segundo mientras tienes esta página abierta; al salir deja de medir para no gastar recursos. Truco: déjala abierta en otra pantalla mientras juegas en ventana para ver la temperatura.`" FontSize=`"12`" Foreground=`"#82828A`" TextWrapping=`"Wrap`" Margin=`"2,12,12,0`"/>"))
    return $sp
}
function Start-Monitor {
    if ($script:MonPs) { return }
    $script:MonSync = [hashtable]::Synchronized(@{ Run = $true; Tick = 0 })
    $script:MonPs = [powershell]::Create(); [void]$script:MonPs.AddScript($MonitorWork).AddArgument($script:MonSync)
    $script:MonH = $script:MonPs.BeginInvoke(); $script:MonLast = -1
    if (-not $script:MonTimer) {
        $script:MonTimer = New-Object Windows.Threading.DispatcherTimer; $script:MonTimer.Interval = [TimeSpan]::FromMilliseconds(400)
        $script:MonTimer.Add_Tick({ Update-Monitor })
    }
    $script:MonTimer.Start()
}
function Stop-Monitor {
    if ($script:MonTimer) { $script:MonTimer.Stop() }
    if ($script:MonPs) { $script:MonSync.Run = $false; $ps = $script:MonPs; $script:MonPs = $null; try { [void]$ps.BeginStop($null, $null) } catch {} }
}
function Push-Hist($k, $v) {
    if (-not $script:MonHist[$k]) { $script:MonHist[$k] = New-Object System.Collections.Generic.List[double] }
    $h = $script:MonHist[$k]; $h.Add([double]$v); while ($h.Count -gt 60) { $h.RemoveAt(0) }
}
function Draw-Line($k, $max) {
    $tile = $script:Mon.Tiles[$k]; $h = $script:MonHist[$k]; if (-not $tile -or -not $h) { return }
    $pc = New-Object Windows.Media.PointCollection
    $w = 222.0; $hh = 36.0; $n = $h.Count
    $m = if ($max) { [double]$max } else { [math]::Max(1.0, (($h | Measure-Object -Maximum).Maximum) * 1.2) }
    for ($i = 0; $i -lt $n; $i++) { $x = $w * ($i + (60 - $n)) / 59; $y = $hh - [math]::Min($hh, $hh * $h[$i] / $m); $pc.Add((New-Object Windows.Point($x, $y))) }
    $tile.L.Points = $pc
}
function Update-Monitor {
    $s = $script:MonSync; if (-not $s -or -not $script:Mon -or $s.Tick -eq $script:MonLast) { return }
    $script:MonLast = $s.Tick; $T = $script:Mon.Tiles
    if ($null -ne $s.Cpu) { $T.cpu.V.Text = "$($s.Cpu) %"; $T.cpu.S.Text = "$($script:Facts.CPU)"; Push-Hist 'cpu' $s.Cpu; Draw-Line 'cpu' 100 }
    if ($T.gpu -and $null -ne $s.Gpu) {
        $T.gpu.V.Text = "$($s.Gpu) %"; $T.gpu.S.Text = ('{0} MHz  ·  VRAM {1:0.0} / {2:0.0} GB' -f $s.GpuClock, ($s.VramUsed / 1024), ($s.VramTotal / 1024)); Push-Hist 'gpu' $s.Gpu; Draw-Line 'gpu' 100
    }
    if ($T.temp -and $null -ne $s.GpuTemp) {
        $T.temp.V.Text = "$($s.GpuTemp) °C"; $T.temp.V.Foreground = Br $(if ($s.GpuTemp -ge 85) { '#EF6F6F' } elseif ($s.GpuTemp -ge 75) { '#E8B23E' } else { '#FFFFFF' })
        $T.temp.S.Text = $(if ($s.GpuTemp -ge 85) { "Muy caliente · $($s.GpuPower) W" } elseif ($s.GpuTemp -ge 75) { "Caliente · $($s.GpuPower) W" } else { "Normal · $($s.GpuPower) W" })
        Push-Hist 'temp' $s.GpuTemp; Draw-Line 'temp' 100
    }
    if ($null -ne $s.RamUsed -and $s.RamTotal) { $pct = [math]::Round(100 * $s.RamUsed / $s.RamTotal); $T.ram.V.Text = "$pct %"; $T.ram.S.Text = ('{0:0.0} de {1:0.0} GB en uso' -f $s.RamUsed, $s.RamTotal); Push-Hist 'ram' $pct; Draw-Line 'ram' 100 }
    if ($null -ne $s.Ping) {
        if ($s.Ping -ge 0) { $T.ping.V.Text = "$($s.Ping) ms"; $T.ping.S.Text = $(if ($s.Ping -le 20) { 'Excelente' } elseif ($s.Ping -le 50) { 'Bueno' } else { 'Alto: revisa tu conexión' }); Push-Hist 'ping' $s.Ping; Draw-Line 'ping' $null }
        else { $T.ping.V.Text = 'Sin respuesta'; $T.ping.S.Text = 'Sin conexión a internet' }
    }
    if ($null -ne $s.TimerMs) {
        $T.timer.V.Text = ('{0:0.0##} ms' -f $s.TimerMs)
        $T.timer.S.Text = $(if ($s.TimerMs -le 0.6) { 'Alta precisión: ideal para jugar' } elseif ($s.TimerMs -le 1.1) { 'Buena precisión' } else { 'La de Windows por defecto' })
        Push-Hist 'timer' $s.TimerMs; Draw-Line 'timer' 16
    }
    if ($s.Top) {
        $script:Mon.Top.Children.Clear()
        foreach ($row in @($s.Top)) {
            $p = "$row" -split '\|'
            [void]$script:Mon.Top.Children.Add((New-El "<Grid {NS} Margin=`"0,4`"><Grid.ColumnDefinitions><ColumnDefinition Width=`"*`"/><ColumnDefinition Width=`"Auto`"/></Grid.ColumnDefinitions><TextBlock Text=`"$(Esc $p[0])`" FontSize=`"13`" Foreground=`"#C8C8CD`"/><TextBlock Grid.Column=`"1`" Text=`"$($p[1]) %`" FontSize=`"13`" FontWeight=`"SemiBold`" Foreground=`"{DynamicResource AccentBrush}`"/></Grid>"))
        }
    }
}

# ---------- Ajustes ----------
function New-SettingCard($glyph, $title, $desc, $right) {
    New-El @"
<Border {NS} CornerRadius="8" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="20,16" Margin="0,0,0,10">
 <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
  <Border Width="42" Height="42" CornerRadius="6" Background="#1C1C1F" VerticalAlignment="Top"><TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="$glyph" FontSize="17" Foreground="#C8C8CD" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
  <StackPanel Grid.Column="1" Margin="16,0,16,0"><TextBlock Text="$(Esc $title)" FontSize="15" FontWeight="SemiBold" Foreground="#EDEDEF"/><TextBlock Text="$(Esc $desc)" FontSize="12.5" Foreground="#8E8E95" TextWrapping="Wrap" Margin="0,3,0,0"/></StackPanel>
  <StackPanel Grid.Column="2" VerticalAlignment="Center" Orientation="Horizontal">$right</StackPanel>
 </Grid>
</Border>
"@
}
function Find-Profile {
    $c = @()
    if ($PSScriptRoot) { $c += (Join-Path $PSScriptRoot 'perfil.json') }
    $c += (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Miki Tweaks - perfil.json')
    foreach ($x in $c) { if (Test-Path $x) { return $x } }
    return $null
}
function Save-Profile {
    $ids = @($script:Tweaks | Where-Object { ($_.Toggle -and $_.Toggle.IsChecked) -or (-not $_.Toggle -and $_.Applied) } | ForEach-Object { $_.Id })
    $st = Get-ModeState
    $json = ([ordered]@{ app = 'Miki Tweaks'; version = $AppVersion; created = (Get-Date).ToString('yyyy-MM-dd HH:mm'); pc = $env:COMPUTERNAME; mode = $st.current; tweaks = $ids }) | ConvertTo-Json -Depth 4
    $saved = @()
    $targets = @(); if ($PSScriptRoot -and ($PSScriptRoot -ne $AppDir)) { $targets += (Join-Path $PSScriptRoot 'perfil.json') }
    $targets += (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Miki Tweaks - perfil.json')
    foreach ($x in $targets) { try { Set-Content -Path $x -Value $json -Encoding UTF8 -ErrorAction Stop; $saved += $x } catch {} }
    Log "✓ Perfil guardado ($($ids.Count) ajuste$(if ($ids.Count -ne 1) { 's' })): $($saved -join '  y  ')"
    Show-AppToast "Perfil guardado: $($ids.Count) ajuste$(if ($ids.Count -ne 1) { 's' })"
    Show-Section 'ajustes'
}
function Load-Profile {
    $f = Find-Profile; if (-not $f) { return }
    try { $o = Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json } catch { Log "✗ Perfil no válido: $f"; return }
    $want = @($o.tweaks); $n = 0
    foreach ($t in $script:Tweaks) { if ($t.Toggle -and $t.Toggle.IsEnabled -and -not $t.Toggle.IsChecked -and ($want -contains $t.Id)) { $t.Toggle.IsChecked = $true; $n++ } }
    Update-Pending
    Log "Perfil cargado desde $f ($n $(if ($n -eq 1) { 'ajuste marcado' } else { 'ajustes marcados' }))"
    $modeTxt = if ($o.mode -and $ModeDefs.ContainsKey("$($o.mode)")) { " En ese PC usabas el $($ModeDefs["$($o.mode)"].Name): actívalo en Modos si quieres lo mismo." } else { '' }
    Show-AppToast "Perfil cargado: $n $(if ($n -eq 1) { 'ajuste marcado. Revísalo' } else { 'ajustes marcados. Revisa' }) y pulsa Aplicar cambios.$modeTxt"
    Select-Nav 'resumen'
}
function Build-SettingsPanel {
    $sp = New-Object Windows.Controls.StackPanel
    [void]$sp.Children.Add((New-Header 'TU PERFIL' 4))
    $c = New-SettingCard '&#xE77B;' (Get-ProfileText (Get-UseProfile)) 'Decide qué modos tienes y qué ajustes se te recomiendan. Cámbialo si usas el equipo de otra forma.' '<Button x:Name="B" Style="{DynamicResource Ghost}" Content="Cambiar perfil"/>'
    $c.FindName('B').Add_Click({ Show-Setup 'ajustes' })
    [void]$sp.Children.Add($c)
    [void]$sp.Children.Add((New-Header 'SEGURIDAD' 18))
    $c = New-SettingCard '&#xE72E;' 'Punto de restauración antes de aplicar' 'Crea un punto de restauración de Windows antes de cada tanda de cambios. Windows solo guarda uno cada 24 horas.' '<CheckBox x:Name="Tg" Style="{DynamicResource Toggle}"/>'
    $tg = $c.FindName('Tg'); $tg.IsChecked = [bool](Get-Setting 'restorePoint' $true)
    $tg.Add_Checked({ Set-Setting 'restorePoint' $true; Log 'Ajuste: punto de restauración antes de aplicar activado' }); $tg.Add_Unchecked({ Set-Setting 'restorePoint' $false; Log 'Ajuste: punto de restauración antes de aplicar desactivado' })
    [void]$sp.Children.Add($c)
    $c = New-SettingCard '&#xE81C;' 'Crear un punto de restauración ahora' 'Una copia del estado de Windows a la que volver desde «Restaurar sistema» si algo fallara.' '<Button x:Name="B" Style="{DynamicResource Ghost}" Content="Crear ahora"/>'
    $c.FindName('B').Add_Click({ param($s, $e)
        $s.IsEnabled = $false; $s.Content = 'Creando...'; DoEvents
        try { Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue; Checkpoint-Computer -Description 'Miki Tweaks (manual)' -RestorePointType MODIFY_SETTINGS -WarningAction SilentlyContinue; $s.Content = '✓ Creado'; Log '✓ Punto de restauración creado' }
        catch { $s.Content = 'No se pudo'; Log "✗ Punto de restauración: $($_.Exception.Message)" } })
    [void]$sp.Children.Add($c)
    $nb = @($script:Tweaks | Where-Object { $_.HasBackup -and $_.Applied -and $_.Id -notlike 'app_*' }).Count
    $c = New-SettingCard '&#xE7A7;' 'Deshacer todos los cambios de la app' "Devuelve a su valor original $(if ($nb -eq 1) { 'el ajuste' } else { "los $nb ajustes" }) que esta app ha cambiado en este PC. Las apps quitadas no se reinstalan solas (están en la Microsoft Store)." '<Button x:Name="B" Style="{DynamicResource Ghost}" Content="Deshacer todo"/>'
    $b = $c.FindName('B'); $b.IsEnabled = ($nb -gt 0)
    $b.Add_Click({
        if ((Get-MsgBox).Invoke('¿Seguro que quieres deshacer todos los ajustes que ha cambiado la app en este PC?', 'Miki Tweaks', 'YesNo', 'Warning') -eq 'Yes') {
            foreach ($t in @($script:Tweaks | Where-Object { $_.HasBackup -and $_.Applied -and $_.Id -notlike 'app_*' -and $_.Toggle })) { $t.Toggle.IsChecked = $false }
            $script:ApplyLabel = 'Deshacer todos los cambios'; Update-Pending; Invoke-Apply
        } })
    [void]$sp.Children.Add($c)

    [void]$sp.Children.Add((New-Header 'LLEVAR TU CONFIGURACIÓN A OTRO PC' 18))
    $c = New-SettingCard '&#xE74E;' 'Guardar mi selección' 'Guarda qué ajustes tienes activos y tu modo en perfil.json: junto a la app (en el pen si la abriste desde ahí) y en Documentos.' '<Button x:Name="B" Style="{DynamicResource Primary}" Content="Guardar perfil"/>'
    $c.FindName('B').Add_Click({ Save-Profile })
    [void]$sp.Children.Add($c)
    $pf = Find-Profile
    $c = New-SettingCard '&#xE8B5;' 'Cargar un perfil' $(if ($pf) { "Encontrado: $pf. Marca en este PC los mismos ajustes (los que existan aquí) para que los revises antes de aplicarlos." } else { 'No hay ningún perfil.json junto a la app ni en Documentos. Guarda uno en tu PC y cópialo al pen.' }) '<Button x:Name="B" Style="{DynamicResource Ghost}" Content="Cargar perfil"/>'
    $b = $c.FindName('B'); $b.IsEnabled = [bool]$pf; $b.Add_Click({ Load-Profile })
    [void]$sp.Children.Add($c)

    $right = ''; $i = 0
    foreach ($k in $AccentThemes.Keys) { $c2 = $AccentThemes[$k]; $right += "<Border x:Name=`"A$i`" Width=`"22`" Height=`"22`" CornerRadius=`"11`" Margin=`"4,0`" Cursor=`"Hand`" ToolTip=`"$k`" Background=`"$($c2[0])`" BorderBrush=`"#0C0C0D`" BorderThickness=`"2`"/>"; $i++ }
    [void]$sp.Children.Add((New-Header 'APARIENCIA' 18))
    $c = New-SettingCard '&#xE790;' 'Color de la app' 'Elige el color de acento: botones, interruptores, gráficas y puntuación.' $right
    $i = 0; foreach ($k in $AccentThemes.Keys) { $dot = $c.FindName("A$i"); $dot.Tag = $k; $dot.Add_MouseLeftButtonUp({ param($s, $e) Set-Accent $s.Tag; Set-Setting 'accent' $s.Tag; Show-AppToast "Color cambiado a $($s.Tag)" }); $i++ }
    [void]$sp.Children.Add($c)
    $langNow = "$(Get-Setting 'lang' 'auto')"
    $right = '<StackPanel Orientation="Horizontal" VerticalAlignment="Center"><RadioButton x:Name="LAuto" Style="{DynamicResource Chip}" GroupName="AppLang" Content="Automático"/><RadioButton x:Name="LEs" Style="{DynamicResource Chip}" GroupName="AppLang" Content="Español"/><RadioButton x:Name="LEn" Style="{DynamicResource Chip}" GroupName="AppLang" Content="English"/></StackPanel>'
    $c = New-SettingCard '&#xE774;' 'Idioma / Language' 'Automático usa el idioma de Windows. Al cambiarlo, la app se reinicia.' $right
    $map = @{ LAuto = 'auto'; LEs = 'es'; LEn = 'en' }
    foreach ($k in $map.Keys) {
        $rb = $c.FindName($k); $rb.Tag = $map[$k]; if ($map[$k] -eq $langNow) { $rb.IsChecked = $true }
        $rb.Add_Checked({ param($s, $e)
            $new = "$($s.Tag)"; if ($new -eq "$(Get-Setting 'lang' 'auto')") { return }
            Set-Setting 'lang' $new; Log "Idioma: $new"
            if ($env:FT_TEST -eq '1') { return }
            Show-AppToast 'Reiniciando para cambiar el idioma... / Restarting to change the language...' 'ok'
            $t = New-Object Windows.Threading.DispatcherTimer; $t.Interval = [TimeSpan]::FromMilliseconds(900)
            $t.Add_Tick({ param($ts, $te) $ts.Stop()
                try { Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$AppPath`"" } catch {}
                $script:SkipCloseConfirm = $true; $window.Close() })
            $t.Start()
        })
    }
    [void]$sp.Children.Add($c)
    [void]$sp.Children.Add((New-Header 'AVISOS E INFORMES' 18))
    $c = New-SettingCard '&#xE8A7;' 'Icono en la bandeja del sistema' 'Junto al reloj: cambia de modo con clic derecho, abre la app con doble clic y muestra la temperatura de la gráfica al pasar el ratón. Arranca solo al iniciar sesión.' '<CheckBox x:Name="Tg" Style="{DynamicResource Toggle}" VerticalAlignment="Center"/>'
    $tg = $c.FindName('Tg'); $tg.IsChecked = (Test-TrayIcon)
    $tg.Add_Checked({ try { Set-TrayIcon $true; Log '✓ Icono en la bandeja activado'; Show-AppToast 'Icono en la bandeja activado' } catch { Log "✗ Icono en la bandeja: $($_.Exception.Message)" } })
    $tg.Add_Unchecked({ try { Set-TrayIcon $false; Log '↺ Icono en la bandeja desactivado' } catch { Log "✗ Icono en la bandeja: $($_.Exception.Message)" } })
    [void]$sp.Children.Add($c)
    $c = New-SettingCard '&#xEA8F;' 'Aviso semanal de drivers y actualizaciones' 'Cada sábado comprueba en segundo plano si hay un driver NVIDIA nuevo o actualizaciones de Windows pendientes, y te avisa con una notificación. Si todo está al día, no molesta.' '<Button x:Name="T" Style="{DynamicResource Ghost}" Content="Probar ahora" Margin="0,0,12,0"/><CheckBox x:Name="Tg" Style="{DynamicResource Toggle}" VerticalAlignment="Center"/>'
    $tg = $c.FindName('Tg'); $tg.IsChecked = (Test-WeeklyCheck)
    $tg.Add_Checked({ try { Set-WeeklyCheck $true; Log '✓ Aviso semanal activado (sábados a las 18:00)' } catch { Log "✗ Aviso semanal: $($_.Exception.Message)" } })
    $tg.Add_Unchecked({ try { Set-WeeklyCheck $false; Log '↺ Aviso semanal desactivado' } catch { Log "✗ Aviso semanal: $($_.Exception.Message)" } })
    $c.FindName('T').Add_Click({ param($s, $e)
        $s.IsEnabled = $false; $s.Content = 'Comprobando...'; $script:WeeklyBtn = $s
        $work = [scriptblock]::Create("`$AppVersion = '$AppVersion'; `$UpdateUrlDefault = '$UpdateUrlDefault'; " + 'return ,@(& {' + (Get-Command Get-WeeklyStatus).Definition + '})')
        Start-Async $work $null {
            param($r)
            $b = $script:WeeklyBtn; $b.IsEnabled = $true; $b.Content = 'Probar ahora'
            $m = @($r | Where-Object { $_ })
            $txt = if ($m.Count) { ($m -join ' · ') + '.' } else { 'Todo al día: driver y Windows actualizados.' }
            if (-not (Show-Toast 'Miki Tweaks' $txt)) { [void](Get-MsgBox).Invoke($txt, 'Miki Tweaks', 'OK', 'Information') }
            Log "Aviso de prueba: $txt"
        } })
    [void]$sp.Children.Add($c)
    $c = New-SettingCard '&#xE8A5;' 'Exportar informe del PC' 'Crea en el escritorio un archivo de texto con tu equipo, diagnóstico, periféricos, salud del hardware y todos los ajustes. Útil para pedir ayuda o guardarlo.' '<Button x:Name="B" Style="{DynamicResource Ghost}" Content="Exportar informe"/>'
    $c.FindName('B').Add_Click({ Export-Report })
    [void]$sp.Children.Add($c)

    [void]$sp.Children.Add((New-Header 'ACTUALIZACIONES DE LA APP' 18))
    $upd = New-El @"
<Border {NS} CornerRadius="8" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="20,16" Margin="0,0,0,10">
 <StackPanel>
  <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
   <StackPanel Margin="0,0,16,0">
    <TextBlock Text="Miki Tweaks $AppVersion" FontSize="15" FontWeight="SemiBold" Foreground="#EDEDEF"/>
    <TextBlock x:Name="St" FontSize="12.5" Foreground="#8E8E95" TextWrapping="Wrap" Margin="0,3,0,0"/>
   </StackPanel>
   <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Top">
    <Button x:Name="Go" Style="{DynamicResource Primary}" Content="Actualizar" Visibility="Collapsed" Margin="0,0,8,0"/>
    <Button x:Name="Chk" Style="{DynamicResource Ghost}" Content="Buscar ahora"/>
   </StackPanel>
  </Grid>
 </StackPanel>
</Border>
"@
    $script:UpdUi = @{ St = $upd.FindName('St'); Go = $upd.FindName('Go'); Chk = $upd.FindName('Chk') }
    Show-UpdateState
    $script:UpdUi.Chk.Add_Click({ Start-UpdateCheck })
    $script:UpdUi.Go.Add_Click({ Start-UpdateInstall })
    [void]$sp.Children.Add($upd)

    [void]$sp.Children.Add((New-Header 'DATOS Y ACERCA DE' 18))
    $c = New-SettingCard '&#xE8B7;' 'Carpeta de datos' "Copias de seguridad de tus ajustes, registro y perfiles de este PC: $DataDir" '<StackPanel Orientation="Horizontal"><Button x:Name="R" Style="{DynamicResource Ghost}" Content="Copiar informe" Margin="0,0,8,0"/><Button x:Name="B" Style="{DynamicResource Ghost}" Content="Abrir carpeta"/></StackPanel>'
    $c.FindName('B').Add_Click({ Start-Process explorer.exe $DataDir })
    $c.FindName('R').Add_Click({ Copy-ErrorReport })
    [void]$sp.Children.Add($c)
    $c = New-SettingCard '&#xE765;' 'Atajos de teclado' 'F5: volver a escanear  ·  Ctrl+F: buscar en la sección  ·  Esc: cerrar el aviso de cambios aplicados  ·  Doble clic en la barra de título: maximizar.' ''
    [void]$sp.Children.Add($c)
    $c = New-SettingCard '&#xE946;' "Miki Tweaks $AppVersion" "Gratis para todo el mundo. Si te ha servido, puedes apoyar el proyecto para que siga mejorando. Instalada en $AppDir; para usarla en otro PC, copia al pen la carpeta que contiene «Abrir Miki Tweaks.cmd»." '<StackPanel Orientation="Horizontal" VerticalAlignment="Center"><Button x:Name="Web" Style="{DynamicResource Ghost}" Content="Web del proyecto" Margin="0,0,8,0"/><Button x:Name="Sup" Style="{DynamicResource Primary}" Content="Apoyar el proyecto"/></StackPanel>'
    $w = $c.FindName('Web'); $s = $c.FindName('Sup')
    if ($ProjectUrlDefault) { $w.Add_Click({ Start-Process $ProjectUrlDefault }) } else { $w.Visibility = 'Collapsed' }
    if ($SupportUrlDefault) { $s.Add_Click({ Start-Process $SupportUrlDefault }) } else { $s.Visibility = 'Collapsed' }
    [void]$sp.Children.Add($c)
    $c = New-SettingCard '&#xE7BA;' 'Aviso de uso' 'Miki Tweaks cambia ajustes de Windows, de tus juegos y de tus dispositivos. Úsala bajo tu responsabilidad: antes de aplicar crea un punto de restauración, cada ajuste se puede deshacer y nada se toca sin que lo marques. La mejora depende de cada PC y no se garantiza una cifra concreta: mídela tú mismo con el Benchmark.' ''
    [void]$sp.Children.Add($c)
    return $sp
}

# ---------- Actualizaciones de la app (interfaz) ----------
function Show-UpdateState {
    $u = $script:UpdUi; if (-not $u) { return }
    $i = $script:UpdateInfo; $u.Go.Visibility = 'Collapsed'; $u.Go.IsEnabled = $true; $u.St.Foreground = Br '#8E8E95'
    if ($script:UpdateReady) {
        # Ya descargada e instalada en segundo plano: se usa al volver a abrir la app
        $u.St.Text = "✓ Miki Tweaks $script:UpdateReady instalada. Se usará la próxima vez que abras la app."; $u.St.Foreground = Br '#4CC38A'
        $u.Go.Content = 'Reiniciar ahora'; $u.Go.Visibility = 'Visible'
    }
    elseif ($script:UpdateBusy) { $u.St.Text = "Descargando Miki Tweaks $($i.Version)..." }
    elseif (-not $i) { $u.St.Text = 'Se actualiza sola: al abrir la app busca la versión nueva y la instala en segundo plano.' }
    elseif ($i.Error) { $u.St.Text = "No se pudo comprobar: $($i.Error)"; $u.St.Foreground = Br '#E8B23E' }
    elseif ($i.Newer) { $u.St.Text = "Hay una versión nueva: $($i.Version)$(if ($i.Notes) { '  ·  ' + $i.Notes })"; $u.St.Foreground = Br '{DynamicResource AccentBrush}'; $u.Go.Content = "Actualizar a $($i.Version)"; $u.Go.Visibility = 'Visible' }
    else { $u.St.Text = "✓ Tienes la última versión ($($i.Version))." }
}
function Start-UpdateCheck([switch]$Quiet) {
    if ($script:UpdateReady -or $script:UpdateBusy) { Show-UpdateState; return }
    if ($script:UpdUi) { $script:UpdUi.St.Text = 'Buscando...'; $script:UpdUi.Chk.IsEnabled = $false }
    $script:UpdQuiet = [bool]$Quiet
    Start-Async $UpdateCheckWork @((Get-UpdateUrl), $AppVersion) {
        param($r)
        $script:UpdateInfo = $r; if ($script:UpdUi) { $script:UpdUi.Chk.IsEnabled = $true }; Show-UpdateState
        if ($r.Newer) { Log "Hay una versión nueva de Miki Tweaks: $($r.Version)"; Start-UpdateInstall -Auto }
        elseif ($r.Error -and -not $script:UpdQuiet) { Log "· Actualizaciones de la app: $($r.Error)" }
    }
}
function Start-UpdateInstall([switch]$Auto) {
    if ($script:UpdateReady) { Open-MainApp; $window.Close(); return }   # botón «Reiniciar ahora»
    $i = $script:UpdateInfo; if (-not $i -or -not $i.Newer -or $script:UpdateBusy) { return }
    $script:UpdateBusy = $true; $script:UpdAuto = [bool]$Auto; Show-UpdateState
    if ($script:UpdUi) { $script:UpdUi.Go.IsEnabled = $false }
    # Mismas comprobaciones que siempre: https, huella SHA-256, sintaxis y versión; guarda la anterior como .anterior
    Start-Async $UpdateInstallWork @($i, $AppPath) {
        param($r)
        $script:UpdateBusy = $false
        if (-not $r -or $r.Error) {
            Log "✗ Actualización a $($script:UpdateInfo.Version): $($r.Error)"
            if (-not $script:UpdAuto) { Show-AppToast "No se pudo actualizar: $($r.Error)" 'warn' }   # en automático se reintenta al volver a abrir
            Show-UpdateState; return
        }
        $script:UpdateReady = $script:UpdateInfo.Version
        Log "✓ Miki Tweaks $script:UpdateReady instalada; se usará al volver a abrir la app"
        if ($script:UpdAuto) { Show-AppToast "Miki Tweaks $script:UpdateReady instalada. Se usará la próxima vez que abras la app." 'ok'; Show-UpdateState }
        else { Open-MainApp; $window.Close() }
    }
}
# ---------- Test de polling rate (Raw Input) ----------
function Initialize-RawMouse {
    if ('CtRawMouse' -as [type]) { return $true }
    try {
        $refs = @([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -in 'PresentationCore', 'WindowsBase', 'System.Xaml' } | ForEach-Object { $_.Location })
        Add-Type -ReferencedAssemblies $refs -TypeDefinition @'
using System; using System.Runtime.InteropServices; using System.Windows.Interop;
public static class CtRawMouse {
  [StructLayout(LayoutKind.Sequential)] struct RAWINPUTDEVICE { public ushort UsagePage; public ushort Usage; public uint Flags; public IntPtr Target; }
  [DllImport("user32.dll", SetLastError = true)] static extern bool RegisterRawInputDevices(RAWINPUTDEVICE[] d, uint n, uint size);
  static System.Diagnostics.Stopwatch sw = System.Diagnostics.Stopwatch.StartNew();
  static long[] ring = new long[32768]; static int head = 0; static int count = 0; static bool attached = false;
  public static bool Active = false;
  static IntPtr Hook(IntPtr hwnd, int msg, IntPtr w, IntPtr l, ref bool handled) {
    if (msg == 0x00FF && Active) { ring[head] = sw.ElapsedTicks; head = (head + 1) % ring.Length; if (count < ring.Length) count++; }
    return IntPtr.Zero;
  }
  public static bool Start(IntPtr hwnd) {
    if (!attached) { HwndSource.FromHwnd(hwnd).AddHook(new HwndSourceHook(Hook)); attached = true; }
    RAWINPUTDEVICE[] d = new RAWINPUTDEVICE[1]; d[0].UsagePage = 1; d[0].Usage = 2; d[0].Flags = 0x100; d[0].Target = hwnd;
    head = 0; count = 0; Active = true;
    return RegisterRawInputDevices(d, 1, (uint)Marshal.SizeOf(typeof(RAWINPUTDEVICE)));
  }
  public static void Stop() {
    Active = false;
    RAWINPUTDEVICE[] d = new RAWINPUTDEVICE[1]; d[0].UsagePage = 1; d[0].Usage = 2; d[0].Flags = 0x1; d[0].Target = IntPtr.Zero;
    RegisterRawInputDevices(d, 1, (uint)Marshal.SizeOf(typeof(RAWINPUTDEVICE)));
  }
  public static double Rate(double windowMs) {
    long now = sw.ElapsedTicks; long win = (long)(windowMs * System.Diagnostics.Stopwatch.Frequency / 1000.0); int n = 0;
    for (int i = 0; i < count; i++) { int idx = (head - 1 - i + ring.Length) % ring.Length; if (now - ring[idx] <= win) n++; else break; }
    return n * 1000.0 / windowMs;
  }
}
'@
        return $true
    } catch { Log "✗ Test de polling: $($_.Exception.Message)"; return $false }
}
function Start-PollTest {
    $p = $script:Poll; if (-not $p) { return }
    if (-not (Initialize-RawMouse)) { $p.State.Text = 'No se pudo iniciar el test en este equipo.'; return }
    $hwnd = (New-Object Windows.Interop.WindowInteropHelper $window).Handle
    [void][CtRawMouse]::Start($hwnd)
    $script:PollMax = 0.0; $script:PollStart = Get-Date
    $p.Btn.IsEnabled = $false; $p.Btn.Content = 'Midiendo...'
    $p.State.Text = 'Mueve el ratón en círculos rápidos y amplios durante 6 segundos...'; $p.State.Foreground = Br '{DynamicResource AccentBrush}'
    if (-not $script:PollTimer) {
        $script:PollTimer = New-Object Windows.Threading.DispatcherTimer; $script:PollTimer.Interval = [TimeSpan]::FromMilliseconds(100)
        $script:PollTimer.Add_Tick({
            $p = $script:Poll; $r = [CtRawMouse]::Rate(250)
            if ($r -gt $script:PollMax) { $script:PollMax = $r }
            $p.Live.Text = ('{0:0} Hz' -f $r)
            $left = 6 - ((Get-Date) - $script:PollStart).TotalSeconds
            if ($left -le 0) { Stop-PollTest -Finish } else { $p.Bar.Width = 240 * (1 - $left / 6) }
        })
    }
    $script:PollTimer.Start()
}
function Stop-PollTest([switch]$Finish) {
    if ($script:PollTimer) { $script:PollTimer.Stop() }
    if ('CtRawMouse' -as [type]) { if ([CtRawMouse]::Active) { [CtRawMouse]::Stop() } }
    $p = $script:Poll; if (-not $p -or -not $Finish) { return }
    $p.Btn.IsEnabled = $true; $p.Btn.Content = 'Repetir test'; $p.Bar.Width = 240
    $m = $script:PollMax
    if ($m -lt 60) { $p.Live.Text = '—'; $p.State.Text = 'No se ha detectado movimiento suficiente. Repite el test moviendo el ratón sin parar.'; $p.State.Foreground = Br '#E8B23E'; return }
    $std = @(125, 250, 500, 1000, 2000, 4000, 8000) | Where-Object { $m -ge $_ * 0.8 } | Select-Object -Last 1
    if (-not $std) { $std = 125 }
    $p.Live.Text = "$std Hz"
    if ($std -ge 1000) { $p.State.Text = ('✓ Tu ratón funciona a unos {0} Hz (pico medido: {1:0} Hz). Perfecto para jugar.' -f $std, $m); $p.State.Foreground = Br '#4CC38A' }
    else { $p.State.Text = ('Tu ratón funciona a unos {0} Hz (pico: {1:0} Hz). Súbelo a 1000 Hz o más en el software de la marca: se nota en la puntería.' -f $std, $m); $p.State.Foreground = Br '#E8B23E' }
    Log ('Test de polling rate: {0} Hz (pico {1:0} Hz)' -f $std, $m)
}

# ---------- Página Periféricos ----------
function Build-PeripheralsPanel {
    $f = $script:Facts
    $sp = New-Object Windows.Controls.StackPanel
    [void]$sp.Children.Add((New-Header 'TUS PERIFÉRICOS' 4))
    $kindGlyph = @{ 'Ratón' = '&#xE962;'; 'Teclado' = '&#xE765;'; 'Mando' = '&#xE7FC;'; 'Auriculares' = '&#xE7F6;'; 'Micrófono' = '&#xE720;'; 'Audio' = '&#xE767;' }
    $list = @($f.Peripherals | Sort-Object { if ($_.Bus -eq 'Integrado') { 1 } else { 0 } })
    if ($list.Count -eq 0) { [void]$sp.Children.Add((New-El "<TextBlock {NS} Text=`"No se ha detectado ningún periférico externo.`" FontSize=`"13`" Foreground=`"#8E8E95`" Margin=`"2,0,0,10`"/>")) }
    foreach ($d in $list) {
        $brand = Get-DeviceBrand $d
        $soft = if ($brand -and $brand[2]) { @($f.InstalledApps | Where-Object { $_ -match [regex]::Escape($brand[2]) } | Select-Object -First 1) } else { @() }
        $kinds = ($d.Kinds -join ' + ')
        $sub = @($kinds, $d.Bus); if ($brand) { $sub = @($brand[0]) + $sub }
        $softTxt = if ($d.Bus -eq 'Integrado') { 'Integrado en el portátil: se actualiza con la BIOS y Windows Update.' }
                   elseif ($soft.Count) { "✓ $($soft[0]) instalado: ábrelo para comprobar si hay firmware nuevo." }
                   elseif ($brand -and $brand[1]) { "Software oficial: $($brand[1]). Ahí se configura y se actualiza el firmware." }
                   else { 'Marca no reconocida: busca el software oficial con el botón.' }
        $softCol = if ($soft.Count) { '#4CC38A' } else { '#8E8E95' }
        $g = $kindGlyph[$d.Kinds[0]]; if (-not $g) { $g = '&#xE88E;' }
        $btnVis = if ($d.Bus -eq 'Integrado') { 'Collapsed' } else { 'Visible' }
        $card = New-El @"
<Border {NS} CornerRadius="8" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="18,14" Margin="0,0,0,10">
 <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
  <Border Width="42" Height="42" CornerRadius="6" Background="#1C1C1F" VerticalAlignment="Top"><TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="$g" FontSize="18" Foreground="#A0A0A7" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
  <StackPanel Grid.Column="1" Margin="16,0,16,0">
   <TextBlock Text="$(Esc $d.Name)" FontSize="15" FontWeight="SemiBold" Foreground="#EDEDEF"/>
   <TextBlock Text="$(Esc ($sub -join '  ·  '))" FontSize="12" Foreground="#82828A" Margin="0,2,0,0"/>
   <TextBlock Text="$(Esc $softTxt)" FontSize="12.5" Foreground="$softCol" TextWrapping="Wrap" Margin="0,6,0,0"/>
  </StackPanel>
  <Button x:Name="B" Grid.Column="2" Style="{DynamicResource Ghost}" Content="Buscar firmware oficial" VerticalAlignment="Center" Visibility="$btnVis"/>
 </Grid>
</Border>
"@
        $q = if ($brand) { "$($brand[0]) $($d.Name) firmware update" } elseif ($d.Vid) { "$($d.Name) USB VID $($d.Vid) PID $($d.Pid) software firmware" } else { "$($d.Name) firmware update" }
        $b = $card.FindName('B'); $b.Tag = 'https://www.google.com/search?q=' + [uri]::EscapeDataString($q)
        $b.Add_Click({ param($s, $e) Start-Process "$($s.Tag)" })
        [void]$sp.Children.Add($card)
    }
    [void]$sp.Children.Add((New-El "<TextBlock {NS} Text=`"El firmware se actualiza siempre con el programa oficial de cada marca y sin desconectar el periférico mientras tanto. Ninguna app genérica puede hacerlo de forma segura.`" FontSize=`"12`" Foreground=`"#82828A`" TextWrapping=`"Wrap`" Margin=`"2,0,0,0`"/>"))

    [void]$sp.Children.Add((New-Header 'TEST DE POLLING RATE DEL RATÓN' 20))
    $poll = New-El @"
<Border {NS} CornerRadius="10" Padding="24,20" Margin="0,0,0,10" Background="#131315" BorderBrush="#232326" BorderThickness="1">
 <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
  <StackPanel>
   <TextBlock Text="¿A cuántos Hz va de verdad tu ratón?" FontSize="17" FontWeight="SemiBold" Foreground="White"/>
   <TextBlock x:Name="St" Text="Muchos ratones vienen a 500 Hz de fábrica o se resetean tras una actualización. Pulsa «Iniciar test» y mueve el ratón en círculos rápidos." FontSize="13" Foreground="#A0A0A7" TextWrapping="Wrap" Margin="0,6,24,0"/>
   <Border Height="6" CornerRadius="3" Background="#232326" Width="240" HorizontalAlignment="Left" Margin="0,14,0,0"><Border x:Name="Bar" Width="0" CornerRadius="3" HorizontalAlignment="Left" Background="{DynamicResource AccentGrad}"/></Border>
  </StackPanel>
  <StackPanel Grid.Column="1" VerticalAlignment="Center" MinWidth="170">
   <TextBlock x:Name="Lv" Text="— Hz" FontSize="34" FontWeight="SemiBold" Foreground="White" HorizontalAlignment="Center"/>
   <Button x:Name="Go" Style="{DynamicResource Primary}" Content="Iniciar test" Margin="0,10,0,0"/>
  </StackPanel>
 </Grid>
</Border>
"@
    $script:Poll = @{ State = $poll.FindName('St'); Live = $poll.FindName('Lv'); Btn = $poll.FindName('Go'); Bar = $poll.FindName('Bar') }
    $script:Poll.Btn.Add_Click({ Start-PollTest })
    [void]$sp.Children.Add($poll)

    $tw = @($script:Tweaks | Where-Object { $_.Category -eq 'Perifericos' })
    if ($tw.Count) {
        [void]$sp.Children.Add((New-Header 'AJUSTES' 20))
        foreach ($t in $tw) { [void]$sp.Children.Add((New-TweakCard $t)) }
    }
    return $sp
}

# ---------- Página Salud del PC ----------
function New-HealthCard($tag, $tagBg, $tagFg, $title, $lines, $status, $statusCol, $btnText, $btnTag) {
    $rows = ($lines | ForEach-Object { "<TextBlock Text=`"$(Esc $_)`" FontSize=`"12.5`" Foreground=`"#8E8E95`" TextWrapping=`"Wrap`" Margin=`"0,3,0,0`"/>" }) -join ''
    $btn = if ($btnText) { "<Button x:Name=`"B`" Grid.Column=`"2`" Style=`"{DynamicResource Ghost}`" Content=`"$(Esc $btnText)`" VerticalAlignment=`"Center`"/>" } else { '' }
    $c = New-El @"
<Border {NS} CornerRadius="8" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="18,14" Margin="0,0,0,10">
 <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
  <Border Width="46" Height="46" CornerRadius="6" Background="$tagBg" VerticalAlignment="Top"><TextBlock Text="$tag" FontSize="11.5" FontWeight="SemiBold" Foreground="$tagFg" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
  <StackPanel Grid.Column="1" Margin="16,0,16,0">
   <WrapPanel><TextBlock Text="$(Esc $title)" FontSize="15" FontWeight="SemiBold" Foreground="#EDEDEF" Margin="0,0,10,0"/><Border CornerRadius="4" Background="#1A1A1D" Padding="7,2" VerticalAlignment="Center"><TextBlock Text="$(Esc $status)" FontSize="11.5" FontWeight="SemiBold" Foreground="$statusCol"/></Border></WrapPanel>
   $rows
  </StackPanel>
  $btn
 </Grid>
</Border>
"@
    if ($btnText) { $b = $c.FindName('B'); $b.Tag = $btnTag; $b.Add_Click({ param($s, $e) if ("$($s.Tag)" -like 'http*') { Start-Process "$($s.Tag)" } }) }
    return $c
}
function Build-HealthPanel {
    $f = $script:Facts
    $sp = New-Object Windows.Controls.StackPanel
    [void]$sp.Children.Add((New-Header 'BIOS' 4))
    $age = $null; try { $age = [int](((Get-Date) - [datetime]::ParseExact($f.BiosDate, 'dd/MM/yyyy', $null)).TotalDays / 30) } catch {}
    $st = if ($null -eq $age) { 'Sin fecha' } elseif ($age -ge 24) { "De hace $age meses" } else { 'Reciente' }
    $col = if ($age -ge 24) { '#E8B23E' } else { '#4CC38A' }
    $q = 'https://www.google.com/search?q=' + [uri]::EscapeDataString("$($f.Maker) $($f.Model) BIOS download support")
    [void]$sp.Children.Add((New-HealthCard 'BIOS' '#1C1C1F' '#E0B954' "Versión $($f.BiosVersion)" @("Fecha: $($f.BiosDate)  ·  Placa: $($f.Board)", 'Las BIOS nuevas suelen mejorar estabilidad, compatibilidad y a veces temperaturas. Se instalan solo con la herramienta oficial del fabricante y con el cargador puesto.') $st $col 'Buscar BIOS oficial' $q))

    [void]$sp.Children.Add((New-Header 'DISCOS' 18))
    foreach ($d in @($f.Disks)) {
        $ok = ($d.Health -eq 'Healthy'); $wear = if ($null -ne $d.Wear) { [int]$d.Wear } else { $null }
        $st = if (-not $ok) { 'Con problemas' } elseif ($null -ne $wear -and $wear -ge 80) { 'Desgastado' } else { 'Buen estado' }
        $col = if ($st -eq 'Buen estado') { '#4CC38A' } elseif ($st -eq 'Desgastado') { '#E8B23E' } else { '#EF6F6F' }
        $l1 = "$($d.SizeGB) GB  ·  $($d.Media)  ·  $($d.Bus)"
        $bits = @(); if ($null -ne $wear) { $bits += "Desgaste: $wear %" }; if ($d.Temp) { $bits += "Temperatura: $($d.Temp) °C" }; if ($d.Hours) { $bits += "Encendido: $([math]::Round($d.Hours / 24)) días" }
        $lines = @($l1); if ($bits.Count) { $lines += ($bits -join '  ·  ') } else { $lines += 'Windows no da datos SMART de este disco.' }
        if (-not $ok) { $lines += 'Haz copia de seguridad de lo importante cuanto antes.' }
        [void]$sp.Children.Add((New-HealthCard $(if ($d.Media -eq 'HDD') { 'HDD' } else { 'SSD' }) '#1C1C1F' '#C8C8CD' $d.Name $lines $st $col $null $null))
    }

    if ($f.BatteryHealth) {
        [void]$sp.Children.Add((New-Header 'BATERÍA' 18))
        $h = [int]$f.BatteryHealth
        $st = if ($h -ge 80) { "Salud $h %" } elseif ($h -ge 60) { "Salud $h %: algo gastada" } else { "Salud $h %: muy gastada" }
        $col = if ($h -ge 80) { '#4CC38A' } elseif ($h -ge 60) { '#E8B23E' } else { '#EF6F6F' }
        $lines = @(('Capacidad actual: {0:N0} mWh de {1:N0} mWh originales' -f $f.BatteryFull, $f.BatteryDesign))
        if ($f.BatteryCycles) { $lines += "Ciclos de carga: $($f.BatteryCycles)" }
        $lines += 'Para cuidarla: si juegas siempre enchufado, activa en el programa del fabricante (MSI Center, Armoury Crate, Lenovo Vantage...) el límite de carga al 80 %.'
        [void]$sp.Children.Add((New-HealthCard 'BAT' '#1C1C1F' '#A0A0A7' 'Batería del portátil' $lines $st $col $null $null))
    }

    [void]$sp.Children.Add((New-Header 'WINDOWS' 18))
    if ($f.BootSeconds) {
        $b = [int]$f.BootSeconds; $st = if ($b -le 30) { 'Rápido' } elseif ($b -le 60) { 'Normal' } else { 'Lento' }
        $col = if ($b -le 30) { '#4CC38A' } elseif ($b -le 60) { '#A0A0A7' } else { '#E8B23E' }
        [void]$sp.Children.Add((New-HealthCard 'ON' '#1C1C1F' '#A0A0A7' "Arranque de Windows: $b segundos" @("Medido por Windows en el último arranque completo ($($f.BootDate)).", 'Quitar programas de la sección «Inicio de Windows» es lo que más lo acelera.') $st $col $null $null))
    }
    $rep = New-HealthCard 'FIX' '#1C1C1F' '#A0A0A7' 'Reparar Windows' @('Comprueba y repara los archivos del sistema con las herramientas oficiales de Microsoft (DISM y SFC). Útil si notas fallos raros, cuelgues o errores. Tarda entre 10 y 30 minutos y puedes seguir usando el PC.') 'Mantenimiento' '#8E8E95' 'Reparar ahora' 'repair'
    $script:RepairBtn = $rep.FindName('B'); $script:RepairBtn.Add_Click({ Start-RepairWindows })
    [void]$sp.Children.Add($rep)
    return $sp
}
$RepairWork = {
    $r = @{}
    try {
        $p1 = Start-Process dism.exe -ArgumentList '/Online /Cleanup-Image /RestoreHealth' -Wait -PassThru -WindowStyle Hidden; $r.Dism = $p1.ExitCode
        $p2 = Start-Process sfc.exe -ArgumentList '/scannow' -Wait -PassThru -WindowStyle Hidden; $r.Sfc = $p2.ExitCode
    } catch { $r.Error = $_.Exception.Message }
    return $r
}
function Start-RepairWindows {
    if ((Get-MsgBox).Invoke('Se van a comprobar y reparar los archivos de Windows (DISM + SFC). Tarda entre 10 y 30 minutos. ¿Empezar?', 'Miki Tweaks', 'YesNo', 'Question') -ne 'Yes') { return }
    $script:RepairBtn.IsEnabled = $false; $script:RepairBtn.Content = 'Reparando... (no apagues el PC)'
    Log 'Reparar Windows: DISM /RestoreHealth y SFC /scannow en marcha...'
    Start-Async $RepairWork $null {
        param($r)
        $script:RepairBtn.IsEnabled = $true
        if ($r.Error) { $script:RepairBtn.Content = 'Reparar ahora'; Log "✗ Reparar Windows: $($r.Error)"; return }
        $ok = ($r.Dism -eq 0 -and $r.Sfc -eq 0)
        $script:RepairBtn.Content = $(if ($ok) { '✓ Terminado' } else { 'Terminado con avisos' })
        Log "Reparar Windows terminado (DISM: $($r.Dism), SFC: $($r.Sfc)). El detalle está en C:\Windows\Logs\CBS\CBS.log"
        [void](Get-MsgBox).Invoke($(if ($ok) { 'Reparación terminada: Windows está en buen estado o se ha reparado. Reinicia cuando puedas.' } else { "Terminó con códigos DISM $($r.Dism) / SFC $($r.Sfc). Reinicia y, si sigues con problemas, vuelve a ejecutarlo." }), 'Miki Tweaks', 'OK', 'Information')
    }
}

# ---------- Test de conexión a regiones ----------
$ConnTargets = @(
    @('Cloudflare', '1.1.1.1'), @('Google', '8.8.8.8'),
    @('Europa · Fráncfort', 'dynamodb.eu-central-1.amazonaws.com'), @('Europa · París', 'dynamodb.eu-west-3.amazonaws.com'),
    @('Europa · Irlanda', 'dynamodb.eu-west-1.amazonaws.com'), @('Europa · Estocolmo', 'dynamodb.eu-north-1.amazonaws.com'),
    @('EE. UU. · Este', 'dynamodb.us-east-1.amazonaws.com'), @('EE. UU. · Oeste', 'dynamodb.us-west-2.amazonaws.com'))
$ConnWork = {
    param($targets)
    $out = @()
    foreach ($t in $targets) {
        $ms = New-Object System.Collections.Generic.List[double]; $fail = 0
        try { $ip = ([Net.Dns]::GetHostAddresses($t[1]) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1) } catch { $ip = $null }
        if (-not $ip) { $out += @{ Name = $t[0]; Avg = -1; Jit = 0; Loss = 100 }; continue }
        for ($i = 0; $i -lt 10; $i++) {
            $c = New-Object Net.Sockets.TcpClient; $sw = [Diagnostics.Stopwatch]::StartNew()
            try { $task = $c.ConnectAsync($ip, 443); if ($task.Wait(1500) -and $c.Connected) { $ms.Add($sw.Elapsed.TotalMilliseconds) } else { $fail++ } } catch { $fail++ } finally { $c.Close() }
            Start-Sleep -Milliseconds 60
        }
        if ($ms.Count) {
            $avg = ($ms | Measure-Object -Average).Average; $jit = 0; for ($i = 1; $i -lt $ms.Count; $i++) { $jit += [math]::Abs($ms[$i] - $ms[$i - 1]) }
            if ($ms.Count -gt 1) { $jit = $jit / ($ms.Count - 1) }
            $out += @{ Name = $t[0]; Avg = [math]::Round($avg); Jit = [math]::Round($jit, 1); Loss = [math]::Round(100 * $fail / 10) }
        } else { $out += @{ Name = $t[0]; Avg = -1; Jit = 0; Loss = 100 } }
    }
    return @{ Rows = $out }
}
# ---------- Herramientas de conexión: bufferbloat y ruta ----------
# Bufferbloat: ping en reposo y con la conexión saturada (descargando y subiendo con los servidores de prueba de Cloudflare)
$BloatWork = {
    param($x)
    Add-Type -AssemblyName System.Net.Http
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $target = '1.1.1.1'; $pinger = New-Object Net.NetworkInformation.Ping; $useTcp = $false
    function Probe {
        if (-not $useTcp) { try { $r = $pinger.Send($target, 1000); if ($r.Status -eq 'Success') { return [double]$r.RoundtripTime } } catch {}; return $null }
        $c = New-Object Net.Sockets.TcpClient; $sw = [Diagnostics.Stopwatch]::StartNew()
        try { $t = $c.ConnectAsync($target, 443); if ($t.Wait(1000) -and $c.Connected) { return [double]$sw.Elapsed.TotalMilliseconds } } catch {} finally { $c.Close() }
        return $null
    }
    function Med($l) { $s = @($l | Sort-Object); $n = $s.Count; if (-not $n) { return $null }; if ($n % 2) { return [double]$s[[int][math]::Floor($n / 2)] }; return ([double]$s[$n / 2 - 1] + [double]$s[$n / 2]) / 2 }
    $ok = 0; for ($i = 0; $i -lt 3; $i++) { if ($null -ne (Probe)) { $ok++ } }
    if (-not $ok) { $useTcp = $true; $ok = 0; for ($i = 0; $i -lt 3; $i++) { if ($null -ne (Probe)) { $ok++ } } }
    if (-not $ok) { return @{ Error = 'no hay respuesta de internet ahora mismo.' } }
    # 1) En reposo
    $idle = New-Object Collections.Generic.List[double]; $lost = 0
    for ($i = 0; $i -lt 20; $i++) { $v = Probe; if ($null -eq $v) { $lost++ } else { $idle.Add($v) }; Start-Sleep -Milliseconds 180 }
    if ($idle.Count -lt 5) { return @{ Error = 'la conexión no responde de forma estable ni siquiera en reposo.' } }
    # 2) Con carga
    # .NET Framework solo abre 2 conexiones por servidor si no se le dice otra cosa: no bastaría para llenar una fibra
    [Net.ServicePointManager]::DefaultConnectionLimit = 32
    $client = New-Object Net.Http.HttpClient; $client.Timeout = [TimeSpan]::FromSeconds(30)
    function NetBytes($dir) {
        # Bytes reales que han pasado por las tarjetas de red (cuenta también las descargas a medias)
        $s = [int64]0
        foreach ($ni in [Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
            if ("$($ni.OperationalStatus)" -ne 'Up' -or "$($ni.NetworkInterfaceType)" -match 'Loopback|Tunnel') { continue }
            try { $st = $ni.GetIPStatistics(); $s += $(if ($dir -eq 'down') { $st.BytesReceived } else { $st.BytesSent }) } catch {}
        }
        return $s
    }
    function Load($kind, $seconds) {
        $samples = New-Object Collections.Generic.List[double]; $lostL = 0; $limited = $false
        $jobs = New-Object Collections.Generic.List[object]
        $chunk = if ($kind -eq 'down') { 50000000 } else { 8000000 }
        $cap = if ($kind -eq 'down') { [int64]1200000000 } else { [int64]400000000 }
        $payload = if ($kind -eq 'up') { New-Object byte[] $chunk } else { $null }
        $b0 = NetBytes $kind; $bStart = $null; $tStart = 0.0
        $sw = [Diagnostics.Stopwatch]::StartNew()
        while ($sw.Elapsed.TotalSeconds -lt $seconds) {
            for ($i = $jobs.Count - 1; $i -ge 0; $i--) {
                $j = $jobs[$i]
                if (-not $j.T.IsCompleted) { continue }
                $okT = ("$($j.T.Status)" -eq 'RanToCompletion')
                if ($j.Stage -eq 'head' -and $okT) {
                    $resp = $j.T.Result
                    if ([int]$resp.StatusCode -eq 429) { $limited = $true; $resp.Dispose(); $jobs.RemoveAt($i); continue }
                    if ($resp.IsSuccessStatusCode) { try { $j.R = $resp; $j.T = $resp.Content.ReadAsStreamAsync().Result.CopyToAsync([IO.Stream]::Null); $j.Stage = 'body'; continue } catch {} }
                    $resp.Dispose()
                } elseif ($okT -and $j.Stage -eq 'post') { try { if ([int]$j.T.Result.StatusCode -eq 429) { $limited = $true }; $j.T.Result.Dispose() } catch {} }
                if ($j.R) { try { $j.R.Dispose() } catch {} }
                $jobs.RemoveAt($i)
            }
            $used = (NetBytes $kind) - $b0
            if ($limited -or $used -ge $cap) { break }
            while ($jobs.Count -lt 6) {
                if ($kind -eq 'down') { $jobs.Add(@{ Stage = 'head'; R = $null; T = $client.GetAsync("https://speed.cloudflare.com/__down?bytes=$chunk", [Net.Http.HttpCompletionOption]::ResponseHeadersRead) }) }
                else { $jobs.Add(@{ Stage = 'post'; R = $null; T = $client.PostAsync('https://speed.cloudflare.com/__up', (New-Object Net.Http.ByteArrayContent -ArgumentList (, $payload))) }) }
            }
            if ($sw.Elapsed.TotalSeconds -ge 2) {
                if ($null -eq $bStart) { $bStart = NetBytes $kind; $tStart = $sw.Elapsed.TotalSeconds }
                $v = Probe; if ($null -eq $v) { $lostL++ } else { $samples.Add($v) }
            }
            Start-Sleep -Milliseconds 120
        }
        $bEnd = NetBytes $kind; $secs = $sw.Elapsed.TotalSeconds - $tStart
        $client.CancelPendingRequests()
        foreach ($j in $jobs) { try { [void]$j.T.Wait(800) } catch {}; if ($j.R) { try { $j.R.Dispose() } catch {} } }
        $mbps = if ($null -ne $bStart -and $secs -gt 0.5) { [math]::Round(($bEnd - $bStart) * 8 / $secs / 1e6) } else { 0 }
        return @{ Samples = $samples; Lost = $lostL; Mbps = $mbps; Bytes = [int64]($bEnd - $b0); Limited = $limited }
    }
    $d = Load 'down' 8
    $u = Load 'up' 7
    $client.Dispose()
    $idleMed = Med $idle
    $dMed = if ($d.Bytes -gt 0) { Med $d.Samples } else { $null }
    $uMed = if ($u.Bytes -gt 0) { Med $u.Samples } else { $null }
    $dInc = if ($null -ne $dMed) { [math]::Max(0, [math]::Round($dMed - $idleMed)) } else { $null }
    $uInc = if ($null -ne $uMed) { [math]::Max(0, [math]::Round($uMed - $idleMed)) } else { $null }
    $incs = @(@($dInc, $uInc) | Where-Object { $null -ne $_ })
    if (-not $incs.Count) {
        if ($d.Limited -or $u.Limited) { return @{ Error = 'los servidores de prueba de Cloudflare te han puesto un límite temporal por hacer varios tests seguidos. Espera unos 10 minutos y repítelo.' } }
        return @{ Error = 'no se pudo cargar la conexión con los servidores de prueba (puede que tu red los bloquee).' }
    }
    $worst = ($incs | Measure-Object -Maximum).Maximum
    $grade = if ($worst -lt 5) { 'A+' } elseif ($worst -lt 30) { 'A' } elseif ($worst -lt 60) { 'B' } elseif ($worst -lt 200) { 'C' } elseif ($worst -lt 400) { 'D' } else { 'F' }
    $total = 20 + $d.Samples.Count + $d.Lost + $u.Samples.Count + $u.Lost
    return @{ Idle = [math]::Round($idleMed); DownInc = $dInc; UpInc = $uInc; Grade = $grade; Worst = $worst
              DownMbps = $d.Mbps; UpMbps = $u.Mbps; Loss = [math]::Round(100 * ($lost + $d.Lost + $u.Lost) / [math]::Max(1, $total)); MB = [math]::Round(($d.Bytes + $u.Bytes) / 1e6); Tcp = $useTcp; Limited = [bool]($d.Limited -or $u.Limited) }
}

# Ruta: traceroute propio (pings con TTL en paralelo) + 10 pings a cada salto + diagnóstico de dónde empieza la pérdida
$RouteWork = {
    param($t)
    $name = $t[0]; $hostName = $t[1]
    try { $ip = ([Net.Dns]::GetHostAddresses($hostName) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1) } catch { $ip = $null }
    if (-not $ip) { return @{ Error = "no se encuentra $hostName. ¿Hay conexión a internet?" } }
    $buf = New-Object byte[] 32; $hops = @{}; $maxTtl = 25; $reach = 0
    for ($try = 0; $try -lt 3; $try++) {
        $pend = @{}
        for ($ttl = 1; $ttl -le $maxTtl; $ttl++) {
            if ($hops.ContainsKey($ttl)) { continue }
            if ($reach -and $ttl -gt $reach) { break }
            $pend[$ttl] = (New-Object Net.NetworkInformation.Ping).SendPingAsync($ip, 2000, $buf, (New-Object Net.NetworkInformation.PingOptions($ttl, $true)))
        }
        foreach ($k in @($pend.Keys)) {
            try { $r = $pend[$k].Result } catch { continue }
            $s = "$($r.Status)"
            if ($s -eq 'TtlExpired' -or $s -eq 'Success') {
                $hops[$k] = "$($r.Address)"
                if ($s -eq 'Success' -and (-not $reach -or $k -lt $reach)) { $reach = $k }
            }
        }
        Start-Sleep -Milliseconds 200
    }
    if (-not $hops.Count) { return @{ Error = 'tu red no deja hacer este diagnóstico (bloquea los pings). Usa la medición de latencia de Rendimiento en vivo.' } }
    $end = if ($reach) { $reach } else { ($hops.Keys | Measure-Object -Maximum).Maximum }
    $rows = @(); for ($ttl = 1; $ttl -le $end; $ttl++) { $rows += @{ Ttl = $ttl; Addr = $(if ($hops.ContainsKey($ttl)) { $hops[$ttl] } else { $null }); Ms = (New-Object Collections.Generic.List[double]); Lost = 0; Name = '' } }
    $dn = @{}; foreach ($h in $rows) { if ($h.Addr) { try { $dn[$h.Ttl] = [Net.Dns]::GetHostEntryAsync($h.Addr) } catch {} } }
    for ($round = 0; $round -lt 10; $round++) {
        $pend = @{}
        foreach ($h in $rows) { if ($h.Addr) { $pend[$h.Ttl] = (New-Object Net.NetworkInformation.Ping).SendPingAsync($h.Addr, 1000) } }
        foreach ($h in $rows) { if ($pend.ContainsKey($h.Ttl)) { try { $r = $pend[$h.Ttl].Result; if ("$($r.Status)" -eq 'Success') { $h.Ms.Add([double]$r.RoundtripTime) } else { $h.Lost++ } } catch { $h.Lost++ } } }
        Start-Sleep -Milliseconds 300
    }
    foreach ($h in $rows) { if ($dn.ContainsKey($h.Ttl)) { try { if ($dn[$h.Ttl].Wait(1500) -and "$($dn[$h.Ttl].Result.HostName)" -ne $h.Addr) { $h.Name = "$($dn[$h.Ttl].Result.HostName)" } } catch {} } }
    $priv = '^(10\.|192\.168\.|169\.254\.|172\.(1[6-9]|2\d|3[01])\.|100\.(6[4-9]|[7-9]\d|1[01]\d|12[0-7])\.)'
    $out = @(foreach ($h in $rows) {
        @{ Ttl = $h.Ttl; Addr = $h.Addr; Name = $h.Name; Dest = $false; Private = [bool]($h.Addr -and $h.Addr -match $priv)
           Avg = $(if ($h.Ms.Count) { [math]::Round(($h.Ms | Measure-Object -Average).Average, 1) } else { $null })
           Loss = $(if ($h.Addr) { [math]::Round(100 * $h.Lost / 10) } else { $null }) }
    })
    if ($reach) { $out[-1].Dest = $true; $fAvg = $out[-1].Avg; $fLoss = $out[-1].Loss }
    else {
        # El destino no contesta a los pings: se mide conectando a su puerto 443
        $ms = New-Object Collections.Generic.List[double]; $fail = 0
        for ($i = 0; $i -lt 10; $i++) {
            $c = New-Object Net.Sockets.TcpClient; $sw = [Diagnostics.Stopwatch]::StartNew()
            try { $tk = $c.ConnectAsync($ip, 443); if ($tk.Wait(1500) -and $c.Connected) { $ms.Add($sw.Elapsed.TotalMilliseconds) } else { $fail++ } } catch { $fail++ } finally { $c.Close() }
            Start-Sleep -Milliseconds 80
        }
        $fAvg = if ($ms.Count) { [math]::Round(($ms | Measure-Object -Average).Average, 1) } else { $null }; $fLoss = [math]::Round(100 * $fail / 10)
        $out += @{ Ttl = $end + 1; Addr = "$ip"; Name = ''; Dest = $true; Private = $false; Avg = $fAvg; Loss = $fLoss }
    }
    $level = 'ok'; $verdict = ''; $detail = @()
    $label = { param($h) if ($h.Name) { "$($h.Name)" } else { "$($h.Addr)" } }
    if ($null -eq $fAvg) {
        $level = 'bad'; $verdict = 'El servidor de destino no responde'
        $detail += 'No se ha podido medir la latencia final. Prueba con otra región o vuelve a intentarlo en un rato.'
    } elseif ($fLoss -ge 10) {
        $origin = $null
        for ($i = 0; $i -lt $out.Count; $i++) {
            $h = $out[$i]; if ($null -eq $h.Loss -or $h.Loss -lt 10) { continue }
            $later = @($out[$i..($out.Count - 1)] | Where-Object { $null -ne $_.Loss })
            if (-not @($later | Where-Object { $_.Loss -lt 10 }).Count) { $origin = $h; break }
        }
        $level = 'bad'
        if (-not $origin -or $origin.Ttl -eq 1) {
            $verdict = "Se pierden paquetes ($fLoss %) en tu propia red"
            $detail += 'Los paquetes ya se pierden entre tu PC y el router. Por Wi-Fi: acércate al router, usa la banda de 5 GHz o, mejor, un cable. Por cable: prueba otro cable u otro puerto y reinicia el router.'
        } elseif ($origin.Ttl -le 4 -or $origin.Private) {
            $verdict = "Se pierden paquetes ($fLoss %) en tu operador"
            $detail += "Tu red de casa está bien, pero la pérdida empieza en el salto $($origin.Ttl) ($(& $label $origin)), que ya es de tu operador. Si se repite en días y horas distintas, llama a tu operador con este resultado."
        } else {
            $verdict = "Se pierden paquetes ($fLoss %) lejos de tu casa"
            $detail += "Tu red y tu operador están bien: la pérdida empieza en el salto $($origin.Ttl) ($(& $label $origin)), ya en internet o cerca del servidor. No depende de ti. Si te pasa a menudo con esta región, aquí es donde una app tipo ExitLag sí puede ayudar, porque usa otra ruta."
        }
    } else {
        $verdict = "Ruta sana: llegas a $name sin perder paquetes ($fAvg ms)"
        $r1 = @($out | Where-Object { $_.Ttl -eq 1 -and $null -ne $_.Avg }) | Select-Object -First 1
        if ($r1 -and $r1.Avg -ge 8) { $level = 'warn'; $detail += "Tu router tarda $($r1.Avg) ms en contestar. Por cable debería ser 1-2 ms; por Wi-Fi es normal algo más. Si vas por cable, reinicia el router." }
        $prev = 0.0; $best = $null; $jump = 0.0
        foreach ($h in @($out | Where-Object { $null -ne $_.Avg })) { $j = $h.Avg - $prev; if ($j -gt $jump -and $h.Ttl -gt 1) { $jump = $j; $best = $h }; $prev = [math]::Max($prev, $h.Avg) }
        if ($best -and $jump -ge 25) { $detail += "El mayor aumento (+$([math]::Round($jump)) ms) aparece en el salto $($best.Ttl) ($(& $label $best)): suele ser el tramo largo hasta otro país o hasta la red del juego. Es normal y no depende de ti." }
        if (@($out | Where-Object { -not $_.Dest -and $_.Loss -ge 10 }).Count) { $detail += 'Algunos saltos intermedios no contestan a todos los pings: es normal (los routers de internet dan poca prioridad a los pings) y no afecta a tu partida, porque al destino llega todo.' }
        if ($level -eq 'ok') { $detail += 'Con una ruta así, una app tipo ExitLag apenas te mejoraría el ping.' }
    }
    return @{ Rows = $out; Verdict = $verdict; Level = $level; Detail = ($detail -join "`n`n"); Target = $name; Via = $(if ($reach) { 'ping' } else { 'tcp' }) }
}

function New-NetTile($label, $value, $color) {
    "<StackPanel Margin=`"0,0,12,0`"><TextBlock Text=`"$(Esc $label)`" FontSize=`"11.5`" Foreground=`"#82828A`"/><TextBlock Text=`"$(Esc $value)`" FontSize=`"20`" FontWeight=`"SemiBold`" Foreground=`"$color`" Margin=`"0,2,0,0`"/></StackPanel>"
}

function New-BloatCard {
    $c = New-El @"
<Border {NS} CornerRadius="8" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="20,16" Margin="0,0,0,10">
 <StackPanel>
  <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
   <StackPanel Margin="0,0,20,0">
    <TextBlock Text="Ping con la conexión ocupada (bufferbloat)" FontSize="15" FontWeight="SemiBold" Foreground="#EDEDEF"/>
    <TextBlock x:Name="St" Text="La causa más común de los picos de lag en casa: alguien descarga, ve una serie o sube fotos y tu ping se dispara. Este test mide tu ping en reposo y con la conexión a tope, y te dice si tu router lo gestiona bien. En fibra rápida usa hasta 1 GB de datos: no lo hagas con datos móviles." FontSize="12.5" Foreground="#8E8E95" TextWrapping="Wrap" Margin="0,3,0,0"/>
   </StackPanel>
   <Button x:Name="Go" Grid.Column="1" Style="{DynamicResource Primary}" Content="Hacer el test" VerticalAlignment="Top"/>
  </Grid>
  <StackPanel x:Name="Res" Margin="0,14,0,0" Visibility="Collapsed">
   <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
    <Border x:Name="GradeBox" Width="66" Height="66" CornerRadius="10" Background="#1C1C1F" VerticalAlignment="Top">
     <TextBlock x:Name="Grade" FontSize="28" FontWeight="Bold" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#EDEDEF"/>
    </Border>
    <StackPanel Grid.Column="1" Margin="18,0,0,0">
     <UniformGrid x:Name="Tiles" Columns="3"/>
     <TextBlock x:Name="Speed" FontSize="12" Foreground="#82828A" Margin="0,8,0,0" TextWrapping="Wrap"/>
    </StackPanel>
   </Grid>
   <TextBlock x:Name="Advice" FontSize="13" Foreground="#C8C8CD" TextWrapping="Wrap" Margin="0,12,0,0"/>
  </StackPanel>
 </StackPanel>
</Border>
"@
    $script:Bloat = @{ St = $c.FindName('St'); Go = $c.FindName('Go'); Res = $c.FindName('Res'); Grade = $c.FindName('Grade'); GradeBox = $c.FindName('GradeBox'); Tiles = $c.FindName('Tiles'); Speed = $c.FindName('Speed'); Advice = $c.FindName('Advice') }
    $script:Bloat.Go.Add_Click({
        $k = $script:Bloat; $k.Go.IsEnabled = $false; $k.Go.Content = 'Midiendo...'; $k.Res.Visibility = 'Collapsed'
        $k.St.Text = 'Midiendo durante unos 25 segundos: primero en reposo, luego descargando y después subiendo a tope. Mientras tanto, no uses internet en este PC.'
        Start-Async $BloatWork (, 0) {
            param($r)
            $k = $script:Bloat; $k.Go.IsEnabled = $true; $k.Go.Content = 'Repetir test'
            if (-not $r -or $r.Error) { $k.St.Text = "No se pudo hacer el test: $(if ($r) { $r.Error } else { 'error desconocido' })"; return }
            $gc = switch ($r.Grade) { 'A+' { '#4CC38A' } 'A' { '#4CC38A' } 'B' { '#A3C94C' } 'C' { '#E8B23E' } 'D' { '#F97316' } default { '#EF6F6F' } }
            $k.Grade.Text = $r.Grade; $k.Grade.Foreground = Br $gc
            $k.Tiles.Children.Clear()
            $fmt = { param($v) if ($null -eq $v) { 'sin medir' } else { "+$v ms" } }
            $col = { param($v) if ($null -eq $v) { '#82828A' } elseif ($v -lt 30) { '#4CC38A' } elseif ($v -lt 60) { '#A3C94C' } elseif ($v -lt 200) { '#E8B23E' } else { '#EF6F6F' } }
            foreach ($x in @(@('En reposo', "$($r.Idle) ms", '#EDEDEF'), @('Descargando', (& $fmt $r.DownInc), (& $col $r.DownInc)), @('Subiendo', (& $fmt $r.UpInc), (& $col $r.UpInc)))) {
                [void]$k.Tiles.Children.Add((New-El ((New-NetTile $x[0] $x[1] $x[2]) -replace '^<StackPanel ', '<StackPanel {NS} ')))
            }
            $k.Speed.Text = "Velocidad medida (aproximada): $($r.DownMbps) Mbps de bajada  $([char]0xB7)  $($r.UpMbps) Mbps de subida  $([char]0xB7)  pérdida $($r.Loss) %  $([char]0xB7)  el test ha usado unos $($r.MB) MB de datos."
            $k.Advice.Text = switch ($r.Grade) {
                { $_ -in 'A+', 'A' } { 'Tu router gestiona muy bien el tráfico: aunque alguien en casa descargue o vea vídeos, tu ping apenas sube. Si notas lag, no viene de aquí: mira la ruta hasta el servidor más abajo.' }
                'B' { 'Tu ping sube algo cuando la conexión está ocupada. Si notas tirones cuando otros usan internet, activa QoS o SQM en tu router (o pide a los demás que pausen las descargas grandes mientras juegas).' }
                default { 'Cuando la conexión está ocupada tu ping se dispara: esta es la causa típica de los picos de lag cuando alguien ve una serie, descarga juegos o sube fotos. Solución: en la configuración del router, activa «QoS», «SQM» o «Smart Queue» y limita la velocidad a un 90 % de la que tienes contratada. Si tu router no lo tiene, juega por cable y activa «Pausar descargas mientras juegas» en Modos.' }
            }
            $k.St.Text = "Resultado: nota $($r.Grade). En reposo $($r.Idle) ms; con la conexión ocupada sube hasta +$($r.Worst) ms$(if ($r.Tcp) { ' (medido por TCP porque tu red bloquea los pings)' })."
            $k.Res.Visibility = 'Visible'
            Log "Test de bufferbloat: nota $($r.Grade) (reposo $($r.Idle) ms, descarga +$($r.DownInc) ms, subida +$($r.UpInc) ms, $($r.DownMbps)/$($r.UpMbps) Mbps)"
        }
    })
    return $c
}

function New-RouteCard {
    $c = New-El @"
<Border {NS} CornerRadius="8" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="20,16" Margin="0,0,0,10">
 <StackPanel>
  <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
   <StackPanel Margin="0,0,20,0">
    <TextBlock Text="¿Dónde se pierde tu conexión?" FontSize="15" FontWeight="SemiBold" Foreground="#EDEDEF"/>
    <TextBlock x:Name="St" Text="Sigue el camino de tus paquetes salto a salto hasta una región de servidores y te dice si el problema está en tu casa, en tu operador o más lejos (donde ya no depende de ti)." FontSize="12.5" Foreground="#8E8E95" TextWrapping="Wrap" Margin="0,3,0,0"/>
   </StackPanel>
   <Button x:Name="Go" Grid.Column="1" Style="{DynamicResource Primary}" Content="Analizar ruta" VerticalAlignment="Top"/>
  </Grid>
  <WrapPanel x:Name="Regions" Margin="0,12,0,0"/>
  <TextBlock x:Name="Verdict" FontSize="14.5" FontWeight="SemiBold" TextWrapping="Wrap" Margin="0,10,0,0" Visibility="Collapsed"/>
  <TextBlock x:Name="Detail" FontSize="12.5" Foreground="#A0A0A7" TextWrapping="Wrap" Margin="0,4,0,0" Visibility="Collapsed"/>
  <StackPanel x:Name="Rows" Margin="0,10,0,0"/>
 </StackPanel>
</Border>
"@
    $script:Route = @{ St = $c.FindName('St'); Go = $c.FindName('Go'); Regions = $c.FindName('Regions'); Verdict = $c.FindName('Verdict'); Detail = $c.FindName('Detail'); Rows = $c.FindName('Rows'); Sel = 2 }
    for ($i = 0; $i -lt $ConnTargets.Count; $i++) {
        if ($ConnTargets[$i][0] -match 'Google') { continue }
        $rb = New-El "<RadioButton {NS} Style=`"{DynamicResource Chip}`" GroupName=`"RouteRegion`" Content=`"$(Esc $ConnTargets[$i][0])`"/>"
        $rb.Tag = $i; if ($i -eq $script:Route.Sel) { $rb.IsChecked = $true }
        $rb.Add_Checked({ param($s, $e) $script:Route.Sel = [int]$s.Tag })
        [void]$script:Route.Regions.Children.Add($rb)
    }
    $script:Route.Go.Add_Click({
        $k = $script:Route; $tg = $ConnTargets[$k.Sel]
        $k.Go.IsEnabled = $false; $k.Go.Content = 'Analizando...'; $k.Rows.Children.Clear(); $k.Verdict.Visibility = 'Collapsed'; $k.Detail.Visibility = 'Collapsed'
        $k.St.Text = "Siguiendo la ruta hasta $($tg[0])... tarda unos 15 segundos."
        Start-Async $RouteWork (, $tg) {
            param($r)
            $k = $script:Route; $k.Go.IsEnabled = $true; $k.Go.Content = 'Analizar otra vez'
            if (-not $r -or $r.Error) { $k.St.Text = "No se pudo analizar: $(if ($r) { $r.Error } else { 'error desconocido' })"; return }
            $k.St.Text = "Ruta hasta $($r.Target): $(@($r.Rows).Count) saltos. Cada salto es un router por el que pasan tus paquetes; la pérdida solo importa si sigue hasta el destino."
            $k.Verdict.Text = $r.Verdict; $k.Verdict.Foreground = Br $(switch ($r.Level) { 'ok' { '#4CC38A' } 'warn' { '#E8B23E' } default { '#EF6F6F' } }); $k.Verdict.Visibility = 'Visible'
            if ($r.Detail) { $k.Detail.Text = $r.Detail; $k.Detail.Visibility = 'Visible' }
            $cols = "<Grid.ColumnDefinitions><ColumnDefinition Width=`"34`"/><ColumnDefinition Width=`"*`"/><ColumnDefinition Width=`"90`"/><ColumnDefinition Width=`"80`"/></Grid.ColumnDefinitions>"
            [void]$k.Rows.Children.Add((New-El "<Grid {NS} Margin=`"0,4`">$cols<TextBlock Text=`"#`" FontSize=`"11.5`" Foreground=`"#82828A`"/><TextBlock Grid.Column=`"1`" Text=`"Salto`" FontSize=`"11.5`" Foreground=`"#82828A`"/><TextBlock Grid.Column=`"2`" Text=`"Latencia`" FontSize=`"11.5`" Foreground=`"#82828A`" TextAlignment=`"Right`"/><TextBlock Grid.Column=`"3`" Text=`"Pérdida`" FontSize=`"11.5`" Foreground=`"#82828A`" TextAlignment=`"Right`"/></Grid>"))
            foreach ($h in @($r.Rows)) {
                $lbl = if ($h.Dest) { "Destino: $($r.Target)$(if ($r.Via -eq 'tcp') { ' (medido por TCP)' })" } elseif (-not $h.Addr) { 'Sin respuesta (normal en algunos routers)' } elseif ($h.Ttl -eq 1 -and $h.Private) { "Tu router  $([char]0xB7)  $($h.Addr)" } elseif ($h.Name) { "$($h.Name)" } else { "$($h.Addr)" }
                $fg = if (-not $h.Addr) { '#82828A' } elseif ($h.Dest) { '#EDEDEF' } else { '#C8C8CD' }
                $lat = if ($null -eq $h.Avg) { '-' } else { "$($h.Avg) ms" }
                $los = if ($null -eq $h.Loss) { '-' } else { "$($h.Loss) %" }
                $lc = if ($null -ne $h.Loss -and $h.Loss -ge 10) { if ($h.Dest) { '#EF6F6F' } else { '#E8B23E' } } else { '#C8C8CD' }
                $num = if ($h.Dest) { '' } else { "$($h.Ttl)" }
                [void]$k.Rows.Children.Add((New-El "<Grid {NS} Margin=`"0,3`">$cols<TextBlock Text=`"$num`" FontSize=`"12.5`" Foreground=`"#82828A`"/><TextBlock Grid.Column=`"1`" Text=`"$(Esc $lbl)`" FontSize=`"12.5`" Foreground=`"$fg`" TextTrimming=`"CharacterEllipsis`" Margin=`"0,0,10,0`"/><TextBlock Grid.Column=`"2`" Text=`"$lat`" FontSize=`"12.5`" Foreground=`"$fg`" TextAlignment=`"Right`"/><TextBlock Grid.Column=`"3`" Text=`"$los`" FontSize=`"12.5`" Foreground=`"$lc`" TextAlignment=`"Right`"/></Grid>"))
            }
            Log "Ruta hasta $($r.Target): $($r.Verdict)"
        }
    })
    return $c
}

function Add-NetToolCards($sp) {
    [void]$sp.Children.Add((New-Header "HERRAMIENTAS DE CONEXI$([char]0xD3)N" 4))
    [void]$sp.Children.Add((New-BloatCard))
    [void]$sp.Children.Add((New-RouteCard))
}

function New-ConnTestCard {
    $c = New-El @"
<Border {NS} CornerRadius="8" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="20,16" Margin="0,0,12,0">
 <StackPanel>
  <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
   <StackPanel>
    <TextBlock Text="Latencia a las regiones de servidores" FontSize="15" FontWeight="SemiBold" Foreground="#EDEDEF"/>
    <TextBlock x:Name="St" Text="Mide la latencia, la estabilidad (jitter) y la pérdida de paquetes hasta los centros de datos donde se alojan muchos juegos online." FontSize="12.5" Foreground="#8E8E95" TextWrapping="Wrap" Margin="0,3,16,0"/>
   </StackPanel>
   <Button x:Name="Go" Grid.Column="1" Style="{DynamicResource Primary}" Content="Medir conexión" VerticalAlignment="Center"/>
  </Grid>
  <StackPanel x:Name="Rows" Margin="0,10,0,0"/>
 </StackPanel>
</Border>
"@
    $script:Conn = @{ St = $c.FindName('St'); Go = $c.FindName('Go'); Rows = $c.FindName('Rows') }
    $script:Conn.Go.Add_Click({
        $k = $script:Conn; $k.Go.IsEnabled = $false; $k.Go.Content = 'Midiendo...'; $k.Rows.Children.Clear(); $k.St.Text = 'Midiendo... tarda unos 15 segundos.'
        Start-Async $ConnWork (, $ConnTargets) {
            param($r)
            $k = $script:Conn; $k.Go.IsEnabled = $true; $k.Go.Content = 'Medir otra vez'
            if (-not $r -or $r.Error) { $k.St.Text = "No se pudo medir: $($r.Error)"; return }
            $k.St.Text = 'Latencia media · jitter (variación) · pérdida. Para jugar: menos de 50 ms, jitter bajo y 0 % de pérdida.'
            [void]$k.Rows.Children.Add((New-El "<Grid {NS} Margin=`"0,4`"><Grid.ColumnDefinitions><ColumnDefinition Width=`"*`"/><ColumnDefinition Width=`"90`"/><ColumnDefinition Width=`"90`"/><ColumnDefinition Width=`"80`"/></Grid.ColumnDefinitions><TextBlock Text=`"Destino`" FontSize=`"11.5`" Foreground=`"#82828A`"/><TextBlock Grid.Column=`"1`" Text=`"Latencia`" FontSize=`"11.5`" Foreground=`"#82828A`" TextAlignment=`"Right`"/><TextBlock Grid.Column=`"2`" Text=`"Jitter`" FontSize=`"11.5`" Foreground=`"#82828A`" TextAlignment=`"Right`"/><TextBlock Grid.Column=`"3`" Text=`"Pérdida`" FontSize=`"11.5`" Foreground=`"#82828A`" TextAlignment=`"Right`"/></Grid>"))
            foreach ($x in @($r.Rows)) {
                $col = if ($x.Avg -lt 0) { '#EF6F6F' } elseif ($x.Avg -le 40) { '#4CC38A' } elseif ($x.Avg -le 90) { '#E8B23E' } else { '#EF6F6F' }
                $lat = if ($x.Avg -lt 0) { 'Sin respuesta' } else { "$($x.Avg) ms" }
                [void]$k.Rows.Children.Add((New-El "<Grid {NS} Margin=`"0,4`"><Grid.ColumnDefinitions><ColumnDefinition Width=`"*`"/><ColumnDefinition Width=`"90`"/><ColumnDefinition Width=`"90`"/><ColumnDefinition Width=`"80`"/></Grid.ColumnDefinitions><TextBlock Text=`"$(Esc $x.Name)`" FontSize=`"13`" Foreground=`"#C8C8CD`"/><TextBlock Grid.Column=`"1`" Text=`"$lat`" FontSize=`"13`" FontWeight=`"SemiBold`" Foreground=`"$col`" TextAlignment=`"Right`"/><TextBlock Grid.Column=`"2`" Text=`"$($x.Jit) ms`" FontSize=`"13`" Foreground=`"#C8C8CD`" TextAlignment=`"Right`"/><TextBlock Grid.Column=`"3`" Text=`"$($x.Loss) %`" FontSize=`"13`" Foreground=`"$(if ($x.Loss -gt 0) { '#E8B23E' } else { '#C8C8CD' })`" TextAlignment=`"Right`"/></Grid>"))
            }
            Log "Test de conexión: $((@($r.Rows) | ForEach-Object { "$($_.Name) $($_.Avg) ms" }) -join ', ')"
        }
    })
    return $c
}

# ---------- Informe del PC ----------
function Export-Report {
    $f = $script:Facts; $L = New-Object System.Collections.Generic.List[string]
    $L.Add("INFORME DE MIKI TWEAKS $AppVersion  ·  $(Get-Date -Format 'dd/MM/yyyy HH:mm')"); $L.Add('=' * 70)
    $L.Add("Equipo: $($f.Maker) $($f.Model)  ·  $($f.OS)")
    $L.Add("Procesador: $($f.CPU) ($($f.Cores) núcleos / $($f.Threads) hilos)")
    $L.Add("Gráfica: $($f.GPU)  ·  Driver $(if ($f.NvDriver) { $f.NvDriver } else { $f.GPUDriver })")
    $L.Add("RAM: $($f.RamGB) GB $($f.RamType) ($($f.RamModules)x$($f.RamModGB) GB a $($f.RamSpeed) MT/s)")
    $L.Add("Pantalla principal: $($f.MainHz) Hz  ·  Plan de energía: $($f.PowerPlan)")
    $L.Add("BIOS: $($f.BiosVersion) ($($f.BiosDate))  ·  Placa: $($f.Board)")
    foreach ($d in @($f.Disks)) { $L.Add("Disco: $($d.Name) $($d.SizeGB) GB · $($d.Health) · desgaste $($d.Wear) % · $($d.Temp) °C") }
    if ($f.BatteryHealth) { $L.Add("Batería: salud $($f.BatteryHealth) % · $($f.BatteryCycles) ciclos") }
    if ($f.BootSeconds) { $L.Add("Arranque de Windows: $($f.BootSeconds) s") }
    $L.Add(''); $L.Add("PUNTUACIÓN: $(Get-Score) / 100"); $L.Add('')
    $L.Add('JUEGOS'); foreach ($g in @($f.Games)) { $L.Add("  $($GameDefById[$g.Id].Name): $($g.Paths[0])") }
    $L.Add(''); $L.Add('PERIFÉRICOS'); foreach ($d in @($f.Peripherals)) { $b = Get-DeviceBrand $d; $L.Add("  $($d.Name) · $($d.Kinds -join '+') · $($d.Bus)$(if ($b) { ' · ' + $b[0] })") }
    $L.Add(''); $L.Add('DIAGNÓSTICO'); foreach ($d in $script:Diags) { $L.Add("  [$($d.Level)] $($d.Title)") }
    $L.Add(''); $L.Add('AJUSTES')
    foreach ($t in ($script:Tweaks | Sort-Object Category)) { $L.Add(("  [{0}] {1,-10} {2}{3}" -f $(if ($t.Applied) { 'X' } else { ' ' }), $t.Category, $t.Name, $(if ($t.Tier -eq 'Opcional') { ' (opcional)' } else { '' }))) }
    $file = Join-Path ([Environment]::GetFolderPath('Desktop')) ("Informe Miki Tweaks {0}.txt" -f (Get-Date -Format 'yyyy-MM-dd HHmm'))
    [IO.File]::WriteAllLines($file, $L, (New-Object Text.UTF8Encoding($true)))
    Log "✓ Informe guardado: $file"
    Show-AppToast 'Informe guardado en el escritorio'
    Start-Process notepad.exe "`"$file`""
}

# ---------- Temas de color, avisos dentro de la app y estado lateral ----------
# Acento (color plano), fondo suave para chips y color del texto encima del acento
$AccentThemes = [ordered]@{
    'Lima'    = @('#CBF24A', '#22270F', '#0B0B0C'); 'Naranja' = @('#FF7A3D', '#2B1A10', '#0B0B0C')
    'Azul'    = @('#5B9DFF', '#14213A', '#0B0B0C'); 'Rojo'    = @('#FF5A60', '#2D1416', '#0B0B0C')
    'Violeta' = @('#A48BFF', '#211C38', '#0B0B0C'); 'Blanco'  = @('#E8E8EA', '#232326', '#0B0B0C')
}
function Set-Accent($name) {
    $c = $AccentThemes[$name]; if (-not $c) { $c = $AccentThemes['Lima'] }
    $cc = [Windows.Media.ColorConverter]
    $window.Resources['AccentA'] = $cc::ConvertFromString($c[0])
    $window.Resources['AccentSoftC'] = $cc::ConvertFromString($c[1])
    $window.Resources['AccentFgC'] = $cc::ConvertFromString($c[2])
}
$script:ToastTimer = New-Object Windows.Threading.DispatcherTimer
$script:ToastTimer.Interval = [TimeSpan]::FromMilliseconds(3200)
$script:ToastTimer.Add_Tick({
    $script:ToastTimer.Stop()
    $a = New-Object Windows.Media.Animation.DoubleAnimation(1, 0, (New-Object Windows.Duration([TimeSpan]::FromMilliseconds(250))))
    $a.Add_Completed({ $UI.Toast.Visibility = 'Collapsed' })
    $UI.Toast.BeginAnimation([Windows.UIElement]::OpacityProperty, $a)
})
function Show-AppToast($text, $kind = 'ok') {
    $map = @{ ok = @([char]0xE73E, '#4CC38A'); info = @([char]0xE946, '#7FA6E0'); warn = @([char]0xE7BA, '#E8B23E') }
    $m = $map[$kind]; if (-not $m) { $m = $map.ok }
    $UI.ToastIcon.Text = [string]$m[0]; $UI.ToastIcon.Foreground = Br $m[1]; $UI.ToastText.Text = $text
    $UI.Toast.Visibility = 'Visible'
    $UI.Toast.BeginAnimation([Windows.UIElement]::OpacityProperty, (New-Object Windows.Media.Animation.DoubleAnimation(0, 1, (New-Object Windows.Duration([TimeSpan]::FromMilliseconds(200))))))
    $tt = New-Object Windows.Media.TranslateTransform; $UI.Toast.RenderTransform = $tt
    $tt.BeginAnimation([Windows.Media.TranslateTransform]::YProperty, (New-Object Windows.Media.Animation.DoubleAnimation(14, 0, (New-Object Windows.Duration([TimeSpan]::FromMilliseconds(260))))))
    $script:ToastTimer.Stop(); $script:ToastTimer.Start()
}
function Update-SideStatus {
    if (-not $UI.SideScore) { return }
    $v = if ($script:Tweaks.Count) { Get-Score } else { 0 }
    $UI.SideScore.Text = "$v"
    # El aro grande del Resumen solo se animaba al aplicar o escanear: tras cambiar de modo podía quedarse con otra cifra
    if ($script:Arc -and $script:Tweaks.Count -and $script:ScoreTarget -ne $v) { Animate-Score }
    $p = [math]::Min([double]$v, 99.99)
    if ($p -le 0.5) { $UI.SideArc.Data = $null } else {
        $a = [math]::PI * 2 * $p / 100 - [math]::PI / 2; $x = 19 + 16 * [math]::Cos($a); $y = 19 + 16 * [math]::Sin($a)
        $UI.SideArc.Data = [Windows.Media.Geometry]::Parse([string]::Format($Inv, 'M 19,3 A 16,16 0 {0} 1 {1:0.##},{2:0.##}', $(if ($p -gt 50) { 1 } else { 0 }), $x, $y))
    }
    $cur = (Get-ModeState).current
    $UI.SideMode.Text = if ($cur -and $ModeDefs.ContainsKey($cur)) { $ModeDefs[$cur].Name } else { 'Sin modo elegido' }
}

# ---------- Benchmark (PresentMon de Intel) ----------
$BenchFile = Join-Path $DataDir 'benchmarks.json'
$ToolsDir  = Join-Path $DataDir 'tools'
$PmPath    = Join-Path $ToolsDir 'PresentMon.exe'
function Get-BenchRuns { try { if (Test-Path $BenchFile) { return @((Get-Content $BenchFile -Raw -Encoding UTF8 | ConvertFrom-Json)) } } catch {}; return @() }
function Save-BenchRuns($runs) { (ConvertTo-Json -InputObject @($runs) -Depth 6) | Set-Content -Path $BenchFile -Encoding UTF8 }

$BenchAnalyze = {
    param($csv)
    $inv = [Globalization.CultureInfo]::InvariantCulture
    $rows = @(Import-Csv $csv)
    if ($rows.Count -lt 30) { return @{ Error = 'Se registraron muy pocos fotogramas. ¿Estaba el juego en primer plano y en partida?' } }
    $cols = @($rows[0].PSObject.Properties.Name)
    if ($cols -contains 'SwapChainAddress') { $rows = @(($rows | Group-Object SwapChainAddress | Sort-Object Count -Descending | Select-Object -First 1).Group) }
    function Col($names) { foreach ($n in $names) { if ($cols -contains $n) { return $n } }; return $null }
    function Nums($name) {
        $l = New-Object System.Collections.Generic.List[double]
        if ($name) { foreach ($r in $rows) { $v = 0.0; if ([double]::TryParse("$($r.$name)", [Globalization.NumberStyles]::Float, $inv, [ref]$v) -and $v -gt 0) { $l.Add($v) } } }
        return , $l
    }
    $ft = Nums (Col @('MsBetweenPresents', 'FrameTime', 'MsBetweenAppStart'))
    if ($ft.Count -lt 30) { return @{ Error = 'PresentMon no devolvió tiempos de fotograma válidos.' } }
    $s = @($ft | Sort-Object); $n = $s.Count
    $mean = ($ft | Measure-Object -Average).Average
    function Pct($p) { $i = [math]::Min($n - 1, [math]::Max(0, [int][math]::Ceiling($p * $n) - 1)); return $s[$i] }
    $med = Pct 0.5
    $var = 0.0; foreach ($x in $ft) { $var += ($x - $mean) * ($x - $mean) }; $sd = [math]::Sqrt($var / $n)
    $lim = [math]::Max(2.5 * $med, $med + 8)
    $stut = 0; foreach ($x in $ft) { if ($x -gt $lim) { $stut++ } }
    $dur = ($ft | Measure-Object -Sum).Sum / 1000
    $gpu = Nums (Col @('MsGPUBusy', 'GPUBusy'))
    $lat = Nums (Col @('DisplayLatency', 'MsUntilDisplayed'))
    $inp = Nums (Col @('MsAllInputToPhotonLatency', 'AllInputToPhotonLatency'))
    $pcl = Nums (Col @('MsPCLatency'))
    $pmCol = Col @('PresentMode')
    $mode = if ($pmCol) { "$(($rows | Group-Object $pmCol | Sort-Object Count -Descending | Select-Object -First 1).Name)" } else { '' }
    $pts = New-Object System.Collections.Generic.List[double]; $bk = [math]::Max(1, [int][math]::Ceiling($ft.Count / 240))
    for ($i = 0; $i -lt $ft.Count; $i += $bk) { $mx = 0.0; for ($j = $i; $j -lt [math]::Min($ft.Count, $i + $bk); $j++) { if ($ft[$j] -gt $mx) { $mx = $ft[$j] } }; $pts.Add([math]::Round($mx, 2)) }
    return @{
        Frames = $n; Seconds = [math]::Round($dur); AvgFps = [math]::Round(1000 / $mean, 1)
        Low1 = [math]::Round(1000 / (Pct 0.99), 1); Low01 = [math]::Round(1000 / (Pct 0.999), 1)
        AvgFt = [math]::Round($mean, 2); P99Ft = [math]::Round((Pct 0.99), 2); Sd = [math]::Round($sd, 2)
        StutPerMin = [math]::Round($stut / [math]::Max(0.1, $dur / 60), 1)
        GpuBound = $(if ($gpu.Count) { [math]::Round(100 * (($gpu | Measure-Object -Average).Average) / $mean) } else { $null })
        Latency = $(if ($lat.Count) { [math]::Round(($lat | Measure-Object -Average).Average, 1) } else { $null })
        InputLat = $(if ($pcl.Count) { [math]::Round(($pcl | Measure-Object -Average).Average, 1) } elseif ($inp.Count -ge 10) { [math]::Round(($inp | Measure-Object -Average).Average, 1) } else { $null })
        PresentMode = $mode; Graph = $pts.ToArray()
    }
}
$BenchWork = {
    param($sync, $pm, $exes, $seconds, $csv, $analyzeText)
    $names = @($exes | ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_) })
    $sync.State = 'wait'
    while (-not $sync.Cancel -and -not (Get-Process -Name $names -ErrorAction SilentlyContinue)) { Start-Sleep -Milliseconds 500 }
    if ($sync.Cancel) { return @{ Cancelled = $true } }
    $sync.State = 'countdown'
    for ($i = 10; $i -gt 0; $i--) { if ($sync.Cancel) { return @{ Cancelled = $true } }; $sync.Count = $i; Start-Sleep -Seconds 1 }
    Remove-Item $csv -ErrorAction SilentlyContinue
    $a = @(); foreach ($e in $exes) { $a += '--process_name'; $a += "`"$e`"" }
    $a += @('--output_file', "`"$csv`"", '--timed', "$seconds", '--terminate_after_timed', '--stop_existing_session', '--session_name', 'MikiTweaks', '--no_console_stats')
    $sync.State = 'capture'; $sync.Start = Get-Date
    $p = Start-Process -FilePath $pm -ArgumentList $a -PassThru -WindowStyle Hidden
    while (-not $p.HasExited) { if ($sync.Cancel) { try { $p.Kill() } catch {}; return @{ Cancelled = $true } }; Start-Sleep -Milliseconds 300 }
    if (-not (Test-Path $csv)) { return @{ Error = 'PresentMon no guardó datos. Comprueba que el juego estaba abierto y en primer plano; algún anticheat puede bloquear la medición.' } }
    $sync.State = 'analyze'
    try { return (& ([scriptblock]::Create($analyzeText)) $csv) } catch { return @{ Error = $_.Exception.Message } }
}
$PmDownloadWork = {
    param($dir)
    $r = @{}
    try {
        $ProgressPreference = 'SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        $rel = Invoke-RestMethod 'https://api.github.com/repos/GameTechDev/PresentMon/releases/latest' -Headers @{ 'User-Agent' = 'MikiTweaks' } -TimeoutSec 30
        $asset = @($rel.assets | Where-Object { $_.name -match '^PresentMon-[\d\.]+-x64\.exe$' }) | Select-Object -First 1
        if (-not $asset) { $r.Error = 'no encontré la versión de consola en GitHub'; return $r }
        $tmp = Join-Path $dir 'PresentMon.download'
        Invoke-WebRequest $asset.browser_download_url -OutFile $tmp -UseBasicParsing -TimeoutSec 120
        $sig = Get-AuthenticodeSignature $tmp
        if ($sig.Status -ne 'Valid' -or "$($sig.SignerCertificate.Subject)" -notmatch 'Intel Corporation') { Remove-Item $tmp -Force; $r.Error = 'la firma digital no es de Intel; descarga descartada por seguridad'; return $r }
        Move-Item $tmp (Join-Path $dir 'PresentMon.exe') -Force
        $r.Version = "$($rel.tag_name)"
    } catch { $r.Error = $_.Exception.Message }
    return $r
}

function Format-Num($v, $fmt = '0') { if ($null -eq $v -or "$v" -eq '') { return '—' }; return ([double]$v).ToString($fmt) }
function New-StatTile($label, $value, $sub, $color) {
    New-El @"
<Border {NS} Width="152" CornerRadius="8" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="14,12" Margin="0,0,10,10">
 <StackPanel><TextBlock Text="$(Esc $label)" FontSize="11.5" Foreground="#82828A"/><TextBlock Text="$(Esc $value)" FontSize="24" FontWeight="SemiBold" Foreground="$color" Margin="0,4,0,0"/><TextBlock Text="$(Esc $sub)" FontSize="11.5" Foreground="#8E8E95" TextWrapping="Wrap"/></StackPanel>
</Border>
"@
}
function Build-BenchPanel {
    $f = $script:Facts
    $sp = New-Object Windows.Controls.StackPanel
    $card = New-El @"
<Border {NS} CornerRadius="10" Padding="26,22" Margin="0,0,0,14" Background="#131315" BorderBrush="#232326" BorderThickness="1">
 <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
  <StackPanel>
   <TextBlock Text="Medición de FPS y latencia" FontSize="12.5" Foreground="#8E8E95"/>
   <TextBlock Text="Mide antes y después de aplicar los ajustes" FontSize="22" FontWeight="SemiBold" Foreground="White" Margin="0,6,0,0"/>
   <TextBlock x:Name="St" FontSize="13" Foreground="#A0A0A7" TextWrapping="Wrap" Margin="0,6,20,0" Text="Elige juego y duración, pulsa Empezar y entra en partida o en el campo de tiro. La medición empieza sola cuando el juego está abierto, con un aviso sonoro al empezar y al terminar."/>
   <TextBlock Text="JUEGO" FontSize="10.5" FontWeight="SemiBold" Foreground="#82828A" Margin="0,16,0,6"/>
   <WrapPanel x:Name="Games"/>
   <Grid Margin="0,6,0,0"><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
    <StackPanel><TextBlock Text="DURACIÓN" FontSize="10.5" FontWeight="SemiBold" Foreground="#82828A" Margin="0,4,0,6"/><WrapPanel x:Name="Durs"/></StackPanel>
    <StackPanel Grid.Column="1" Margin="14,0,20,0"><TextBlock Text="NOMBRE DE LA MEDICIÓN" FontSize="10.5" FontWeight="SemiBold" Foreground="#82828A" Margin="0,4,0,6"/>
     <Border CornerRadius="6" Background="#161618" BorderBrush="#2A2A2E" BorderThickness="1" Padding="12,0" Height="36" MaxWidth="320" HorizontalAlignment="Left"><TextBox x:Name="Lbl" Background="Transparent" BorderThickness="0" Foreground="#EDEDEF" CaretBrush="White" SelectionBrush="{DynamicResource AccentBrush}" FontSize="13" VerticalAlignment="Center" MinWidth="220"/></Border>
    </StackPanel>
   </Grid>
  </StackPanel>
  <StackPanel Grid.Column="1" VerticalAlignment="Center" MinWidth="190">
   <TextBlock x:Name="Big" Text="" FontSize="40" FontWeight="SemiBold" Foreground="White" HorizontalAlignment="Center"/>
   <Button x:Name="Go" Style="{DynamicResource Primary}" Content="Empezar medición" Margin="0,8,0,0" Padding="22,13"/>
   <Button x:Name="Cancel" Style="{DynamicResource Ghost}" Content="Cancelar" Margin="0,8,0,0" Visibility="Collapsed"/>
  </StackPanel>
 </Grid>
</Border>
"@
    $b = @{ St = $card.FindName('St'); Big = $card.FindName('Big'); Go = $card.FindName('Go'); Cancel = $card.FindName('Cancel'); Lbl = $card.FindName('Lbl'); Games = $card.FindName('Games'); Durs = $card.FindName('Durs'); GameId = $null; Seconds = 60 }
    $script:Bench = $b
    foreach ($g in @($f.Games)) {
        $rb = New-El "<RadioButton {NS} Style=`"{DynamicResource Chip}`" GroupName=`"bgame`" Content=`"$(Esc $GameDefById[$g.Id].Name)`"/>"
        $rb.Tag = $g.Id; $rb.Add_Checked({ param($s, $e) Select-BenchGame $s.Tag }); [void]$b.Games.Children.Add($rb)
    }
    foreach ($sec in 30, 60, 120) {
        $rb = New-El "<RadioButton {NS} Style=`"{DynamicResource Chip}`" GroupName=`"bdur`" Content=`"$sec s`"/>"
        $rb.Tag = $sec; if ($sec -eq 60) { $rb.IsChecked = $true }; $rb.Add_Checked({ param($s, $e) $script:Bench.Seconds = [int]$s.Tag }); [void]$b.Durs.Children.Add($rb)
    }
    $b.Go.Add_Click({ Start-Bench })
    $b.Cancel.Add_Click({ if ($script:BenchSync) { $script:BenchSync.Cancel = $true; $script:Bench.St.Text = 'Cancelando...' } })
    [void]$sp.Children.Add($card)
    [void]$sp.Children.Add((New-El "<TextBlock {NS} Text=`"Para comparar de forma justa: misma escena (por ejemplo el campo de tiro o un mapa creativo), mismos gráficos, misma duración y nada más abierto. Usa PresentMon, la herramienta de Intel en la que se basan HWiNFO, FrameView u OCCT.`" FontSize=`"12`" Foreground=`"#82828A`" TextWrapping=`"Wrap`" Margin=`"2,0,0,18`"/>"))
    $b.Res = New-Object Windows.Controls.StackPanel; [void]$sp.Children.Add($b.Res)
    $runs = @(Get-BenchRuns); $pref = if ($runs.Count) { "$($runs[-1].Game)" } else { '' }
    $first = @($b.Games.Children | Where-Object { $_.Tag -eq $pref }) | Select-Object -First 1
    if (-not $first) { $first = @($b.Games.Children) | Select-Object -First 1 }
    if ($first) { $first.IsChecked = $true } else { $b.Go.IsEnabled = $false; $b.St.Text = 'No se ha detectado ningún juego compatible en este PC.' }
    return $sp
}
function Select-BenchGame($id) {
    $b = $script:Bench; $b.GameId = $id
    $runs = @(Get-BenchRuns | Where-Object { $_.Game -eq $id })
    $b.Lbl.Text = if ($runs.Count) { 'Después de los ajustes' } else { 'Antes de los ajustes' }
    Render-BenchResults
}
function Start-Bench {
    $b = $script:Bench; if (-not $b.GameId) { return }
    if ($script:BenchSync -and $script:BenchSync.State -in @('wait', 'countdown', 'capture', 'analyze')) { return }
    if (Test-Path $PmPath) {
        $sig = Get-AuthenticodeSignature $PmPath
        if ($sig.Status -ne 'Valid' -or "$($sig.SignerCertificate.Subject)" -notmatch 'Intel Corporation') { Remove-Item $PmPath -Force -ErrorAction SilentlyContinue; Log '· PresentMon no tenía una firma válida de Intel: se vuelve a descargar' }
    }
    if (-not (Test-Path $PmPath)) {
        $b.Go.IsEnabled = $false; $b.St.Foreground = Br '#A0A0A7'; $b.St.Text = 'Descargando PresentMon (menos de 1 MB) desde el GitHub oficial de Intel y comprobando su firma...'
        Start-Async $PmDownloadWork @($ToolsDir) {
            param($r)
            $b = $script:Bench; $b.Go.IsEnabled = $true
            if (-not $r -or $r.Error) { $b.St.Text = "No se pudo descargar PresentMon: $($r.Error)"; $b.St.Foreground = Br '#E8B23E'; Log "✗ PresentMon: $($r.Error)"; return }
            Log "✓ PresentMon $($r.Version) descargado y verificado (firma de Intel)"; Start-Bench
        }
        return
    }
    $b.St.Foreground = Br '#A0A0A7'; $b.RunSeconds = $b.Seconds
    $b.Go.Visibility = 'Collapsed'; $b.Cancel.Visibility = 'Visible'
    $script:BenchSync = [hashtable]::Synchronized(@{ State = 'wait'; Cancel = $false; Count = 0; Start = $null })
    Log "Benchmark: esperando a $($GameDefById[$b.GameId].Name) ($($b.Seconds) s)"
    if (-not $script:BenchTimer) {
        $script:BenchTimer = New-Object Windows.Threading.DispatcherTimer; $script:BenchTimer.Interval = [TimeSpan]::FromMilliseconds(250)
        $script:BenchTimer.Add_Tick({ Update-BenchStatus })
    }
    $script:BenchLastState = ''; $script:BenchTimer.Start()
    $exes = [string[]]$GameDefById[$b.GameId].Exes
    Start-Async $BenchWork @($script:BenchSync, $PmPath, $exes, $b.Seconds, (Join-Path $ToolsDir 'ultima-medicion.csv'), "$BenchAnalyze") { param($r) Finish-Bench $r }
}
function Update-BenchStatus {
    $s = $script:BenchSync; $b = $script:Bench; if (-not $s -or -not $b) { return }
    switch ($s.State) {
        'wait' { $b.St.Text = "Esperando a que abras $($GameDefById[$b.GameId].Name)... Puedes minimizar esta ventana: la medición empezará sola."; $b.Big.Text = '···' }
        'countdown' {
            if ($script:BenchLastState -ne 'countdown') { [System.Media.SystemSounds]::Beep.Play() }
            $b.St.Text = 'Juego detectado. Ponte en la escena que quieras medir: la medición empieza en unos segundos.'; $b.Big.Text = "$($s.Count)" }
        'capture' {
            if ($script:BenchLastState -ne 'capture') { [System.Media.SystemSounds]::Exclamation.Play() }
            $left = [math]::Max(0, $b.RunSeconds - [int]((Get-Date) - $s.Start).TotalSeconds)
            $b.St.Text = 'Midiendo... juega con normalidad y no salgas del juego hasta oír el aviso.'; $b.Big.Text = "$left s" }
        'analyze' { $b.St.Text = 'Analizando los fotogramas...'; $b.Big.Text = '' }
    }
    $script:BenchLastState = $s.State
}
function Finish-Bench($r) {
    if ($script:BenchTimer) { $script:BenchTimer.Stop() }
    $b = $script:Bench; if ($script:BenchSync) { $script:BenchSync.State = 'done' }
    $b.Go.Visibility = 'Visible'; $b.Cancel.Visibility = 'Collapsed'; $b.Big.Text = ''
    if (-not $r -or $r.Cancelled) { $b.St.Text = 'Medición cancelada.'; return }
    if ($r.Error) { $b.St.Text = "No se pudo medir: $($r.Error)"; $b.St.Foreground = Br '#E8B23E'; Log "✗ Benchmark: $($r.Error)"; return }
    $run = [ordered]@{ Id = [guid]::NewGuid().ToString(); Date = (Get-Date).ToString('yyyy-MM-dd HH:mm'); Game = $b.GameId; GameName = $GameDefById[$b.GameId].Name
        Label = $(if ("$($b.Lbl.Text)".Trim()) { "$($b.Lbl.Text)".Trim() } else { 'Medición' }); Mode = "$((Get-ModeState).current)"; Applied = @($script:Tweaks | Where-Object Applied).Count }
    foreach ($k in $r.Keys) { $run[$k] = $r[$k] }
    Save-BenchRuns (@(Get-BenchRuns) + @([pscustomobject]$run))
    [System.Media.SystemSounds]::Asterisk.Play()
    [void](Show-Toast 'Miki Tweaks' ("Medición terminada: {0} FPS medios, {1} en el 1 % más bajo" -f (Format-Num $r.AvgFps), (Format-Num $r.Low1)))
    $b.St.Text = '✓ Medición guardada. Aplica ajustes y vuelve a medir con la misma escena para ver la diferencia.'; $b.St.Foreground = Br '#4CC38A'
    Log ("✓ Benchmark {0}: {1} FPS medios, 1 % bajos {2}, latencia {3} ms" -f $run.GameName, (Format-Num $r.AvgFps), (Format-Num $r.Low1), (Format-Num $r.Latency '0.0'))
    $b.Lbl.Text = 'Después de los ajustes'
    Show-AppToast 'Medición guardada'
    Render-BenchResults
}
function Render-BenchResults {
    $b = $script:Bench; if (-not $b -or -not $b.Res) { return }
    $b.Res.Children.Clear()
    $all = @(Get-BenchRuns); $runs = @($all | Where-Object { $_.Game -eq $b.GameId })
    if ($runs.Count -eq 0) {
        [void]$b.Res.Children.Add((New-El "<Border {NS} CornerRadius=`"8`" Background=`"#131315`" BorderBrush=`"#232326`" BorderThickness=`"1`" Padding=`"20,18`"><TextBlock Text=`"Aún no hay mediciones de este juego. Haz una ahora (antes de aplicar ajustes) y otra después: aquí verás la diferencia en FPS, estabilidad y latencia.`" FontSize=`"13`" Foreground=`"#8E8E95`" TextWrapping=`"Wrap`"/></Border>"))
    } else {
        $r = $runs[-1]
        [void]$b.Res.Children.Add((New-Header ("ÚLTIMA MEDICIÓN  ·  {0}  ·  {1}" -f "$($r.Label)".ToUpper(), $r.Date) 0))
        $wp = New-Object Windows.Controls.WrapPanel
        [void]$wp.Children.Add((New-StatTile 'FPS medios' (Format-Num $r.AvgFps) "$($r.Frames) fotogramas en $($r.Seconds) s" '#FFFFFF'))
        [void]$wp.Children.Add((New-StatTile '1 % más bajo' (Format-Num $r.Low1) 'Lo que notas en los tirones' '{DynamicResource AccentBrush}'))
        [void]$wp.Children.Add((New-StatTile '0,1 % más bajo' (Format-Num $r.Low01) 'Los peores momentos' '#A0A0A7'))
        $latTxt = if ($null -ne $r.InputLat) { (Format-Num $r.InputLat '0.0') + ' ms' } elseif ($null -ne $r.Latency) { (Format-Num $r.Latency '0.0') + ' ms' } else { '—' }
        [void]$wp.Children.Add((New-StatTile 'Latencia' $latTxt $(if ($null -ne $r.InputLat) { 'Del ratón a la pantalla' } else { 'Del fotograma a la pantalla' }) '#A0A0A7'))
        [void]$wp.Children.Add((New-StatTile 'Tirones' ((Format-Num $r.StutPerMin '0.#') + ' /min') ('Variación: ' + (Format-Num $r.Sd '0.0') + ' ms') $(if ([double]$r.StutPerMin -gt 5) { '#E8B23E' } else { '#FFFFFF' })))
        [void]$b.Res.Children.Add($wp)
        # gráfica de tiempos de fotograma
        $g = @($r.Graph | ForEach-Object { [double]$_ }); $cv = New-Object Windows.Controls.Canvas; $cv.Width = 740; $cv.Height = 130
        if ($g.Count -gt 1) {
            $mx = [math]::Max([double]$r.P99Ft * 1.8, [double]$r.AvgFt * 2.2); $pc = New-Object Windows.Media.PointCollection
            for ($i = 0; $i -lt $g.Count; $i++) { $pc.Add((New-Object Windows.Point((740.0 * $i / ($g.Count - 1)), (130 - [math]::Min(128, 125 * $g[$i] / $mx))))) }
            $pl = New-Object Windows.Shapes.Polyline; $pl.Points = $pc; $pl.Stroke = $window.Resources['AccentGrad']; $pl.StrokeThickness = 1.6; [void]$cv.Children.Add($pl)
            $ay = 130 - 125 * [double]$r.AvgFt / $mx
            $ln = New-Object Windows.Shapes.Line; $ln.X1 = 0; $ln.X2 = 740; $ln.Y1 = $ay; $ln.Y2 = $ay; $ln.Stroke = Br '#5F5F66'; $ln.StrokeThickness = 1; $ln.StrokeDashArray = [Windows.Media.DoubleCollection]::Parse('4 4'); [void]$cv.Children.Add($ln)
        }
        $gb = New-El "<Border {NS} CornerRadius=`"8`" Background=`"#131315`" BorderBrush=`"#232326`" BorderThickness=`"1`" Padding=`"18,14`" Margin=`"0,0,10,10`"><StackPanel><TextBlock Text=`"Tiempo de cada fotograma (más plano = más fluido; los picos son tirones)  ·  media $(Format-Num $r.AvgFt '0.00') ms`" FontSize=`"12`" Foreground=`"#8E8E95`" Margin=`"0,0,0,8`"/><Viewbox x:Name=`"V`" Stretch=`"Fill`" Height=`"130`"/></StackPanel></Border>"
        $gb.FindName('V').Child = $cv
        [void]$b.Res.Children.Add($gb)
        # interpretación
        $notes = @()
        if ($null -ne $r.GpuBound) {
            if ([double]$r.GpuBound -ge 90) { $notes += @('&#xE7F4;', '#A0A0A7', "La gráfica va al límite ($($r.GpuBound) % del tiempo ocupada): para más FPS, baja ajustes gráficos o la resolución 3D.") }
            elseif ([double]$r.GpuBound -le 65) { $notes += @('&#xE9D9;', '#E8B23E', "El procesador es el que limita (la gráfica solo va al $($r.GpuBound) %): bajar gráficos casi no dará FPS; cierra programas en segundo plano.") }
            else { $notes += @('&#xE73E;', '#4CC38A', "Procesador y gráfica están equilibrados (gráfica al $($r.GpuBound) %).") }
        }
        if ("$($r.PresentMode)" -match '^Hardware') { $notes += @('&#xE73E;', '#4CC38A', "Presentación directa a la pantalla ($($r.PresentMode)): la vía de menor latencia.") }
        elseif ("$($r.PresentMode)" -match 'Composed') { $notes += @('&#xE7BA;', '#E8B23E', "La imagen pasa por el compositor de Windows ($($r.PresentMode)), que añade latencia: usa pantalla completa o activa las optimizaciones para juegos en ventana.") }
        if ([double]$r.StutPerMin -gt 5) { $notes += @('&#xE7BA;', '#E8B23E', 'Hay tirones frecuentes: prueba a limpiar la caché de sombreadores (Caché y temporales), revisa la temperatura en Rendimiento en vivo y cierra lo que no uses.') }
        for ($i = 0; $i -lt $notes.Count; $i += 3) {
            [void]$b.Res.Children.Add((New-El "<Border {NS} CornerRadius=`"6`" Background=`"#131315`" BorderBrush=`"#232326`" BorderThickness=`"1`" Padding=`"16,12`" Margin=`"0,0,10,8`"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width=`"Auto`"/><ColumnDefinition Width=`"*`"/></Grid.ColumnDefinitions><TextBlock FontFamily=`"Segoe Fluent Icons, Segoe MDL2 Assets`" Text=`"$($notes[$i])`" Foreground=`"$($notes[$i+1])`" FontSize=`"15`" VerticalAlignment=`"Top`" Margin=`"0,1,0,0`"/><TextBlock Grid.Column=`"1`" Text=`"$(Esc $notes[$i+2])`" FontSize=`"12.5`" Foreground=`"#C8C8CD`" TextWrapping=`"Wrap`" Margin=`"12,0,0,0`"/></Grid></Border>"))
        }
        # comparación
        if ($runs.Count -ge 2) {
            [void]$b.Res.Children.Add((New-Header 'COMPARAR CON' 16))
            $chips = New-Object Windows.Controls.WrapPanel; [void]$b.Res.Children.Add($chips)
            $b.Comp = New-Object Windows.Controls.StackPanel; [void]$b.Res.Children.Add($b.Comp)
            $prev = @($runs[0..($runs.Count - 2)]); [array]::Reverse($prev)
            $base = ($prev | Where-Object { "$($_.Label)" -match 'Antes' } | Select-Object -Last 1); if (-not $base) { $base = $prev[-1] }
            foreach ($p in ($prev | Select-Object -First 8)) {
                $rb = New-El "<RadioButton {NS} Style=`"{DynamicResource Chip}`" GroupName=`"bbase`" Content=`"$(Esc ("$($p.Label)  ·  $($p.Date)"))`"/>"
                $rb.Tag = "$($p.Id)"; $rb.Add_Checked({ param($s, $e) Show-BenchCompare $s.Tag }); [void]$chips.Children.Add($rb)
                if ($p.Id -eq $base.Id) { $rb.IsChecked = $true }
            }
        }
    }
    # historial
    if ($all.Count) {
        [void]$b.Res.Children.Add((New-Header 'HISTORIAL' 16))
        $hist = New-El "<Border {NS} CornerRadius=`"8`" Background=`"#131315`" BorderBrush=`"#232326`" BorderThickness=`"1`" Padding=`"18,10`" Margin=`"0,0,10,0`"><StackPanel x:Name=`"H`"/></Border>"
        $hp = $hist.FindName('H')
        $hdr = "<Grid {NS} Margin=`"0,4`"><Grid.ColumnDefinitions><ColumnDefinition Width=`"120`"/><ColumnDefinition Width=`"*`"/><ColumnDefinition Width=`"80`"/><ColumnDefinition Width=`"80`"/><ColumnDefinition Width=`"80`"/><ColumnDefinition Width=`"36`"/></Grid.ColumnDefinitions><TextBlock Text=`"Fecha`" FontSize=`"11.5`" Foreground=`"#82828A`"/><TextBlock Grid.Column=`"1`" Text=`"Juego · medición`" FontSize=`"11.5`" Foreground=`"#82828A`"/><TextBlock Grid.Column=`"2`" Text=`"FPS`" FontSize=`"11.5`" Foreground=`"#82828A`" TextAlignment=`"Right`"/><TextBlock Grid.Column=`"3`" Text=`"1 % bajo`" FontSize=`"11.5`" Foreground=`"#82828A`" TextAlignment=`"Right`"/><TextBlock Grid.Column=`"4`" Text=`"Latencia`" FontSize=`"11.5`" Foreground=`"#82828A`" TextAlignment=`"Right`"/></Grid>"
        [void]$hp.Children.Add((New-El $hdr))
        foreach ($x in ($all | Sort-Object Date -Descending | Select-Object -First 20)) {
            $lt = if ($null -ne $x.InputLat) { (Format-Num $x.InputLat '0.0') + ' ms' } elseif ($null -ne $x.Latency) { (Format-Num $x.Latency '0.0') + ' ms' } else { '—' }
            $row = New-El "<Grid {NS} Margin=`"0,4`"><Grid.ColumnDefinitions><ColumnDefinition Width=`"120`"/><ColumnDefinition Width=`"*`"/><ColumnDefinition Width=`"80`"/><ColumnDefinition Width=`"80`"/><ColumnDefinition Width=`"80`"/><ColumnDefinition Width=`"36`"/></Grid.ColumnDefinitions><TextBlock Text=`"$(Esc $x.Date)`" FontSize=`"12.5`" Foreground=`"#8E8E95`" VerticalAlignment=`"Center`"/><TextBlock Grid.Column=`"1`" Text=`"$(Esc ("$($x.GameName)  ·  $($x.Label)"))`" FontSize=`"12.5`" Foreground=`"#C8C8CD`" TextTrimming=`"CharacterEllipsis`" VerticalAlignment=`"Center`"/><TextBlock Grid.Column=`"2`" Text=`"$(Format-Num $x.AvgFps)`" FontSize=`"12.5`" FontWeight=`"SemiBold`" Foreground=`"#EDEDEF`" TextAlignment=`"Right`" VerticalAlignment=`"Center`"/><TextBlock Grid.Column=`"3`" Text=`"$(Format-Num $x.Low1)`" FontSize=`"12.5`" Foreground=`"{DynamicResource AccentBrush}`" TextAlignment=`"Right`" VerticalAlignment=`"Center`"/><TextBlock Grid.Column=`"4`" Text=`"$lt`" FontSize=`"12.5`" Foreground=`"#A0A0A7`" TextAlignment=`"Right`" VerticalAlignment=`"Center`"/><Button x:Name=`"Del`" Grid.Column=`"5`" Style=`"{DynamicResource TitleBtn}`" Width=`"30`" Height=`"28`" Content=`"&#xE74D;`" ToolTip=`"Borrar esta medición`" HorizontalAlignment=`"Right`"/></Grid>"
            $del = $row.FindName('Del'); $del.Tag = "$($x.Id)"
            $del.Add_Click({ param($s, $e) Save-BenchRuns @(Get-BenchRuns | Where-Object { "$($_.Id)" -ne "$($s.Tag)" }); Log 'Medición borrada del historial'; Render-BenchResults })
            [void]$hp.Children.Add($row)
        }
        [void]$b.Res.Children.Add($hist)
    }
}
# ---------- Compartir el resultado del Benchmark como imagen ----------
function Export-BenchShare {
    $sh = $script:BenchShare; if (-not $sh) { return }
    $base = $sh.Base; $now = $sh.Now
    $acc = try { "$($window.Resources['AccentA'])" } catch { '#FFC6F432' }; if (-not $acc) { $acc = '#FFC6F432' }
    $sign = { param($v) if ($null -eq $v) { '-' } else { ('{0}{1:0.#} %' -f $(if ($v -ge 0) { '+' } else { '' }), $v) } }
    $num = { param($v, $f) if ($null -eq $v -or "$v" -eq '') { '-' } else { ([double]$v).ToString($f) } }
    $big = if ($null -ne $sh.FpsP) { (& $sign $sh.FpsP) + ' FPS' } else { 'Antes y después' }
    $bigCol = if ($null -eq $sh.FpsP -or $sh.FpsP -ge 0) { $acc } else { '#FFEF6F6F' }
    $sub = if ($null -ne $sh.LowP) { "$(& $sign $sh.LowP) en los mínimos (1 % más bajo)" } else { '' }
    $game = if ($GameDefById.ContainsKey("$($sh.Game)")) { $GameDefById["$($sh.Game)"].Name } else { "$($sh.Game)" }
    $f = $script:Facts
    $pc = (@(("$($f.CPU)" -replace '\(R\)|\(TM\)|CPU|Processor|\d+-Core|@.*$', '' -replace '\s+', ' ').Trim(), ("$($f.GPU)" -replace '^(NVIDIA|AMD|Intel\(R\))\s+', '' -replace '\s+GPU$', '' -replace '\s+', ' ').Trim()) | Where-Object { $_ }) -join '  ·  '
    $row = { param($label, $a, $b, $fmt, $higherBetter)
        $p = if ($null -eq $a -or $null -eq $b -or "$a" -eq '' -or "$b" -eq '' -or [double]$a -eq 0) { $null } else { 100 * ([double]$b - [double]$a) / [double]$a }
        $col = if ($null -eq $p -or [math]::Abs($p) -lt 1.5) { '#FFA0A0A7' } elseif (($p -gt 0) -eq $higherBetter) { '#FF4CC38A' } else { '#FFEF6F6F' }
        "<Grid Margin=`"0,14,0,0`"><Grid.ColumnDefinitions><ColumnDefinition Width=`"*`"/><ColumnDefinition Width=`"190`"/><ColumnDefinition Width=`"190`"/><ColumnDefinition Width=`"170`"/></Grid.ColumnDefinitions><TextBlock Text=`"$(Esc $label)`" FontSize=`"30`" Foreground=`"#FFC8C8CD`"/><TextBlock Grid.Column=`"1`" Text=`"$(& $num $a $fmt)`" FontSize=`"30`" Foreground=`"#FFA0A0A7`" TextAlignment=`"Right`"/><TextBlock Grid.Column=`"2`" Text=`"$(& $num $b $fmt)`" FontSize=`"30`" FontWeight=`"SemiBold`" Foreground=`"#FFEDEDEF`" TextAlignment=`"Right`"/><TextBlock Grid.Column=`"3`" Text=`"$(& $sign $p)`" FontSize=`"30`" FontWeight=`"SemiBold`" Foreground=`"$col`" TextAlignment=`"Right`"/></Grid>"
    }
    $rows = (& $row 'FPS medios' $base.AvgFps $now.AvgFps '0' $true) + (& $row '1 % más bajo' $base.Low1 $now.Low1 '0' $true) + (& $row 'Tirones por minuto' $base.StutPerMin $now.StutPerMin '0.#' $false)
    if ($null -ne $sh.Lat0 -and $null -ne $sh.Lat1) { $rows += (& $row 'Latencia (ms)' $sh.Lat0 $sh.Lat1 '0.0' $false) }
    $el = New-El @"
<Border {NS} Width="1080" Height="1080" Background="#FF0F0F11" Padding="80,72">
 <DockPanel>
  <StackPanel DockPanel.Dock="Top" Orientation="Horizontal">
   <Image x:Name="Lg" Width="76" Height="76"/>
   <StackPanel Margin="22,0,0,0" VerticalAlignment="Center">
    <TextBlock Text="Miki Tweaks" FontSize="34" FontWeight="SemiBold" Foreground="#FFEDEDEF"/>
    <TextBlock Text="$(Esc $game)  ·  antes y después de optimizar" FontSize="24" Foreground="#FF8E8E95"/>
   </StackPanel>
  </StackPanel>
  <TextBlock DockPanel.Dock="Bottom" Text="Medido con el Benchmark de Miki Tweaks (PresentMon de Intel)  ·  $(Get-Date -Format 'dd/MM/yyyy')" FontSize="21" Foreground="#FF5F5F66" Margin="0,30,0,0" TextWrapping="Wrap"/>
  <StackPanel VerticalAlignment="Center">
   <TextBlock Text="$(Esc $big)" FontSize="128" FontWeight="Bold" Foreground="$bigCol"/>
   <TextBlock Text="$(Esc $sub)" FontSize="34" Foreground="#FFC8C8CD" Margin="4,0,0,40"/>
   <Grid Margin="0,0,0,4"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="190"/><ColumnDefinition Width="190"/><ColumnDefinition Width="170"/></Grid.ColumnDefinitions>
    <TextBlock Grid.Column="1" Text="Antes" FontSize="22" Foreground="#FF5F5F66" TextAlignment="Right"/><TextBlock Grid.Column="2" Text="Después" FontSize="22" Foreground="#FF5F5F66" TextAlignment="Right"/><TextBlock Grid.Column="3" Text="Cambio" FontSize="22" Foreground="#FF5F5F66" TextAlignment="Right"/>
   </Grid>
   $rows
   <TextBlock Text="$(Esc $pc)" FontSize="22" Foreground="#FF76767D" Margin="0,40,0,0" TextTrimming="CharacterEllipsis"/>
  </StackPanel>
 </DockPanel>
</Border>
"@
    try { $el.FindName('Lg').Source = $window.Icon } catch {}
    $el.Measure((New-Object Windows.Size 1080, 1080)); $el.Arrange((New-Object Windows.Rect 0, 0, 1080, 1080)); $el.UpdateLayout()
    $rtb = New-Object Windows.Media.Imaging.RenderTargetBitmap(1080, 1080, 96, 96, [Windows.Media.PixelFormats]::Pbgra32); $rtb.Render($el)
    $dir = Join-Path ([Environment]::GetFolderPath('MyPictures')) 'Miki Tweaks'; New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $file = Join-Path $dir ("Resultado $game $(Get-Date -Format 'yyyy-MM-dd HHmm').png" -replace '[\\/:*?"<>|]', '')
    $enc = New-Object Windows.Media.Imaging.PngBitmapEncoder; $enc.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($rtb))
    $fs = [IO.File]::Create($file); try { $enc.Save($fs) } finally { $fs.Close() }
    try { [Windows.Clipboard]::SetImage($rtb) } catch {}
    Log "Imagen del resultado guardada: $file"
    Show-AppToast 'Imagen guardada en Imágenes > Miki Tweaks y copiada: pégala en Discord o súbela a TikTok o Instagram.' 'ok'
    try { Start-Process explorer.exe "/select,`"$file`"" } catch {}
    return $file
}

function Show-BenchCompare($baseId) {
    $b = $script:Bench; if (-not $b.Comp) { return }
    $runs = @(Get-BenchRuns | Where-Object { $_.Game -eq $b.GameId }); $now = $runs[-1]; $base = $runs | Where-Object { "$($_.Id)" -eq "$baseId" } | Select-Object -First 1
    if (-not $base) { return }
    $b.Comp.Children.Clear()
    function Pct2($a, $c) { if ($null -eq $a -or $null -eq $c -or [double]$a -eq 0) { return $null }; return 100 * ([double]$c - [double]$a) / [double]$a }
    $fpsP = Pct2 $base.AvgFps $now.AvgFps; $lowP = Pct2 $base.Low1 $now.Low1
    $bLat = if ($null -ne $now.InputLat -and $null -ne $base.InputLat) { @($base.InputLat, $now.InputLat) } else { @($base.Latency, $now.Latency) }
    $head = if ($null -ne $fpsP) { ('{0}{1:0.#} % de FPS medios  ·  {2}{3:0.#} % en el 1 % más bajo' -f $(if ($fpsP -ge 0) { '+' } else { '' }), $fpsP, $(if ($lowP -ge 0) { '+' } else { '' }), $lowP) } else { '' }
    $good = ($fpsP -ge 2 -or $lowP -ge 3); $bad = ($fpsP -le -3 -and $lowP -le -3)
    $hc = if ($good) { '#4CC38A' } elseif ($bad) { '#EF6F6F' } else { '#E0B954' }
    $verdict = if ($good) { 'Mejora clara respecto a la medición elegida.' } elseif ($bad) { 'Ha ido a peor: revisa si la escena era la misma o deshaz los últimos cambios.' } else { 'Diferencia pequeña: dentro de lo que varía entre partidas. Repite la medición para confirmarlo.' }
    $rowsX = ''
    $defs = @(@('FPS medios', $base.AvgFps, $now.AvgFps, $true, '0'), @('1 % más bajo', $base.Low1, $now.Low1, $true, '0'), @('0,1 % más bajo', $base.Low01, $now.Low01, $true, '0'),
        @('Latencia (ms)', $bLat[0], $bLat[1], $false, '0.0'), @('Variación (ms)', $base.Sd, $now.Sd, $false, '0.0'), @('Tirones por minuto', $base.StutPerMin, $now.StutPerMin, $false, '0.#'))
    foreach ($d in $defs) {
        $p = Pct2 $d[1] $d[2]; $chg = if ($null -eq $p) { '—' } else { ('{0}{1:0.#} %' -f $(if ($p -ge 0) { '+' } else { '' }), $p) }
        $better = if ($null -eq $p -or [math]::Abs($p) -lt 1.5) { $null } elseif ($d[3]) { $p -gt 0 } else { $p -lt 0 }
        $cc = if ($null -eq $better) { '#8E8E95' } elseif ($better) { '#4CC38A' } else { '#EF6F6F' }
        $rowsX += "<Grid Margin=`"0,5`"><Grid.ColumnDefinitions><ColumnDefinition Width=`"*`"/><ColumnDefinition Width=`"100`"/><ColumnDefinition Width=`"100`"/><ColumnDefinition Width=`"100`"/></Grid.ColumnDefinitions><TextBlock Text=`"$(Esc $d[0])`" FontSize=`"13`" Foreground=`"#C8C8CD`"/><TextBlock Grid.Column=`"1`" Text=`"$(Format-Num $d[1] $d[4])`" FontSize=`"13`" Foreground=`"#8E8E95`" TextAlignment=`"Right`"/><TextBlock Grid.Column=`"2`" Text=`"$(Format-Num $d[2] $d[4])`" FontSize=`"13`" FontWeight=`"SemiBold`" Foreground=`"#EDEDEF`" TextAlignment=`"Right`"/><TextBlock Grid.Column=`"3`" Text=`"$chg`" FontSize=`"13`" FontWeight=`"SemiBold`" Foreground=`"$cc`" TextAlignment=`"Right`"/></Grid>"
    }
    [void]$b.Comp.Children.Add((New-El @"
<Border {NS} CornerRadius="10" Background="#131315" BorderBrush="$hc" BorderThickness="1" Padding="20,16" Margin="0,4,10,0">
 <StackPanel>
  <TextBlock Text="$(Esc $head)" FontSize="18" FontWeight="SemiBold" Foreground="$hc" TextWrapping="Wrap"/>
  <TextBlock Text="$(Esc $verdict)" FontSize="12.5" Foreground="#8E8E95" Margin="0,4,0,10" TextWrapping="Wrap"/>
  <Grid Margin="0,0,0,2"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="100"/><ColumnDefinition Width="100"/><ColumnDefinition Width="100"/></Grid.ColumnDefinitions>
   <TextBlock Text="" /><TextBlock Grid.Column="1" Text="$(Esc $base.Label)" FontSize="11.5" Foreground="#82828A" TextAlignment="Right" TextTrimming="CharacterEllipsis"/><TextBlock Grid.Column="2" Text="$(Esc $now.Label)" FontSize="11.5" Foreground="#82828A" TextAlignment="Right" TextTrimming="CharacterEllipsis"/><TextBlock Grid.Column="3" Text="Cambio" FontSize="11.5" Foreground="#82828A" TextAlignment="Right"/>
  </Grid>
  $rowsX
 </StackPanel>
</Border>
"@))
    $script:BenchShare = @{ Base = $base; Now = $now; FpsP = $fpsP; LowP = $lowP; Game = $b.GameId; Lat0 = $bLat[0]; Lat1 = $bLat[1] }
    $sb = New-El "<Button {NS} Style=`"{DynamicResource Ghost}`" HorizontalAlignment=`"Left`" Margin=`"0,10,0,0`"><StackPanel Orientation=`"Horizontal`"><TextBlock FontFamily=`"Segoe Fluent Icons, Segoe MDL2 Assets`" Text=`"&#xE72D;`" FontSize=`"13`" VerticalAlignment=`"Center`" Margin=`"0,0,8,0`"/><TextBlock Text=`"Compartir resultado (imagen)`"/></StackPanel></Button>"
    $sb.Add_Click({ Invoke-Safe 'compartir resultado' { [void](Export-BenchShare) } })
    [void]$b.Comp.Children.Add($sb)
}

# ---------- Modos (interfaz) ----------
function Update-ModeChip {
    $st = Get-ModeState
    if ($st.current -and $ModeDefs.ContainsKey($st.current)) {
        $m = $ModeDefs[$st.current]
        $UI.ModeChip.Visibility = 'Visible'; $UI.ModeChip.Background = Br $m.Soft; $UI.ModeDot.Fill = Br $m.Color
        $UI.ModeChipText.Text = $m.Name; $UI.ModeChipText.Foreground = Br $m.Fg
    } else { $UI.ModeChip.Visibility = 'Collapsed' }
    Update-SideStatus
}
function Build-WelcomeModes {
    $UI.WelcomeModes.Children.Clear(); $cur = (Get-ModeState).current
    foreach ($id in $ModeOrder) {
        $m = $ModeDefs[$id]; $style = if ($id -eq $cur) { 'Primary' } else { 'Ghost' }
        $b = New-El "<Button {NS} Style=`"{DynamicResource $style}`" Margin=`"0,0,6,0`" Padding=`"12,7`" FontSize=`"12.5`"><StackPanel Orientation=`"Horizontal`"><TextBlock FontFamily=`"Segoe Fluent Icons, Segoe MDL2 Assets`" Text=`"$($m.Glyph)`" FontSize=`"12`" VerticalAlignment=`"Center`"/><TextBlock Text=`"$(Esc $m.Short)`" Margin=`"7,0,0,0`" VerticalAlignment=`"Center`"/></StackPanel></Button>"
        $b.Tag = $id; $b.Add_Click({ param($s, $e) Invoke-ModeUI $s.Tag })
        [void]$UI.WelcomeModes.Children.Add($b)
    }
}
function Build-ModesPanel {
    $cur = (Get-ModeState).current
    $sp = New-Object Windows.Controls.StackPanel
    $prof = Get-UseProfile
    $ug = New-Object Windows.Controls.Primitives.UniformGrid; $ug.Columns = $(if ($ModeOrder.Count -eq 4) { 2 } else { $ModeOrder.Count })
    [void]$sp.Children.Add((New-El "<TextBlock {NS} Text=`"$(Esc ("Modos para tu perfil: " + (Get-ProfileText $prof).ToLower()))`" FontSize=`"12.5`" Foreground=`"#8E8E95`" Margin=`"2,0,0,12`"/>"))
    foreach ($id in $ModeOrder) {
        $m = $ModeDefs[$id]; $on = ($id -eq $cur)
        $items = ($m.Items | ForEach-Object { "<Grid Margin=`"0,7,0,0`"><Grid.ColumnDefinitions><ColumnDefinition Width=`"Auto`"/><ColumnDefinition Width=`"*`"/></Grid.ColumnDefinitions><TextBlock FontFamily=`"Segoe Fluent Icons, Segoe MDL2 Assets`" Text=`"&#xE73E;`" FontSize=`"11`" Foreground=`"$($m.Fg)`" Margin=`"0,3,0,0`"/><TextBlock Grid.Column=`"1`" Text=`"$(Esc $_)`" FontSize=`"12.5`" Foreground=`"#C8C8CD`" TextWrapping=`"Wrap`" Margin=`"10,0,0,0`"/></Grid>" }) -join ''
        $border = if ($on) { $m.Color } else { '#232326' }; $bt = if ($on) { 2 } else { 1 }
        $style = 'Ghost'; $btn = if ($on) { 'Modo activo' } else { 'Activar' }
        $chipVis = if ($on) { 'Visible' } else { 'Collapsed' }
        $card = New-El @"
<Border {NS} CornerRadius="10" Background="#131315" BorderBrush="$border" BorderThickness="$bt" Padding="20" Margin="0,0,12,12">
 <DockPanel>
  <Button x:Name="Go" DockPanel.Dock="Bottom" Style="{DynamicResource $style}" Content="$btn" Margin="0,18,0,0"/>
  <StackPanel>
   <Grid>
    <Border Width="46" Height="46" CornerRadius="6" Background="$($m.Soft)" HorizontalAlignment="Left"><TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="$($m.Glyph)" FontSize="20" Foreground="$($m.Fg)" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
    <Border CornerRadius="4" Background="$($m.Soft)" Padding="8,2" HorizontalAlignment="Right" VerticalAlignment="Top" Visibility="$chipVis"><TextBlock Text="ACTIVO" FontSize="10.5" FontWeight="SemiBold" Foreground="$($m.Fg)"/></Border>
   </Grid>
   <TextBlock Text="$(Esc $m.Name)" FontSize="18" FontWeight="SemiBold" Foreground="White" Margin="0,14,0,0"/>
   <TextBlock Text="$(Esc $m.Desc)" FontSize="12.5" Foreground="#8E8E95" TextWrapping="Wrap" Margin="0,4,0,6"/>
   $items
  </StackPanel>
 </DockPanel>
</Border>
"@
        $go = $card.FindName('Go'); $go.Tag = $id; if ($on) { $go.IsEnabled = $false }
        $go.Add_Click({ param($s, $e) Invoke-ModeUI $s.Tag })
        [void]$ug.Children.Add($card)
    }
    [void]$sp.Children.Add($ug)
    $auto = New-El @"
<Border {NS} CornerRadius="8" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="20,16" Margin="0,16,12,0">
 <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
  <Border Width="42" Height="42" CornerRadius="6" Background="#1C1C1F" VerticalAlignment="Top"><TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="&#xE945;" FontSize="17" Foreground="#A0A0A7" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
  <StackPanel Grid.Column="1" Margin="16,0,20,0">
   <TextBlock Text="Cambio automático" FontSize="15" FontWeight="SemiBold" Foreground="#EDEDEF"/>
   <TextBlock Text="Al desenchufar el cargador pasa a Ahorro de batería y, al volver a enchufarlo, recupera el modo que tenías. También mantiene tu modo después de reiniciar." FontSize="12.5" Foreground="#8E8E95" TextWrapping="Wrap" Margin="0,4,0,0"/>
  </StackPanel>
  <CheckBox x:Name="AutoTg" Grid.Column="2" Style="{DynamicResource Toggle}" VerticalAlignment="Center"/>
 </Grid>
</Border>
"@
    $tg = $auto.FindName('AutoTg'); $tg.IsChecked = (Test-AutoMode)
    $tg.Add_Checked({ try { Set-AutoMode $true; Log '✓ Cambio automático de modo activado' } catch { Log "✗ Cambio automático: $($_.Exception.Message)" } })
    $tg.Add_Unchecked({ try { Set-AutoMode $false; Log '↺ Cambio automático de modo desactivado' } catch { Log "✗ Cambio automático: $($_.Exception.Message)" } })
    if (-not $prof -or $prof.Type -eq 'portatil' -or (Test-AutoMode)) { [void]$sp.Children.Add($auto) }   # en sobremesa no hay cargador que desenchufar
    $watch = New-El @"
<Border {NS} CornerRadius="8" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="20,16" Margin="0,10,12,0">
 <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
  <Border Width="42" Height="42" CornerRadius="6" Background="#1C1C1F" VerticalAlignment="Top"><TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="&#xE7FC;" FontSize="17" Foreground="#A0A0A7" HorizontalAlignment="Center" VerticalAlignment="Center"/></Border>
  <StackPanel Grid.Column="1" Margin="16,0,20,0">
   <TextBlock Text="Modo Juego automático al abrir un juego" FontSize="15" FontWeight="SemiBold" Foreground="#EDEDEF"/>
   <TextBlock Text="En cuanto abres uno de tus juegos se activa el Modo Juego, y al cerrarlo vuelve solo al modo que tenías. Funciona en segundo plano con un consumo mínimo." FontSize="12.5" Foreground="#8E8E95" TextWrapping="Wrap" Margin="0,4,0,0"/>
  </StackPanel>
  <CheckBox x:Name="WatchTg" Grid.Column="2" Style="{DynamicResource Toggle}" VerticalAlignment="Center"/>
 </Grid>
</Border>
"@
    $wt = $watch.FindName('WatchTg'); $wt.IsChecked = (Test-GameWatch)
    $wt.Add_Checked({ try { Set-GameWatch $true; Log '✓ Modo Juego automático activado'; Show-AppToast 'Modo Juego automático activado' } catch { Log "✗ Modo Juego automático: $($_.Exception.Message)" } })
    $wt.Add_Unchecked({ try { Set-GameWatch $false; Log '↺ Modo Juego automático desactivado'; Show-AppToast 'Modo Juego automático desactivado' 'info' } catch { Log "✗ Modo Juego automático: $($_.Exception.Message)" } })
    if ((Test-Gamer $prof) -or (Test-GameWatch)) { [void]$sp.Children.Add($watch) }

    # ---- Programas que se cierran al activar el Modo Juego ----
    $close = New-El @"
<Border {NS} CornerRadius="8" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="20,16" Margin="0,10,12,0">
 <StackPanel>
  <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
   <StackPanel Margin="0,0,20,0">
    <TextBlock Text="Cerrar programas al activar el Modo Juego" FontSize="15" FontWeight="SemiBold" Foreground="#EDEDEF"/>
    <TextBlock Text="Marca los que quieres que se cierren solos para liberar procesador, memoria y red. Los navegadores se cierran como si lo hicieras tú y recuperan sus pestañas al abrirlos." FontSize="12.5" Foreground="#8E8E95" TextWrapping="Wrap" Margin="0,4,0,0"/>
   </StackPanel>
   <Button x:Name="CloseNow" Grid.Column="1" Style="{DynamicResource Ghost}" Content="Cerrar ahora" VerticalAlignment="Top"/>
  </Grid>
  <WrapPanel x:Name="Apps" Margin="0,14,0,0"/>
  <TextBlock x:Name="Running" FontSize="12" Foreground="#82828A" TextWrapping="Wrap" Margin="0,6,0,0"/>
 </StackPanel>
</Border>
"@
    $sel = @(Get-Setting 'closeOnGame' @()); $openNow = @()
    foreach ($k in $CloseApps.Keys) {
        $procs = @(Get-Process -Name $k -ErrorAction SilentlyContinue)
        $mb = [math]::Round((($procs | Measure-Object WorkingSet64 -Sum).Sum) / 1MB)
        if ($procs.Count) { $openNow += "$($CloseApps[$k]) ($(if ($mb -ge 1024) { '{0:0.0} GB' -f ($mb / 1024) } else { "$mb MB" }))" }
        $cb = New-El "<CheckBox {NS} Style=`"{DynamicResource ChipCheck}`" Content=`"$(Esc $CloseApps[$k])$(if ($procs.Count) { '  ·  abierto' })`"/>"
        $cb.Tag = $k; $cb.IsChecked = ($sel -contains $k)
        $cb.Add_Click({ param($s, $e)
            $cur = @(Get-Setting 'closeOnGame' @() | Where-Object { $_ -and $_ -ne $s.Tag }); if ($s.IsChecked) { $cur += $s.Tag }
            Set-Setting 'closeOnGame' @($cur); Log "Modo Juego cerrará: $(if ($cur.Count) { ($cur | ForEach-Object { $CloseApps[$_] }) -join ', ' } else { 'nada' })" })
        [void]$close.FindName('Apps').Children.Add($cb)
    }
    $close.FindName('Running').Text = if ($openNow.Count) { "Abiertos ahora: $($openNow -join '  ·  ')" } else { 'Ahora mismo no hay ninguno abierto.' }
    $close.FindName('CloseNow').Add_Click({ Close-GameNuisances; Show-AppToast 'Programas marcados cerrados'; $script:Sections['modos'] = Build-ModesPanel; $UI.SecHost.Content = $script:Sections['modos'] })
    if (Test-Gamer $prof) { [void]$sp.Children.Add($close) }
    # ---- Descargas en pausa mientras juegas ----
    $dl = New-SettingCard '&#xE896;' 'Pausar descargas mientras juegas' 'Al activar el Modo Juego se pausan Windows Update, la optimización de distribución y OneDrive para que no te quiten ancho de banda ni provoquen picos de ping. Vuelven solas al cambiar de modo o al cerrar el juego. Steam y Epic ya pausan sus descargas durante las partidas.' '<CheckBox x:Name="DlTg" Style="{DynamicResource Toggle}" VerticalAlignment="Center"/>'
    $dl.Margin = '0,10,12,0'
    $dt = $dl.FindName('DlTg'); $dt.IsChecked = [bool](Get-Setting 'pauseDownloads' $true)
    $dt.Add_Click({ param($s, $e) Set-Setting 'pauseDownloads' ([bool]$s.IsChecked); Log "Pausar descargas al jugar: $(if ($s.IsChecked) { 'activado' } else { 'desactivado' })" })
    if (Test-Gamer $prof) { [void]$sp.Children.Add($dl) }
    [void]$sp.Children.Add((New-El "<TextBlock {NS} Text=`"Medal, el Bluetooth, el Modo Juego de Windows y los ajustes de las demás secciones no cambian con los modos. Tus planes de energía no se modifican: el modo solo elige cuál está activo.`" FontSize=`"12`" Foreground=`"#82828A`" TextWrapping=`"Wrap`" Margin=`"2,14,12,0`"/>"))
    return $sp
}
function Invoke-ModeUI($id) {
    $m = $ModeDefs[$id]
    $st = Get-ModeState; $st.autoSwitched = $false; $st.watchActive = $false; Save-ModeState $st
    $inRes = $UI.ResultsView.Visibility -eq 'Visible'
    if ($inRes) {
        $UI.OvLog.Text = ''; $UI.OvTitle.Text = "Activando $($m.Name)..."; $UI.OvSub.Text = 'Tarda unos segundos; la pantalla puede parpadear un momento.'
        $UI.OvSpin.Visibility = 'Visible'; $UI.OvDone.Visibility = 'Collapsed'; $UI.OvButtons.Visibility = 'Collapsed'
        $UI.Overlay.Visibility = 'Visible'; Fade $UI.Overlay; DoEvents
    } else { $UI.WelcomeModeStatus.Text = "Activando $($m.Name)..."; DoEvents }
    $ok = $true
    try { Invoke-Mode $id } catch { $ok = $false; Log "✗ $($_.Exception.Message)" }
    Update-ModeChip; Build-WelcomeModes
    if ($inRes) {
        $script:Sections['modos'] = Build-ModesPanel
        if ($script:CurrentKey -eq 'modos') { $UI.SecHost.Content = $script:Sections['modos'] }
        $UI.OvSpin.Visibility = 'Collapsed'; $UI.OvDone.Visibility = 'Visible'
        $UI.OvDone.Text = [string][char]0xE73E; $UI.OvDone.Foreground = Br $m.Color
        $UI.OvTitle.Text = if ($ok) { "$($m.Name) activado" } else { 'Hecho, con algún aviso' }
        $UI.OvSub.Text = 'Puedes cambiar de modo cuando quieras.'
        $UI.BtnReboot.Visibility = 'Collapsed'; $UI.BtnLater.Content = 'Listo'; $UI.OvButtons.Visibility = 'Visible'
    } else { $UI.WelcomeModeStatus.Text = if ($ok) { "✓ $($m.Name) activado" } else { 'Hecho, con algún aviso (míralo en el Registro)' } }
}
$ModesSectionText = @('Modos', 'Cambia el PC entero de un clic según lo que vayas a hacer. Puedes volver a cualquier modo cuando quieras.')

# ---------- Navegación ----------
function Get-GameCats { @(@($script:Facts.Games) | ForEach-Object { $_.Id }) }
function Get-Categories { @(Get-GameCats) + @('Windows', 'Limpieza', 'Red', 'Inicio') }
$SysNav = @(
    @{ Key = 'Windows'; Label = 'Windows'; Glyph = '&#xE770;' },
    @{ Key = 'Limpieza'; Label = 'Limpieza'; Glyph = '&#xE74D;' },
    @{ Key = 'Red'; Label = 'Red'; Glyph = '&#xE839;' },
    @{ Key = 'Inicio'; Label = 'Inicio de Windows'; Glyph = '&#xE768;' })

function Get-SectionText($key) {
    if ($key -eq 'modos') { return $ModesSectionText }
    if ($key -eq 'monitor') { return @('Rendimiento en vivo', 'Procesador, gráfica, temperatura, memoria y conexión en tiempo real.') }
    if ($key -eq 'ajustes') { return @('Ajustes', 'Seguridad, perfiles para llevar tu configuración a otro PC y datos de la app.') }
    if ($key -eq 'perifericos') { return @('Periféricos', 'Tu ratón, teclado, mandos y audio: marca, software oficial, firmware y test de polling rate.') }
    if ($key -eq 'salud') { return @('Salud del PC', 'BIOS, discos, batería y arranque de Windows, más una reparación del sistema con las herramientas de Microsoft.') }
    if ($key -eq 'benchmark') { return @('Benchmark', 'Mide FPS, estabilidad y latencia con PresentMon de Intel, y compara antes y después de aplicar los ajustes.') }
    if ($key -eq 'actualizaciones') { return @('Actualizaciones', 'El driver de tu gráfica y las actualizaciones de Windows, comprobados en directo cada vez que abres la app.') }
    if ($key -eq 'cache') { return @('Caché y temporales', 'Libera espacio borrando lo que Windows, los drivers y los juegos acumulan y ya no necesitan.') }
    if ($key -eq 'Limpieza') { return @('Limpieza de Windows', 'Quita lo que Windows trae y no necesitas para jugar. Nunca se tocan Xbox, Microsoft Store, Defender, Windows Update ni las funciones de desarrollo (Hyper-V, WSL, Docker).') }
    $f = $script:Facts
    if ($GameDefById.ContainsKey($key)) {
        $g = @($f.Games) | Where-Object { $_.Id -eq $key } | Select-Object -First 1
        $sub = if ($key -eq 'fortnite') { 'Cierra Fortnite antes de aplicar sus ajustes; se guarda una copia de tu configuración original.' } else { "Instalado en $(Split-Path $g.Paths[0])" }
        return @($GameDefById[$key].Name, $sub)
    }
    switch ($key) {
        'resumen'  { @('Resumen', "$($f.Maker) $($f.Model)  ·  $($f.OS)  ·  $(Get-ProfileText (Get-UseProfile))") }
        'Windows'  { @('Windows', ("$($f.OS)  $([char]0xB7)  " + 'Ajustes del sistema que ayudan a todos tus juegos. Tus planes de energía no se modifican.')) }
        'Red'      { @('Red', "$($f.NicDesc)  ·  $($f.NicSpeed)") }
        'Inicio'   { @('Inicio de Windows', 'Programas que arrancan al encender. Medal y Riot Vanguard no aparecen: siguen como siempre.') }
        'registro' { @('Registro', 'Todo lo que ha hecho la app en esta sesión.') }
        'historial' { @('Historial', 'Cada vez que aplicas cambios queda una tanda con fecha. Puedes deshacer una tanda concreta sin tocar las demás.') }
    }
}

function New-NavIcon($n) {
    if ($n.Abbr) {
        $c = if ("$($n.Color)" -match '^#[0-9A-Fa-f]{6}$') { $n.Color.TrimStart('#') } else { '475569' }
        "<Border Width=`"22`" Height=`"22`" CornerRadius=`"4`" Background=`"#4D$c`" BorderBrush=`"#8C$c`" BorderThickness=`"1`" HorizontalAlignment=`"Left`"><TextBlock Text=`"$(Esc $n.Abbr)`" FontSize=`"8`" FontWeight=`"Bold`" Foreground=`"#E4E4E7`" HorizontalAlignment=`"Center`" VerticalAlignment=`"Center`"/></Border>"
    }
    else { "<TextBlock FontFamily=`"Segoe Fluent Icons, Segoe MDL2 Assets`" Text=`"$($n.Glyph)`" FontSize=`"15`" VerticalAlignment=`"Center`" Margin=`"4,0,0,0`"/>" }
}
function Add-NavHeader($text, $top = 14) { [void]$UI.NavPanel.Children.Add((New-El "<TextBlock {NS} Text=`"$text`" FontSize=`"11`" FontWeight=`"SemiBold`" Foreground=`"#82828A`" Margin=`"12,$top,0,6`"/>")) }
function Add-NavItem($n) {
    $cnt = 0
    if ($n.Key -notin @('resumen', 'registro', 'historial')) {
        $cnt = @($script:Tweaks | Where-Object { $_.Category -eq $n.Key -and $_.Tier -eq 'Recomendado' -and -not $_.Applied }).Count
    }
    $vis = if ($cnt -gt 0) { 'Visible' } else { 'Collapsed' }
    $rb = New-El @"
<RadioButton {NS} Style="{DynamicResource Nav}" GroupName="nav">
 <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="34"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
  $(New-NavIcon $n)
  <TextBlock Grid.Column="1" Text="$(Esc $n.Label)" FontSize="14" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
  <Border Grid.Column="2" CornerRadius="4" Background="{DynamicResource AccentSoft}" Padding="8,1" Visibility="$vis" VerticalAlignment="Center"><TextBlock Text="$cnt" Foreground="{DynamicResource AccentBrush}" FontSize="11.5" FontWeight="SemiBold"/></Border>
 </Grid>
</RadioButton>
"@
    $rb.Tag = $n.Key
    $rb.Add_Checked({ param($s, $e) Show-Section $s.Tag })
    [void]$UI.NavPanel.Children.Add($rb); $script:NavButtons[$n.Key] = $rb
}
function Build-Nav {
    $UI.NavPanel.Children.Clear(); $script:NavButtons = @{}
    Add-NavHeader 'PANEL' 8
    Add-NavItem @{ Key = 'resumen'; Label = 'Resumen'; Glyph = '&#xE80F;' }
    Add-NavItem @{ Key = 'monitor'; Label = 'Rendimiento en vivo'; Glyph = '&#xE9D9;' }
    Add-NavItem @{ Key = 'benchmark'; Label = 'Benchmark'; Glyph = '&#xE916;' }
    Add-NavItem @{ Key = 'modos'; Label = 'Modos'; Glyph = '&#xE945;' }
    Add-NavItem @{ Key = 'actualizaciones'; Label = 'Actualizaciones'; Glyph = '&#xE777;' }
    Add-NavItem @{ Key = 'cache'; Label = "Cach$([char]0xE9) y temporales"; Glyph = '&#xEDA2;' }
    Add-NavItem @{ Key = 'perifericos'; Label = "Perif$([char]0xE9)ricos"; Glyph = '&#xE962;' }
    Add-NavItem @{ Key = 'salud'; Label = 'Salud del PC'; Glyph = '&#xE95E;' }
    $gs = @(Get-GameCats)
    if ($gs.Count) {
        Add-NavHeader 'JUEGOS'
        foreach ($id in $gs) { $d = $GameDefById[$id]; Add-NavItem @{ Key = $id; Label = $d.Name; Abbr = $d.Abbr; Color = $d.Color } }
    }
    Add-NavHeader 'SISTEMA'
    foreach ($n in $SysNav) { if ($script:Tweaks | Where-Object Category -eq $n.Key) { Add-NavItem $n } }
    Add-NavItem @{ Key = 'historial'; Label = 'Historial'; Glyph = '&#xE81C;' }
    Add-NavItem @{ Key = 'registro'; Label = 'Registro'; Glyph = '&#xE7C3;' }
    Add-NavItem @{ Key = 'ajustes'; Label = 'Ajustes'; Glyph = '&#xE713;' }
}
function Select-Nav($key) {
    if (-not $script:NavButtons.ContainsKey($key)) { $key = 'resumen' }
    $rb = $script:NavButtons[$key]
    if ($rb.IsChecked) { Show-Section $key } else { $rb.IsChecked = $true }
}
function Show-Section($key) {
    Stop-PollTest
    if ($script:CurrentKey -eq 'monitor' -and $key -ne 'monitor') { Stop-Monitor }
    $script:CurrentKey = $key
    $tx = Get-SectionText $key
    $UI.SecTitle.Text = $tx[0]; $UI.SecSub.Text = $tx[1]
    switch ($key) {
        'registro' { $script:Sections['registro'] = Get-SafeSection 'registro' { Build-LogPanel } }
        'historial' { $script:Sections['historial'] = Get-SafeSection 'historial' { Build-HistoryPanel } }
        'modos'    { $script:Sections['modos'] = Get-SafeSection 'modos' { Build-ModesPanel } }
        'monitor'  { $script:Sections['monitor'] = Get-SafeSection 'monitor' { Build-MonitorPanel } }
        'ajustes'  { $script:Sections['ajustes'] = Get-SafeSection 'ajustes' { Build-SettingsPanel } }
    }
    Set-SectionTools $key
    if ($null -eq $script:Sections[$key]) { $script:Sections[$key] = Get-SafeSection $key { throw "Sección $key no disponible" } }
    $UI.SecHost.Content = $script:Sections[$key]
    $UI.MainScroll.ScrollToTop(); Fade $UI.SecHost; Slide $UI.SecHost
    if ($key -eq 'monitor') { Start-Monitor }
}
function Render-Results($key) {
    $script:Sections = @{}
    foreach ($t in $script:Tweaks) { $t.Toggle = $null }
    Invoke-Safe 'menú lateral' { Build-Nav }
    $script:Sections['resumen'] = Get-SafeSection 'resumen' { Build-Summary }
    $script:Sections['modos'] = Get-SafeSection 'modos' { Build-ModesPanel }
    $script:Sections['actualizaciones'] = Get-SafeSection 'actualizaciones' { Build-UpdatesPanel }
    $script:Sections['cache'] = Get-SafeSection 'cache' { Build-CachePanel }
    $script:Sections['perifericos'] = Get-SafeSection 'perifericos' { Build-PeripheralsPanel }
    $script:Sections['salud'] = Get-SafeSection 'salud' { Build-HealthPanel }
    $script:Sections['benchmark'] = if ($script:BenchPanel -and $script:BenchSync -and $script:BenchSync.State -in @('wait', 'countdown', 'capture', 'analyze')) { $script:BenchPanel } else { ($script:BenchPanel = Get-SafeSection 'benchmark' { Build-BenchPanel }) }
    foreach ($c in (Get-Categories)) { $script:Sections[$c] = Get-SafeSection $c { Build-CategoryPanel $c } }
    Invoke-Safe 'cambios pendientes' { Update-Pending }
    Select-Nav $key
}

# ---------- Cambios pendientes ----------
function Update-Pending {
    $n = 0
    foreach ($t in $script:Tweaks) {
        if (-not $t.Toggle) { continue }
        $on = [bool]$t.Toggle.IsChecked
        if ($on -ne $t.Applied) {
            $n++
            if ($on) { $t.StatusText.Text = '● Se aplicará'; $t.StatusText.Foreground = Br '{DynamicResource AccentBrush}' }
            else { $t.StatusText.Text = '● Se revertirá'; $t.StatusText.Foreground = Br '#E8B23E' }
            $t.Card.BorderBrush = Br '{DynamicResource AccentBrush}'
        } else {
            $t.Card.BorderBrush = Br '#232326'
            if ($t.Applied) { $t.StatusText.Text = $(if ($t.HasBackup) { '✓ Activo' } else { '✓ Ya estaba así' }); $t.StatusText.Foreground = Br '#8E8E95' }
            else { $t.StatusText.Text = 'Desactivado'; $t.StatusText.Foreground = Br '#82828A' }
        }
    }
    $script:PendingCount = $n
    if ($n -gt 0) {
        $UI.PendingText.Text = "$n cambio$(if ($n -ne 1) { 's' }) pendiente$(if ($n -ne 1) { 's' }) de aplicar"
        $UI.PendingDot.Fill = Br '{DynamicResource AccentBrush}'; $UI.BtnApply.IsEnabled = $true; $UI.BtnDiscard.IsEnabled = $true
    } else {
        $UI.PendingText.Text = 'Todo al día  ·  sin cambios pendientes'
        $UI.PendingDot.Fill = Br '#4CC38A'; $UI.BtnApply.IsEnabled = $false; $UI.BtnDiscard.IsEnabled = $false
    }
    if ($script:HeroTitle) {
        $score = Get-Score
        $recPend = @($script:Tweaks | Where-Object { $_.Tier -eq 'Recomendado' -and -not $_.Applied }).Count
        $active = @($script:Tweaks | Where-Object Applied).Count
        $script:HeroTitle.Text = if ($score -ge 90) { 'Tu PC está listo para competir' } elseif ($score -ge 70) { 'Va bien, pero aún puede rendir más' } else { 'Hay bastante margen de mejora' }
        $script:HeroText.Text = "$recPend mejora$(if ($recPend -ne 1) { 's' }) recomendada$(if ($recPend -ne 1) { 's' }) sin aplicar  ·  $active ajustes ya activos"
        $proj = Get-Score -Projected
        $script:HeroProj.Text = if ($n -gt 0 -and $proj -ne $score) { "Con los cambios marcados llegarías a $proj / 100" } else { '' }
        $script:HeroApply.Visibility = $(if ($n -gt 0) { 'Visible' } else { 'Collapsed' })
        $script:HeroApply.Content = "Aplicar $n cambio$(if ($n -ne 1) { 's' })"
    }
    Update-SideStatus
}

# ---------- Historial de cambios ----------
$HistoryFile = Join-Path $DataDir 'historial.json'
function Get-History { try { if (Test-Path $HistoryFile) { return @(Get-Content $HistoryFile -Raw -Encoding UTF8 | ConvertFrom-Json | ForEach-Object { $_ }) } } catch {}; return @() }
function Add-History($label, $items) {
    $arr = @(foreach ($x in $items) { $x })
    if (-not $arr.Count) { return }
    $h = @(Get-History) + @([pscustomobject]@{ Id = [guid]::NewGuid().ToString(); Date = (Get-Date).ToString('yyyy-MM-dd HH:mm'); Label = $label; Items = $arr })
    if ($h.Count -gt 60) { $h = @($h[($h.Count - 60)..($h.Count - 1)]) }
    try { (ConvertTo-Json -InputObject @($h) -Depth 5) | Set-Content -Path $HistoryFile -Encoding UTF8 } catch {}
}
function Build-HistoryPanel {
    $sp = New-Object Windows.Controls.StackPanel
    $hist = @(Get-History); [array]::Reverse($hist)
    if (-not $hist.Count) {
        [void]$sp.Children.Add((New-El "<Border {NS} CornerRadius=`"8`" Background=`"#131315`" BorderBrush=`"#232326`" BorderThickness=`"1`" Padding=`"20,18`"><TextBlock Text=`"Aún no has aplicado ningún cambio desde esta versión. Cada vez que pulses «Aplicar cambios» quedará aquí una tanda con fecha que podrás deshacer por separado.`" FontSize=`"13`" Foreground=`"#8E8E95`" TextWrapping=`"Wrap`"/></Border>"))
        return $sp
    }
    $byId = @{}; foreach ($t in $script:Tweaks) { $byId[$t.Id] = $t }
    foreach ($b in $hist) {
        $items = @($b.Items)
        $undo = @($items | Where-Object { $_.Action -eq 'aplicado' -and $_.Ok -and $byId[$_.Id] -and $byId[$_.Id].Applied -and $byId[$_.Id].HasBackup -and $byId[$_.Id].Toggle -and $byId[$_.Id].Toggle.IsEnabled })
        $d = try { [datetime]::ParseExact("$($b.Date)", 'yyyy-MM-dd HH:mm', $null).ToString('dd/MM/yyyy · HH:mm') } catch { "$($b.Date)" }
        $rows = ($items | ForEach-Object {
            $g = if (-not $_.Ok) { '&#xE711;' } else { switch ($_.Action) { 'aplicado' { '&#xE73E;' } 'restaurado' { '&#xE7A7;' } default { '&#xE946;' } } }
            $c = if (-not $_.Ok) { '#EF6F6F' } elseif ($_.Action -eq 'aplicado') { '{DynamicResource AccentBrush}' } else { '#8E8E95' }
            "<StackPanel Orientation=`"Horizontal`" Margin=`"0,3`"><TextBlock FontFamily=`"Segoe Fluent Icons, Segoe MDL2 Assets`" Text=`"$g`" FontSize=`"11`" Foreground=`"$c`" Width=`"20`" VerticalAlignment=`"Center`"/><TextBlock Text=`"$(Esc $_.Name)$(if (-not $_.Ok) { '  (falló)' })`" FontSize=`"12.5`" Foreground=`"#C8C8CD`"/></StackPanel>" }) -join ''
        $card = New-El @"
<Border {NS} CornerRadius="8" Background="#131315" BorderBrush="#232326" BorderThickness="1" Padding="20,16" Margin="0,0,0,10">
 <StackPanel>
  <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
   <StackPanel><TextBlock Text="$(Esc $d)" FontSize="15" FontWeight="SemiBold" Foreground="#EDEDEF"/><TextBlock Text="$(Esc $b.Label)  ·  $($items.Count) cambio$(if ($items.Count -ne 1) { 's' })" FontSize="12.5" Foreground="#8E8E95" Margin="0,2,0,0"/></StackPanel>
   <Button x:Name="U" Grid.Column="1" Style="{DynamicResource Ghost}" Content="Deshacer esta tanda" VerticalAlignment="Top"/>
  </Grid>
  <StackPanel Margin="0,10,0,0">$rows</StackPanel>
 </StackPanel>
</Border>
"@
        $u = $card.FindName('U'); $u.Tag = @($undo | ForEach-Object { $_.Id }); $u.IsEnabled = [bool]$undo.Count
        $u.ToolTip = if ($undo.Count) { $(if ($undo.Count -eq 1) { 'Devuelve a su valor anterior el ajuste de esta tanda que sigue activo' } else { "Devuelve a su valor anterior los $($undo.Count) ajustes de esta tanda que siguen activos" }) } else { 'No queda nada activo de esta tanda que se pueda deshacer' }
        $u.Add_Click({ param($s, $e)
            foreach ($id in @($s.Tag)) { $t = $script:Tweaks | Where-Object { $_.Id -eq $id } | Select-Object -First 1; if ($t -and $t.Toggle -and $t.Toggle.IsEnabled) { $t.Toggle.IsChecked = $false } }
            $script:ApplyLabel = 'Deshacer una tanda anterior'; Update-Pending; Invoke-Apply })
        [void]$sp.Children.Add($card)
    }
    return $sp
}

# ---------- Aplicar ----------
function Invoke-Apply {
    $changes = @($script:Tweaks | Where-Object { $_.Toggle -and $_.Toggle.IsEnabled -and ([bool]$_.Toggle.IsChecked -ne $_.Applied) })
    $label = if ($script:ApplyLabel) { $script:ApplyLabel } else { 'Cambios aplicados' }; $script:ApplyLabel = $null
    if ($changes.Count -eq 0) { return }
    $hItems = New-Object System.Collections.Generic.List[object]
    $UI.OvLog.Text = ''; $UI.OvTitle.Text = 'Aplicando cambios...'; $UI.OvSub.Text = 'No cierres la app, tarda unos segundos.'
    $UI.OvSpin.Visibility = 'Visible'; $UI.OvDone.Visibility = 'Collapsed'; $UI.OvButtons.Visibility = 'Collapsed'
    $UI.Overlay.Visibility = 'Visible'; Fade $UI.Overlay; DoEvents
    $reboot = $false; $fail = 0
    if ((@($changes | Where-Object { $_.Toggle.IsChecked }).Count -gt 0) -and [bool](Get-Setting 'restorePoint' $true)) {
        Log 'Creando punto de restauración...'
        try {
            Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
            Checkpoint-Computer -Description 'Miki Tweaks' -RestorePointType MODIFY_SETTINGS -WarningAction SilentlyContinue
            Log '✓ Punto de restauración (Windows crea como máximo uno cada 24 h)'
        } catch { Log "· No se pudo crear el punto de restauración: $($_.Exception.Message)" }
    }
    foreach ($t in $changes) {
        $on = [bool]$t.Toggle.IsChecked
        $nm = if ($GameDefById.ContainsKey("$($t.Category)")) { "$($GameDefById[$t.Category].Name): $($t.Name)" } else { $t.Name }
        try {
            if ($on) { [void](& $t.Apply $t); Log "✓ $($t.Name)"; $hItems.Add(@{ Id = $t.Id; Name = $nm; Action = 'aplicado'; Ok = $true }) }
            else {
                $res = @(& $t.Revert $t)
                if ($res.Count -and $res[-1] -eq $true) { Log "↺ $($t.Name): restaurado"; $hItems.Add(@{ Id = $t.Id; Name = $nm; Action = 'restaurado'; Ok = $true }) } else { Log "· $($t.Name): no había copia, se deja igual" }
            }
            if ($t.Reboot) { $reboot = $true }
        } catch { Log "✗ $($t.Name): $($_.Exception.Message)"; $fail++; $hItems.Add(@{ Id = $t.Id; Name = $nm; Action = $(if ($on) { 'aplicado' } else { 'restaurado' }); Ok = $false }) }
    }
    Add-History $label $hItems.ToArray()
    foreach ($t in $script:Tweaks) { Test-Tweak $t }
    $script:Diags = Build-Diagnostics $script:Facts
    $script:PreselectRecommended = $false
    Render-Results $script:CurrentKey
    Animate-Score
    $UI.OvSpin.Visibility = 'Collapsed'; $UI.OvDone.Visibility = 'Visible'
    if ($fail) { $UI.OvDone.Text = [string][char]0xE7BA; $UI.OvDone.Foreground = Br '#E8B23E'; $UI.OvTitle.Text = 'Hecho, con algún aviso' }
    else { $UI.OvDone.Text = [string][char]0xE73E; $UI.OvDone.Foreground = Br '#4CC38A'; $UI.OvTitle.Text = 'Cambios aplicados' }
    $UI.OvSub.Text = if ($reboot) { 'Algunos cambios necesitan reiniciar el PC para surtir efecto.' } else { 'Ya puedes jugar. Si mediste antes, vuelve a medir en Benchmark para ver la mejora.' }
    $UI.BtnReboot.Visibility = $(if ($reboot) { 'Visible' } else { 'Collapsed' })
    $UI.BtnLater.Content = if ($reboot) { 'Más tarde' } else { 'Listo' }
    $UI.OvButtons.Visibility = 'Visible'
}

# ---------- Escaneo ----------
$script:ScanTimer = New-Object Windows.Threading.DispatcherTimer
$script:ScanTimer.Interval = [TimeSpan]::FromMilliseconds(30)
function Start-Scan {
    if ($script:ScanPs) { return }   # ya hay un escaneo en marcha
    Show-View 'ScanView'
    $UI.ScanSteps.Children.Clear(); $UI.ScanPct.Text = '0%'; $UI.ScanBar.Width = 0; $UI.ScanStep.Text = 'Preparando...'
    $script:Sync = [hashtable]::Synchronized(@{ Progress = 0; Step = ''; Steps = [Collections.ArrayList]::Synchronized((New-Object Collections.ArrayList)); Done = $false; Facts = $null; Error = $null; GameDefs = $GameDefs })
    $script:ScanPs = [powershell]::Create()
    [void]$script:ScanPs.AddScript($ScanScript).AddArgument($script:Sync)
    $script:ScanHandle = $script:ScanPs.BeginInvoke()
    $script:Shown = 0.0; $script:StepRows = New-Object System.Collections.Generic.List[object]; $script:Finishing = $false
    Log 'Escaneo iniciado'
    $script:ScanTimer.Start()
}
function Set-RowDone($row) { $row.G.Text = [string][char]0xE73E; $row.G.Foreground = Br '#4CC38A'; $row.T.Foreground = Br '#8E8E95' }
$script:ScanTimer.Add_Tick({
    $s = $script:Sync
    $target = if ($s.Done) { 100.0 } else { [double]$s.Progress }
    $script:Shown += ($target - $script:Shown) * 0.1
    if ($target -ge 100 -and $script:Shown -gt 99.2) { $script:Shown = 100 }
    $UI.ScanPct.Text = "$([int][math]::Floor($script:Shown))%"
    $UI.ScanBar.Width = 620 * $script:Shown / 100
    while ($script:StepRows.Count -lt $s.Steps.Count) {
        $idx = $script:StepRows.Count
        if ($idx -gt 0) { Set-RowDone $script:StepRows[$idx - 1] }
        $row = New-El "<StackPanel {NS} Orientation=`"Horizontal`" Margin=`"0,3`"><TextBlock x:Name=`"G`" FontFamily=`"Segoe Fluent Icons, Segoe MDL2 Assets`" Text=`"&#xE895;`" FontSize=`"11`" Foreground=`"{DynamicResource AccentBrush}`" Width=`"18`" VerticalAlignment=`"Center`"/><TextBlock x:Name=`"T`" Text=`"$(Esc $s.Steps[$idx])`" FontSize=`"13`" Foreground=`"#EDEDEF`" Margin=`"6,0,0,0`"/></StackPanel>"
        [void]$UI.ScanSteps.Children.Add($row); Fade $row
        $script:StepRows.Add(@{ G = $row.FindName('G'); T = $row.FindName('T') })
        $UI.ScanStep.Text = "$($s.Steps[$idx])..."
    }
    if ($s.Done -and $script:Shown -ge 100 -and -not $script:Finishing) {
        $script:Finishing = $true; $script:ScanTimer.Stop()
        try { [void]$script:ScanPs.EndInvoke($script:ScanHandle) } catch {}
        $script:ScanPs.Dispose(); $script:ScanPs = $null
        Finish-Scan
    }
})
function Finish-Scan {
    $script:SafeErrors.Clear()
    $script:Facts = $script:Sync.Facts
    if (-not $script:Facts) { $script:Facts = @{} }
    if ($script:Sync.Error) { Log "Aviso del escáner: $($script:Sync.Error)"; Write-CrashLog $script:Sync.Error 'escáner' }
    Invoke-Safe 'catálogo de ajustes' { Build-Catalog $script:Facts }
    Invoke-Safe 'perfil de uso' { Apply-UseProfileToCatalog }
    if ($null -eq $script:Tweaks) { $script:Tweaks = New-Object System.Collections.Generic.List[object] }
    foreach ($t in $script:Tweaks) { Invoke-Safe "comprobar $($t.Id)" { Test-Tweak $t }; DoEvents }
    if ($script:StepRows.Count) { Set-RowDone $script:StepRows[$script:StepRows.Count - 1] }
    $UI.ScanStep.Text = 'Escaneo completado'
    $script:Diags = @()
    Invoke-Safe 'diagnóstico' { $script:Diags = @(Build-Diagnostics $script:Facts) }
    $script:PreselectRecommended = $true
    Log "Escaneo completado: $($script:Tweaks.Count) ajustes analizados"
    Start-Sleep -Milliseconds 350
    $script:ScoreCur = 0.0
    Invoke-Safe 'mostrar resultados' { Render-Results 'resumen' }
    Show-View 'ResultsView'
    Invoke-Safe 'puntuación' { Animate-Score }
    if ($script:SafeErrors.Count) {
        Log "Partes que fallaron en este PC: $($script:SafeErrors -join ', ')"
        try { Show-AppToast 'Parte del análisis ha fallado en este PC. Puedes copiar el informe en Ajustes → Carpeta de datos.' 'warn' } catch {}
    }
}

# ---------- Perfil de uso: cómo cambia las recomendaciones ----------
function Apply-UseProfileToCatalog {
    $p = Get-UseProfile; if (-not $p) { return }
    $gameIds = @($GameDefById.Keys)
    $gamingWin = @('win_gamemode', 'win_mmcss', 'win_timer', 'win_hags', 'win_gamedvr', 'win_mouse', 'win_windowedopt', 'win_hvci')
    foreach ($t in $script:Tweaks) {
        if (-not (Test-Gamer $p) -and $t.Tier -eq 'Recomendado' -and ($gameIds -contains $t.Category -or $gamingWin -contains $t.Id)) {
            $t.Tier = 'Opcional'; $t.Why = "$($t.Why)  ·  opcional: en tu perfil no juegas"
        }
        if (@($p.Uses) -contains 'creacion' -and $t.Id -eq 'win_powerthrottle') {
            $t.Tier = 'Recomendado'; $t.Why = 'Tu perfil: creas contenido (OBS, editores y renders no se frenan en segundo plano)'
        }
        if (($p.Priority -eq 'silencio' -or ($p.Type -eq 'portatil' -and $p.Battery -eq 'bateria')) -and $t.Id -eq 'fn_fpscap') {
            $t.Tier = 'Recomendado'; $t.Why = "$($t.Why)  ·  tu perfil prioriza $(if ($p.Type -eq 'portatil') { 'batería y temperatura' } else { 'silencio y temperatura' })"
        }
    }
}

# ---------- Asistente: tipo de equipo y uso ----------
function New-OptionCard($glyph, $title, $desc, [bool]$sel, $tag, $badge = '') {
    $bb = if ($sel) { '{DynamicResource AccentBrush}' } else { '#232326' }; $bg = if ($sel) { '{DynamicResource AccentSoft}' } else { '#131315' }
    $ic = if ($sel) { '{DynamicResource AccentBrush}' } else { '#A0A0A7' }
    $chk = if ($sel) { 'Visible' } else { 'Collapsed' }
    $bd = if ($badge) { "<Border CornerRadius=`"4`" Background=`"#1C1C1F`" Padding=`"6,1`" Margin=`"8,0,0,0`" VerticalAlignment=`"Center`"><TextBlock Text=`"$(Esc $badge)`" FontSize=`"11`" Foreground=`"#A0A0A7`"/></Border>" } else { '' }
    $c = New-El @"
<Border {NS} CornerRadius="8" Background="$bg" BorderBrush="$bb" BorderThickness="1" Padding="16,14" Margin="0,0,10,10" Cursor="Hand">
 <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
  <TextBlock FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="$glyph" FontSize="20" Foreground="$ic" VerticalAlignment="Top" Margin="0,1,14,0"/>
  <StackPanel Grid.Column="1">
   <StackPanel Orientation="Horizontal"><TextBlock Text="$(Esc $title)" FontSize="14.5" FontWeight="SemiBold" Foreground="#EDEDEF"/>$bd</StackPanel>
   <TextBlock Text="$(Esc $desc)" FontSize="12.5" Foreground="#8E8E95" TextWrapping="Wrap" Margin="0,3,0,0"/>
  </StackPanel>
  <TextBlock Grid.Column="2" FontFamily="Segoe Fluent Icons, Segoe MDL2 Assets" Text="&#xE73E;" FontSize="13" Foreground="{DynamicResource AccentBrush}" VerticalAlignment="Top" Margin="10,2,0,0" Visibility="$chk"/>
 </Grid>
</Border>
"@
    $c.Tag = $tag
    $c.Add_MouseEnter({ param($s, $e) if (-not $s.Tag.Sel) { $s.Background = Br '#17171A' } }); $c.Add_MouseLeave({ param($s, $e) if (-not $s.Tag.Sel) { $s.Background = Br '#131315' } })
    $c.Tag = @{ Value = $tag; Sel = $sel }
    return $c
}
function Show-Setup([string]$From = 'welcome') {
    $p = Get-UseProfile
    $det = if (Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select-Object -First 1) { 'portatil' } else { 'sobremesa' }
    $script:Wiz = @{ Step = 0; From = $From; Detected = $det; Type = $(if ($p) { $p.Type } else { $det }); Uses = @(if ($p) { $p.Uses })
        Priority = $(if ($p -and $p.Priority) { $p.Priority } else { 'equilibrio' }); Battery = $(if ($p -and $p.Battery) { $p.Battery } else { 'enchufado' })
        AutoBattery = $null; AutoGame = $null; Activate = $true }
    Show-View 'SetupView'; Render-SetupStep
}
function Get-SetupSteps { $s = @('tipo', 'uso', 'prioridad'); if ($script:Wiz.Type -eq 'portatil') { $s += 'bateria' }; $s += 'resumen'; return $s }
function Get-WizProfile { $w = $script:Wiz; return @{ Type = $w.Type; Uses = @($w.Uses); Priority = $w.Priority; Battery = $(if ($w.Type -eq 'portatil') { $w.Battery } else { '' }) } }
function Get-WizRecommendedMode {
    $p = Get-WizProfile
    if ($p.Type -eq 'sobremesa' -and $p.Priority -eq 'silencio') { return 'silencio' }
    $onlyGames = -not (@($p.Uses) | Where-Object { $_ -notin @('competitivo', 'casual') })
    if ($onlyGames -and $p.Priority -eq 'rendimiento' -and -not ($p.Type -eq 'portatil' -and $p.Battery -eq 'bateria')) { return 'juego' }
    return 'trabajo'
}
function Render-SetupStep {
    $w = $script:Wiz; $steps = @(Get-SetupSteps); if ($w.Step -ge $steps.Count) { $w.Step = $steps.Count - 1 }
    $key = $steps[$w.Step]; $h = $UI.SetupHost; $h.Children.Clear()
    $lap = ($w.Type -eq 'portatil')
    [void]$h.Children.Add((New-El "<TextBlock {NS} Text=`"Paso $($w.Step + 1) de $($steps.Count)  ·  Tu perfil de uso`" FontSize=`"12.5`" Foreground=`"#8E8E95`"/>"))
    $bar = New-El "<Border {NS} Height=`"2`" Background=`"#1F1F23`" Margin=`"0,10,0,24`"><Border HorizontalAlignment=`"Left`" Width=`"$([int](640 * ($w.Step + 1) / $steps.Count))`" Background=`"{DynamicResource AccentBrush}`"/></Border>"
    [void]$h.Children.Add($bar)
    $q = switch ($key) {
        'tipo'      { @('¿Qué ordenador es?', "Los modos cambian bastante: un portátil cuida la batería y la temperatura; un sobremesa puede ir siempre a tope o en silencio. Hemos detectado un $(if ($w.Detected -eq 'portatil') { 'portátil' } else { 'sobremesa' }).") }
        'uso'       { @('¿Para qué lo usas?', 'Marca todo lo que hagas a menudo. Con esto decidimos qué modos tienes y qué ajustes te recomendamos.') }
        'prioridad' { @('¿Qué prefieres en el día a día?', 'Cuando no estás jugando ni haciendo nada pesado.') }
        'bateria'   { @('¿Cómo lo usas normalmente?', 'Así sabemos si cambiar de modo solo al desenchufarlo y cuánto cuidar la batería.') }
        'resumen'   { @('Tu configuración', (Get-ProfileText (Get-WizProfile)) + '.') }
    }
    [void]$h.Children.Add((New-El "<TextBlock {NS} Text=`"$(Esc $q[0])`" FontSize=`"26`" FontWeight=`"SemiBold`" Foreground=`"#EDEDEF`"/>"))
    [void]$h.Children.Add((New-El "<TextBlock {NS} Text=`"$(Esc $q[1])`" FontSize=`"13.5`" Foreground=`"#9A9AA1`" TextWrapping=`"Wrap`" LineHeight=`"21`" Margin=`"0,8,0,22`"/>"))
    $grid = New-Object Windows.Controls.Primitives.UniformGrid
    $opts = @()
    switch ($key) {
        'tipo' {
            $grid.Columns = 2
            $opts += , @('&#xE7F8;', 'Portátil', 'Con batería. Modos para jugar enchufado, trabajar y alargar la batería.', 'portatil')
            $opts += , @('&#xE977;', 'Sobremesa', 'Siempre enchufado. Modos para rendir al máximo o ir en silencio.', 'sobremesa')
        }
        'uso' {
            $grid.Columns = 2
            $opts += , @('&#xE7FC;', 'Jugar en competitivo', 'Fortnite, VALORANT, CS2... Máximos FPS y mínima latencia.', 'competitivo')
            $opts += , @('&#xE7FC;', 'Jugar por diversión', 'Juegos con amigos o de un jugador, sin obsesionarse con los FPS.', 'casual')
            $opts += , @('&#xE821;', 'Trabajar o estudiar', 'Office, navegador, videollamadas, clases.', 'trabajo')
            $opts += , @('&#xE714;', 'Crear contenido', 'Editar vídeo o fotos, hacer streaming, grabar.', 'creacion')
            $opts += , @('&#xE8B2;', 'Navegar y ver series', 'Internet, YouTube, Netflix y poco más.', 'basico')
        }
        'prioridad' {
            $grid.Columns = 1
            $opts += , @('&#xE945;', 'Máximo rendimiento', 'Que todo vaya lo más rápido posible, aunque gaste más y haga más ruido.', 'rendimiento')
            $opts += , @('&#xE9D9;', 'Equilibrio', 'Rendimiento cuando hace falta y tranquilo el resto del tiempo.', 'equilibrio')
            $opts += , @('&#xE708;', $(if ($lap) { 'Batería y temperatura' } else { 'Silencio y temperatura' }), $(if ($lap) { 'Más horas sin cargador y un portátil más fresco.' } else { 'Ventiladores tranquilos y el PC más fresco.' }), 'silencio')
        }
        'bateria' {
            $grid.Columns = 2
            $opts += , @('&#xE83E;', 'Casi siempre enchufado', 'En la mesa, con el cargador puesto.', 'enchufado')
            $opts += , @('&#xE859;', 'A menudo con batería', 'Clase, trabajo, sofá... lo desenchufas cada día.', 'bateria')
        }
    }
    foreach ($o in $opts) {
        $sel = switch ($key) { 'tipo' { $w.Type -eq $o[3] } 'uso' { @($w.Uses) -contains $o[3] } 'prioridad' { $w.Priority -eq $o[3] } 'bateria' { $w.Battery -eq $o[3] } }
        $badge = if ($key -eq 'tipo' -and $o[3] -eq $w.Detected) { 'Detectado' } else { '' }
        $card = New-OptionCard $o[0] $o[1] $o[2] ([bool]$sel) $o[3] $badge
        $card.Tag.Key = $key
        $card.Add_MouseLeftButtonUp({ param($s, $e)
            $w = $script:Wiz; $v = $s.Tag.Value
            switch ($s.Tag.Key) {
                'tipo' { $w.Type = $v } 'prioridad' { $w.Priority = $v } 'bateria' { $w.Battery = $v }
                'uso' { if (@($w.Uses) -contains $v) { $w.Uses = @($w.Uses | Where-Object { $_ -ne $v }) } else { $w.Uses = @($w.Uses) + $v } }
            }
            $w.AutoBattery = $null; $w.AutoGame = $null
            Render-SetupStep })
        [void]$grid.Children.Add($card)
    }
    if ($opts.Count) { [void]$h.Children.Add($grid) }

    if ($key -eq 'resumen') {
        $p = Get-WizProfile
        # Modos que tendrá (misma lógica que Update-ModesForProfile)
        $mods = @(); if (Test-Gamer $p) { $mods += 'Modo Juego' }; if (@($p.Uses) -contains 'creacion') { $mods += 'Modo Creación' }
        $mods += $(if (@($p.Uses) -contains 'trabajo') { 'Modo Trabajo' } else { 'Modo Diario' }); $mods += $(if ($lap) { 'Ahorro de batería' } else { 'Modo Silencio' })
        $chips = ($mods | ForEach-Object { "<Border CornerRadius=`"6`" Background=`"#1A1A1D`" BorderBrush=`"#2A2A2E`" BorderThickness=`"1`" Padding=`"10,5`" Margin=`"0,0,6,6`"><TextBlock Text=`"$(Esc $_)`" FontSize=`"12.5`" Foreground=`"#EDEDEF`"/></Border>" }) -join ''
        $notes = @()
        if (-not (Test-Gamer $p)) { $notes += 'Los ajustes de juegos pasan a opcionales y desaparece el Modo Juego.' }
        if (@($p.Uses) -contains 'creacion') { $notes += 'Nuevo Modo Creación, y Windows deja de frenar OBS y los editores en segundo plano.' }
        if (-not $lap) { $notes += 'Sin ahorro de batería: en su lugar tienes un Modo Silencio.' }
        if ($p.Priority -eq 'silencio' -or ($lap -and $p.Battery -eq 'bateria')) { $notes += 'Se recomienda limitar los FPS para que el equipo vaya más fresco.' }
        if ($p.Type -eq 'sobremesa' -and $p.Priority -eq 'rendimiento') { $notes += 'El modo del día a día también usa el plan de alto rendimiento.' }
        $noteX = ($notes | ForEach-Object { "<StackPanel Orientation=`"Horizontal`" Margin=`"0,3`"><TextBlock FontFamily=`"Segoe Fluent Icons, Segoe MDL2 Assets`" Text=`"&#xE73E;`" FontSize=`"11`" Foreground=`"{DynamicResource AccentBrush}`" Width=`"20`" VerticalAlignment=`"Center`"/><TextBlock Text=`"$(Esc $_)`" FontSize=`"12.5`" Foreground=`"#C8C8CD`" TextWrapping=`"Wrap`" MaxWidth=`"580`"/></StackPanel>" }) -join ''
        $noteBlock = ''
        if ($noteX) { $noteBlock = '<TextBlock Text="Qué cambia" FontSize="12.5" Foreground="#82828A" Margin="0,14,0,6"/>' + $noteX }
        [void]$h.Children.Add((New-El ('<StackPanel {NS}><TextBlock Text="Tus modos" FontSize="12.5" Foreground="#82828A" Margin="0,0,0,8"/><WrapPanel>' + $chips + '</WrapPanel>' + $noteBlock + '<TextBlock Text="Automático" FontSize="12.5" Foreground="#82828A" Margin="0,18,0,4"/></StackPanel>')))
        if ($null -eq $w.AutoBattery) { $w.AutoBattery = $lap -and (($p.Battery -eq 'bateria') -or (Test-AutoMode)) }
        if ($null -eq $w.AutoGame) { $w.AutoGame = (@($p.Uses) -contains 'competitivo') -or (Test-GameWatch) }
        $rec = Get-WizRecommendedMode
        $rows = @()
        if ($lap) { $rows += , @('AutoBattery', 'Pasar a Ahorro de batería al desenchufar el cargador', 'Y volver a tu modo al enchufarlo.') }
        if (Test-Gamer $p) { $rows += , @('AutoGame', 'Activar el Modo Juego al abrir un juego', 'Al cerrarlo vuelve solo al modo que tenías.') }
        $recName = if ($rec -eq 'trabajo') { if (@($p.Uses) -contains 'trabajo') { 'Modo Trabajo' } else { 'Modo Diario' } } else { $ModeDefs[$rec].Name }
        $rows += , @('Activate', "Activar ahora el $recName", 'El modo que mejor encaja con tu perfil para el día a día.')
        foreach ($r in $rows) {
            $row = New-El "<Grid {NS} Margin=`"0,6`"><Grid.ColumnDefinitions><ColumnDefinition Width=`"*`"/><ColumnDefinition Width=`"Auto`"/></Grid.ColumnDefinitions><StackPanel><TextBlock Text=`"$(Esc $r[1])`" FontSize=`"13.5`" Foreground=`"#EDEDEF`"/><TextBlock Text=`"$(Esc $r[2])`" FontSize=`"12`" Foreground=`"#8E8E95`" Margin=`"0,2,0,0`"/></StackPanel><CheckBox x:Name=`"Tg`" Grid.Column=`"1`" Style=`"{DynamicResource Toggle}`" VerticalAlignment=`"Center`"/></Grid>"
            $tg = $row.FindName('Tg'); $tg.Tag = $r[0]; $tg.IsChecked = [bool]$w[$r[0]]
            $tg.Add_Checked({ param($s, $e) $script:Wiz[$s.Tag] = $true }); $tg.Add_Unchecked({ param($s, $e) $script:Wiz[$s.Tag] = $false })
            [void]$h.Children.Add($row)
        }
    }

    # Botones
    $first = ($w.Step -eq 0); $last = ($key -eq 'resumen')
    $backTxt = if (-not $first) { 'Atrás' } elseif (Get-UseProfile) { 'Cancelar' } else { 'Ahora no' }
    $nav = New-El @"
<Grid {NS} Margin="0,18,0,0"><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
 <Button x:Name="Back" Style="{DynamicResource Ghost}" Content="$backTxt"/>
 <TextBlock x:Name="Hint" Grid.Column="1" FontSize="12" Foreground="#82828A" VerticalAlignment="Center" HorizontalAlignment="Right" Margin="0,0,14,0"/>
 <Button x:Name="Next" Grid.Column="2" Style="{DynamicResource Primary}" Content="$(if ($last) { 'Guardar y empezar' } else { 'Siguiente' })" Padding="20,10"/>
</Grid>
"@
    $nb = $nav.FindName('Next')
    if ($key -eq 'uso' -and -not @($w.Uses).Count) { $nb.IsEnabled = $false; $nav.FindName('Hint').Text = 'Marca al menos una opción' }
    $nav.FindName('Back').Add_Click({ $w = $script:Wiz; if ($w.Step -gt 0) { $w.Step--; Render-SetupStep } else { Exit-Setup } })
    $nb.Add_Click({ $w = $script:Wiz; if (@(Get-SetupSteps)[$w.Step] -eq 'resumen') { Complete-Setup } else { $w.Step++; Render-SetupStep } })
    [void]$h.Children.Add($nav)
    Fade $h
}
function Exit-Setup {
    if ($script:Wiz.From -eq 'ajustes' -and $script:Facts) { Show-View 'ResultsView' } else { Show-View 'WelcomeView' }
}
function Update-WelcomeProfile { $UI.WelcomeProfile.Text = Get-ProfileText (Get-UseProfile) }
function Complete-Setup {
    $w = $script:Wiz; $p = Get-WizProfile
    Set-Setting 'perfil' @{ type = $p.Type; uses = @($p.Uses); priority = $p.Priority; battery = $p.Battery }
    Update-ModesForProfile
    Log "Perfil de uso: $(Get-ProfileText $p) (prioridad: $($p.Priority))"
    $lap = ($p.Type -eq 'portatil')
    try { if ($lap -and $w.AutoBattery) { if (-not (Test-AutoMode)) { Set-AutoMode $true; Log '✓ Cambio automático de modo activado' } } elseif (Test-AutoMode) { Set-AutoMode $false; Log '↺ Cambio automático de modo desactivado' } } catch { Log "✗ Cambio automático: $($_.Exception.Message)" }
    try { if ((Test-Gamer $p) -and $w.AutoGame) { if (-not (Test-GameWatch)) { Set-GameWatch $true; Log '✓ Modo Juego automático activado' } } elseif (Test-GameWatch) { Set-GameWatch $false; Log '↺ Modo Juego automático desactivado' } } catch { Log "✗ Modo Juego automático: $($_.Exception.Message)" }
    if ($w.Activate) { $rec = Get-WizRecommendedMode; try { $st = Get-ModeState; $st.autoSwitched = $false; $st.watchActive = $false; Save-ModeState $st; Invoke-Mode $rec } catch { Log "✗ $($_.Exception.Message)" } }
    Update-ModeChip; Build-WelcomeModes; Update-WelcomeProfile
    Show-AppToast "Perfil guardado: $((Get-ProfileText $p).ToLower())"
    if ($script:Sync -and $script:Sync.Facts) { Finish-Scan } else { Show-View 'WelcomeView' }
}

# ---------- Eventos ----------
$UI.BtnMin.Add_Click({ $window.WindowState = 'Minimized' })
$window.MaxWidth = [Windows.SystemParameters]::WorkArea.Width
$window.MaxHeight = [Windows.SystemParameters]::WorkArea.Height
$UI.BtnMax.Add_Click({ $window.WindowState = $(if ($window.WindowState -eq 'Maximized') { 'Normal' } else { 'Maximized' }) })
$window.Add_StateChanged({ Update-WindowChrome })
$window.Add_KeyDown({ param($s, $e)
    if ($e.Key -eq 'Escape' -and $UI.Overlay.Visibility -eq 'Visible' -and $UI.OvButtons.Visibility -eq 'Visible') { $UI.Overlay.Visibility = 'Collapsed'; $e.Handled = $true }
    elseif ($e.Key -eq 'F5' -and $UI.ResultsView.Visibility -eq 'Visible' -and $UI.Overlay.Visibility -ne 'Visible') { Start-Scan; $e.Handled = $true }
    elseif ($e.Key -eq 'F' -and (([Windows.Input.Keyboard]::Modifiers -band [Windows.Input.ModifierKeys]::Control) -ne 0) -and $UI.SecTools.Visibility -eq 'Visible') { [void]$UI.SecSearch.Focus(); $e.Handled = $true }
})
$UI.BtnClose.Add_Click({ $window.Close() })
$UI.BtnScan.Add_Click({ Start-Scan })
$UI.BtnProfile.Add_Click({ Show-Setup 'welcome' })
$UI.BtnRescan.Add_Click({ Start-Scan })
$UI.BtnApply.Add_Click({ Invoke-Apply })
$UI.BtnDiscard.Add_Click({ foreach ($t in $script:Tweaks) { if ($t.Toggle -and $t.Toggle.IsEnabled) { $t.Toggle.IsChecked = $t.Applied } }; Update-Pending })
$UI.BtnLater.Add_Click({ $UI.Overlay.Visibility = 'Collapsed' })
$UI.BtnReboot.Add_Click({ Log 'Reiniciando el PC...'; Start-Process shutdown.exe -ArgumentList '/r /t 5 /c "Miki Tweaks: reiniciando para aplicar los cambios"' -WindowStyle Hidden; $window.Close() })
$window.Add_Closing({ param($s, $e)
    if ($script:AsyncJobs -and $script:AsyncJobs.Count -gt 0) {
        if ((Get-MsgBox).Invoke('Hay una tarea en marcha (por ejemplo, Windows Update). Si cierras ahora se interrumpe. ¿Cerrar igualmente?', 'Miki Tweaks', 'YesNo', 'Warning') -ne 'Yes') { $e.Cancel = $true; return }
    }
    if ($script:BenchSync) { $script:BenchSync.Cancel = $true }; Stop-PollTest; Stop-Monitor; $script:ScanTimer.Stop(); if ($script:ScanPs) { try { $script:ScanPs.Stop(); $script:ScanPs.Dispose() } catch {} } })

try {
    New-AppIcon
    $img = New-Object Windows.Media.Imaging.BitmapImage
    $img.BeginInit(); $img.CacheOption = 'OnLoad'; $img.UriSource = New-Object Uri (Join-Path $DataDir 'logo.png'); $img.EndInit()
    $window.Icon = $img; $UI.TitleIcon.Source = $img; $UI.BigLogo.Source = $img
} catch {}

Set-Accent (Get-Setting 'accent' 'Lima')
$UI.PcName.Text = $env:COMPUTERNAME
Update-ModeChip; Build-WelcomeModes
$UI.WelcomeGamesText.Text = (@($GameDefs | ForEach-Object { $_.Name }) -join ',  ')
$window.Dispatcher.Add_UnhandledException({ param($s, $e) Write-CrashLog $e.Exception 'interfaz'; $e.Handled = $true; try { Show-AppToast 'Algo ha fallado, pero la app sigue funcionando. Hay un informe en el escritorio.' 'warn' } catch {} })
[AppDomain]::CurrentDomain.Add_UnhandledException({ param($s, $e) Write-CrashLog $e.ExceptionObject 'proceso' })
Update-WelcomeProfile
if ($env:FT_TEST -ne '1') {
    if (-not (Get-UseProfile)) { Show-Setup 'first' }   # primera vez: el asistente antes que nada
    if (Get-UpdateUrl) { try { Start-UpdateCheck -Quiet } catch {} }
    [void]$window.ShowDialog()
}
