# Corrida reproducible en SQL Server — evidencia

**Fecha:** 23 de noviembre de 2026. Se creó una base vacía en SQL Server 2022 Developer, en un contenedor temporal sin puertos publicados. Los cuatro scripts se ejecutaron en orden. El contenedor se eliminó tras la captura.

## Resultado comprobado

| Capa / control | Resultado | Qué significa |
|---|---:|---|
| POS en Bronce | 7 filas | 5 ventas base + 2 registros sintéticos para la demostración |
| IDs POS únicos / duplicados | 6 / 1 | `ROW_NUMBER()` selecciona la versión de `POS-805` a las 19:30 |
| POS inválidos / ventas Oro | 1 / 5 | `POS-806` no convierte `muchas` a cantidad y queda fuera de Oro |
| Ratings Bronce / válidos / inválidos | 4 / 3 / 1 | El rating sintético 120 sale de la escala 0–100 |
| CRM | 4 clientes / 1 proxy | El valor imputado de `CLI-V02` es $4,920 observados, no gasto anual confirmado |
| Oro | 5 ventas / 24 botellas / $22,760 MXN | Totales de la muestra válida |
| Venta anónima | 1 / $450 MXN | Se conserva bajo `CLI-MOSTRADOR` |
| Clientes / vinos huérfanos | 0 / 0 | Las relaciones de la muestra se resuelven |
| Reejecución de la integración | 5 ventas / 24 botellas / $22,760 MXN | No duplica el hecho Oro |

Las filas sucias añadidas son **sintéticas y didácticas**; se identifican así en el SQL. La corrida no tiene interfaz SSMS: es una ejecución real de `sqlcmd` conectada a SQL Server 2022. La imagen [captura-sqlserver-demo-2026-11-23.png](captura-sqlserver-demo-2026-11-23.png) muestra la consola y [evidencia-ejecucion-sqlserver-2026-11-23.txt](evidencia-ejecucion-sqlserver-2026-11-23.txt) conserva la salida íntegra.

## Lectura de negocio

- Rioja suma 12 botellas y $14,400 MXN, 63.27% del ingreso observado.
- Las 12 botellas Platinum con puntaje >93 corresponden a una persona de esta muestra.
- Es una hipótesis para medir con más clientes, no una relación causal ni un patrón validado.

## Cobertura técnica verificada

- Se consultaron las cinco vistas y se ejecutaron los siete procedimientos.
- La base se creó desde cero con los cuatro archivos `src/01` → `src/04`.
- La segunda ejecución de `usp_ProcesarPlata` mantuvo 5 ventas, 24 botellas y $22,760 MXN.
- No se conectó a una instancia persistente; el script [run-sqlserver-demo.sh](../tasks/run-sqlserver-demo.sh) genera una contraseña temporal en memoria, publica cero puertos y elimina el contenedor al cerrar.

## Uso para la exposición

La diapositiva 6 muestra la evidencia visual real. Para demostrarlo en otra computadora, ejecutar `./tasks/run-sqlserver-demo.sh` con Docker instalado; si no está disponible, se conserva el PDF y la salida completa. No afirmar que la captura se obtuvo en SSMS.
