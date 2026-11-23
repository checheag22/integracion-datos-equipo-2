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

> “Somos el Equipo 2. Conectamos ventas POS, clientes del CRM y calificaciones de vinos en SQL Server para saber qué se vendió, por qué canal y con qué perfil. Viñedos del Alba es un nombre ficticio. La base de muestra tiene cinco ventas, cuatro clientes y tres vinos; agregamos tres filas sintéticas para demostrar cómo se limpian datos sucios. No recibimos archivos fuente, inventario ni ventas web.”

En la diapositiva 2, indicar en una frase quién lleva Arquitectura, ETL, QA, Liderazgo/BI y Documentación/Trello. Los nombres y roles coinciden con el banco oficial.

### 4–5 · José — arquitectura y modelo

> “Bronce conserva los valores como llegaron; Plata limpia, escoge versiones y conecta cliente con vino; Oro publica las cinco ventas válidas y sus vistas. La llave primaria identifica la venta y dos llaves foráneas conectan Cliente y Vino. Si falta cliente, se conserva como CLI-MOSTRADOR.”

### 7–8 · Patricio — limpieza e idempotencia

> “En POS-805, TRIM quita los espacios y ROW_NUMBER elige la versión más reciente. En POS-806, TRY_CONVERT no puede convertir ‘muchas’ y la fila queda fuera de Oro. El puntaje 120 también queda fuera del rango. Repetir el proceso conserva cinco ventas en Oro.”

### 9 · Ximena — calidad

> “La vista marca siete filas POS en Bronce, seis IDs, un duplicado, un dato inválido y cinco ventas Oro. Ratings: cuatro recibidos, uno fuera de rango, tres válidos. No hay huérfanos; una venta anónima se conserva. Son cifras de la muestra.”

### 10 · Joel + Ezequiel — lectura de Oro

**Joel:** “La vista Oro muestra $22,760 en cinco ventas; Rioja aporta $14,400, 63.27% de los ingresos. En el segmento Platinum, 12 de 15 botellas superan 93 puntos.”

**Ezequiel:** “Las doce botellas son de una sola persona. Proponemos probar una recomendación con más clientes y medir conversión; estos datos no demuestran causalidad.”

### 6 · Patricio — demostración real (2:30)

La corrida ya fue ejecutada en SQL Server 2022 desde una base vacía con `sqlcmd` y un contenedor temporal. La diapositiva 6 contiene captura real; el log íntegro está en `docs/evidencia-ejecucion-sqlserver-2026-11-23.txt`. No es SSMS. Si el equipo decide mostrar una corrida en otra computadora, puede abrir los cuatro archivos en SSMS y seguir el mismo orden.

1. En Bronce, enseñar el duplicado ` POS-805 ` y la cantidad inválida `muchas`.
2. En Plata, explicar que queda la versión de las 19:30 y se excluye POS-806.
3. En la vista de calidad, leer `7 → 6 → 5` y `4 → 3` para POS y ratings.
4. En Oro, mostrar 5 ventas, 24 botellas y $22,760; preguntar: “¿Qué compró CLI-V01 y qué puntaje tenía el vino?”

### 11 · Ximena — límites

> “No podemos recomendar inventario ni evaluar e-commerce porque esas fuentes no están en el alcance. Customer 360 es un modelo separado y no está en este SQL. Tampoco generalizamos a partir de cinco ventas.”

### 12 · Joel — entrega

> “En `src` están los cuatro scripts en orden; en `assets`, el logo, el flujo, el DER y las imágenes; en `docs`, la presentación, las respuestas, el Plan B y la evidencia de ejecución. El tablero de Trello es privado. Antes de la entrega verificaremos el ensayo y cualquier requisito separado de Customer 360.”

### 13 · Ezequiel — cierre

> “Integramos para preguntar mejor. El siguiente paso es ampliar la muestra y medir si la recomendación realmente cambia la conversión. Gracias; estamos listos para responder.”

## Plan B

El PDF lleva la captura real de Terminal/`sqlcmd`, los conteos, el insight y las tres reglas de la demo. El log conserva resultados desde una base temporal limpia. Si preguntan, decir con claridad que fue SQL Server 2022 ejecutado con `sqlcmd`, no SSMS.

## Referencias rápidas

- Banco oficial y respuestas razonadas: `docs/respuestas-banco-preguntas-por-rol.md`.
- Salida reciente: `docs/plan-b-resultados.md` y `docs/evidencia-ejecucion-sqlserver-2026-11-23.txt`.
- Scripts: `src/01_ddl_arquitectura_der.sql` → `src/02_etl_ingesta_bronce.sql` → `src/03_etl_limpieza_plata.sql` → `src/04_vistas_gold_bi.sql`.
