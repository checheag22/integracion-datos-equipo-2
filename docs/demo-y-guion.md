# Guion de exposición y demo — Equipo 2

## Duración acordada: 25 minutos

Moodle pide una exposición de 25–35 minutos. La guía PDF adjunta marca 20–25 minutos en total, con 12–15 minutos de exposición/demo y 6–8 de preguntas. El guion usa el extremo común: **15 minutos de exposición y demo + 8 minutos de preguntas + 2 minutos para transiciones = 25 minutos**. En Moodle se indica que cada integrante debe preparar dos preguntas; el banco oficial trae tres por rol, así que estudien las dos prioritarias y lean la tercera como respaldo.

## Orden, quién habla y qué explicar

| Diapositiva | Persona | Tiempo | Explicación en una frase |
|---|---|---:|---|
| 1 | Ezequiel | 0:30 | Presentar el objetivo y el caso ficticio. |
| 2 | Ezequiel | 0:45 | Presentar las responsabilidades de los cinco integrantes. |
| 3 | Ezequiel | 1:00 | Explicar las fuentes disponibles y los límites de la muestra. |
| 4 | José | 1:15 | Recorrer Bronce → Plata → Oro en el flujo real. |
| 5 | José | 1:15 | Mostrar PK, FK y tipos del modelo relacional. |
| 6 | Patricio | 2:30 | Correr ingesta, transformación y consulta Oro en vivo. |
| 7 | Patricio | 1:15 | Explicar tres reglas de limpieza con ejemplos. |
| 8 | Patricio | 1:00 | Contar cómo se evita duplicar y qué probó SQL Server. |
| 9 | Ximena | 1:30 | Leer la calidad en conteos concretos. |
| 10 | Joel + Ezequiel | 2:00 | Joel lee Oro; Ezequiel interpreta la decisión comercial. |
| 11 | Ximena | 0:30 | Declarar con claridad qué no puede concluirse. |
| 12 | Joel | 1:00 | Ubicar los entregables y pendientes en GitHub Desktop/Trello. |
| 13 | Ezequiel | 0:30 | Cerrar con el siguiente paso medible e invitar preguntas. |
| **Exposición + demo** |  | **15:00** |  |
| **Preguntas** | Todos | **8:00** | Dos respuestas por integrante, alrededor de 48 segundos cada una. |
| **Transiciones y preparación de pantalla** | Todos | **2:00** | Cambios de expositor/ventana y margen técnico. |
| **Total** |  | **25:00** |  |

La asignación de roles y nombres sigue el banco oficial. Para cinco integrantes, la guía también pide dividir Liderazgo y BI: Joel muestra la lectura de la vista como parte del bloque documental y Ezequiel la traduce a decisión. Ezequiel conserva la respuesta comercial oficial del banco.

## Guion fácil de decir

### 1–3 · Ezequiel — propósito, roles y alcance

> “Somos el Equipo 2. Conectamos ventas POS, clientes del CRM y calificaciones de vinos en SQL Server para saber qué se vendió, por qué canal y con qué perfil. Viñedos del Alba es un nombre ficticio para este caso. La muestra tiene cinco ventas, cuatro clientes y tres vinos. No recibimos los archivos originales ni datos de inventario o venta web.”

En la diapositiva 2, indicar en una frase quién lleva Arquitectura, ETL, QA, Liderazgo/BI y Documentación/Trello. Los nombres y roles coinciden con el banco oficial.

### 4–5 · José — arquitectura y modelo

> “Bronce conserva los valores como llegaron; Plata limpia y relaciona; Oro concentra las ventas y las vistas de consumo. En el hecho de ventas, la llave primaria identifica la transacción y las llaves foráneas conectan Cliente y Vino. Si falta el cliente, se conserva la venta bajo CLI-MOSTRADOR. La relación con Customer 360 no está implementada.”

### 7–8 · Patricio — limpieza e idempotencia

