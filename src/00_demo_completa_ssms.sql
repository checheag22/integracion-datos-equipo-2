/* DEMO COMPLETA EN SSMS — VIÑEDOS DEL ALBA (CASO FICTICIO)
   Ejecuta desde una instancia de prueba con permisos para crear DB.
   En SSMS activa Query > SQLCMD Mode para que :ON ERROR EXIT detenga
   toda la corrida si la base ya existe o cualquier paso falla.
   NO elimina bases ni datos. Si la base ya existe, usa una instancia limpia;
   no borres una base que contenga información.
   Resultado esperado al final: 5 ventas, 24 botellas, $22,760 MXN.
*/
:ON ERROR EXIT
USE master;
GO
IF DB_ID(N'DB_Vinicola_Integration') IS NOT NULL
    THROW 51000, 'DB_Vinicola_Integration ya existe. No se modifica ni elimina; conecta a una instancia limpia de prueba.', 1;
GO


/* ==================== INICIO: src/01_ddl_arquitectura_der.sql ==================== */
/* 01 | DDL de arquitectura Medallón para el caso vinícola.
   Ejecutar los cuatro archivos en orden dentro de una instancia de práctica. */
IF DB_ID(N'DB_Vinicola_Integration') IS NULL
    CREATE DATABASE DB_Vinicola_Integration;
GO
USE DB_Vinicola_Integration;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO
IF DB_NAME() <> N'DB_Vinicola_Integration'
    THROW 50020, 'Base de datos de destino inesperada.', 1;
GO
IF SCHEMA_ID(N'bronce') IS NULL EXEC(N'CREATE SCHEMA bronce AUTHORIZATION dbo;');
IF SCHEMA_ID(N'plata') IS NULL EXEC(N'CREATE SCHEMA plata AUTHORIZATION dbo;');
IF SCHEMA_ID(N'oro') IS NULL EXEC(N'CREATE SCHEMA oro AUTHORIZATION dbo;');
GO
/* Bronce conserva las celdas como texto y acepta filas repetidas para que la
   limpieza pueda medirlas y deduplicarlas sin perder el registro de origen. */
IF OBJECT_ID(N'bronce.Ventas_POS_Tienda', N'U') IS NULL
BEGIN
    CREATE TABLE bronce.Ventas_POS_Tienda (
        POS_Row_ID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_bronce_Ventas_POS PRIMARY KEY,
        ID_Venta_POS NVARCHAR(30) NULL,
        Fecha_Hora NVARCHAR(50) NULL,
        ID_Cliente NVARCHAR(30) NULL,
        SKU_Vino NVARCHAR(30) NULL,
        Canal_Venta NVARCHAR(80) NULL,
        Botellas_Vendidas NVARCHAR(30) NULL,
        Precio_Unitario_MXN NVARCHAR(50) NULL
    );
END;
IF OBJECT_ID(N'bronce.Staging_CRM', N'U') IS NULL
BEGIN
    CREATE TABLE bronce.Staging_CRM (
        CRM_Row_ID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_bronce_Staging_CRM PRIMARY KEY,
        ID_Cliente NVARCHAR(30) NULL,
        Nombre_Cliente NVARCHAR(150) NULL,
        Categoria_Membresia NVARCHAR(50) NULL,
        Ciudad_Entrega NVARCHAR(100) NULL,
        Gasto_Acumulado_Anual NVARCHAR(50) NULL
    );
END;
IF OBJECT_ID(N'bronce.Staging_Ratings', N'U') IS NULL
BEGIN
    CREATE TABLE bronce.Staging_Ratings (
        Rating_Row_ID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_bronce_Staging_Ratings PRIMARY KEY,
        SKU_Vino NVARCHAR(30) NULL,
        Nombre_Etiqueta NVARCHAR(200) NULL,
        Puntaje_Guia_Penin_Vivino NVARCHAR(30) NULL,
        Maridaje_Sugerido NVARCHAR(150) NULL,
        Cepa_Origen NVARCHAR(150) NULL
    );
END;
/* Plata contiene dimensiones tipadas y el modelo limpio de transacciones. */
IF OBJECT_ID(N'plata.Dim_Clientes', N'U') IS NULL
BEGIN
    CREATE TABLE plata.Dim_Clientes (
        ID_Cliente VARCHAR(30) NOT NULL CONSTRAINT PK_plata_Dim_Clientes PRIMARY KEY,
        Nombre_Cliente NVARCHAR(150) NOT NULL,
        Categoria_Membresia NVARCHAR(50) NOT NULL,
        Ciudad_Entrega NVARCHAR(100) NOT NULL,
        Gasto_Acumulado_Anual DECIMAL(14,2) NOT NULL,
        Gasto_Fue_Imputado BIT NOT NULL CONSTRAINT DF_plata_Cliente_Imputado DEFAULT(0),
        CONSTRAINT CK_plata_Cliente_Gasto CHECK (Gasto_Acumulado_Anual >= 0)
    );
