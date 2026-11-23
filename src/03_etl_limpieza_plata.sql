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
