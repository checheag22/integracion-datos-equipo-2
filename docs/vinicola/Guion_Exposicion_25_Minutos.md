# Guion de exposición · 25 minutos

**Proyecto Integrador de Datos · Equipo 2 · Viñedos del Alba (caso ficticio)**

La presentación dura 25 minutos. Las preguntas del profesor se responden después y se preparan con el banco de evaluación por rol; no aparecen contestadas en las láminas. Hablen con calma y dejen que el público mire cada imagen antes de explicarla. Las cifras son de la corrida de demostración, no de una operación real.

| Diapositiva | Tiempo | Quién la presenta |
|---|---:|---|
| 1–2 | 2:45 | Ezequiel |
| 3–5 | 5:00 | José |
| 6–7 | 3:45 | Patricio |
| 8 | 4:00 | Patricio (2:15), Ximena (1:00), Joel (0:45) |
| 9 | 1:45 | Ximena |
| 10 | 1:30 | Joel |
| 11 | 1:45 | Ezequiel |
| 12 | 1:30 | Ximena |
| 13 | 1:30 | Joel |
| 14 | 1:30 | Ezequiel |
| **Total** | **25:00** | **Cinco integrantes** |

## 1. Del ticket a una respuesta confiable · 1:00 · Ezequiel

“Hola, somos el Equipo 2. El caso que usamos se llama Viñedos del Alba y es ficticio. En estos 25 minutos vamos a explicar un recorrido sencillo: parte de un ticket de venta, se conecta con información del cliente y del vino, pasa por reglas de limpieza y termina en consultas que pueden contestar preguntas del negocio. No vamos a empezar leyendo código. Primero explicaremos la idea y luego mostraremos qué hicimos en SQL Server. Al final distinguiremos lo que sí observamos de lo que todavía no podemos afirmar. Las preguntas quedan para después de la exposición.”

**Transición:** “Empecemos por la pregunta que nos llevó a integrar las fuentes.”

## 2. Una venta sola no cuenta toda la historia · 1:45 · Ezequiel

“Un ticket sirve para revisar una transacción: qué producto se llevó, cuántas botellas, cuánto pagó y a qué hora. Pero si alguien pregunta qué tipo de cliente lo compró o qué características tiene ese vino, el ticket por sí solo no basta. Esa información suele estar en otros sistemas. Por eso la pregunta del proyecto es: ¿qué compran nuestros clientes? Para responderla necesitamos reunir tres piezas: venta, cliente y vino.

La ilustración muestra esa unión de manera simple. POS representa el punto de venta. CRM guarda el perfil de cliente. La fuente de calificaciones describe los vinos. La integración permite consultar esas piezas juntas. El objetivo no es juntar todo por acumular tablas; buscamos dejar disponible una respuesta que se pueda rastrear hasta los datos que la formaron. Esa diferencia será importante cuando expliquemos los resultados: cada cifra se debe poder justificar con su fuente y con una regla.”

**Transición:** “¿Qué significa integrar? Lo podemos explicar con algo que todos conocemos.”

## 3. Integrar datos es unir pistas · 1:45 · José

“Imaginemos que alguien nos da tres cosas: un ticket, la ficha de quien compró y la ficha del producto. Cada papel cuenta algo diferente. Para saber que las tres piezas se refieren a la misma compra, necesitamos una referencia compartida. En una base de datos esa referencia se llama llave. Es como un número de pedido que aparece en varias partes.

En nuestro modelo, ID_Cliente permite relacionar la venta con el perfil del cliente. SKU_Vino permite relacionarla con la ficha del vino. La computadora no adivina que ‘José H.’ y ‘Jose Hernandez’ son la misma persona: depende de las llaves que acordamos. Esa es la parte central de la teoría de integración: combinar fuentes distintas usando reglas explícitas para que el resultado tenga significado. Si falta una llave o viene mal escrita, la relación puede fallar; por eso la limpieza se realiza antes de publicar el resultado para consulta.”

