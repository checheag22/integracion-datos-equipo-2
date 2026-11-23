# Guion de demostración y defensa

## Corrida en vivo (2–3 minutos)

1. Abrir la base de práctica y mostrar que las cinco ventas y las fuentes están en `bronce`.
2. Mostrar el ejemplo de la diapositiva 5: `Nombre=' sofia mendiolea '` se conserva en minúsculas y sin espacios exteriores tras `TRIM`; `Categoría=' Gold '` queda como `GOLD` con `TRIM`/`UPPER`; el gasto CRM nulo de `CLI-V02` se completa con `$4,920` observado en POS y marcado como proxy imputado. Volver a ejecutar `03_etl_limpieza_plata.sql` y explicar también `TRY_CONVERT`, `COALESCE`, `ROW_NUMBER()` y la protección de llave.
3. Consultar `oro.vw_Calidad_Integracion`: comparar filas Bronze con ventas Oro, anomalías, nulos y claves únicas.
4. Consultar `oro.vw_Gold_Ventas_Vinos` y `oro.vw_KPI_Membresia_Canal`; explicar que 12 de 15 botellas Platinum con puntaje >93 representan una persona de cinco ventas, por lo que no se debe generalizar.
5. Ejecutar `plata.sp_HistorialVentasCliente` para `CLI-V01` del 1 al 3 de agosto de 2026; cierra con `oro.vw_KPI_Origen_Vino` y explica que Rioja aporta `$14,400` (63.27%).

**Plan B:** llevar capturas recientes de las consultas de Calidad, Vista 360° y KPIs. La captura debe generarse justo antes de exponer con el mismo conjunto de SQL. No usar capturas simuladas como evidencia de ejecución.

## Distribución orientativa (12–15 minutos, incluida demo)

- Ezequiel, Líder de Proyecto: propósito, alcance y coordinación del cierre (2–3 min).
- José, Arquitecto: fuentes, arquitectura, DER, PK/FK y repositorio (2.5 min).
- Patricio, Ingeniero ETL: limpieza, idempotencia y corrida en vivo (4.5 min incluida demo).
- Ximena, QA: calidad, controles y límites de la muestra (2 min).
- Joel, BI + Documentación y Trello: lectura de Oro, insight, repositorio y tablero (2–3 min).
- Transiciones y preguntas al público: 0.5–1 min. Después reservar 6–8 min para preguntas individuales por rol.

La guía oficial divide Liderazgo/BI para equipos de cinco; el banco oficial de preguntas mantiene a Ezequiel como Líder + BI y a Joel como Documentación/Trello. Para la exposición oral, Joel presenta BI junto con el repositorio. Ambos preparan el insight y Ezequiel contesta la pregunta de decisión que aparece a su nombre en el banco.

## Banco oficial de preguntas por rol

Las 15 preguntas y respuestas justificadas con el SQL de la entrega están en `docs/respuestas-banco-preguntas-por-rol.md`. El archivo fuente oficial del Equipo 2 se conserva en `docs/banco-preguntas-oficial-equipo-2.pdf`.

El modelo `Customer 360` (Tickets, Interacciones y Ventas) y las propiedades `MS_Description` no están implementados en el script actual; se deben explicar como pendientes y fuera del alcance de la muestra actual.

### Arquitectura — José
- **¿Por qué Bronze guarda texto?** Para preservar el dato de origen y diagnosticar valores inválidos antes de asignar tipos.
- **¿Qué relación es una FK física?** `oro.Fact_Ventas_POS.ID_Cliente` apunta a `plata.Dim_Clientes.ID_Cliente`; `SKU_Vino` apunta a `plata.Dim_Vinos`.
- **¿Cómo se conecta cada fuente?** POS con CRM por `ID_Cliente` y ventas con ratings por `SKU_Vino`.

### ETL — Patricio
- **¿Qué vuelve idempotente la carga?** La inserción Bronze evita filas de muestra idénticas; el ETL deduplica por llave natural y la venta Oro se inserta por `ID_Venta_POS`.
- **¿Qué significa el valor $4,920?** Es el total observado de POS para `CLI-V02`, usado como proxy porque falta el gasto CRM; no es gasto anual confirmado.
- **¿Cómo tratarían un duplicado tardío?** `ROW_NUMBER()` ordena por fecha y desempata por ID de fila de ingesta; el reproceso actualiza la llave Oro.

### Calidad — Ximena
- **¿Qué anomalías aparecen?** Un `ID_Cliente` nulo en POS y un gasto CRM nulo; no hay filas inválidas ni duplicados en la muestra entregada.
- **¿Se pierde la venta anónima?** No. Se asigna a `CLI-MOSTRADOR` y se conserva para el total de ingresos.
- **¿Qué hacen las restricciones?** FK evita clientes/vinos huérfanos en Oro; `CHECK` limita puntuación, botellas y precio.

### Liderazgo y BI — Ezequiel
- **¿Cuál es el alcance?** La muestra integra POS, CRM y ratings; no hay registros para probar inventario ni órdenes web.
- **¿Qué decisión permiten los datos?** Probar una recomendación de etiquetas >93 para clientes Platinum y medir conversión e ingreso incremental con más clientes; la muestra pequeña no prueba causalidad.
- **¿Cuál es el hallazgo principal?** Rioja aporta `$14,400` (63.27%) y los vinos >93 puntos también `$14,400`, por 12 botellas de Tempranillo Rioja con 93.8 puntos.

### Documentación y Trello — Joel
- **¿Qué falta documentar?** El diccionario de `Customer 360` debe definir Tickets, Interacciones y Ventas; esas tablas no están implementadas en el SQL actual.
- **¿Para qué usar `MS_Description`?** Mantiene definiciones consultables junto a tablas y columnas; esta mejora aún no está implementada en el script.
- **¿Cómo está Trello?** El tablero privado ya tiene nombre conceptual, descripción y columnas de avance; quedan tareas de ensayo, capturas recientes y Moodle.