END;
IF OBJECT_ID(N'plata.Dim_Vinos', N'U') IS NULL
BEGIN
    CREATE TABLE plata.Dim_Vinos (
        SKU_Vino VARCHAR(30) NOT NULL CONSTRAINT PK_plata_Dim_Vinos PRIMARY KEY,
        Nombre_Etiqueta NVARCHAR(200) NOT NULL,
        Puntaje_Guia_Penin_Vivino DECIMAL(5,2) NULL,
        Maridaje_Sugerido NVARCHAR(150) NULL,
        Cepa_Origen NVARCHAR(150) NULL,
        CONSTRAINT CK_plata_Vino_Puntaje CHECK (Puntaje_Guia_Penin_Vivino BETWEEN 0 AND 100)
    );
END;
IF OBJECT_ID(N'oro.Fact_Ventas_POS', N'U') IS NULL
BEGIN
    CREATE TABLE oro.Fact_Ventas_POS (
        ID_Venta_POS VARCHAR(30) NOT NULL CONSTRAINT PK_oro_Fact_Ventas_POS PRIMARY KEY,
        Fecha_Hora DATETIME2(0) NOT NULL,
        ID_Cliente VARCHAR(30) NOT NULL,
        SKU_Vino VARCHAR(30) NOT NULL,
        Canal_Venta NVARCHAR(80) NOT NULL,
        Botellas_Vendidas INT NOT NULL,
        Precio_Unitario_MXN DECIMAL(12,2) NOT NULL,
        Total_Venta_MXN AS (CONVERT(DECIMAL(14,2), Botellas_Vendidas) * Precio_Unitario_MXN) PERSISTED,
        CONSTRAINT FK_oro_Fact_Cliente FOREIGN KEY (ID_Cliente) REFERENCES plata.Dim_Clientes(ID_Cliente),
        CONSTRAINT FK_oro_Fact_Vino FOREIGN KEY (SKU_Vino) REFERENCES plata.Dim_Vinos(SKU_Vino),
        CONSTRAINT CK_oro_Fact_Botellas CHECK (Botellas_Vendidas > 0),
        CONSTRAINT CK_oro_Fact_Precio CHECK (Precio_Unitario_MXN >= 0)
    );
END;
GO
/* ====================== FIN: src/01_ddl_arquitectura_der.sql ====================== */

/* ==================== INICIO: src/02_etl_ingesta_bronce.sql ==================== */
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
/* ====================== FIN: src/02_etl_ingesta_bronce.sql ====================== */

/* ==================== INICIO: src/03_etl_limpieza_plata.sql ==================== */
/* 03 | Limpieza, deduplicación por llave de negocio e integración.
   Las ejecuciones repetidas no duplican plata/oro. La fuente conserva filas. */