> “TRIM quita espacios, UPPER normaliza categorías y TRY_CONVERT convierte valores solo cuando son válidos. El gasto faltante de CLI-V02 usa un proxy de $4,920 derivado de POS y queda marcado como imputado. ROW_NUMBER escoge una versión por ID; repetir el proceso conserva cinco ventas en Oro.”

### 9 · Ximena — calidad

> “La vista de calidad compara cinco registros POS en Bronce con cinco ventas en Oro. Hay cero filas POS inválidas, cero claves huérfanas y una venta anónima preservada. Los tres ratings son válidos y el gasto de un cliente está marcado como proxy. Estos conteos describen esta muestra, no sistemas completos.”

### 10 · Joel + Ezequiel — lectura de Oro

**Joel:** “La vista Oro muestra $22,760 en cinco ventas; Rioja aporta $14,400, 63.27% de los ingresos. En el segmento Platinum, 12 de 15 botellas superan 93 puntos.”

**Ezequiel:** “Las doce botellas son de una sola persona. Proponemos probar una recomendación con más clientes y medir conversión; estos datos no demuestran causalidad.”

### 6 · Patricio — demostración real (2:30)

Preparar SQL Server Management Studio (SSMS) con la base `DB_Vinicola_Integration` creada y los cuatro archivos del repositorio abiertos. La demostración muestra que la ingesta se puede volver a ejecutar, el procedimiento transforma los datos, la vista cuantifica calidad y Oro responde una pregunta. No hay que teclear los archivos durante la exposición.

1. Ejecutar `02_etl_ingesta_bronce.sql`; mostrar que la muestra permanece en 5 filas de POS, sin agregar las mismas filas otra vez.
2. Ejecutar `03_etl_limpieza_plata.sql`; explicar `TRIM`/`UPPER`, `TRY_CONVERT`, `ROW_NUMBER()` y la venta anónima.
3. Ejecutar `04_vistas_gold_bi.sql`; mostrar `oro.vw_Calidad_Integracion` y `oro.vw_Gold_Ventas_Vinos`. Preguntar: “¿Qué compró CLI-V01 y qué puntaje tenía el vino?”
4. Cerrar con Rioja: `$14,400` de ingresos, sin afirmar que el puntaje causó la venta.

**Antes de la presentación:** probar estos tres pasos en la computadora e instancia que se usarán. La ejecución limpia de los cuatro scripts ya se verificó por separado y el log reciente está en `docs/evidencia-ejecucion-sqlserver-2026-11-23.txt`.

### 11 · Ximena — límites

> “No podemos recomendar inventario ni evaluar e-commerce porque esas fuentes no están en el alcance. Customer 360 es un modelo separado y no está en este SQL. Tampoco generalizamos a partir de cinco ventas.”

### 12 · Joel — entrega

> “En `src` están los cuatro scripts en orden; en `assets`, el logo, el flujo, el DER y las imágenes; en `docs`, la presentación, las respuestas, el Plan B y la evidencia de ejecución. El tablero de Trello es privado. Antes de la entrega verificaremos el ensayo y cualquier requisito separado de Customer 360.”

### 13 · Ezequiel — cierre

> “Integramos para preguntar mejor. El siguiente paso es ampliar la muestra y medir si la recomendación realmente cambia la conversión. Gracias; estamos listos para responder.”

## Plan B

El PDF ya lleva los conteos, el insight y las tres acciones de la demo. El log de ejecución guarda resultados reales obtenidos en SQL Server 2022 desde una base temporal limpia. No es una captura de SSMS; si el docente solicita una captura visual de esa interfaz, hay que generarla en la computadora de exposición y presentarla como respaldo.

## Referencias rápidas

- Banco oficial y respuestas razonadas: `docs/respuestas-banco-preguntas-por-rol.md`.
- Salida reciente: `docs/plan-b-resultados.md` y `docs/evidencia-ejecucion-sqlserver-2026-11-23.txt`.
- Scripts: `src/01_ddl_arquitectura_der.sql` → `src/02_etl_ingesta_bronce.sql` → `src/03_etl_limpieza_plata.sql` → `src/04_vistas_gold_bi.sql`.