**Transición:** “Con esa idea, veamos qué aporta cada fuente.”

## 4. Cada fuente aporta una parte · 1:45 · José

“POS aporta la venta: el identificador del ticket, la fecha, el canal, la cantidad y el importe. CRM aporta información del cliente, como membresía o ciudad. Ratings aporta el puntaje y el origen del vino. Las tres fuentes son diferentes, pero el POS trae ID_Cliente y SKU_Vino, que nos permiten buscar los datos relacionados.

El dibujo es un apoyo visual hecho como imagen; no es una captura de un sistema ni representa una carga en vivo. Lo que demuestra la ejecución está en la diapositiva de SQL Server y en el archivo de evidencia. Para este recorrido usamos datos de prueba en SQL Server, porque no teníamos los archivos fuente originales. Lo decimos desde el principio para no confundir una demostración académica con datos reales de una vinícola. La arquitectura, las reglas y las consultas sí son las que implementamos; la muestra numérica permite observar su funcionamiento.”

**Transición:** “Ahora sigamos las llaves en el modelo.”

## 5. La venta queda en medio · 1:30 · José

“En el dibujo, cliente, venta y vino forman una cadena. Cada venta tiene su propio identificador. Además, guarda una referencia al cliente y otra al producto. En SQL esas referencias se implementan con llaves foráneas. La llave primaria identifica una fila; la foránea apunta a una fila de otra tabla. Así la base puede proteger la relación y evitar que una venta quede asociada con un cliente o vino que no existe.

En la muestra hay una venta anónima. La conservamos ligada a CLI-MOSTRADOR. Eso significa que sabemos que hubo una venta, pero no atribuimos una persona que no conocemos. Es una decisión de calidad: conservar el ingreso y marcar el límite de lo que se sabe, en vez de inventar una identidad.”

**Transición:** “Con el modelo claro, vamos a seguir el camino que recorre el dato.”

## 6. Tres etapas: guardar, ordenar y responder · 2:00 · Patricio

“Usamos una arquitectura de tres zonas, que suele llamarse Medallion. Lo podemos traducir a tres verbos: Bronce guarda, Plata ordena y Oro responde.

Bronce recibe la información de origen y conserva cómo llegó. Si una fila trae espacios, un dato extraño o un duplicado, sigue siendo importante conservar esa evidencia para entender qué pasó. Plata es donde aplicamos las reglas: limpiamos espacios, convertimos tipos, revisamos rangos y relacionamos los datos. También preparamos las dimensiones de cliente y vino. Oro contiene la información integrada lista para las consultas y los indicadores.

La ventaja de separar etapas es que podemos revisar el proceso. Si una venta no aparece en Oro, preguntamos qué pasó en Bronce y qué regla se aplicó en Plata. Cada zona tiene una responsabilidad y evita mezclar la entrada cruda con la respuesta que usará el análisis. El dibujo representa esta idea con una caja de entrada, una limpieza y un reporte final.”

**Transición:** “Veamos una fila real de nuestra prueba para que las capas no se queden como teoría.”

## 7. POS-805 llegó dos veces · 1:45 · Patricio

“Este ejemplo muestra dos versiones de la misma venta, POS-805: una a las 19:15 y otra a las 19:30. Además, el identificador tenía espacios. En Bronce conservamos las dos filas. En Plata quitamos los espacios y comparamos las versiones por su fecha y hora. La regla decide que la versión más reciente, 19:30, es la vigente. En Oro queda una sola venta.

La palabra ROW_NUMBER que aparece en la ilustración es la función SQL que numera las filas de cada grupo para poder elegir una. No hace falta memorizar el código; basta entender la decisión: primero reconocemos que los identificadores son iguales después de limpiar el formato; después ordenamos por hora y nos quedamos con el registro más reciente. Si mañana alguien pregunta por qué desapareció la versión de las 19:15, todavía podemos verla en Bronce y explicar la regla.”