USE DB_Vinicola_Integration;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO
CREATE OR ALTER PROCEDURE plata.usp_ProcesarPlata
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRAN;
    BEGIN TRY
        IF OBJECT_ID('tempdb..#POS_Dedup') IS NOT NULL DROP TABLE #POS_Dedup;
        WITH POSConRanking AS (
            SELECT p.*,
                ROW_NUMBER() OVER (
                    PARTITION BY NULLIF(TRIM(p.ID_Venta_POS),N'')
                    ORDER BY TRY_CONVERT(DATETIME2(0),TRIM(p.Fecha_Hora),126) DESC,
                             p.POS_Row_ID DESC
                ) AS rn
            FROM bronce.Ventas_POS_Tienda p
            WHERE NULLIF(TRIM(p.ID_Venta_POS),N'') IS NOT NULL
        )
        SELECT POS_Row_ID,TRIM(ID_Venta_POS) AS ID_Venta_POS,
               TRY_CONVERT(DATETIME2(0),TRIM(Fecha_Hora),126) AS Fecha_Hora,
               NULLIF(TRIM(ID_Cliente),N'') AS ID_Cliente,
               NULLIF(TRIM(SKU_Vino),N'') AS SKU_Vino,
               NULLIF(TRIM(Canal_Venta),N'') AS Canal_Venta,
               TRY_CONVERT(INT,TRIM(Botellas_Vendidas)) AS Botellas_Vendidas,
               TRY_CONVERT(DECIMAL(12,2),TRIM(Precio_Unitario_MXN)) AS Precio_Unitario_MXN
        INTO #POS_Dedup
        FROM POSConRanking
        WHERE rn=1;

        WITH CRMConRanking AS (
            SELECT c.*,
                ROW_NUMBER() OVER (
                    PARTITION BY NULLIF(TRIM(c.ID_Cliente),N'')
                    ORDER BY (CASE WHEN NULLIF(TRIM(c.Nombre_Cliente),N'') IS NULL THEN 0 ELSE 1 END
                            + CASE WHEN NULLIF(TRIM(c.Categoria_Membresia),N'') IS NULL THEN 0 ELSE 1 END
                            + CASE WHEN NULLIF(TRIM(c.Ciudad_Entrega),N'') IS NULL THEN 0 ELSE 1 END) DESC,
                             c.CRM_Row_ID DESC
                ) AS rn
            FROM bronce.Staging_CRM c
            WHERE NULLIF(TRIM(c.ID_Cliente),N'') IS NOT NULL
        ), CRMNormalizado AS (
            SELECT TRIM(c.ID_Cliente) AS ID_Cliente,
                   TRIM(c.Nombre_Cliente) AS Nombre_Cliente,
                   CASE UPPER(TRIM(c.Categoria_Membresia))
                     WHEN N'PLATINUM' THEN N'Platinum'
                     WHEN N'GOLD' THEN N'Gold'
                     WHEN N'STANDARD' THEN N'Standard'
                     ELSE N'Sin categoría' END AS Categoria_Membresia,
                   COALESCE(NULLIF(TRIM(c.Ciudad_Entrega),N''),N'Sin ciudad') AS Ciudad_Entrega,
                   TRY_CONVERT(DECIMAL(14,2),TRIM(c.Gasto_Acumulado_Anual)) AS Gasto_Confirmado
            FROM CRMConRanking c WHERE c.rn=1 AND NULLIF(TRIM(c.Nombre_Cliente),N'') IS NOT NULL
        ), CRMConProxy AS (
            SELECT c.ID_Cliente,c.Nombre_Cliente,c.Categoria_Membresia,c.Ciudad_Entrega,
                   CASE WHEN c.Gasto_Confirmado>=0 THEN c.Gasto_Confirmado
                        ELSE COALESCE(ventas.Gasto_POS,CONVERT(DECIMAL(14,2),0)) END AS Gasto,
                   CONVERT(BIT,CASE WHEN c.Gasto_Confirmado>=0 THEN 0 ELSE 1 END) AS Imputado
            FROM CRMNormalizado c
            OUTER APPLY (
                SELECT SUM(CONVERT(DECIMAL(14,2),p.Botellas_Vendidas)*p.Precio_Unitario_MXN) AS Gasto_POS
                FROM #POS_Dedup p WHERE p.ID_Cliente=c.ID_Cliente
                  AND p.Fecha_Hora IS NOT NULL AND p.Botellas_Vendidas>0 AND p.Precio_Unitario_MXN>=0
            ) ventas
        )
        UPDATE d SET Nombre_Cliente=s.Nombre_Cliente,
                      Categoria_Membresia=s.Categoria_Membresia,
                      Ciudad_Entrega=s.Ciudad_Entrega,
                      Gasto_Acumulado_Anual=s.Gasto,
                      Gasto_Fue_Imputado=s.Imputado
        FROM plata.Dim_Clientes d JOIN CRMConProxy s ON s.ID_Cliente=d.ID_Cliente;

        WITH CRMConRanking AS (
            SELECT c.*,
                ROW_NUMBER() OVER (
                    PARTITION BY NULLIF(TRIM(c.ID_Cliente),N'')
                    ORDER BY (CASE WHEN NULLIF(TRIM(c.Nombre_Cliente),N'') IS NULL THEN 0 ELSE 1 END
                            + CASE WHEN NULLIF(TRIM(c.Categoria_Membresia),N'') IS NULL THEN 0 ELSE 1 END
                            + CASE WHEN NULLIF(TRIM(c.Ciudad_Entrega),N'') IS NULL THEN 0 ELSE 1 END) DESC,
                             c.CRM_Row_ID DESC
                ) AS rn
            FROM bronce.Staging_CRM c
            WHERE NULLIF(TRIM(c.ID_Cliente),N'') IS NOT NULL
        ), CRMNormalizado AS (
            SELECT TRIM(c.ID_Cliente) AS ID_Cliente,
                   TRIM(c.Nombre_Cliente) AS Nombre_Cliente,
                   CASE UPPER(TRIM(c.Categoria_Membresia))
                     WHEN N'PLATINUM' THEN N'Platinum'
                     WHEN N'GOLD' THEN N'Gold'
                     WHEN N'STANDARD' THEN N'Standard'
                     ELSE N'Sin categoría' END AS Categoria_Membresia,
                   COALESCE(NULLIF(TRIM(c.Ciudad_Entrega),N''),N'Sin ciudad') AS Ciudad_Entrega,
                   TRY_CONVERT(DECIMAL(14,2),TRIM(c.Gasto_Acumulado_Anual)) AS Gasto_Confirmado
            FROM CRMConRanking c WHERE c.rn=1 AND NULLIF(TRIM(c.Nombre_Cliente),N'') IS NOT NULL
        ), CRMConProxy AS (
            SELECT c.ID_Cliente,c.Nombre_Cliente,c.Categoria_Membresia,c.Ciudad_Entrega,
                   CASE WHEN c.Gasto_Confirmado>=0 THEN c.Gasto_Confirmado
                        ELSE COALESCE(ventas.Gasto_POS,CONVERT(DECIMAL(14,2),0)) END AS Gasto,
                   CONVERT(BIT,CASE WHEN c.Gasto_Confirmado>=0 THEN 0 ELSE 1 END) AS Imputado
            FROM CRMNormalizado c
            OUTER APPLY (
                SELECT SUM(CONVERT(DECIMAL(14,2),p.Botellas_Vendidas)*p.Precio_Unitario_MXN) AS Gasto_POS
                FROM #POS_Dedup p WHERE p.ID_Cliente=c.ID_Cliente
                  AND p.Fecha_Hora IS NOT NULL AND p.Botellas_Vendidas>0 AND p.Precio_Unitario_MXN>=0
            ) ventas
        )
        INSERT INTO plata.Dim_Clientes (ID_Cliente,Nombre_Cliente,Categoria_Membresia,Ciudad_Entrega,Gasto_Acumulado_Anual,Gasto_Fue_Imputado)
        SELECT s.ID_Cliente,s.Nombre_Cliente,s.Categoria_Membresia,s.Ciudad_Entrega,s.Gasto,s.Imputado
        FROM CRMConProxy s
        WHERE NOT EXISTS (SELECT 1 FROM plata.Dim_Clientes d WHERE d.ID_Cliente=s.ID_Cliente);

        IF NOT EXISTS (SELECT 1 FROM plata.Dim_Clientes WHERE ID_Cliente='CLI-MOSTRADOR')
            INSERT INTO plata.Dim_Clientes (ID_Cliente,Nombre_Cliente,Categoria_Membresia,Ciudad_Entrega,Gasto_Acumulado_Anual,Gasto_Fue_Imputado)
            VALUES ('CLI-MOSTRADOR',N'Venta anónima',N'Sin membresía',N'Sin ciudad',0,0);

        WITH RatingsConRanking AS (
            SELECT r.*,
                ROW_NUMBER() OVER (
                    PARTITION BY NULLIF(TRIM(r.SKU_Vino),N'')
                    ORDER BY CASE WHEN TRY_CONVERT(DECIMAL(5,2),TRIM(r.Puntaje_Guia_Penin_Vivino)) BETWEEN 0 AND 100 THEN 1 ELSE 0 END DESC,
                             r.Rating_Row_ID DESC
                ) AS rn
            FROM bronce.Staging_Ratings r
            WHERE NULLIF(TRIM(r.SKU_Vino),N'') IS NOT NULL
        ), VinosLimpios AS (
            SELECT TRIM(SKU_Vino) AS SKU_Vino,TRIM(Nombre_Etiqueta) AS Nombre_Etiqueta,
                   TRY_CONVERT(DECIMAL(5,2),TRIM(Puntaje_Guia_Penin_Vivino)) AS Puntaje,
                   NULLIF(TRIM(Maridaje_Sugerido),N'') AS Maridaje,
                   NULLIF(TRIM(Cepa_Origen),N'') AS Origen
            FROM RatingsConRanking
            WHERE rn=1 AND NULLIF(TRIM(Nombre_Etiqueta),N'') IS NOT NULL
              AND TRY_CONVERT(DECIMAL(5,2),TRIM(Puntaje_Guia_Penin_Vivino)) BETWEEN 0 AND 100
        )
        UPDATE d SET Nombre_Etiqueta=s.Nombre_Etiqueta,Puntaje_Guia_Penin_Vivino=s.Puntaje,
                     Maridaje_Sugerido=s.Maridaje,Cepa_Origen=s.Origen
        FROM plata.Dim_Vinos d JOIN VinosLimpios s ON s.SKU_Vino=d.SKU_Vino;

        WITH RatingsConRanking AS (
            SELECT r.*,
                ROW_NUMBER() OVER (
                    PARTITION BY NULLIF(TRIM(r.SKU_Vino),N'')
                    ORDER BY CASE WHEN TRY_CONVERT(DECIMAL(5,2),TRIM(r.Puntaje_Guia_Penin_Vivino)) BETWEEN 0 AND 100 THEN 1 ELSE 0 END DESC,
                             r.Rating_Row_ID DESC
                ) AS rn
            FROM bronce.Staging_Ratings r
            WHERE NULLIF(TRIM(r.SKU_Vino),N'') IS NOT NULL
        ), VinosLimpios AS (
            SELECT TRIM(SKU_Vino) AS SKU_Vino,TRIM(Nombre_Etiqueta) AS Nombre_Etiqueta,
                   TRY_CONVERT(DECIMAL(5,2),TRIM(Puntaje_Guia_Penin_Vivino)) AS Puntaje,
                   NULLIF(TRIM(Maridaje_Sugerido),N'') AS Maridaje,
                   NULLIF(TRIM(Cepa_Origen),N'') AS Origen
            FROM RatingsConRanking
            WHERE rn=1 AND NULLIF(TRIM(Nombre_Etiqueta),N'') IS NOT NULL
              AND TRY_CONVERT(DECIMAL(5,2),TRIM(Puntaje_Guia_Penin_Vivino)) BETWEEN 0 AND 100
        )
        INSERT INTO plata.Dim_Vinos (SKU_Vino,Nombre_Etiqueta,Puntaje_Guia_Penin_Vivino,Maridaje_Sugerido,Cepa_Origen)
        SELECT s.SKU_Vino,s.Nombre_Etiqueta,s.Puntaje,s.Maridaje,s.Origen
        FROM VinosLimpios s
        WHERE NOT EXISTS (SELECT 1 FROM plata.Dim_Vinos d WHERE d.SKU_Vino=s.SKU_Vino);

        /* Una corrección/duplicado tardío con la misma llave de venta actualiza
           la fila integrada con la versión más reciente elegida en #POS_Dedup. */
        UPDATE f SET Fecha_Hora=p.Fecha_Hora,
                     ID_Cliente=COALESCE(c.ID_Cliente,'CLI-MOSTRADOR'),
                     SKU_Vino=p.SKU_Vino,Canal_Venta=TRIM(p.Canal_Venta),
                     Botellas_Vendidas=p.Botellas_Vendidas,Precio_Unitario_MXN=p.Precio_Unitario_MXN
        FROM oro.Fact_Ventas_POS f
        JOIN #POS_Dedup p ON p.ID_Venta_POS=f.ID_Venta_POS
        LEFT JOIN plata.Dim_Clientes c ON c.ID_Cliente=p.ID_Cliente
        JOIN plata.Dim_Vinos v ON v.SKU_Vino=p.SKU_Vino
        WHERE p.Fecha_Hora IS NOT NULL AND p.Botellas_Vendidas>0
          AND p.Precio_Unitario_MXN>=0 AND NULLIF(TRIM(p.Canal_Venta),N'') IS NOT NULL;

        INSERT INTO oro.Fact_Ventas_POS (ID_Venta_POS,Fecha_Hora,ID_Cliente,SKU_Vino,Canal_Venta,Botellas_Vendidas,Precio_Unitario_MXN)
        SELECT p.ID_Venta_POS,p.Fecha_Hora,
               COALESCE(c.ID_Cliente,'CLI-MOSTRADOR'),p.SKU_Vino,TRIM(p.Canal_Venta),p.Botellas_Vendidas,p.Precio_Unitario_MXN
        FROM #POS_Dedup p
        LEFT JOIN plata.Dim_Clientes c ON c.ID_Cliente=p.ID_Cliente
        JOIN plata.Dim_Vinos v ON v.SKU_Vino=p.SKU_Vino
        WHERE p.Fecha_Hora IS NOT NULL AND p.Botellas_Vendidas>0 AND p.Precio_Unitario_MXN>=0
          AND NULLIF(TRIM(p.Canal_Venta),N'') IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM oro.Fact_Ventas_POS f WHERE f.ID_Venta_POS=p.ID_Venta_POS);
        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRAN;
        THROW;
    END CATCH
