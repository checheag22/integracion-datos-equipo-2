# Guion rápido para presentar y responder

Úsenlo para repartir la exposición y ensayar el banco oficial. La presentación completa dura 12–15 minutos, incluida una demo de 2–3 minutos; después vienen 6–8 minutos de preguntas. Hablen con sus palabras: aprendan la idea y los números, no un párrafo de memoria.

## Reparto sugerido

| Persona | Diapositivas | Tiempo aproximado | Idea principal |
|---|---|---:|---|
| Ezequiel | 1 y 2 | 2–3 min | Qué integramos y cuáles son los límites |
| José | 3 | 2 min | Cómo se relacionan las tablas y sus llaves |
| Patricio | 4 y 5 | 4–5 min, incluida demo | Cómo se limpian e integran las ventas |
| Ximena | 6 | 2 min | Qué controles se ejecutaron y qué limitan |
| Joel | 7 y 8 | 2–3 min | Cómo leer Oro y dónde está el proyecto |

## Lo que puede decir cada quien

### Ezequiel — inicio, alcance e insight

**Inicio:** “Somos el Equipo 2. Integramos una muestra de ventas, clientes y calificaciones de vino en SQL Server para contestar preguntas de negocio con datos relacionados. ‘Viñedos del Alba’ es solo el nombre ficticio del caso.”

**Fuentes y límites:** “Tenemos cinco ventas, cuatro clientes y tres vinos. La muestra se carga desde los scripts del repositorio; no recibimos los archivos originales. Tampoco tenemos datos de inventario ni ventas web, así que no vamos a inventar conclusiones sobre esos temas.”

### José — arquitectura

“Bronce conserva la entrada como texto. Plata convierte y limpia los datos; ahí viven las dimensiones de clientes y vinos. Oro tiene las ventas, con una llave foránea hacia cada dimensión. Así una venta analítica no puede quedar ligada a un cliente o vino que no exista.”

### Patricio — corrida y ETL

“Primero revisamos el dato como llegó. Después usamos TRIM y UPPER para normalizar texto, TRY_CONVERT para validar conversiones y ROW_NUMBER para escoger una versión por llave. Al final integramos las ventas sin borrar la venta anónima. Si repetimos la carga, no se duplica la venta en Oro.”

**Demo (2–3 min):** ejecutar los cuatro archivos en orden si la instancia está vacía; si ya se preparó, mostrar `EXEC plata.usp_ProcesarPlata;`. Después consultar `oro.vw_Calidad_Integracion`, `oro.vw_Gold_Ventas_Vinos` y ejecutar:

```sql
EXEC plata.sp_HistorialVentasCliente
    @ID_Cliente = 'CLI-V01',
    @FechaInicio = '2026-08-01',
    @FechaFin = '2026-08-03';
```

La salida esperada son dos ventas del cliente en esas fechas. Expliquen qué respondió la consulta. Si la demo falla, usen capturas reales recientes de SSMS y aclaren que son respaldo; todavía faltan por preparar esas capturas.

### Ximena — calidad

“La muestra tiene cinco ventas POS integradas, cero filas POS rechazadas, cero clientes o vinos huérfanos y una venta anónima conservada. El CRM tiene un gasto faltante: se muestra como proxy de $4,920 y queda marcado como imputado. Estos controles describen la muestra disponible; no prueban calidad de fuentes que no recibimos.”

### Joel — BI, documentación y tablero

**Lectura de Oro:** “Las cinco ventas suman $22,760 MXN. Rioja aporta $14,400, o 63.27%. También hay $14,400 en vinos con más de 93 puntos, pero las doce botellas son de una persona. Es una hipótesis para probar, no una causa demostrada.”

“El repositorio tiene los cuatro scripts SQL, el README, la presentación y la guía de respuestas. El Trello ya está actualizado con el avance y pendientes de defensa. Nos falta completar el diccionario de Customer 360 con su definición oficial, preparar las capturas de SSMS y subir el PDF a Moodle cuando corresponda.”

## Banco oficial: preguntas y respuestas breves

### Patricio García — Ingeniero ETL

1. **¿Por qué conservar POS-804 como `CLI-MOSTRADOR`?** La venta es válida aunque no sepamos quién compró. Si la quitamos, perdemos $450 MXN de ingreso; la conservamos sin atribuirla a una persona.
2. **¿Cómo evitan cargar dos veces las mismas ventas?** Bronze evita reinsertar la fila idéntica; el proceso deduplica por ID de venta y Oro protege esa llave. En una prueba añadimos una versión posterior y Oro mantuvo cinco ventas, tomando la más reciente.
3. **¿Por qué marcar los $4,920 como imputados?** Porque es un proxy calculado desde POS para llenar el gasto CRM faltante. La marca permite distinguirlo del dato que sí reportó CRM y evita presentarlo como gasto anual confirmado.

