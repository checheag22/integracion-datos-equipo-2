# Guía de defensa por rol — Equipo 2

**Caso:** Viñedos del Alba *(nombre ficticio propuesto para el proyecto académico)*.  
**Fuente:** [Banco oficial de preguntas del Equipo 2](banco-preguntas-oficial-equipo-2.pdf).

Esta guía responde el banco oficial con base en los scripts y resultados disponibles. Cuando un elemento no está implementado, la respuesta lo dice y propone cómo completarlo.

**Moodle pide preparar dos preguntas por integrante; el banco adjunto contiene tres por rol.** Ensayen primero las dos marcadas **PRIORIDAD**. Lean la tercera como pregunta de respaldo. Respuestas de 35–45 segundos ayudan a completar ocho minutos de defensa para el equipo.

## Patricio García — Ingeniero ETL

### 1. PRIORIDAD — ¿Por qué conservar POS-804 y asignarle `CLI-MOSTRADOR`?

POS-804 es una venta válida: tiene SKU, canal, cantidad y precio correctos; lo que falta es la identidad del cliente. Eliminarla reduciría ventas e ingresos. Por eso se conserva como transacción anónima con `CLI-MOSTRADOR`, sin atribuirla a una persona.

### 2. PRIORIDAD — ¿Cómo evitan duplicar ventas al volver a correr el script?

La ingesta Bronze evita insertar de nuevo una fila idéntica. En la transformación, `ROW_NUMBER()` elige una versión por `ID_Venta_POS`, prioriza la fecha más reciente y desempata con el identificador de ingesta. La llave primaria de Oro en `ID_Venta_POS` y las operaciones de actualización/inserción hacen que la reejecución no cree una segunda venta. Bronze conserva la traza de la fuente.

### 3. Respaldo — ¿Por qué marcar el gasto de CLI-V02 como imputado?

Porque los `$4,920 MXN` provienen de ventas POS observadas en esta muestra y se usan como proxy del gasto CRM faltante. `Gasto_Fue_Imputado=1` permite reconocer su origen, excluirlo o tratarlo distinto en análisis y evita presentarlo como gasto anual confirmado por el CRM.

## José Hernández — Arquitecto de datos

### 1. PRIORIDAD — ¿Qué aporta separar Bronce, Plata y Oro?

Bronce preserva los valores de origen para auditoría y reproceso; Plata limpia, convierte, deduplica y aplica reglas; Oro publica hechos y vistas listos para consulta. Así se puede rastrear un resultado hasta su fuente y corregir reglas sin sobrescribir el dato crudo.

### 2. PRIORIDAD — ¿Qué pasa si llega una venta con un `SKU_Vino` desconocido?

La llave foránea de `oro.Fact_Ventas_POS` impide registrar una venta Oro con un vino inexistente. El proceso actual integra solo SKUs que encuentra en `plata.Dim_Vinos`; la fila sigue en Bronce, pero aún no se envía a una tabla de rechazos. Para producción convendría registrar ahí el motivo —por ejemplo, `SKU sin correspondencia`— y revisarlo antes de reintentar.

### 3. Respaldo — ¿Cómo se relaciona `DB_Customer_360` con el modelo actual?

No está implementado en esta entrega. El modelo actual integra POS, CRM y ratings mediante `ID_Cliente` y `SKU_Vino`; no contiene `Tabla_Tickets`, `Tabla_Interacciones` ni una llave `email_usuario`. Para integrarlo habría que recuperar su diccionario y fuente, confirmar cómo se normaliza y relaciona el correo, y después crear staging, reglas y relaciones verificables. No se deben inventar esas tablas o vínculos.

## Ximena Ibarra — Analista QA

### 1. PRIORIDAD — ¿Qué otras anomalías revisar antes de aceptar la carga?

Además de nulos, revisaría llaves duplicadas, fechas no convertibles, botellas no positivas, precios negativos, clientes o SKUs huérfanos, puntuaciones fuera del rango 0–100, categorías fuera de catálogo y campos de texto vacíos o con espacios. En esta demo, de siete filas POS Bronce quedan seis IDs únicos: se descarta una versión anterior duplicada, se excluye POS-806 porque `muchas` no convierte a cantidad y Oro conserva cinco ventas válidas. También se excluye un rating sintético de 120 y se conserva una venta anónima.

### 2. Respaldo — ¿Cómo afectan las descripciones faltantes del diccionario?

