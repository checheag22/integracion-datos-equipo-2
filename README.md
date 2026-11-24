# Viñedos del Alba — Integración de Datos, Equipo 2
### Arquitectura Medallón en Microsoft SQL Server

**Caso académico ficticio:** Viñedos del Alba. No identifica una marca comercial real.

**Materia:** Integración de Datos · Universidad Iberoamericana León  
**Equipo:** 2 · [Tablero Trello](https://trello.com/b/fUVw5rtM) (privado)

![Símbolo conceptual de Viñedos del Alba](assets/logo_negocio.png)

## Proyecto

Integra una muestra de ventas de punto de venta (POS), clientes CRM y calificaciones de vinos. `ID_Cliente` y `SKU_Vino` permiten relacionar las fuentes. No se recibieron archivos originales CSV/Excel ni datos de inventario u órdenes en línea; las fuentes del recorrido están declaradas en los scripts y los ejemplos sucios son sintéticos.

## Arquitectura y modelo

![Flujo de integración Medallón](assets/flujo_medallon_sql.png)

- **Bronce (`bronce`)** conserva los valores recibidos, incluidos espacios, duplicados y datos inválidos.
- **Plata (`plata`)** normaliza texto, convierte tipos, deduplica por llave y construye dimensiones.
- **Oro (`oro`)** consolida hechos POS y ofrece vistas para calidad, KPIs y análisis.

![Diagrama entidad-relación de SQL Server](assets/diagrama_der_sqlserver.png)

Las llaves foráneas físicas conectan `oro.Fact_Ventas_POS` con `plata.Dim_Clientes` y `plata.Dim_Vinos`. Las líneas punteadas del flujo representan el proceso ETL, no relaciones físicas. La vista de Oro integra ventas, cliente y vino; no implementa historial de interacciones ni una Customer 360 multicanal.

## Estructura solicitada

```text
src/
├── 01_ddl_arquitectura_der.sql
├── 02_etl_ingesta_bronce.sql
├── 03_etl_limpieza_plata.sql
├── 04_vistas_gold_bi.sql
└── 00_demo_completa_ssms.sql
assets/
├── logo_negocio.png
├── flujo_medallon_sql.png
└── diagrama_der_sqlserver.png
README.md
```

`01` crea base, esquemas y tablas; `02` ingesta; `03` limpia y transforma; `04` crea vistas analíticas. `00_demo_completa_ssms.sql` combina esos pasos para una demostración desde cero. `docs/` contiene presentación, guiones, respuestas, guía y evidencias; `tasks/` incluye utilidades auxiliares. Son material complementario al esquema principal pedido.

## Corrida en SQL Server Management Studio

Abre `src/00_demo_completa_ssms.sql`, activa **Consulta > Modo SQLCMD**, conéctate a una instancia de práctica y ejecuta desde `master`. El script crea `DB_Vinicola_Integration` y se detiene si ya existe; no borra ni modifica una base previa. Requiere permiso para crear bases. Como alternativa, ejecuta `01` a `04` en orden.

La corrida se validó en SQL Server 2022 aislado. Resultado de la muestra: 7 filas POS en Bronce → 6 IDs únicos → 5 ventas válidas en Oro; 24 botellas y $22,760 MXN. El gasto CRM de `CLI-V02` se imputa como proxy observado y queda marcado; no representa gasto anual confirmado. La venta sin cliente se conserva como `CLI-MOSTRADOR`. Los ejemplos sintéticos y sus límites están documentados en scripts y evidencias de `docs/`.

## Equipo y roles de evaluación

La guía asigna cuatro roles; para las cinco personas, el rol de liderazgo/comercial se distribuye entre líder y BI:

- **José Hernández — Data Architect / SQL Specialist:** modelo, tipos, llaves y estructura SQL.
- **Patricio García — Data Engineer / Pipeline Lead:** ingesta y flujo ETL.
- **Ximena Ibarra — Data Quality & QA Specialist:** controles, limpieza y validaciones.
- **Ezequiel Aguilera — Líder de Proyecto:** coordinación, contexto del caso, Trello y cierre.
- **Joel Ibarra — BI & Analytics Specialist:** capa Oro, vistas, KPIs e interpretación de resultados.

## Entregables y duración

El repositorio conserva la presentación editable y PDF, el guion, preguntas/respuestas por rol, Plan B, documentación y evidencia de SQL. La guía PDF adjunta marca 20–25 minutos totales, con 12–15 minutos de exposición, corrida breve y preguntas individuales. Antes de entregar, cotejen el tiempo final con la indicación vigente en Moodle: la presentación del repositorio actualmente desarrolla un guion de 25 minutos, por lo que debe ajustarse si se aplica estrictamente la distribución de la guía.
