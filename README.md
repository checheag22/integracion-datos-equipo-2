# Integración de Datos — Equipo 2

Proyecto académico de integración POS + CRM + ratings de vinos para Otoño 2026.

## Estado técnico

- `sql/script.sql` ejecutó completo en SQL Server 2022 aislado el 29-oct-2026; pasó los ASSERTS de 5 ventas, 24 botellas, $22,760 MXN, una venta anónima y gasto imputado de $4,920 para CLI-V02.
- Crea 5 vistas y 7 procedimientos. El KPI incluye COUNT, SUM, AVG y GROUP BY.
- La consulta de Platinum arroja 12 de 15 botellas (80%) con puntaje >93; en esta muestra corresponden a una persona. Por origen geográfico: Rioja 12 botellas, Mendoza 8 y Valle de Guadalupe 4.
- El alcance verificable es pequeño: 5 transacciones POS, 4 registros CRM y 3 vinos. No hay inventario ni ventas web. El valor de $4,920 es un proxy del gasto observado en la muestra, no un gasto anual confirmado.

## Archivos

- `docs/avance-equipo-2.pptx`: presentación del avance compartida en Teams.
- `docs/avance.docx`: avance técnico editable. La invitación privada de Trello se sustituyó por el enlace corto que aparece en la presentación; confirmar que sea de solo lectura. La captura Trello incrustada es antigua y debe reemplazarse.
- `docs/guia-oficial-avance.pdf`: requisitos oficiales del avance.
- `sql/script.sql`: DDL, muestra, ETL, vistas, procedimientos y consultas.

## Ejecución

Requiere SQL Server 2022 (o versión compatible) y `sqlcmd`. Ejecutar desde una base/instancia de práctica con permisos para crear `DB_Vinicola_Integration`. El script recrea las vistas, procedimientos y tablas que enumera dentro de esa base; **no ejecutarlo sobre una base de trabajo con datos que deban conservarse**. No guardar contraseñas en este repositorio.

Ejemplo con autenticación integrada:

```sh
sqlcmd -C -b -S localhost -E -i sql/script.sql
```

## Pendientes conocidos

1. Confirmar roles con todos los integrantes y actualizar las notas del PPT, que aún mencionan el nombre antiguo `SQL_Equipo2_OpcionA_FINAL.sql`.
2. Actualizar Trello con tareas/responsables, captura real del tablero y permiso de lectura; validar el enlace. La guía exige las listas Backlog/Por hacer, En proceso, En revisión y Concluido.
3. Completar el PDF ejecutivo para Moodle. El estado de entrega/calificación no se pudo confirmar.
4. La deduplicación con `ROW_NUMBER()` se describe como futura; no está implementada para ingestas con IDs repetidos.
5. La presentación necesita mostrar la comparación completa de Platinum, el cruce ciudad de entrega/canal y volúmenes por origen.
6. El DER aparece como imagen, pero no se encontró el `.dot` editable.
7. El diccionario `DB_Customer_360` es una actividad separada de este caso vinícola y conserva tres tablas sin descripción; aclarar también la nomenclatura de esa base.

Los archivos originales POS/CSV/JSON mencionados en la presentación no estaban en la carpeta local revisada; el SQL contiene la muestra de forma embebida. Las muestras y resultados son demostrativos y no sustentan conclusiones generales de negocio.
