# Estado de entregables — Integración de Datos, Equipo 2

**Corte de revisión:** 23 de noviembre de 2026. Este estado separa lo verificado en los archivos y en la corrida de lo que sigue pendiente en plataformas externas.

## Entrega de exposición

| Requisito | Estado | Evidencia / pendiente |
|---|---|---|
| Caso, alcance y fuentes | Cubierto | POS, CRM y ratings. El nombre Viñedos del Alba es ficticio; no se recibieron CSV/Excel originales, inventario ni datos web. |
| Arquitectura y modelo | Cubierto | Capas Bronce, Plata y Oro, DER, llaves, reglas ETL y límites de la muestra en el deck y README. |
| Corrida demostrable | Verificada | SQL Server 2022 Developer desde base vacía: cuatro scripts en orden y segunda ejecución. Resultado: POS `7 → 6 → 5`, una versión duplicada descartada, una venta POS inválida excluida, rating `120` excluido; Oro conserva 5 ventas, 24 botellas y $22,760 MXN. |
| Vistas y procedimientos | Verificados | Cinco vistas consultadas; siete procedimientos ejecutados. La inserción de prueba fue revertida y no dejó el cliente temporal. |
| Evidencia visual y de salida | Incluida | `captura-sqlserver-demo-2026-11-23.png` y salida íntegra `.txt`. La captura es de `sqlcmd` conectado a SQL Server, no de SSMS. |
| Exposición y defensa | Preparada | 18 diapositivas y guion de 25 minutos de exposición/demo. Las preguntas van al terminar; sus respuestas están en un archivo aparte y no se proyectan en el deck. |
| Envío en Moodle | Pendiente | La actividad 2139292 abre el 24 de noviembre de 2026 a las 11:00 y cierra el 26 a las 15:00. No se ha enviado ningún archivo. |

## Entregas de otras actividades que aparecen en el curso

- **Actividad 2136994 — práctica de Medallion/Databricks:** enviada el 23 de noviembre como `Actividad_Clase_27_Carlos_Aguilera.pdf`; Moodle la muestra “Enviado para calificar”, todavía sin calificación. Es una actividad separada del proyecto de vinícola.
- **Actividad 2128345 — diccionario Customer 360:** `Act 9.pdf` figura enviada y calificada con **83.33/100**. La retroalimentación pide ejecutar instrucciones y scripts en secuencia, adjuntar evidencia completa y responder cómo el linaje de datos ayuda en auditorías de cumplimiento. Ese trabajo no es el modelo de vinícola.
- **Brecha de Customer 360:** no encontramos en el repositorio del proyecto ni en los archivos locales revisados el esquema/fuentes oficiales de `Tabla_Tickets`, `Tabla_Interacciones` y `Tabla_Ventas` (o sus definiciones completas). No es correcto fabricar esos metadatos para afirmar que el diccionario está terminado. La rúbrica separada también pide propiedades `MS_Description`, ejecutar el procedimiento/script de diccionario y mostrar el Results Grid de SSMS. La evidencia `sqlcmd` de este proyecto no satisface ese requisito específico.

## Pendientes concretos

1. Entregar en la actividad 2139292 la presentación final cuando Moodle abra. El paquete ya está preparado; falta la acción de envío dentro de la ventana indicada.
2. Para resolver correctamente el diccionario Customer 360, recuperar el SQL/diccionario de datos oficial de esa actividad y producir la evidencia de ejecución SSMS que pide su rúbrica. Después, responder la reflexión de linaje y reemplazar o complementar el PDF enviado según permita la actividad.
3. Si el docente exige archivos originales de las fuentes o captura de SSMS para esta defensa, obtenerlos/confirmarlo. La corrida actual sí prueba SQL Server real, pero se hizo mediante `sqlcmd` en un contenedor temporal.

## Archivos principales

- Presentación editable: `presentacion-final-equipo-2.pptx`; versión de lectura: `presentacion-final-equipo-2.pdf`.
- Avance editable y PDF: `avance.docx` y `avance.pdf`.
- Guiones: `demo-y-guion.md`, `guion-rapido-por-integrante.md`, `respuestas-banco-preguntas-por-rol.md`.
- Evidencia técnica: `evidencia-ejecucion-sqlserver-2026-11-23.txt`, `captura-sqlserver-demo-2026-11-23.png`.
- Ejecución reproducible local: `../tasks/run-sqlserver-demo.sh` (requiere Docker y SQL Server 2022 Developer image).
