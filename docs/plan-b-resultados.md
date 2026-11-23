# Plan B — resultados de la corrida SQL Server

**Última comprobación:** 23 de noviembre de 2026. SQL Server 2022, contenedor temporal aislado, base vacía, cuatro scripts ejecutados en orden. La evidencia completa de consola está en `docs/evidencia-ejecucion-sqlserver-2026-11-23.txt`. La instancia temporal se elimina al terminar la verificación.

## Conteos reproducidos

| Control | Resultado | Lectura sencilla |
|---|---:|---|
| POS en Bronce → ventas en Oro | 5 → 5 | Las cinco ventas válidas se integran |
| IDs de venta distintos en Bronce | 5 | No había duplicados en la muestra real |
| Filas POS inválidas | 0 | Las conversiones y rangos pasan |
| Clientes / vinos huérfanos | 0 / 0 | Ninguna relación falta |
| Venta anónima | 1 / $450 MXN | Se conserva bajo `CLI-MOSTRADOR` |
| CRM | 4 filas / 4 clientes | Un gasto se marca como proxy |
| Ratings | 3 filas / 3 válidos | No hay puntajes inválidos |
| Ventas / botellas / ingresos Oro | 5 / 24 / $22,760 MXN | Totales observados |
| Ticket promedio | $4,552 MXN | Promedio de cinco transacciones |
| Proxy de `CLI-V02` | $4,920 MXN | No es gasto anual confirmado |

## Dos lecturas de negocio

- Rioja: 12 botellas y `$14,400 MXN`, el 63.27% del ingreso observado.
- Platinum: 12 de 15 botellas (80%) tienen puntaje >93; las compró una persona en esta muestra.
- Interpretación: hipótesis para medir con una prueba y más clientes; no es causalidad ni patrón validado.

## Alcance de la corrida

- Las cinco vistas (`oro`) respondieron y los siete procedimientos (`plata`) se ejecutaron, incluido el registro de un cliente temporal dentro de una transacción revertida.
- La reejecución de ingesta/ETL y del script de vistas conservó cinco ventas, cinco IDs únicos, 24 botellas y `$22,760 MXN`.
- Los cuatro scripts también se ejecutaron otra vez, en orden y sin errores, sobre la misma base temporal; los conteos se mantuvieron en 5 ventas, 24 botellas y `$22,760 MXN`.
- En una prueba aislada se agregó una segunda versión posterior de `POS-805`. Al reprocesar, Oro mantuvo cinco ventas y eligió la fecha más reciente. Se borró la fila de prueba al finalizar; los datos de la muestra volvieron a quedar en su estado original.
- Los scripts no fueron conectados a una instancia persistente; el contenedor QA fue desechable.

## Uso durante la exposición

Intentar la corrida en vivo primero. Si SQL Server/SSMS falla, abrir el PPT/PDF final y este resumen; también se conserva el log completo en la carpeta `docs/`. El log es salida real de `sqlcmd`, **no una captura de SSMS**. Si piden una captura de la interfaz, habrá que tomarla en la computadora donde se hará la exposición y nombrarla como respaldo.