END;
GO
CREATE OR ALTER PROCEDURE plata.sp_RegistrarClienteCRM
    @ID_Cliente VARCHAR(30), @Nombre NVARCHAR(150), @Membresia NVARCHAR(50),
    @Ciudad NVARCHAR(100), @Gasto_Confirmado DECIMAL(14,2)
AS
BEGIN
    SET NOCOUNT ON;
    IF NULLIF(TRIM(@ID_Cliente),'') IS NULL OR NULLIF(TRIM(@Nombre),N'') IS NULL
        THROW 50010,'ID y nombre son obligatorios.',1;
    IF @Gasto_Confirmado IS NULL OR @Gasto_Confirmado<0
        THROW 50011,'El gasto confirmado debe ser no negativo.',1;
    DECLARE @m NVARCHAR(50)=UPPER(TRIM(@Membresia));
    IF @m NOT IN (N'PLATINUM',N'GOLD',N'STANDARD')
        THROW 50013,'Membresía fuera de catálogo.',1;
    IF EXISTS (SELECT 1 FROM plata.Dim_Clientes WHERE ID_Cliente=TRIM(@ID_Cliente))
        THROW 50014,'El ID de cliente ya existe.',1;
    INSERT INTO plata.Dim_Clientes (ID_Cliente,Nombre_Cliente,Categoria_Membresia,Ciudad_Entrega,Gasto_Acumulado_Anual,Gasto_Fue_Imputado)
    VALUES (TRIM(@ID_Cliente),TRIM(@Nombre),CASE @m WHEN N'PLATINUM' THEN N'Platinum' WHEN N'GOLD' THEN N'Gold' ELSE N'Standard' END,
            COALESCE(NULLIF(TRIM(@Ciudad),N''),N'Sin ciudad'),@Gasto_Confirmado,0);