**Transición:** “Con esa lógica presente, pasemos a la corrida completa.”

## 8. Lo ejecutamos desde una base vacía · 4:00 · Patricio, Ximena y Joel

**Patricio · 2:15:** “La captura muestra la salida de una corrida real en SQL Server 2022 usando sqlcmd. El proceso se ejecutó en cuatro pasos: crear estructura y relaciones; cargar los datos de entrada en Bronce; limpiar y construir Plata; y publicar las tablas y vistas de Oro. Se partió de una base vacía. La salida del terminal resume la ejecución y no es una pantalla dibujada.

Miremos la primera línea: siete filas de POS en Bronce, seis identificadores después de normalizar y cinco ventas en Oro. La razón de la diferencia es concreta: hay una versión repetida y una fila cuya cantidad no se puede interpretar como número. Oro conserva las cinco ventas válidas. La siguiente línea confirma las anomalías detectadas y el resumen inferior muestra 24 botellas y 22,760 pesos. También se repitió el proceso: el resultado volvió a ser cinco ventas y el mismo total. Eso comprueba que esta corrida no duplicó las ventas al ejecutarse de nuevo.”

**Ximena · 1:00:** “Voy a explicar los controles de calidad que aparecen en el resultado. La cantidad inválida no se convierte a un número, así que la venta no pasa a Oro. En calificaciones entraron cuatro registros: tres están dentro del rango esperado y el valor 120 se marca como inválido. No borramos la evidencia original: Bronce permite revisar las entradas. El control responde tres preguntas: qué recibimos, qué regla no se cumplió y cuántas filas quedaron listas.”

**Joel · 0:45:** “Después de la carga también verificamos las cinco vistas y siete procedimientos. La captura resume la salida del proceso. En el repositorio quedan los scripts y el archivo de evidencia para revisar la secuencia completa. La idea de la demostración no es que aprendamos cada comando de memoria, sino mostrar que el mismo flujo llega al mismo resultado desde cero.”

**Transición:** “Ahora resumimos esos controles con los conteos.”

## 9. De siete filas a cinco ventas válidas · 1:45 · Ximena

“Este conteo se puede leer de izquierda a derecha. Entraron siete filas POS. Al limpiar el identificador, encontramos seis IDs diferentes, porque una venta llegó en dos versiones. Finalmente quedaron cinco ventas válidas en Oro: además de la versión anterior, una fila tenía la palabra ‘muchas’ donde debía venir la cantidad de botellas. SQL no la puede convertir a entero, por eso no se integra como venta válida.

También revisamos las calificaciones: cuatro registros llegaron, tres cumplieron el rango de 0 a 100 y uno, con valor 120, quedó fuera de la regla. En la imagen podemos ver una duplicidad; el número resume el conjunto. Estos datos de prueba son sintéticos y se usan para demostrar los controles. La calidad no consiste en ocultar errores: consiste en poder detectarlos, explicar la regla y dar un resultado que se entienda.”

**Transición:** “Una vez listas las tablas, las vistas simplifican consultas frecuentes.”

## 10. Cada vista responde una pregunta · 1:30 · Joel

“Las vistas son consultas guardadas que podemos volver a usar. Una muestra el detalle de cada venta; otra combina la venta con cliente y vino. Las de indicadores agrupan por membresía y canal, o por origen del vino. La última resume la calidad de la integración.

Pensemos en las vistas como reportes preparados: el equipo puede consultar una pregunta conocida sin escribir todo el cruce cada vez. En el proyecto verificamos que las cinco vistas devolvieran resultados y también ejecutamos siete procedimientos. Para exponer no hace falta enumerar sus nombres técnicos. Es más fácil recordar qué pregunta contesta cada una y mostrar un ejemplo si el profesor pide detalle. La ronda de preguntas va después de estos 25 minutos.”

**Transición:** “¿Y qué historia podemos contar con los resultados de Oro?”

