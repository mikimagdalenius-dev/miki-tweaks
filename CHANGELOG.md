# Cambios

## 8.5.2
- **Sin Widgets:** ya no aparece si los Widgets no están instalados (antes salía siempre y fallaba en Windows 11 reciente).
- Nuevo **Quitar Widgets** en Limpieza → Apps preinstaladas: en las versiones recientes de Windows 11, Windows bloquea la directiva de Widgets y esta es la forma de quitarlos del todo. Se reinstalan desde la Microsoft Store.

## 8.5.1
- **Corregido:** al abrir la app desde su acceso directo, en Windows 11 se creía en Windows 10. Mostraba avisos de Windows 10, ocultaba ajustes de Windows 11, ofrecía ajustes de Windows 10 y buscaba el driver de NVIDIA para Windows 10.
- Si en tu Windows 11 se aplicó algún ajuste de Windows 10 por ese fallo, aparece en Limpieza marcado como «Aplicado por error» para que puedas deshacerlo.

## 8.5
- **Se actualiza sola:** al abrir la app busca la versión nueva, la descarga y la instala en segundo plano (con la misma comprobación de huella de siempre). Se usa la próxima vez que la abras, o al momento con «Reiniciar ahora» en Ajustes.
- Si una actualización falla, no molesta: la app sigue como estaba y lo vuelve a intentar al abrirla.

## 8.4.2
- Ajustes más claros: se quitan el campo del canal de actualizaciones y el botón «Preparar publicación», que solo servían para publicar la app. Las actualizaciones llegan siempre desde la web oficial.
- Frases en singular cuando toca («1 ajuste», «1 actualización pendiente»…), también en inglés.

## 8.4.1
- La app ya no deja archivos en tu escritorio cuando algo falla: el informe se guarda solo en su carpeta.
- Botón **Copiar informe** (en Ajustes → Carpeta de datos y en el aviso de error) para pegarlo al reportar un fallo en GitHub.
- En inglés, «Cache & temp files» ya no se corta en el menú lateral.

## 8.4
- **Más clara de leer:** los textos secundarios tienen más contraste.
- Cada juego luce su color en el Resumen y en el menú lateral.
- El nombre de la gráfica ya no se corta en «Tu equipo».
- La puntuación del Resumen y la del menú lateral siempre coinciden (tras cambiar de modo podían diferir).
- Barra de desplazamiento más discreta.

## 8.3
- **Ajustes avanzados con pruebas** para Windows 10 y 11 (solo aparecen si hacen falta): temporizadores de arranque en automático, modo MSI de la gráfica, sin Fault Tolerant Heap, el juego no baja de volumen en las llamadas, sin inicio rápido, Windows Update no cambia tus drivers, sin transparencias y sin marca de último acceso.
- **Seguridad:** la carpeta de la app solo la pueden modificar los administradores, así ningún programa puede usarla para conseguir permisos de admin sin el aviso de Windows.
- Al deshacer un ajuste de la tarjeta de red, si falla, ya no se pierde la copia del valor original y queda anotado en el informe de errores.
- El aviso semanal encuentra el driver de más modelos de gráfica NVIDIA (sobre todo de portátil).

## 8.2 · noviembre de 2026
- La app en **inglés y español**: detecta el idioma de Windows y tiene selector en Ajustes.

## 8.1
- **Compartir resultado:** imagen del antes y después del Benchmark, lista para redes y Discord.
- «Acerca de», botón para apoyar el proyecto y aviso de uso.

## 8.0
- Corregido un fallo de PowerShell 5.1 que podía dejar a medias «Aplicar cambios».
- El informe de errores indica la línea exacta y la sección abierta.

## 7.8
- **Herramientas de red:** test de bufferbloat y análisis de la ruta hasta los servidores.
- Prioridad de red para los juegos (QoS) y Wi-Fi estable para jugar.
- Pausar descargas de Windows Update y OneDrive mientras juegas.
- Aviso si el cable de red va a 100 Mbps en vez de 1 Gbps.

## 7.x
- Benchmark con PresentMon, modos, Modo Juego automático, perfiles de NVIDIA, salud del PC, soporte de Windows 10, historial de cambios y protección contra errores.
