# Guion de exposición — Equipo 2

**Duración de exposición y demo: 25 minutos.** La ronda de preguntas va después y no forma parte de estos 25 minutos. Las respuestas del banco oficial están en un archivo aparte; no aparecen en las diapositivas.

## Orden y tiempo

| Diapositiva | Quién | Tiempo | Qué debe quedar claro |
|---|---|---:|---|
| 1–3 | Ezequiel | 2:45 | Objetivo, equipo y alcance de la muestra. |
| 4 | Joel | 1:30 | Qué aporta cada fuente y cómo se relaciona. |
| 5–7 | José | 4:45 | Para qué sirve cada capa, cómo viaja una fila y cómo se relacionan las tablas. |
| 8–10 | Patricio | 6:00 | Ejecución real, reglas de limpieza e idempotencia. |
| 11 | Ximena | 1:45 | Qué muestran los controles de calidad. |
| 12 | Joel | 1:30 | Qué preguntas responden las cinco vistas. |
| 13 | Joel + Ezequiel | 1:45 | Joel lee los indicadores; Ezequiel explica el alcance del insight. |
| 14 | Ezequiel | 1:15 | Cómo convertir una señal en una prueba medible. |
| 15–16 | Ximena | 2:30 | Límites y mejoras priorizadas. |
| 17 | Joel | 0:45 | Dónde encontrar el código y la evidencia. |
| 18 | Ezequiel | 0:30 | Cierre y paso a preguntas. |
| **Total** |  | **25:00** | Las preguntas se contestan al terminar. |

## Guion fácil de explicar

### Diapositivas 1–3 · Ezequiel

> “Integramos ventas POS, clientes CRM y calificaciones de vinos para contestar qué se vendió, por qué canal y a qué tipo de cliente. Viñedos del Alba es un caso ficticio. La muestra base tiene cinco ventas, cuatro clientes y tres vinos. No recibimos inventario ni ventas web.”

Aclarar que las filas extra de la corrida son datos sintéticos de prueba autorizados por el profesor. Sirven para demostrar reglas y no se reportan como ventas reales.

### Diapositiva 4 · Joel

> “POS aporta el detalle de la venta; CRM, los atributos del cliente; y ratings, el contexto del vino. `ID_Cliente` conecta POS con CRM y `SKU_Vino` conecta POS con el catálogo de vinos.”

Explicar que las llaves hacen verificable el cruce. Los datos falsos se usan solo en ejemplos sucios de la corrida.

### Diapositivas 5–7 · José

> “Bronce conserva lo que llegó; Plata aplica las reglas y prepara las dimensiones; Oro publica las ventas relacionadas y las vistas. En el ejemplo, Bronce mantiene las dos versiones de POS-805, Plata limpia los espacios y elige la de las 19:30, y Oro deja una venta. El modelo relaciona cada venta con cliente y vino mediante llaves foráneas.”

Mencionar una venta sin cliente: se conserva bajo `CLI-MOSTRADOR` para no perder el importe ni inventar una identidad.

### Diapositivas 8–10 · Patricio

> “La corrida parte de una base vacía en SQL Server 2022 y ejecuta los cuatro archivos en orden. La muestra tiene siete filas POS después de añadir datos de prueba: seis IDs únicos y cinco ventas válidas en Oro. POS-806 trae ‘muchas’ en la cantidad; no se convierte y queda fuera de Oro. Repetir el proceso conserva cinco ventas, 24 botellas y $22,760.”

En la evidencia señalar `7 → 6 → 5`, la versión de POS-805 a las 19:30, la exclusión de POS-806 y los totales. Es salida real de `sqlcmd` contra SQL Server 2022; no decir que es SSMS.

### Diapositiva 11 · Ximena

> “La vista de calidad resume entradas y rechazos. También detecta el rating sintético 120 fuera del rango 0–100. No hay clientes ni vinos huérfanos; se conserva una venta anónima. Estos resultados describen la muestra de prueba.”

### Diapositivas 12–13 · Joel y Ezequiel

**Joel:** explicar que `vw_POS_Operativa` y `vw_Gold_Ventas_Vinos` dan detalle integrado; las vistas KPI resumen membresía/canal y origen; `vw_Calidad_Integracion` explica el proceso.

**Ezequiel:** “Observamos $22,760 en cinco ventas. Rioja aporta $14,400, 63.27% del ingreso. Las doce botellas con puntaje mayor a 93 también las compró una persona; es una señal pequeña, no prueba causalidad.”

### Diapositiva 14 · Ezequiel

> “La señal nos da una hipótesis, no una conclusión. Probaríamos una recomendación en un grupo y la compararíamos con otro; mediríamos conversión, ingreso por cliente y margen antes de decidir si funciona.”

### Diapositivas 15–16 · Ximena

> “No recomendamos reabasto porque no tenemos inventario, ni generalizamos desde cinco ventas. Para mejorar, primero integraríamos fuentes reales con trazabilidad; después guardaríamos los rechazos con su motivo; ampliaríamos periodos y, cuando exista la fuente, agregaríamos inventario.”

### Diapositivas 17–18 · Joel y Ezequiel

**Joel:** “GitHub guarda los scripts, la presentación y la evidencia; Trello nos dice quién sigue y qué evidencia falta; Moodle es donde se entrega el PDF.”

**Ezequiel:** “Integramos fuentes para responder una pregunta con reglas claras. El siguiente paso es medir la hipótesis con más datos. Gracias; ahora pasamos a preguntas.”

## Verificación de SQL ya realizada

Se ejecutaron los cuatro archivos desde una base vacía y se repitieron. Se consultaron las cinco vistas y se ejecutaron los siete procedimientos; la transacción de prueba se revirtió. La salida completa está en `evidencia-ejecucion-sqlserver-2026-11-23.txt` y la captura en `captura-sqlserver-demo-2026-11-23.png`.

## Preguntas

El banco de respuestas se mantiene aparte en `respuestas-banco-preguntas-por-rol.md`. Las diapositivas terminan con una invitación a preguntas, sin incluir las respuestas.
