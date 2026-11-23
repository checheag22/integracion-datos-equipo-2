# Integración de Datos para una Vinícola — Equipo 2
### Arquitectura Medallón en Microsoft SQL Server

**Materia:** Integración de Datos | Universidad Iberoamericana León

**Equipo:** 2 | **Tablero Trello:** [Vinícola — tablero del equipo](https://trello.com/b/fUVw5rtM) *(la lectura del tablero requiere iniciar sesión; el permiso de solo lectura no pudo verificarse en esta sesión).*

![Marca gráfica del proyecto](assets/logo_negocio.png)

> La marca gráfica incluida identifica el proyecto académico; no sustituye el logotipo comercial oficial de la vinícola.

## 1. Descripción del proyecto

El proyecto consolida ventas de punto de venta (POS), clientes del CRM y calificaciones de vinos. El cruce se realiza mediante `ID_Cliente` y `SKU_Vino`. La muestra disponible contiene cinco transacciones POS, cuatro clientes CRM y tres vinos con ratings. No se recibieron datos de inventario ni órdenes de comercio electrónico; por tanto, el análisis no los atribuye al negocio.

La muestra POS suma 24 botellas y $22,760 MXN. Una transacción con cliente nulo se conserva bajo `CLI-MOSTRADOR`. El gasto ausente de `CLI-V02` se completa con $4,920 MXN observados en la muestra POS y se marca `Gasto_Fue_Imputado=1`; no es un gasto anual confirmado.

## 2. Arquitectura de integración (SQL Server)

![Flujo de integración Medallón](assets/flujo_medallon_sql.png)

- **Bronce (`bronce`):** conserva texto crudo de POS, CRM y ratings; permite rastrear filas repetidas y valores que no convierten.
- **Plata (`plata`):** estandariza con `TRIM`/`UPPER`, convierte con `TRY_CONVERT`, resuelve duplicados por llave de negocio con `ROW_NUMBER()` y aplica reglas y claves.
- **Oro (`oro`):** concentra los hechos POS y expone vistas para análisis, calidad y KPIs.

La ingesta de demostración usa datos de referencia incluidos en SQL y un objeto JSON de ejemplo. Los archivos originales CSV/JSON/SQL no estaban disponibles en el paquete local; las cargas deben reemplazarse por fuentes originales si el equipo las recupera.

## 3. Modelo entidad-relación (DER)

![Diagrama Entidad-Relación](assets/diagrama_der_sqlserver.png)

Las llaves foráneas físicas salen de `oro.Fact_Ventas_POS` hacia `plata.Dim_Clientes` y `plata.Dim_Vinos`. Las líneas punteadas representan transformación ETL, no relaciones físicas.

## 4. Estructura del repositorio (`/src`)

```text
src/
├── 01_ddl_arquitectura_der.sql
├── 02_etl_ingesta_bronce.sql
├── 03_etl_limpieza_plata.sql
└── 04_vistas_gold_bi.sql
assets/
├── logo_negocio.png
├── flujo_medallon_sql.png
├── diagrama_der_sqlserver.png
└── portada-vinicola-golden-hour.png
docs/
├── presentacion-final-equipo-2.pptx / .pdf
├── avance.docx / .pdf
├── demo-y-guion.md
├── plan-b-resultados.md
└── guia-presentacion-proyecto-final.pdf
tasks/
└── presentation_polish.py
README.md
```

1. `01_ddl_arquitectura_der.sql`: base de datos, esquemas, tablas, PK, FK y restricciones.
2. `02_etl_ingesta_bronce.sql`: cargas de muestra SQL, CRM y JSON; evita reinsertar una fila idéntica.
3. `03_etl_limpieza_plata.sql`: siete procedimientos, conversiones, estandarización, deduplicación e integración idempotente.
4. `04_vistas_gold_bi.sql`: cinco vistas Oro, KPIs y validaciones cuantitativas.

El deck del avance previo se conserva en `docs/archivo-historico/`; el archivo final para exponer es `docs/presentacion-final-equipo-2.pptx` (también exportado a PDF). El guion por rol y la salida de Plan B están en `docs/demo-y-guion.md` y `docs/plan-b-resultados.md`.
La guía de avance anterior también queda en `docs/archivo-historico/`; la guía que rige esta presentación está en `docs/guia-presentacion-proyecto-final.pdf`.

### Ejecución

En SQL Server 2022, abrir y ejecutar los cuatro archivos en orden (`01` → `04`) dentro de una instancia de práctica. Repetir el flujo es seguro para esta carga de demostración: no borra bases ni tablas, la ingesta exacta evita duplicados y la integración vuelve a procesar las llaves sin duplicar ventas Oro.

La carga actual utiliza `INSERT` y `OPENJSON`; no usa `BULK INSERT` porque los archivos originales no se incluyeron. No ejecutar sobre una instancia con políticas que impidan crear `DB_Vinicola_Integration`.

### Calidad y resultados reproducibles

- POS: 5 filas crudas, 5 IDs únicos, 5 ventas Oro; 0 filas inválidas en la muestra y 1 cliente nulo preservado como anónimo.
- CRM: 4 filas / 4 IDs únicos; 1 gasto imputado como proxy observado.
- Ratings: 3 filas / 3 vinos válidos.
- Oro: 24 botellas; ingresos de $22,760 MXN; venta anónima de $450 MXN.
- Platinum: 12 de 15 botellas (80%) corresponden a vino con puntaje >93; las 12 pertenecen a una sola persona en esta muestra.
- Origen: Rioja 12 botellas (50%), Mendoza 8 (33.33%) y Valle de Guadalupe 4 (16.67%).

La muestra no tiene filas duplicadas. La deduplicación se comprobó en un SQL Server desechable insertando una segunda fila POS con la misma llave y nueva fecha; Plata/Oro conservó una venta por llave y actualizó la versión elegida por fecha más reciente.

## 5. Integrantes y roles (cinco personas)

La guía conserva cuatro roles oficiales y divide el rol integrado de Liderazgo/BI en dos personas para equipos de cinco.

- **Data Architect / SQL Specialist:** José Hernández.
- **Data Engineer / Pipeline Lead:** Patricio García.
- **Data Quality & QA Specialist:** Ximena Ibarra.
- **Líder de Proyecto:** Ezequiel Aguilera.
- **BI & Analytics Specialist:** Joel Ibarra.

La distribución sigue los roles propuestos en el avance; requiere que los cinco integrantes mantengan la misma asignación al exponer.

## Presentación final

La portada usa una imagen conceptual generada para este proyecto; no representa una ubicación o marca comercial confirmada. La diapositiva de ETL muestra valores reales de la muestra antes y después de estandarizar. La presentación editable y su PDF están en `docs/`.
