# Reparto rápido — exposición de 25 minutos

Las preguntas comienzan **después** de los 25 minutos. Las respuestas del banco oficial están aparte en [`respuestas-banco-preguntas-por-rol.md`](respuestas-banco-preguntas-por-rol.md); no se proyectan como contenido de la exposición.

| Integrante | Diapositivas | Tiempo | Parte |
|---|---:|---:|---|
| Ezequiel Aguilera | 1–3, parte de 13, 14, 18 | 5:15 | Objetivo, alcance, lectura comercial, prueba propuesta y cierre. |
| Joel Ibarra | 4, 12, parte de 13, 17 | 4:45 | Fuentes y llaves, vistas, lectura de indicadores y repositorio. |
| José Hernández | 5–7 | 4:45 | Capas Bronce/Plata/Oro, recorrido de una fila, modelo relacional. |
| Patricio García | 8–10 | 6:00 | Corrida desde cero, limpieza e idempotencia. |
| Ximena Ibarra | 11, 15–16 | 4:15 | Controles, límites y mejoras priorizadas. |
| **Total** | **18 diapositivas** | **25:00** | Preguntas al terminar. |

## Mensaje listo para enviar al grupo

> Equipo, actualicé la presentación para que la **exposición dure 25 minutos completos**; la ronda de preguntas va después y sus respuestas no están en las diapositivas. Este es el reparto:
>
> • **Ezequiel:** diapositivas 1–3, parte de la 13, 14 y 18. Presenta el objetivo y el alcance; cierra la lectura de negocio, propone cómo medir la hipótesis y da el cierre. Tiempo: **5:15**.
> • **Joel:** diapositivas 4, 12, parte de la 13 y 17. Explica qué aporta cada fuente, presenta las vistas, lee indicadores y aclara qué se hace en GitHub, Trello y Moodle. Tiempo: **4:45**.
> • **José:** diapositivas 5–7. Explica Bronce, Plata y Oro, sigue el ejemplo de POS-805 por las capas y presenta el modelo y las llaves. Tiempo: **4:45**.
> • **Patricio:** diapositivas 8–10. Hace el recorrido de la corrida SQL, explica las reglas de limpieza y demuestra que reprocesar no duplica las ventas. Tiempo: **6:00**.
> • **Ximena:** diapositivas 11 y 15–16. Explica los controles, los límites de la muestra y qué mejoras seguirían. Tiempo: **4:15**.
>
> El profesor permite usar datos falsos para el recorrido: los ejemplos sintéticos están identificados como datos de prueba, no como ventas reales. La corrida comprobada dio 7 filas POS → 6 IDs → 5 ventas Oro, con 24 botellas y $22,760. Ensayemos con cronómetro para mantener los 25 minutos y dejemos las preguntas para el final. Cada quien revise por separado sus dos preguntas prioritarias del banco.

## Ideas clave para recordar

- **Ezequiel:** la muestra inspira una prueba comercial; no prueba causalidad.
- **Joel:** `ID_Cliente` y `SKU_Vino` explican cómo se integran las fuentes.
- **José:** Bronce conserva, Plata transforma, Oro responde.
- **Patricio:** `TRIM` limpia, `ROW_NUMBER` elige la última versión y `TRY_CONVERT` excluye valores no convertibles.
- **Ximena:** la vista de calidad cuenta entradas, errores y salida válida.

La corrida, captura y salida están en `plan-b-resultados.md`, `captura-sqlserver-demo-2026-11-23.png` y `evidencia-ejecucion-sqlserver-2026-11-23.txt`.
