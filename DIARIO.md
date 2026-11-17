# Diario de Miki Tweaks

Este archivo es la memoria del proyecto. Claude lo lee antes de trabajar y apunta aquí todo lo que hace, con fecha.
Los cambios de cada versión, para los usuarios, están en `CHANGELOG.md`.

## Resumen

- **Qué es:** una app para Windows (PowerShell + WPF) que optimiza el PC para jugar en competitivo.
- **Qué hace:**
  - Escanea el hardware, Windows y los juegos, y propone solo los ajustes que tienen sentido.
  - Benchmark de FPS y latencia (con PresentMon).
  - Herramientas de red: bufferbloat y ruta hasta los servidores.
  - Modos de un clic.
  - Diagnóstico y limpieza.
- **Seguridad:** todo se puede deshacer.
- **Idiomas:** español e inglés.
- **Dónde está:**
  - Repositorio: `mikimagdalenius-dev/miki-tweaks`.
  - Web: https://mikimagdalenius-dev.github.io/miki-tweaks/
- **Actualización:** desde la 8.5 se actualiza sola.

### Quién ha hecho qué

- **Miki:** la idea, las decisiones y las pruebas en su PC.
- **Claude:** el código, los tests, la web, las capturas y las publicaciones. Hace commit, push y releases él mismo.

### Cómo se publica

1. Añadir una sección `## X.Y` en `CHANGELOG.md`.
2. Ejecutar `.\publicar.ps1 X.Y`. El script hace las comprobaciones, los tests, `version.json`, el ZIP, el push y la release.

Antes de publicar, probar abriendo `github\Abrir Miki Tweaks.cmd`. No hacer push del script sin publicar versión: la huella de `version.json` fallaría.

## Estado (13/11/2026)

- **Versión 9.0 publicada:** menú de 5 entradas con pestañas, inicio guiado y estilo renovado. A Miki le gusta más así.
- **Lo próximo:** Miki pasará la app a 5-10 amigos. Hasta tener sus comentarios, no añadir funciones nuevas.
- **Sin probar en uso real:**
  - ventanas emergentes;
  - Benchmark;
  - tests de red con resultados;
  - ajustes que necesitan admin;
  - el botón "Copiar informe".
- **Ideas para más adelante:**
  - firma digital (SignPath), cuando haya usuarios;
  - recomendar "Quitar Widgets" si a algún amigo le falla "Sin Widgets".

## Registro

### Antes del 10/11/2026
- Versiones 7.7 a 8.2. Las copias están en `Desktop\Miki Tweaks\versiones-antiguas-7.7-a-8.2.zip`.

### 10/11/2026
- **8.3:** estado inicial en GitHub.
  - Protección de la carpeta de datos.
  - Las copias ya no se pierden al deshacer los ajustes de red.
  - Aviso de NVIDIA en portátiles.
- **Canal de actualizaciones y web:**
  - script de publicación;
  - tests con Pester;
  - GitHub Actions;
  - plantilla de fallos.
- **8.4 y 8.4.1:**
  - capturas en español e inglés;
  - descarga directa en la web;
  - releases con el nombre fijo `Miki-Tweaks.zip`.
- **8.4.2:** ajustes más claros y plurales correctos.
- **8.5:** se actualiza sola en segundo plano.
- **8.5.1:**
  - Arreglado: en Windows 11 se creía en Windows 10.
  - Los ajustes aplicados por error salen en Limpieza.
- **8.5.2:** "Sin Widgets" solo aparece si están instalados, y nuevo "Quitar Widgets".
- **8.5.3:** el Modo Juego ya no deja Windows Update en pausa durante semanas.

### 13/11/2026
- **9.0:** rediseño con menú de 5 entradas y pestañas, inicio guiado ("Optimizar ahora" y siguientes pasos) y estilo renovado.