## 11. Rioja concentra parte del ingreso · 1:45 · Ezequiel

“Las cinco ventas suman 22,760 pesos. De ese total, 14,400 están asociados a vinos de origen Rioja; es 63.27 por ciento del ingreso que observamos en esta muestra. También encontramos doce botellas con puntaje arriba de 93 dentro de una compra de una persona.

Es útil decir las dos cosas juntas: hay una señal interesante, pero la muestra solo tiene cinco ventas. Podemos afirmar que ocurrió en estos registros. No podemos decir que los puntajes altos causaron la compra ni que todos los clientes comprarán de la misma forma. Para hablar de causalidad necesitaríamos una comparación planificada y más observaciones.

La utilidad del análisis es sugerir una pregunta para investigar. Por ejemplo, si recomendaciones basadas en origen o calificación podrían ayudar. Esa sería una hipótesis futura, no un resultado que ya hayamos comprobado.”

**Transición:** “Para ser claros, enumeremos también qué información nos hace falta.”

## 12. Qué falta para usarlo con datos del negocio · 1:30 · Ximena

“Este proyecto demuestra el proceso de integración, pero la muestra no equivale a la operación completa de una vinícola. No recibimos los CSV o Excel originales; por tanto, no conectamos una fuente real. Cinco ventas permiten comprobar la lógica y ver resultados, pero no generalizar. Tampoco hay datos de inventario o ventas en línea para medir existencias o conversión. Un gasto de cliente aparece como proxy y está marcado como aproximación.

Estas limitaciones no invalidan la ejecución académica. Delimitan la conclusión. Si tuviéramos los archivos y más historial, podríamos medir si los resultados cambian por periodo y validar las reglas con quien administra la fuente. Para recomendar una acción de negocio, primero deberíamos comprobar que los datos representan esa operación.”

**Transición:** “Con esas brechas claras, los siguientes pasos se ordenan solos.”

## 13. Primero mejorar la entrada · 1:30 · Joel

“Primero conectaríamos los archivos originales y registraríamos de qué fuente y fecha llegó cada carga. Después guardaríamos los rechazos junto con su motivo, para que el equipo pueda revisar por qué una fila no pasó. Con más periodos volveríamos a calcular los indicadores para ver si las señales se sostienen. Añadiríamos inventario solo cuando hubiera una fuente confiable.

También conviene separar las herramientas del equipo: GitHub conserva versiones de scripts y documentos; Trello sirve para organizar responsable y siguiente tarea; Moodle es donde se entrega el archivo académico. Una no reemplaza a la otra. El flujo es simple: construir y revisar, coordinar pendientes y presentar la entrega.”

**Transición:** “Ezequiel cierra con la idea principal del proyecto.”

## 14. Conectamos datos para responder mejor · 1:30 · Ezequiel

“Lo que construimos une registros mediante llaves, aplica reglas visibles y presenta una salida que se puede consultar. La corrida desde cero demuestra el flujo para esta muestra. Vimos cómo Bronce conserva, Plata ordena y Oro responde. También vimos que un resultado útil incluye tanto los datos válidos como los límites y las filas que requieren atención.

El siguiente paso depende de obtener fuentes reales y más historial. Con eso podríamos validar los indicadores antes de usarlos para una decisión del negocio. Gracias por escucharnos. Terminamos los 25 minutos de exposición; ahora abrimos la ronda de preguntas.”

## Recordatorio para los cinco

- Ezequiel abre, explica la pregunta de negocio, presenta la lectura con sus límites y cierra.
- José explica integración, fuentes y llaves con ejemplos sencillos.
- Patricio explica las capas y guía la demostración de SQL.
- Ximena interpreta errores, controles de calidad y límites de la muestra.
- Joel explica las vistas y dónde queda el seguimiento y la entrega.
- Las respuestas del profesor se preparan por separado en el banco oficial. No se leen durante la exposición.