Sin definición, unidad, dominio y regla de nulidad no es claro qué significa cada campo ni cómo usarlo. Eso dificulta validar, integrar y explicar indicadores, y reduce la confianza en los datos. En el modelo `Customer 360` las descripciones de Tickets, Interacciones y Ventas siguen pendientes; la entrega actual documenta el esquema de vinícola, no esas tablas ausentes.

### 3. PRIORIDAD — ¿Qué hacer con un rating nulo o fuera de rango?

La transformación actual conserva el registro en Bronze y excluye de Plata los puntajes nulos, no convertibles o fuera de 0–100; Oro solo consulta vinos integrados válidos. La vista `oro.vw_Calidad_Integracion` cuenta ratings inválidos y la restricción de Plata/Oro evita valores fuera de escala.

## Joel Ibarra — Documentación y Trello

### 1. PRIORIDAD — ¿Qué falta para completar diccionario y Trello?

El tablero ya quedó con nombre del caso, descripción, fondo temático y columnas en español; también conserva el avance previo y registra tareas para defensa, demo, capturas Plan B, Moodle y diccionario. Falta cerrar esas tareas con evidencia. Para el diccionario `Customer 360` hay que obtener la definición oficial de Tickets, Interacciones y Ventas; ese modelo no viene implementado en el SQL actual.

### 2. Respaldo — ¿Para qué documentar con `MS_Description` además de un documento?

Las propiedades extendidas dejan las descripciones junto a las tablas y columnas de la base de datos. Herramientas y consultas a `sys.tables`, `sys.columns` y `sys.extended_properties` pueden recuperarlas sin depender de un Word separado. Esta entrega aún no agrega `MS_Description`; se propone como mejora pendiente del esquema SQL.

### 3. PRIORIDAD — ¿Cómo mantener alineados SQL, presentación y Trello?

Usar la rama de entrega del repositorio como versión de referencia, enlazarla desde las tarjetas, registrar responsable y evidencia, y actualizar presentación solo con resultados comprobados del mismo SQL. La rama publicada es `entrega-final-2026-11-23`; Trello se mantiene privado para sus miembros.

## Ezequiel Aguilera — Líder de proyecto y BI Specialist

### 1. PRIORIDAD — ¿Qué decisión sugieren Rioja y los vinos con más de 93 puntos?

La muestra suma `$22,760 MXN`; los vinos de Rioja aportan `$14,400` (63.27%) y los vinos con más de 93 puntos también suman `$14,400`, por la venta de 12 botellas de Tempranillo Rioja calificado con 93.8. La coincidencia no demuestra que el puntaje causó la venta ni que el patrón se repita. Se puede proponer una prueba pequeña de recomendación/promoción y medir conversión e ingreso incremental con más clientes.

### 2. PRIORIDAD — ¿Qué limita no tener inventario ni ventas web?

No se puede estimar existencia o agotamiento, recomendar cantidades de reabastecimiento, comparar conversión en línea ni medir la mezcla de canales completa. Las conclusiones describen POS, CRM y ratings de la muestra; no sustituyen una planeación de inventario o comercio electrónico.

### 3. Respaldo — ¿Cómo coordinar la corrida y el Plan B?

El reparto oficial asigna arquitectura a José, ETL a Patricio, QA a Ximena, documentación/Trello a Joel y liderazgo/BI a Ezequiel. La demo debe ejecutar el flujo modular una vez, revisar `oro.vw_Gold_Ventas_Vinos` y demostrar `plata.sp_HistorialVentasCliente` para `CLI-V01` entre `2026-08-01` y `2026-08-03`. Ximena prepara capturas recientes de Calidad, Vista 360° y KPIs solo como respaldo si falla la corrida en vivo; no se presentan capturas simuladas como ejecución.

## Consultas cortas de apoyo

```sql
SELECT * FROM oro.vw_Calidad_Integracion;
SELECT * FROM oro.vw_Gold_Ventas_Vinos ORDER BY Fecha_Hora;

EXEC plata.sp_HistorialVentasCliente
    @ID_Cliente = 'CLI-V01',
    @FechaInicio = '2026-08-01',
    @FechaFin = '2026-08-03';
```

La salida del historial son dos ventas de `CLI-V01` en ese intervalo, comprobadas en la corrida reciente. Para la exposición, usen la vista de calidad y la Vista Gold como las dos consultas principales.