END;
GO
CREATE OR ALTER PROCEDURE plata.sp_ObtenerClientePorID @ID_Cliente VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT c.*,COUNT(f.ID_Venta_POS) AS Numero_Compras_POS,
           COALESCE(SUM(f.Total_Venta_MXN),0) AS Gasto_POS_En_Muestra
    FROM plata.Dim_Clientes c LEFT JOIN oro.Fact_Ventas_POS f ON f.ID_Cliente=c.ID_Cliente
    WHERE c.ID_Cliente=TRIM(@ID_Cliente)
    GROUP BY c.ID_Cliente,c.Nombre_Cliente,c.Categoria_Membresia,c.Ciudad_Entrega,c.Gasto_Acumulado_Anual,c.Gasto_Fue_Imputado;
END;
GO
CREATE OR ALTER PROCEDURE plata.sp_HistorialVentasCliente
    @ID_Cliente VARCHAR(30),@FechaInicio DATE,@FechaFin DATE
AS
BEGIN
    SET NOCOUNT ON;
    IF @FechaInicio IS NULL OR @FechaFin IS NULL OR @FechaFin<@FechaInicio
        THROW 50012,'El rango de fechas no es válido.',1;
    SELECT c.ID_Cliente,c.Nombre_Cliente,f.ID_Venta_POS,f.Fecha_Hora,f.SKU_Vino,v.Nombre_Etiqueta,
           f.Canal_Venta,f.Botellas_Vendidas,f.Total_Venta_MXN
    FROM plata.Dim_Clientes c JOIN oro.Fact_Ventas_POS f ON f.ID_Cliente=c.ID_Cliente
    JOIN plata.Dim_Vinos v ON v.SKU_Vino=f.SKU_Vino
    WHERE c.ID_Cliente=TRIM(@ID_Cliente) AND f.Fecha_Hora>=@FechaInicio
      AND f.Fecha_Hora<DATEADD(DAY,1,@FechaFin)
    ORDER BY f.Fecha_Hora DESC;