### José Hernández — Arquitecto de datos

1. **¿Qué ventaja tiene separar Bronce, Plata y Oro?** Bronce permite revisar el origen; Plata limpia y valida; Oro facilita el análisis. Si una regla cambia, podemos corregir el proceso sin perder la entrada original.
2. **¿Qué pasa si llega un SKU que no existe?** No se integra a Oro porque no encuentra dimensión y la llave foránea impide una relación inválida. Se conserva en Bronce, pero todavía no tenemos una tabla de rechazos que registre el motivo.
3. **¿Cómo empatan `DB_Customer_360` con el modelo actual?** Todavía no lo integramos: faltan Tickets, Interacciones, Ventas y la definición de `email_usuario`. Primero necesitamos el diccionario y la fuente; luego comprobamos cómo relacionar el correo. No inventamos esa unión.

### Ximena Ibarra — Analista QA

1. **¿Qué otras anomalías revisarían?** Fechas o números que no conviertan, precios o cantidades fuera de rango, puntuaciones fuera de 0–100, duplicados y llaves sin correspondencia. En la muestra actual no hubo filas POS inválidas ni huérfanas.
2. **¿Cómo afecta que falten descripciones del diccionario?** Sin significado, unidad y reglas de nulidad, dos personas pueden interpretar el mismo campo de forma distinta. Eso debilita validaciones, análisis y confianza; faltan las definiciones oficiales de Customer 360.
3. **¿Qué harían con un rating nulo o fuera de rango?** Se conserva en Bronze para rastrearlo, se excluye de Plata/Oro y se cuenta en calidad. La regla de puntaje válida es de 0 a 100.

### Joel Ibarra — Documentación y Trello

1. **¿Qué falta para dejar Trello y el diccionario al 100%?** Trello ya está actualizado; falta cerrar los pendientes con evidencia. Para Customer 360 necesitamos las definiciones oficiales de Tickets, Interacciones y Ventas; esas tablas no están en el SQL.
2. **¿Para qué sirve `MS_Description` además de un documento?** Guarda definiciones dentro de SQL Server, junto a las tablas y columnas, para que consultas y herramientas las puedan recuperar. Esa propiedad aún no está incluida en nuestros scripts.
3. **¿Cómo mantienen alineados SQL, presentación y Trello?** Tomamos la rama de entrega del repositorio como referencia, actualizamos las tarjetas con responsable y evidencia, y cambiamos la presentación solo después de comprobar el resultado en SQL.

### Ezequiel Aguilera — Líder de proyecto y BI Specialist

1. **¿Qué decisión sugieren los resultados?** Probar una recomendación de vinos Rioja o con más de 93 puntos y medir su conversión. No podemos decir que el puntaje causó la venta: son cinco transacciones y las doce botellas >93 son de una sola persona.
2. **¿Qué limita no tener inventario ni ventas web?** No podemos recomendar reabasto ni medir conversión en línea. El análisis solo describe las ventas POS disponibles.
3. **¿Cómo organizaron la demo y el Plan B?** Repartimos arquitectura, ETL, QA, liderazgo/BI y documentación/Trello entre el equipo. La demo se limita a calidad, vista Oro e historial de cliente; Ximena lleva capturas actuales de SSMS como respaldo cuando las preparemos.

## Una discrepancia que deben resolver antes de exponer

El banco oficial asigna a Ezequiel “Líder de proyecto y BI Specialist” y a Joel “Documentación y Trello”. La guía oficial de presentación dice que, para cinco integrantes, se divida Liderazgo y BI entre dos personas. Para la exposición, Ezequiel presenta el contexto y Joel explica la lectura BI además de Documentación/Trello; el banco de preguntas conserva los nombres originales. Por eso ambos deben dominar el insight de la diapositiva 7, y Ezequiel contesta la pregunta oficial de decisión comercial.

## Qué falta para cerrar la entrega

- Conseguir o confirmar si existen los CSV/Excel originales; el repositorio actual carga una muestra incluida en SQL y no puede demostrar la ingesta de esos archivos.
- Obtener el diccionario oficial de `DB_Customer_360` y decidir si se implementan esas tablas o se documenta formalmente que quedan fuera del alcance.
- Preparar capturas reales y recientes de SSMS para el Plan B.
- Ensayar la demo en la computadora/instancia de exposición y comprobar la salida de dos ventas de `CLI-V01`.
- Subir el PDF a Moodle cuando la actividad esté disponible y verificar el estado de entrega.
