# Guion rápido por integrante — Equipo 2

**Meta de tiempo: 25 min.** 15 min de exposición y demo + 8 min de preguntas + 2 min de transiciones. Moodle pide dos preguntas por persona; el banco oficial trae tres. Estas son las dos prioritarias. La respuesta completa y una tercera pregunta de respaldo están en [`respuestas-banco-preguntas-por-rol.md`](respuestas-banco-preguntas-por-rol.md).

## Reparto al presentar

| Persona | Diapositivas | Tiempo hablado | Idea que debe quedar |
|---|---:|---:|---|
| Ezequiel | 1–3, apoya 10, 13 | 3:45 | Alcance y decisión de negocio, con sus límites. |
| José | 4–5 | 2:30 | Qué hace cada capa y cómo se conectan las llaves. |
| Patricio | 6–8 | 4:45 | Corrida en vivo, limpieza e idempotencia. |
| Ximena | 9, 11 | 2:00 | Calidad medida y lo que la muestra no demuestra. |
| Joel | apoya 10, 12 | 2:00 | Cómo leer la Vista Oro y dónde están los entregables. |
| **Total** |  | **15:00** | Preguntas: 8 min · transiciones: 2 min. |

El banco oficial conserva a Ezequiel como Líder + BI y a Joel como Documentación/Trello. Para atender la guía que divide Liderazgo y BI en equipos de cinco, Joel lee los KPI de la vista; Ezequiel propone la decisión comercial y responde la pregunta oficial de BI.

## Qué decir

### Ezequiel — apertura y cierre

> “Integramos ventas POS, clientes del CRM y calificaciones de vinos en SQL Server. La muestra tiene cinco ventas; no recibimos archivos originales, inventario ni datos web. Los resultados permiten proponer una prueba, no generalizar. Viñedos del Alba es un nombre ficticio para el caso.”

**Insight:** “Rioja aporta $14,400, 63.27% del ingreso. Doce de quince botellas Platinum superan 93 puntos, pero las compró una persona. Probaríamos una recomendación y mediríamos conversión con más clientes.”

### José — arquitectura y modelo

> “Bronce conserva; Plata limpia y relaciona; Oro contiene el hecho de ventas y las vistas. La venta tiene una PK y dos FKs hacia cliente y vino. Una venta sin cliente se conserva como CLI-MOSTRADOR.”

### Patricio — ETL y demo

> “TRIM y UPPER normalizan texto; TRY_CONVERT intenta conversiones válidas; ROW_NUMBER elige una versión por llave. El proxy de $4,920 está marcado. Reprocesar conservó cinco ventas en Oro.”

**Demo (diapositiva 6):** ejecutar `02_etl_ingesta_bronce.sql`, luego `03_etl_limpieza_plata.sql`, y terminar con `04_vistas_gold_bi.sql`. Mostrar conteo Bronce, `oro.vw_Calidad_Integracion` y `oro.vw_Gold_Ventas_Vinos`. Pregunta de cierre: “¿Qué compró CLI-V01 y qué puntaje tenía el vino?” El archivo 01 se ejecuta antes para crear la base y sus tablas.

### Ximena — QA y límites

> “La vista cuenta cinco ventas en Bronce y cinco en Oro, cero POS inválidas, cero clientes o vinos huérfanos y una venta anónima preservada. Los tres ratings son válidos. Son conteos de la muestra disponible.”

### Joel — lectura de Oro y entregables

> “La Vista Gold reúne cliente, vino, canal, botellas e importe; las vistas KPI resumen membresía, origen y calidad. En el repo están los cuatro scripts, assets, presentación, Q&A y Plan B. El Trello es privado y Customer 360 queda fuera de este modelo.”

## Dos preguntas prioritarias por integrante

### Patricio García — ETL

1. **¿Por qué conservar POS-804?** Es una venta válida aunque no se conoce al cliente; se asigna CLI-MOSTRADOR y se conservan los $450 sin inventar identidad.
2. **¿Cómo evita duplicados al reejecutar?** La ingesta exacta no repite filas; `ROW_NUMBER()` elige por ID de venta y fecha; Oro actualiza/insert por llave. Se probó una versión tardía y Oro mantuvo cinco ventas.

### José Hernández — Arquitectura

1. **¿Qué aporta Medallón?** Bronce permite rastrear la entrada, Plata limpia y valida, y Oro sirve hechos y vistas listos para analizar.
2. **¿Qué pasa con un SKU desconocido?** Plata no lo integra como dimensión válida y la FK bloquea una relación inexistente en Oro. La fila queda en Bronce; todavía falta una tabla que registre el motivo del rechazo.

### Ximena Ibarra — QA

1. **¿Qué anomalías revisan?** Nulos, duplicados, conversiones, cantidades/precios fuera de rango, huérfanos, categorías y ratings inválidos. La vista resume esos controles; hoy no hay POS inválidas ni huérfanos.
2. **¿Qué hacen con un rating nulo o fuera de rango?** Se conserva en Bronce, se excluye de Plata/Oro y se cuenta como inválido. La escala válida es 0–100.

### Joel Ibarra — Documentación y Trello

1. **¿Qué falta para cerrar diccionario y Trello?** Trello tiene el avance y las tareas de defensa. El diccionario de Customer 360 necesita las definiciones oficiales de Tickets, Interacciones y Ventas; ese esquema no está en este SQL.
2. **¿Cómo alinean SQL, presentación y Trello?** La rama de entrega da la versión de referencia; se anotan responsables/evidencias en Trello y la presentación usa solo resultados reproducidos desde SQL.

### Ezequiel Aguilera — Liderazgo y BI

1. **¿Qué decisión sugieren los KPI?** Probar una recomendación Rioja o >93 puntos y medir conversión e ingreso incremental con más clientes; cinco ventas no prueban causalidad.
2. **¿Qué limita no tener inventario ni venta web?** No se puede calcular reabasto, agotamiento ni conversión en línea. El análisis describe únicamente la muestra POS.

## Si se bloquea la demo

Usar el resultado local de `plan-b-resultados.md` y `evidencia-ejecucion-sqlserver-2026-11-23.txt`. El log es salida real de SQL Server por `sqlcmd`, no captura de SSMS. No inventar que la pantalla se ejecutó en vivo.
