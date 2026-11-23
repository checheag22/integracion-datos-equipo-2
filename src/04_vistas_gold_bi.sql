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
