# Rediseño de Miki Tweaks 9.0: inicio guiado, menú corto y estilo modernizado

## Contexto
Al abrir Miki Tweaks, alguien nuevo **no sabe qué hacer**: el menú tiene ~20 entradas con el mismo peso. Además el aspecto se ve **anticuado**: muchas cajas con borde, esquinas de 4 px, poca jerarquía. Miki eligió:
- **Inicio guiado + menú de 5 entradas** con pestañas dentro.
- **Mantener oscuro + lima**, pero modernizado.

No se quita ninguna función: solo se reordena y se cambia el aspecto. Todo vive en `MikiTweaks.ps1` (WPF en PowerShell, ~5.650 líneas).

**Anti-objetivos:** perder secciones o atajos que funcionan hoy, romper la traducción al inglés o publicar algo sin probarlo en su PC (la autoactualización lo reparte a todas las copias).

## 1. Menú de 5 entradas con pestañas (zona «Navegación», `MikiTweaks.ps1:5104-5226`)
Se agrupan las secciones que ya existen. Las claves y los `Build-*Panel` no cambian:

| Entrada | Pestañas (claves actuales) |
|---|---|
| Inicio | `resumen` (sin pestañas) |
| Juegos | un juego por cada uno instalado (`Get-GameCats`), `modos`, `benchmark` |
| Windows | `Windows`, `Limpieza`, `Red`, `Inicio`, `cache`, `actualizaciones` |
| Herramientas | `monitor`, `perifericos`, `salud` |
| Ajustes | `ajustes`, `historial`, `registro` |

- Una tabla `$NavGroups` sustituye a los `Add-NavHeader`/`Add-NavItem` sueltos de `Build-Nav`. La entrada `Windows` solo muestra las categorías que tienen ajustes, igual que hace hoy `$SysNav`.
- El aviso de cada entrada del menú pasa a ser la **suma** de los recomendados pendientes de sus pestañas. Se reutiliza el cálculo de `Add-NavItem`, que también se muestra en cada pestaña.
- Una tira de pestañas nueva (`SubNav`) va bajo el título, en el XAML de la ventana (~línea 2497). Se dibuja con el estilo `Chip` que ya existe (`MikiTweaks.ps1:2635`), retocado, y cada pestaña llama a `Show-Section` sin cambios.
- `Select-Nav $key` acepta cualquier clave de pestaña: marca su entrada y su pestaña. Así siguen funcionando todos los atajos actuales (líneas 3053, 3064-3065, 3090, 3737, 5225) sin tocarlos.

## 2. Inicio guiado (`Build-Summary`, `MikiTweaks.ps1:3022`)
- **Arriba**: la puntuación y un solo botón grande, **«Optimizar ahora»**, que aplica los recomendados (el flujo de «Aplicar N cambios» de hoy). Si no queda nada: «Todo listo» y el botón desaparece.
- **«Siguientes pasos»**: como mucho 3 filas grandes y clicables, cada una con una frase y una flecha. Se eligen por orden de prioridad y **solo con datos reales**:
  1. Recomendados pendientes en una sección
  2. Driver o Windows Update pendiente
  3. Espacio que se puede liberar
  4. «Mide tus FPS» si no hay ningún Benchmark guardado
  5. Elegir un modo

  Para cada paso se reutilizan los datos que ya calculan las tareas en segundo plano y las páginas Actualizaciones y Caché. Si un dato llega tarde (driver), la fila se añade cuando llega o no sale.
- La fila de 5 botones rápidos (Q1–Q5) desaparece: queda cubierta por los pasos y el menú. «Tus juegos» y «Tu equipo» se mantienen, más compactos y debajo.

## 3. Estilo modernizado (estilos del XAML, ~2509-2660, y colores fijos)
- Antes de tocar nada, se pasa la skill **impeccable** (crítica y dirección) sobre las capturas actuales para fijar las reglas. La skill está pensada para web; aquí se usa como criterio y se traduce a mano a WPF.
- Dirección fijada:
  - Esquinas de 8 px y mucho menos borde (superficies diferenciadas por tono, no por línea).
  - Más aire entre tarjetas.
  - Títulos en `Segoe UI Variable Display` y con más contraste entre título, texto y texto secundario.
  - Lima solo para la acción principal y el estado activo.
- **Colores**: se ajusta el puñado de grises más usados (`#131315`, `#1C1C1F`, `#232326`, `#82828A`, `#8E8E95`…) con un mapa de sustitución hex → hex, sin refactorizar a tokens. El tema de acento (`Set-Accent`, línea ~4530) sigue funcionando.
- Estilos `Primary`, `Ghost`, `Nav`, `Toggle`, `Chip` y la tarjeta de ajuste (`Tarjetas`, ~2932): mismos nombres, nueva plantilla.

## 4. Textos e idioma
Cada texto nuevo («Optimizar ahora», «Siguientes pasos», «Herramientas», frases de los pasos…) necesita su entrada en el diccionario de traducción (`MikiTweaks.ps1:185-290`: frases exactas y plantillas `{0}`).

## Archivos
- `MikiTweaks.ps1`: todo lo anterior.
- `CHANGELOG.md`: sección `## 9.0`.
- `docs/img/es|en/*.png`, `README.md` y `docs/index.html` si nombran secciones: capturas nuevas.
- `docs/superpowers/specs/2026-11-13-rediseno-design.md`: este diseño, guardado en el repo.

## Verificación
1. `Invoke-Pester .\tests`, incluido el test «Interfaz», que construye todas las plantillas de estilo (así se coló el cuelgue de la barra de desplazamiento).
2. `herramientas\capturas.ps1` en `es` y `en`, con todas las claves (`-CapListKeys`), mirando las capturas una a una. Se buscan textos sin traducir, cortados o solapados, pestañas activas correctas y que cada atajo del Inicio lleve a su pestaña.
3. Recorrido de las 20 secciones de antes, ahora en pestañas, sin errores en `errores.txt` aislado.
4. Miki lo abre en su PC con `github\Abrir Miki Tweaks.cmd` **antes de publicar** y da el visto bueno.
5. Publicar con `.\publicar.ps1 9.0` (tests, version.json, ZIP, push, release).

## Queda sin probar
Pantallas pequeñas (el mínimo es 1000×660: revisar que la tira de pestañas de Windows, con 6 pestañas, no se corte) y PCs sin juegos (Juegos solo con Modos y Benchmark).
