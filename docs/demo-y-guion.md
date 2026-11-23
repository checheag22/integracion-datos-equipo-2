# Guion de demostración y defensa

## Corrida en vivo (2–3 minutos)

1. Abrir la base de práctica y mostrar que las cinco ventas y las fuentes están en `bronce`.
2. Mostrar el ejemplo de la diapositiva 5: `Nombre=' sofia mendiolea '` se conserva en minúsculas y sin espacios exteriores tras `TRIM`; `Categoría=' Gold '` queda como `GOLD` con `TRIM`/`UPPER`; el gasto CRM nulo de `CLI-V02` se completa con `$4,920` observado en POS y marcado como proxy imputado. Volver a ejecutar `03_etl_limpieza_plata.sql` y explicar también `TRY_CONVERT`, `COALESCE`, `ROW_NUMBER()` y la protección de llave.
3. Consultar `oro.vw_Calidad_Integracion`: comparar filas Bronze con ventas Oro, anomalías, nulos y claves únicas.
4. Consultar `oro.vw_Gold_Ventas_Vinos` y `oro.vw_KPI_Membresia_Canal`; explicar que 12 de 15 botellas Platinum con puntaje >93 representan una persona de cinco ventas, por lo que no se debe generalizar.
5. Cerrar con `oro.vw_KPI_Origen_Vino`: Rioja aporta 12 botellas, Mendoza 8 y Valle de Guadalupe 4.

**Plan B:** llevar capturas recientes de las consultas de Calidad, Vista 360° y KPIs. La captura debe generarse justo antes de exponer con el mismo conjunto de SQL. No usar capturas simuladas como evidencia de ejecución.

## Distribución orientativa (12–15 minutos, incluida demo)

- Ezequiel, Líder de Proyecto: propósito, alcance, equipo y cierre (1.5 min).
- José, Arquitecto: fuentes, arquitectura, DER, PK/FK y repositorio (2.5 min).
- Patricio, Ingeniero ETL: limpieza, idempotencia y corrida en vivo (4.5 min incluida demo).
- Ximena, QA: calidad, controles y límites de la muestra (2 min).
- Joel, BI Analyst: vista Oro, KPIs y decisiones prudentes (2 min).
- Transiciones y preguntas al público: 0.5–1 min. Después reservar 6–8 min para preguntas individuales por rol.

## Preguntas probables de práctica

Estas preguntas sirven para ensayar; el archivo oficial del Equipo 2 en Moodle no se pudo abrir en esta sesión, así que no deben presentarse como transcripción del banco oficial.

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

### Liderazgo — Ezequiel
- **¿Cuál es el alcance?** La muestra integra POS, CRM y ratings; no hay registros para probar inventario ni órdenes web.
- **¿Qué queda pendiente del equipo?** Mostrar acceso de lectura al tablero Trello vigente y validar la marca comercial oficial.

### BI — Joel
- **¿Qué decisión permiten los datos?** Diseñar una prueba de promoción de etiquetas de alta puntuación para clientes Platinum; medirla con una muestra mayor antes de generalizar.
- **¿Cuál es el insight por origen?** Rioja tiene la mitad del volumen (12/24 botellas), pero la categoría es origen geográfico de los vinos, no variedad de uva.
- **¿Qué limitación tiene el KPI Platinum?** Doce botellas representan a una sola persona; no es una tendencia de clientes.
