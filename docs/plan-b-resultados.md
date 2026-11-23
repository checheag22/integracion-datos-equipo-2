# Plan B — resultados recientes para la exposición

Ejecución verificada el 23 de noviembre de 2026 en SQL Server 2022 temporal; los cuatro scripts se ejecutaron en orden. La base desechable se eliminó al finalizar. Estos resultados son la referencia de respaldo, no sustituyen la corrida en vivo.

## Muestra oficial

| Control | Resultado |
|---|---:|
| POS en Bronce | 5 filas |
| IDs POS únicos | 5 |
| Transacciones en Oro | 5 |
| Filas POS inválidas | 0 |
| Clientes POS huérfanos | 0 |
| Vinos POS huérfanos | 0 |
| Venta con cliente nulo, preservada como mostrador | 1 |
| Clientes CRM | 4 |
| Ratings / vinos válidos | 3 / 3 |
| Botellas e ingresos POS | 24 / $22,760 MXN |
| Proxy imputado de CLI-V02 | $4,920 MXN; no equivale a gasto anual confirmado |

## KPIs del caso

- Platinum: 12 de 15 botellas (80%) corresponden a vino con puntaje >93; las 12 son de un cliente en esta muestra.
- Origen: Rioja 12 botellas (50%); Mendoza 8 (33.33%); Valle de Guadalupe 4 (16.67%).
- Ingresos por origen: Rioja $14,400 (63.27%); Mendoza $6,560 (28.82%); Valle de Guadalupe $1,800 (7.91%).

## Prueba de duplicado y reejecución

Se agregó solo al entorno desechable una segunda fila `POS-805`, con fecha posterior. Resultado al volver a procesar y ejecutar todos los scripts:

```text
Bronce POS: 6 filas
IDs POS distintos: 5
Duplicados identificados: 1
Oro: 5 ventas · $22,760 MXN
La fila con fecha más reciente fue la integrada
Vistas Oro: 5 · Procedimientos Plata: 7
ALL ASSERTS PASSED
```

Los scripts no eliminan bases/tablas y vuelven a ejecutarse sin duplicar las cinco llaves de Oro. Para la exposición, guardar además capturas reales de SSMS de las tres consultas clave en el equipo que se usará para la demo.