END;
GO
CREATE OR ALTER PROCEDURE plata.sp_VinosPorPuntaje @Puntaje_Minimo DECIMAL(5,2)=93.00
AS
BEGIN
    SET NOCOUNT ON;
    IF @Puntaje_Minimo NOT BETWEEN 0 AND 100 THROW 50001,'Puntaje fuera de escala 0-100.',1;
    SELECT v.SKU_Vino,v.Nombre_Etiqueta,v.Puntaje_Guia_Penin_Vivino,v.Cepa_Origen,
           COALESCE(SUM(f.Botellas_Vendidas),0) AS Botellas,COALESCE(SUM(f.Total_Venta_MXN),0) AS Ingresos_MXN
    FROM plata.Dim_Vinos v LEFT JOIN oro.Fact_Ventas_POS f ON f.SKU_Vino=v.SKU_Vino
    WHERE v.Puntaje_Guia_Penin_Vivino>@Puntaje_Minimo
    GROUP BY v.SKU_Vino,v.Nombre_Etiqueta,v.Puntaje_Guia_Penin_Vivino,v.Cepa_Origen
    ORDER BY v.Puntaje_Guia_Penin_Vivino DESC;
END;
GO
CREATE OR ALTER PROCEDURE plata.sp_ResumenFinanciero @Ciudad NVARCHAR(100)=NULL,@Membresia NVARCHAR(50)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT COUNT(*) AS Transacciones_POS,COALESCE(SUM(Botellas_Vendidas),0) AS Botellas,
           COALESCE(SUM(Total_Venta_MXN),0) AS Ingresos_MXN,CAST(AVG(Total_Venta_MXN) AS DECIMAL(14,2)) AS Ticket_Promedio_MXN
    FROM oro.vw_Gold_Ventas_Vinos
    WHERE (@Ciudad IS NULL OR Ciudad_Entrega=@Ciudad) AND (@Membresia IS NULL OR Categoria_Membresia=@Membresia);
END;
GO
CREATE OR ALTER PROCEDURE plata.sp_ConsultarVentasPorCanal @Canal_Venta NVARCHAR(80)=NULL,@Fecha_Desde DATE=NULL,@Fecha_Hasta DATE=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM oro.vw_Gold_Ventas_Vinos
    WHERE (@Canal_Venta IS NULL OR Canal_Venta=@Canal_Venta)
      AND (@Fecha_Desde IS NULL OR Fecha_Hora>=@Fecha_Desde)
      AND (@Fecha_Hasta IS NULL OR Fecha_Hora<DATEADD(DAY,1,@Fecha_Hasta))
    ORDER BY Fecha_Hora;
END;
GO
/* Primera ejecución ETL: al volver a ejecutar el archivo no agrega duplicados. */
EXEC plata.usp_ProcesarPlata;
GO
/* Inspección posterior: la versión más nueva gana y los errores quedan visibles. */
WITH POSInspeccion AS (
    SELECT p.*,
           ROW_NUMBER() OVER (PARTITION BY NULLIF(TRIM(p.ID_Venta_POS),N'')
                              ORDER BY TRY_CONVERT(DATETIME2(0),TRIM(p.Fecha_Hora),126) DESC,
                                       p.POS_Row_ID DESC) AS rn
    FROM bronce.Ventas_POS_Tienda p
    WHERE TRIM(p.ID_Venta_POS) IN (N'POS-805',N'POS-806')
)
SELECT p.POS_Row_ID,p.ID_Venta_POS,p.Fecha_Hora,p.Botellas_Vendidas,
       CASE WHEN TRY_CONVERT(INT,TRIM(p.Botellas_Vendidas)) IS NULL
                 OR TRY_CONVERT(INT,TRIM(p.Botellas_Vendidas))<=0 THEN N'Excluida: cantidad inválida'
            WHEN p.rn>1 THEN N'Descartada: versión duplicada anterior'
            WHEN f.ID_Venta_POS IS NOT NULL THEN N'Integrada: versión más reciente'
            ELSE N'Excluida: revisar relaciones o campos' END AS Resultado
FROM POSInspeccion p
LEFT JOIN oro.Fact_Ventas_POS f ON f.ID_Venta_POS=TRIM(p.ID_Venta_POS)
ORDER BY p.POS_Row_ID;
GO
/* ====================== FIN: src/03_etl_limpieza_plata.sql ====================== */

