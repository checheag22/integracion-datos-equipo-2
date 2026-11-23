/* 02 | Ingesta reproducible de la muestra de demostración.
   Las fuentes originales no se entregaron como archivos. Los registros POS-805
   (repetido/corregido) y POS-806 (cantidad inválida), más un rating fuera de
   escala, son datos sintéticos añadidos para demostrar limpieza en clase.
   No representan transacciones reales. Inserts exactos idempotentes. */
USE DB_Vinicola_Integration;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
GO
INSERT INTO bronce.Ventas_POS_Tienda
    (ID_Venta_POS, Fecha_Hora, ID_Cliente, SKU_Vino, Canal_Venta, Botellas_Vendidas, Precio_Unitario_MXN)
SELECT s.ID_Venta_POS, s.Fecha_Hora, s.ID_Cliente, s.SKU_Vino, s.Canal_Venta, s.Botellas_Vendidas, s.Precio_Unitario_MXN
FROM (VALUES
    (N'POS-801',N'2026-08-01T12:10:00',N'CLI-V01',N'VIN-CAB-01',N'Boutique',N'3',N'450.00'),
    (N'POS-802',N'2026-08-01T15:40:00',N'CLI-V02',N'VIN-MAL-02',N'Boutique',N'6',N'820.00'),
    (N'POS-803',N'2026-08-02T18:20:00',N'CLI-V01',N'VIN-TEM-03',N'Cata Presencial',N'12',N'1200.00'),
    (N'POS-804',N'2026-08-03T11:00:00',NULL,N'VIN-CAB-01',N'Boutique',N'1',N'450.00'),
    (N'POS-805',N'2026-08-03T19:15:00',N'CLI-V03',N'VIN-MAL-02',N'Boutique',N'2',N'820.00'),
    (N' POS-805 ',N'2026-08-03T19:30:00',N' CLI-V03 ',N' VIN-MAL-02 ',N' Boutique ',N' 2 ',N'820.00'),
    (N'POS-806',N'2026-08-03T20:00:00',N'CLI-V03',N'VIN-MAL-02',N'Boutique',N'muchas',N'820.00')
) s(ID_Venta_POS,Fecha_Hora,ID_Cliente,SKU_Vino,Canal_Venta,Botellas_Vendidas,Precio_Unitario_MXN)
WHERE NOT EXISTS (
    SELECT 1 FROM bronce.Ventas_POS_Tienda t
    WHERE ISNULL(t.ID_Venta_POS,N'')=ISNULL(s.ID_Venta_POS,N'')
      AND ISNULL(t.Fecha_Hora,N'')=ISNULL(s.Fecha_Hora,N'')
      AND ISNULL(t.ID_Cliente,N'')=ISNULL(s.ID_Cliente,N'')
      AND ISNULL(t.SKU_Vino,N'')=ISNULL(s.SKU_Vino,N'')
      AND ISNULL(t.Canal_Venta,N'')=ISNULL(s.Canal_Venta,N'')
      AND ISNULL(t.Botellas_Vendidas,N'')=ISNULL(s.Botellas_Vendidas,N'')
      AND ISNULL(t.Precio_Unitario_MXN,N'')=ISNULL(s.Precio_Unitario_MXN,N'')
);
INSERT INTO bronce.Staging_CRM (ID_Cliente,Nombre_Cliente,Categoria_Membresia,Ciudad_Entrega,Gasto_Acumulado_Anual)
SELECT s.ID_Cliente,s.Nombre_Cliente,s.Categoria_Membresia,s.Ciudad_Entrega,s.Gasto_Acumulado_Anual
FROM (VALUES
    (N'CLI-V01',N' sofia mendiolea ',N'Platinum',N'León',N'18500.00'),
    (N'CLI-V02',N'CARLOS ALVAREZ',N' Gold ',N'Guadalajara',CAST(NULL AS NVARCHAR(50))),
    (N'CLI-V03',N' Rodrigo Navarro ',N'Standard',N'CDMX',N'4200.00'),
    (N'CLI-V04',N'Ana Paula Rios',N'Platinum',N'Querétaro',N'22000.00')
) s(ID_Cliente,Nombre_Cliente,Categoria_Membresia,Ciudad_Entrega,Gasto_Acumulado_Anual)
WHERE NOT EXISTS (
    SELECT 1 FROM bronce.Staging_CRM t
    WHERE ISNULL(t.ID_Cliente,N'')=ISNULL(s.ID_Cliente,N'')
      AND ISNULL(t.Nombre_Cliente,N'')=ISNULL(s.Nombre_Cliente,N'')
      AND ISNULL(t.Categoria_Membresia,N'')=ISNULL(s.Categoria_Membresia,N'')
      AND ISNULL(t.Ciudad_Entrega,N'')=ISNULL(s.Ciudad_Entrega,N'')
      AND ISNULL(t.Gasto_Acumulado_Anual,N'')=ISNULL(s.Gasto_Acumulado_Anual,N'')
);
DECLARE @RatingsJson NVARCHAR(MAX)=N'[
 {"SKU_Vino":"VIN-CAB-01","Nombre_Etiqueta":"Reserva Cabernet Sauvignon 2020","Puntaje_Guia_Peñin_Vivino":91.5,"Maridaje_Sugerido":"Cortes de Carne","Cepa_Origen":"Valle de Guadalupe, México"},
 {"SKU_Vino":"VIN-MAL-02","Nombre_Etiqueta":"Gran Reserva Malbec 2018","Puntaje_Guia_Peñin_Vivino":95.0,"Maridaje_Sugerido":"Quesos Madurados","Cepa_Origen":"Mendoza, Argentina"},
 {"SKU_Vino":"VIN-TEM-03","Nombre_Etiqueta":"Edición Especial Tempranillo 2019","Puntaje_Guia_Peñin_Vivino":93.8,"Maridaje_Sugerido":"Pastas y Cordero","Cepa_Origen":"Rioja, España"},
 {"SKU_Vino":"VIN-DEMO-INVALIDO","Nombre_Etiqueta":"Registro sintético fuera de escala","Puntaje_Guia_Peñin_Vivino":120,"Maridaje_Sugerido":"Sin validar","Cepa_Origen":"Ejemplo didáctico"}
]';
WITH Parsed AS (
    SELECT SKU_Vino,Nombre_Etiqueta,Puntaje,Maridaje_Sugerido,Cepa_Origen
    FROM OPENJSON(@RatingsJson) WITH (
        SKU_Vino NVARCHAR(30) '$.SKU_Vino',
        Nombre_Etiqueta NVARCHAR(200) '$.Nombre_Etiqueta',
        Puntaje NVARCHAR(30) '$."Puntaje_Guia_Peñin_Vivino"',
        Maridaje_Sugerido NVARCHAR(150) '$.Maridaje_Sugerido',
        Cepa_Origen NVARCHAR(150) '$.Cepa_Origen'
    )
)
INSERT INTO bronce.Staging_Ratings (SKU_Vino,Nombre_Etiqueta,Puntaje_Guia_Penin_Vivino,Maridaje_Sugerido,Cepa_Origen)
SELECT p.SKU_Vino,p.Nombre_Etiqueta,p.Puntaje,p.Maridaje_Sugerido,p.Cepa_Origen
FROM Parsed p
WHERE NOT EXISTS (
    SELECT 1 FROM bronce.Staging_Ratings t
    WHERE ISNULL(t.SKU_Vino,N'')=ISNULL(p.SKU_Vino,N'')
      AND ISNULL(t.Nombre_Etiqueta,N'')=ISNULL(p.Nombre_Etiqueta,N'')
      AND ISNULL(t.Puntaje_Guia_Penin_Vivino,N'')=ISNULL(p.Puntaje,N'')
      AND ISNULL(t.Maridaje_Sugerido,N'')=ISNULL(p.Maridaje_Sugerido,N'')
      AND ISNULL(t.Cepa_Origen,N'')=ISNULL(p.Cepa_Origen,N'')
);
GO
SELECT N'Bronce POS' AS Fuente, COUNT(*) AS Filas FROM bronce.Ventas_POS_Tienda
UNION ALL SELECT N'Bronce CRM', COUNT(*) FROM bronce.Staging_CRM
UNION ALL SELECT N'Bronce Ratings', COUNT(*) FROM bronce.Staging_Ratings;
GO
/* Inspección previa: filas sucias visibles antes de aplicar las reglas. */
SELECT ID_Venta_POS,Fecha_Hora,ID_Cliente,SKU_Vino,Canal_Venta,Botellas_Vendidas,Precio_Unitario_MXN
FROM bronce.Ventas_POS_Tienda
WHERE TRIM(ID_Venta_POS) IN (N'POS-805',N'POS-806')
ORDER BY POS_Row_ID;
SELECT SKU_Vino,Puntaje_Guia_Penin_Vivino
FROM bronce.Staging_Ratings
WHERE SKU_Vino=N'VIN-DEMO-INVALIDO';
GO