/* ==================== INICIO: src/04_vistas_gold_bi.sql ==================== */
/* 04 | Vistas de consumo, métricas de calidad y consultas BI. */
USE DB_Vinicola_Integration;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER VIEW oro.vw_POS_Operativa
AS
SELECT ID_Venta_POS,Fecha_Hora,ID_Cliente,SKU_Vino,Canal_Venta,Botellas_Vendidas,Precio_Unitario_MXN,Total_Venta_MXN
FROM oro.Fact_Ventas_POS;
GO
CREATE OR ALTER VIEW oro.vw_Gold_Ventas_Vinos
AS
SELECT f.ID_Venta_POS,f.Fecha_Hora,CONVERT(DATE,f.Fecha_Hora) AS Fecha_Venta,
       f.ID_Cliente,c.Nombre_Cliente,c.Categoria_Membresia,c.Ciudad_Entrega,
       c.Gasto_Acumulado_Anual,c.Gasto_Fue_Imputado,
       f.SKU_Vino,v.Nombre_Etiqueta,v.Puntaje_Guia_Penin_Vivino,v.Maridaje_Sugerido,v.Cepa_Origen,
       f.Canal_Venta,f.Botellas_Vendidas,f.Precio_Unitario_MXN,f.Total_Venta_MXN
FROM oro.Fact_Ventas_POS f
JOIN plata.Dim_Clientes c ON c.ID_Cliente=f.ID_Cliente
JOIN plata.Dim_Vinos v ON v.SKU_Vino=f.SKU_Vino;
GO
CREATE OR ALTER VIEW oro.vw_KPI_Membresia_Canal
AS
SELECT Categoria_Membresia,Canal_Venta,COUNT(*) AS Numero_Ventas,
       SUM(Botellas_Vendidas) AS Botellas_Vendidas,SUM(Total_Venta_MXN) AS Ingresos_MXN,
       CAST(AVG(Total_Venta_MXN) AS DECIMAL(14,2)) AS Ticket_Promedio_MXN
FROM oro.vw_Gold_Ventas_Vinos
GROUP BY Categoria_Membresia,Canal_Venta;
GO
CREATE OR ALTER VIEW oro.vw_KPI_Origen_Vino
AS
SELECT Cepa_Origen AS Origen_Geografico,SKU_Vino,Nombre_Etiqueta,Puntaje_Guia_Penin_Vivino,
       SUM(Botellas_Vendidas) AS Botellas_Vendidas,SUM(Total_Venta_MXN) AS Ingresos_MXN
FROM oro.vw_Gold_Ventas_Vinos
GROUP BY Cepa_Origen,SKU_Vino,Nombre_Etiqueta,Puntaje_Guia_Penin_Vivino;
GO
CREATE OR ALTER VIEW oro.vw_Calidad_Integracion
AS
SELECT
    (SELECT COUNT(*) FROM bronce.Ventas_POS_Tienda) AS POS_Filas_Bronce,
    (SELECT COUNT(DISTINCT NULLIF(TRIM(ID_Venta_POS),N'')) FROM bronce.Ventas_POS_Tienda) AS POS_Ids_Unicos_Bronce,
    (SELECT COUNT(*) FROM bronce.Ventas_POS_Tienda WHERE NULLIF(TRIM(ID_Venta_POS),N'') IS NOT NULL)
      - (SELECT COUNT(DISTINCT NULLIF(TRIM(ID_Venta_POS),N'')) FROM bronce.Ventas_POS_Tienda) AS POS_Duplicados_Descartables,
    (SELECT COUNT(*) FROM oro.Fact_Ventas_POS) AS POS_Transacciones_Oro,
    (SELECT COUNT(*) FROM bronce.Ventas_POS_Tienda WHERE TRY_CONVERT(DATETIME2(0),TRIM(Fecha_Hora),126) IS NULL
        OR TRY_CONVERT(INT,TRIM(Botellas_Vendidas)) IS NULL OR TRY_CONVERT(INT,TRIM(Botellas_Vendidas))<=0
        OR TRY_CONVERT(DECIMAL(12,2),TRIM(Precio_Unitario_MXN)) IS NULL
        OR TRY_CONVERT(DECIMAL(12,2),TRIM(Precio_Unitario_MXN))<0) AS POS_Filas_Invalidas_Bronce,
    (SELECT COUNT(*) FROM bronce.Ventas_POS_Tienda WHERE NULLIF(TRIM(ID_Cliente),N'') IS NULL) AS POS_Ventas_Anonimas_Bronce,
    (SELECT COUNT(*) FROM bronce.Ventas_POS_Tienda p
      WHERE NULLIF(TRIM(p.ID_Cliente),N'') IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM bronce.Staging_CRM c WHERE TRIM(c.ID_Cliente)=TRIM(p.ID_Cliente))) AS POS_Clientes_Huerfanos,
    (SELECT COUNT(*) FROM bronce.Ventas_POS_Tienda p
      WHERE NULLIF(TRIM(p.SKU_Vino),N'') IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM bronce.Staging_Ratings r WHERE TRIM(r.SKU_Vino)=TRIM(p.SKU_Vino))) AS POS_Vinos_Huerfanos,
    (SELECT COUNT(*) FROM oro.Fact_Ventas_POS WHERE ID_Cliente='CLI-MOSTRADOR') AS POS_Ventas_Anonimas_Oro,
    (SELECT COUNT(*) FROM bronce.Staging_CRM) AS CRM_Filas_Bronce,
    (SELECT COUNT(DISTINCT NULLIF(TRIM(ID_Cliente),N'')) FROM bronce.Staging_CRM) AS CRM_Clientes_Unicos_Bronce,
    (SELECT COUNT(*) FROM bronce.Staging_CRM
      WHERE NULLIF(TRIM(Gasto_Acumulado_Anual),N'') IS NOT NULL
        AND (TRY_CONVERT(DECIMAL(14,2),TRIM(Gasto_Acumulado_Anual)) IS NULL
             OR TRY_CONVERT(DECIMAL(14,2),TRIM(Gasto_Acumulado_Anual))<0)) AS CRM_Gastos_Invalidos_Bronce,
    (SELECT COUNT(*) FROM plata.Dim_Clientes WHERE Gasto_Fue_Imputado=1) AS CRM_Gastos_Proxy,
    (SELECT COUNT(*) FROM bronce.Staging_Ratings) AS Ratings_Filas_Bronce,
    (SELECT COUNT(*) FROM plata.Dim_Vinos) AS Ratings_Vinos_Validos_Plata,
    (SELECT COUNT(*) FROM bronce.Staging_Ratings r
      WHERE NULLIF(TRIM(r.SKU_Vino),N'') IS NULL
         OR NULLIF(TRIM(r.Nombre_Etiqueta),N'') IS NULL
         OR TRY_CONVERT(DECIMAL(5,2),TRIM(r.Puntaje_Guia_Penin_Vivino)) IS NULL
         OR TRY_CONVERT(DECIMAL(5,2),TRIM(r.Puntaje_Guia_Penin_Vivino)) NOT BETWEEN 0 AND 100) AS Ratings_Filas_Invalidas_Bronce;
GO
/* Control cuantitativo de la muestra oficial usada en la exposición. */
IF (SELECT COUNT(*) FROM oro.Fact_Ventas_POS)<>5 THROW 50101,'QA: número de ventas distinto a 5.',1;
IF (SELECT SUM(Botellas_Vendidas) FROM oro.Fact_Ventas_POS)<>24 THROW 50102,'QA: botellas distintas a 24.',1;
IF (SELECT SUM(Total_Venta_MXN) FROM oro.Fact_Ventas_POS)<>22760 THROW 50103,'QA: ingresos distintos a 22,760 MXN.',1;
IF (SELECT COUNT(*) FROM oro.Fact_Ventas_POS WHERE ID_Cliente='CLI-MOSTRADOR')<>1 THROW 50104,'QA: no se preservó la venta anónima.',1;
IF (SELECT Gasto_Acumulado_Anual FROM plata.Dim_Clientes WHERE ID_Cliente='CLI-V02')<>4920 THROW 50105,'QA: proxy de CLI-V02 distinto a 4,920 MXN.',1;
IF (SELECT COUNT(*) FROM bronce.Ventas_POS_Tienda)<>7 THROW 50106,'QA: se esperan 7 filas POS Bronce, incluida la demo sintética.',1;
IF (SELECT COUNT(*) FROM bronce.Staging_Ratings)<>4 THROW 50107,'QA: se esperan 4 ratings Bronce, incluido el inválido sintético.',1;
IF (SELECT POS_Duplicados_Descartables FROM oro.vw_Calidad_Integracion)<>1 THROW 50108,'QA: el duplicado sintético no fue detectado.',1;
IF (SELECT POS_Filas_Invalidas_Bronce FROM oro.vw_Calidad_Integracion)<>1 THROW 50109,'QA: la cantidad POS inválida no fue detectada.',1;
IF (SELECT Ratings_Filas_Invalidas_Bronce FROM oro.vw_Calidad_Integracion)<>1 THROW 50110,'QA: el rating fuera de rango no fue detectado.',1;
GO
SELECT * FROM oro.vw_Calidad_Integracion;
SELECT * FROM oro.vw_Gold_Ventas_Vinos ORDER BY ID_Venta_POS;
SELECT * FROM oro.vw_KPI_Membresia_Canal ORDER BY Categoria_Membresia,Canal_Venta;
SELECT * FROM oro.vw_KPI_Origen_Vino ORDER BY Ingresos_MXN DESC;
/* Pregunta de negocio: participación de vino >93 puntos entre clientes Platinum. */
SELECT Nombre_Etiqueta,SUM(Botellas_Vendidas) AS Botellas,
       CAST(100.0*SUM(Botellas_Vendidas)/NULLIF((SELECT SUM(Botellas_Vendidas) FROM oro.vw_Gold_Ventas_Vinos WHERE Categoria_Membresia=N'Platinum'),0) AS DECIMAL(6,2)) AS Pct_Botellas_Platinum,
       SUM(Total_Venta_MXN) AS Ingresos_MXN
FROM oro.vw_Gold_Ventas_Vinos
WHERE Categoria_Membresia=N'Platinum' AND Puntaje_Guia_Penin_Vivino>93
GROUP BY Nombre_Etiqueta;
GO
/* ====================== FIN: src/04_vistas_gold_bi.sql ====================== */

PRINT N'CORRIDA COMPLETA TERMINADA. Revisa los resultados; no se borró ninguna base.';
GO
