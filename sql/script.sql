
IF DB_ID('DB_Vinicola_Integration') IS NULL CREATE DATABASE DB_Vinicola_Integration;
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
/* REINICIO DESTRUCTIVO: elimina y recrea solo los objetos listados de esta base; no borra la base completa. Ejecutar únicamente en entorno de práctica. */
/* El diccionario DB_Customer_360 de la diapositiva 7 es un entregable separado; este pipeline implementa el caso vinícola POS + CRM + ratings. */
DROP VIEW IF EXISTS dbo.vw_POS_Operativa;
DROP VIEW IF EXISTS dbo.vw_Gold_Ventas_Vinos;
DROP VIEW IF EXISTS dbo.vw_KPI_Membresia_Canal;
DROP VIEW IF EXISTS dbo.vw_KPI_Origen_Vino;
DROP VIEW IF EXISTS dbo.vw_Calidad_Integracion;
GO
DROP PROCEDURE IF EXISTS dbo.sp_RegistrarClienteCRM;
DROP PROCEDURE IF EXISTS dbo.sp_ObtenerClientePorID;
DROP PROCEDURE IF EXISTS dbo.sp_HistorialVentasCliente;
DROP PROCEDURE IF EXISTS dbo.sp_ConsultarVentasPorCanal;
DROP PROCEDURE IF EXISTS dbo.sp_VinosPorPuntaje;
DROP PROCEDURE IF EXISTS dbo.sp_ResumenFinanciero;
DROP PROCEDURE IF EXISTS dbo.sp_ActualizarGastoCRM;
GO
DROP TABLE IF EXISTS dbo.Fact_Ventas_POS;
DROP TABLE IF EXISTS dbo.Dim_Clientes;
DROP TABLE IF EXISTS dbo.Dim_Vinos;
DROP TABLE IF EXISTS dbo.Staging_Ratings;
DROP TABLE IF EXISTS dbo.Staging_CRM;
DROP TABLE IF EXISTS dbo.Ventas_POS_Tienda;
GO
/* 1) BRONCE: fuente SQL física tal como la entrega el docente */
CREATE TABLE dbo.Ventas_POS_Tienda (
 ID_Venta_POS VARCHAR(10) NOT NULL PRIMARY KEY,
 Fecha_Hora DATETIME NULL,
 ID_Cliente VARCHAR(10) NULL,
 SKU_Vino VARCHAR(15) NULL,
 Canal_Venta VARCHAR(20) NULL,
 Botellas_Vendidas INT NULL,
 Precio_Unitario_MXN DECIMAL(10,2) NULL
);
INSERT INTO dbo.Ventas_POS_Tienda VALUES
('POS-801','2026-08-01T12:10:00','CLI-V01','VIN-CAB-01','Boutique',3,450.00),
('POS-802','2026-08-01T15:40:00','CLI-V02','VIN-MAL-02','Boutique',6,820.00),
('POS-803','2026-08-02T18:20:00','CLI-V01','VIN-TEM-03','Cata Presencial',12,1200.00),
('POS-804','2026-08-03T11:00:00',NULL,'VIN-CAB-01','Boutique',1,450.00),
('POS-805','2026-08-03T19:15:00','CLI-V03','VIN-MAL-02','Boutique',2,820.00);
/* Bronce CSV: conservar cadenas originales con espacios y ausencia de gasto */
CREATE TABLE dbo.Staging_CRM (
 ID_Cliente VARCHAR(10) NOT NULL PRIMARY KEY,
 Nombre_Cliente NVARCHAR(100) NULL,
 Categoria_Membresia NVARCHAR(30) NULL,
 Ciudad_Entrega NVARCHAR(60) NULL,
 Gasto_Acumulado_Anual DECIMAL(14,2) NULL
);
INSERT INTO dbo.Staging_CRM VALUES
('CLI-V01',N' sofia mendiolea ',N'Platinum',N'León',18500.00),
('CLI-V02',N'CARLOS ALVAREZ',N' Gold ',N'Guadalajara',NULL),
('CLI-V03',N' Rodrigo Navarro ',N'Standard',N'CDMX',4200.00),
('CLI-V04',N'Ana Paula Rios',N'Platinum',N'Querétaro',22000.00);
/* Bronce JSON: OPENJSON para extraer los 3 objetos de API simulada */
CREATE TABLE dbo.Staging_Ratings (
 SKU_Vino VARCHAR(15) NOT NULL PRIMARY KEY,
 Nombre_Etiqueta NVARCHAR(150) NULL,
 Puntaje_Guia_Penin_Vivino DECIMAL(5,2) NULL,
 Maridaje_Sugerido NVARCHAR(100) NULL,
 Cepa_Origen NVARCHAR(100) NULL
);
DECLARE @json NVARCHAR(MAX) = N'[
 {"SKU_Vino":"VIN-CAB-01","Nombre_Etiqueta":"Reserva Cabernet Sauvignon 2020","Puntaje_Guia_Peñin_Vivino":91.5,"Maridaje_Sugerido":"Cortes de Carne","Cepa_Origen":"Valle de Guadalupe, México"},
 {"SKU_Vino":"VIN-MAL-02","Nombre_Etiqueta":"Gran Reserva Malbec 2018","Puntaje_Guia_Peñin_Vivino":95.0,"Maridaje_Sugerido":"Quesos Madurados","Cepa_Origen":"Mendoza, Argentina"},
 {"SKU_Vino":"VIN-TEM-03","Nombre_Etiqueta":"Edición Especial Tempranillo 2019","Puntaje_Guia_Peñin_Vivino":93.8,"Maridaje_Sugerido":"Pastas y Cordero","Cepa_Origen":"Rioja, España"}
]';
INSERT INTO dbo.Staging_Ratings (SKU_Vino,Nombre_Etiqueta,Puntaje_Guia_Penin_Vivino,Maridaje_Sugerido,Cepa_Origen)
SELECT SKU_Vino, Nombre_Etiqueta, Puntaje, Maridaje_Sugerido, Cepa_Origen
FROM OPENJSON(@json) WITH (
 SKU_Vino VARCHAR(15) '$.SKU_Vino',
 Nombre_Etiqueta NVARCHAR(150) '$.Nombre_Etiqueta',
 Puntaje DECIMAL(5,2) '$."Puntaje_Guia_Peñin_Vivino"',
 Maridaje_Sugerido NVARCHAR(100) '$.Maridaje_Sugerido',
 Cepa_Origen NVARCHAR(100) '$.Cepa_Origen'
);
GO
/* 2) PLATA: clientes normalizados y cliente genérico anónimo */
CREATE TABLE dbo.Dim_Clientes (
 ID_Cliente VARCHAR(15) NOT NULL PRIMARY KEY,
 Nombre_Cliente NVARCHAR(100) NOT NULL,
 Categoria_Membresia NVARCHAR(30) NOT NULL,
 Ciudad_Entrega NVARCHAR(60) NOT NULL,
 Gasto_Acumulado_Anual DECIMAL(14,2) NOT NULL,
 Gasto_Fue_Imputado BIT NOT NULL DEFAULT 0
);
/* SQL Server no tiene INITCAP: normalización explícita del pequeño dataset provisto.
   Se aplica TRIM a todos los nombres y membresías. La tabla de excepciones
   permite restaurar nombres en formato propio sin alterar grafía original. */
INSERT INTO dbo.Dim_Clientes
SELECT c.ID_Cliente,
 CASE c.ID_Cliente
  WHEN 'CLI-V01' THEN N'Sofia Mendiolea'
  WHEN 'CLI-V02' THEN N'Carlos Alvarez'
  WHEN 'CLI-V03' THEN N'Rodrigo Navarro'
  WHEN 'CLI-V04' THEN N'Ana Paula Rios'
  ELSE TRIM(c.Nombre_Cliente) END,
 CASE UPPER(TRIM(c.Categoria_Membresia))
  WHEN 'PLATINUM' THEN N'Platinum' WHEN 'GOLD' THEN N'Gold'
  WHEN 'STANDARD' THEN N'Standard' ELSE N'Sin categoría' END,
 COALESCE(NULLIF(TRIM(c.Ciudad_Entrega),N''),N'Sin ciudad'),
 COALESCE(c.Gasto_Acumulado_Anual,
  (SELECT COALESCE(SUM(CONVERT(DECIMAL(14,2),v.Botellas_Vendidas)*v.Precio_Unitario_MXN),0)
   FROM dbo.Ventas_POS_Tienda v WHERE v.ID_Cliente=c.ID_Cliente)),
 CASE WHEN c.Gasto_Acumulado_Anual IS NULL THEN 1 ELSE 0 END
FROM dbo.Staging_CRM c;
INSERT INTO dbo.Dim_Clientes VALUES
('CLI-MOSTRADOR',N'Anónimo',N'Sin membresía',N'Sin ciudad',0,0);
CREATE TABLE dbo.Dim_Vinos (
 SKU_Vino VARCHAR(15) NOT NULL PRIMARY KEY,
 Nombre_Etiqueta NVARCHAR(150) NOT NULL,
 Puntaje_Guia_Penin_Vivino DECIMAL(5,2) NULL,
 Maridaje_Sugerido NVARCHAR(100) NULL,
 Cepa_Origen NVARCHAR(100) NULL,
 CONSTRAINT CK_Dim_Vinos_Puntaje CHECK(Puntaje_Guia_Penin_Vivino BETWEEN 0 AND 100)
);
INSERT INTO dbo.Dim_Vinos
SELECT SKU_Vino,TRIM(Nombre_Etiqueta),Puntaje_Guia_Penin_Vivino,
 TRIM(Maridaje_Sugerido),TRIM(Cepa_Origen) FROM dbo.Staging_Ratings;
/* 3) ORO: hecho de ventas; no inventa operaciones eCommerce */
CREATE TABLE dbo.Fact_Ventas_POS (
 ID_Venta_POS VARCHAR(10) NOT NULL PRIMARY KEY,
 Fecha_Hora DATETIME NOT NULL,
 ID_Cliente VARCHAR(15) NOT NULL,
 SKU_Vino VARCHAR(15) NOT NULL,
 Canal_Venta NVARCHAR(30) NOT NULL,
 Botellas_Vendidas INT NOT NULL,
 Precio_Unitario_MXN DECIMAL(10,2) NOT NULL,
 Total_Venta_MXN AS (CONVERT(DECIMAL(14,2),Botellas_Vendidas)*Precio_Unitario_MXN) PERSISTED,
 CONSTRAINT FK_Fact_Cliente FOREIGN KEY (ID_Cliente) REFERENCES dbo.Dim_Clientes(ID_Cliente),
 CONSTRAINT FK_Fact_Vino FOREIGN KEY (SKU_Vino) REFERENCES dbo.Dim_Vinos(SKU_Vino),
 CONSTRAINT CK_Fact_Cantidad CHECK(Botellas_Vendidas > 0),
 CONSTRAINT CK_Fact_Precio CHECK(Precio_Unitario_MXN >= 0)
);
INSERT INTO dbo.Fact_Ventas_POS(ID_Venta_POS,Fecha_Hora,ID_Cliente,SKU_Vino,Canal_Venta,Botellas_Vendidas,Precio_Unitario_MXN)
SELECT v.ID_Venta_POS,v.Fecha_Hora,
 CASE WHEN c.ID_Cliente IS NULL THEN 'CLI-MOSTRADOR' ELSE c.ID_Cliente END,
 v.SKU_Vino,TRIM(v.Canal_Venta),v.Botellas_Vendidas,v.Precio_Unitario_MXN
FROM dbo.Ventas_POS_Tienda v
LEFT JOIN dbo.Dim_Clientes c ON v.ID_Cliente=c.ID_Cliente
INNER JOIN dbo.Dim_Vinos w ON v.SKU_Vino=w.SKU_Vino
WHERE v.Fecha_Hora IS NOT NULL AND v.Botellas_Vendidas>0 AND v.Precio_Unitario_MXN>=0;
GO
/* 4) VISTAS requeridas: Operativa, 360 y KPI */
CREATE VIEW dbo.vw_POS_Operativa AS
SELECT ID_Venta_POS,Fecha_Hora,ID_Cliente,SKU_Vino,Canal_Venta,
 Botellas_Vendidas,Precio_Unitario_MXN,Total_Venta_MXN
FROM dbo.Fact_Ventas_POS;
GO
CREATE VIEW dbo.vw_Gold_Ventas_Vinos AS
SELECT f.ID_Venta_POS,f.Fecha_Hora,CAST(f.Fecha_Hora AS DATE) AS Fecha_Venta,
 f.ID_Cliente,c.Nombre_Cliente,c.Categoria_Membresia,c.Ciudad_Entrega,
 c.Gasto_Acumulado_Anual,c.Gasto_Fue_Imputado,
 f.SKU_Vino,w.Nombre_Etiqueta,w.Puntaje_Guia_Penin_Vivino,
 w.Maridaje_Sugerido,w.Cepa_Origen,f.Canal_Venta,
 f.Botellas_Vendidas,f.Precio_Unitario_MXN,f.Total_Venta_MXN
FROM dbo.Fact_Ventas_POS f
JOIN dbo.Dim_Clientes c ON f.ID_Cliente=c.ID_Cliente
JOIN dbo.Dim_Vinos w ON f.SKU_Vino=w.SKU_Vino;
GO
CREATE VIEW dbo.vw_KPI_Membresia_Canal AS
SELECT Categoria_Membresia,Canal_Venta,COUNT(*) AS Numero_Ventas,
 SUM(Botellas_Vendidas) AS Botellas_Vendidas,
 SUM(Total_Venta_MXN) AS Ingresos_MXN,
 CAST(AVG(Total_Venta_MXN) AS DECIMAL(14,2)) AS Ticket_Promedio_MXN
FROM dbo.vw_Gold_Ventas_Vinos
GROUP BY Categoria_Membresia,Canal_Venta;
GO
CREATE VIEW dbo.vw_KPI_Origen_Vino AS
SELECT Cepa_Origen,SKU_Vino,Nombre_Etiqueta,Puntaje_Guia_Penin_Vivino,
 SUM(Botellas_Vendidas) AS Botellas_Vendidas,
 SUM(Total_Venta_MXN) AS Ingresos_MXN
FROM dbo.vw_Gold_Ventas_Vinos
GROUP BY Cepa_Origen,SKU_Vino,Nombre_Etiqueta,Puntaje_Guia_Penin_Vivino;
GO
CREATE VIEW dbo.vw_Calidad_Integracion AS
SELECT (SELECT COUNT(*) FROM dbo.Ventas_POS_Tienda) AS Ventas_Origen,
 (SELECT COUNT(*) FROM dbo.Fact_Ventas_POS) AS Ventas_Integradas,
 (SELECT COUNT(*) FROM dbo.Ventas_POS_Tienda WHERE ID_Cliente IS NULL) AS Ventas_Anonimas_Origen,
 (SELECT COUNT(*) FROM dbo.Fact_Ventas_POS WHERE ID_Cliente='CLI-MOSTRADOR') AS Ventas_Mostrador_Gold,
 (SELECT COUNT(*) FROM dbo.Dim_Clientes WHERE Gasto_Fue_Imputado=1) AS Clientes_Gasto_Imputado,
 (SELECT COUNT(*) FROM dbo.Staging_Ratings) AS Etiquetas_Origen,
 (SELECT COUNT(*) FROM dbo.Dim_Vinos) AS Etiquetas_Integradas;
GO
/* 5) PROCEDIMIENTOS almacenados adaptados al dataset correcto */
/* Procedimiento obligatorio 1: insercion maestra controlada, sin tocar Staging */
CREATE PROCEDURE dbo.sp_RegistrarClienteCRM
 @ID_Cliente VARCHAR(15), @Nombre NVARCHAR(100),
 @Membresia NVARCHAR(30), @Ciudad NVARCHAR(60),
 @Gasto_Anual DECIMAL(14,2)=0
AS BEGIN
 SET NOCOUNT ON;
 BEGIN TRY
  IF NULLIF(TRIM(@ID_Cliente),'') IS NULL OR NULLIF(TRIM(@Nombre),N'') IS NULL
   THROW 50010,'ID y nombre obligatorios.',1;
  IF @Gasto_Anual IS NULL OR @Gasto_Anual<0
   THROW 50011,'Gasto anual no valido.',1;
  DECLARE @m NVARCHAR(30)=LOWER(TRIM(@Membresia));
  IF @m IS NULL OR @m NOT IN (N'platinum',N'gold',N'standard')
   THROW 50013,'Membresia no permitida.',1;
  BEGIN TRAN;
  IF EXISTS(SELECT 1 FROM dbo.Dim_Clientes WITH (UPDLOCK,HOLDLOCK)
            WHERE ID_Cliente=TRIM(@ID_Cliente))
   THROW 50014,'El cliente ya existe.',1;
  INSERT INTO dbo.Dim_Clientes
   (ID_Cliente,Nombre_Cliente,Categoria_Membresia,Ciudad_Entrega,Gasto_Acumulado_Anual,Gasto_Fue_Imputado)
  VALUES(TRIM(@ID_Cliente),TRIM(@Nombre),
   CASE @m WHEN N'platinum' THEN N'Platinum' WHEN N'gold' THEN N'Gold' ELSE N'Standard' END,
   COALESCE(NULLIF(TRIM(@Ciudad),N''),N'Sin ciudad'),@Gasto_Anual,0);
  COMMIT TRAN;
  SELECT * FROM dbo.Dim_Clientes WHERE ID_Cliente=TRIM(@ID_Cliente);
 END TRY
 BEGIN CATCH
  IF @@TRANCOUNT>0 ROLLBACK TRAN;
  THROW;
 END CATCH
END;
GO
CREATE PROCEDURE dbo.sp_ObtenerClientePorID @ID_Cliente VARCHAR(15)
AS BEGIN SET NOCOUNT ON;
 SELECT c.*,COUNT(f.ID_Venta_POS) AS Numero_Compras_POS,
 COALESCE(SUM(f.Total_Venta_MXN),0) AS Gasto_POS_En_Muestra
 FROM dbo.Dim_Clientes c LEFT JOIN dbo.Fact_Ventas_POS f ON c.ID_Cliente=f.ID_Cliente
 WHERE c.ID_Cliente=@ID_Cliente
 GROUP BY c.ID_Cliente,c.Nombre_Cliente,c.Categoria_Membresia,c.Ciudad_Entrega,
 c.Gasto_Acumulado_Anual,c.Gasto_Fue_Imputado;
END;
GO
CREATE PROCEDURE dbo.sp_HistorialVentasCliente
 @ID_Cliente VARCHAR(15), @FechaInicio DATE, @FechaFin DATE
AS BEGIN
 SET NOCOUNT ON;
 IF @FechaInicio IS NULL OR @FechaFin IS NULL OR @FechaFin < @FechaInicio
  THROW 50012,'Rango de fechas invalido.',1;
 SELECT c.ID_Cliente,c.Nombre_Cliente,f.ID_Venta_POS,f.Fecha_Hora,
  f.SKU_Vino,v.Nombre_Etiqueta,f.Canal_Venta,f.Botellas_Vendidas,f.Total_Venta_MXN
 FROM dbo.Dim_Clientes c INNER JOIN dbo.Fact_Ventas_POS f
  ON c.ID_Cliente=f.ID_Cliente
 INNER JOIN dbo.Dim_Vinos v ON v.SKU_Vino=f.SKU_Vino
 WHERE c.ID_Cliente=TRIM(@ID_Cliente) AND f.Fecha_Hora>=@FechaInicio
  AND f.Fecha_Hora<DATEADD(DAY,1,@FechaFin)
 ORDER BY f.Fecha_Hora DESC;
END;
GO
CREATE PROCEDURE dbo.sp_ConsultarVentasPorCanal
 @Canal_Venta NVARCHAR(30)=NULL,
 @Fecha_Desde DATE=NULL,
 @Fecha_Hasta DATE=NULL
AS BEGIN SET NOCOUNT ON;
 SELECT * FROM dbo.vw_Gold_Ventas_Vinos
 WHERE (@Canal_Venta IS NULL OR Canal_Venta=@Canal_Venta)
 AND (@Fecha_Desde IS NULL OR Fecha_Hora>=@Fecha_Desde)
 AND (@Fecha_Hasta IS NULL OR Fecha_Hora<DATEADD(DAY,1,@Fecha_Hasta))
 ORDER BY Fecha_Hora;
END;
GO
CREATE PROCEDURE dbo.sp_VinosPorPuntaje @Puntaje_Minimo DECIMAL(5,2)=93.00
AS BEGIN SET NOCOUNT ON;
 IF @Puntaje_Minimo NOT BETWEEN 0 AND 100 THROW 50001,'Puntaje fuera de escala 0-100.',1;
 SELECT v.SKU_Vino,v.Nombre_Etiqueta,v.Puntaje_Guia_Penin_Vivino,v.Cepa_Origen,
 COALESCE(SUM(f.Botellas_Vendidas),0) AS Botellas,
 COALESCE(SUM(f.Total_Venta_MXN),0) AS Ingresos_MXN
 FROM dbo.Dim_Vinos v LEFT JOIN dbo.Fact_Ventas_POS f ON f.SKU_Vino=v.SKU_Vino
 WHERE v.Puntaje_Guia_Penin_Vivino>@Puntaje_Minimo
 GROUP BY v.SKU_Vino,v.Nombre_Etiqueta,v.Puntaje_Guia_Penin_Vivino,v.Cepa_Origen
 ORDER BY v.Puntaje_Guia_Penin_Vivino DESC;
END;
GO
CREATE PROCEDURE dbo.sp_ResumenFinanciero
 @Ciudad NVARCHAR(60)=NULL,@Membresia NVARCHAR(30)=NULL
AS BEGIN SET NOCOUNT ON;
 SELECT COUNT(*) AS Transacciones_POS,COALESCE(SUM(Botellas_Vendidas),0) AS Botellas,
 COALESCE(SUM(Total_Venta_MXN),0) AS Ingresos_MXN,
 CAST(AVG(Total_Venta_MXN) AS DECIMAL(14,2)) AS Ticket_Promedio_MXN
 FROM dbo.vw_Gold_Ventas_Vinos
 WHERE (@Ciudad IS NULL OR Ciudad_Entrega=@Ciudad)
 AND (@Membresia IS NULL OR Categoria_Membresia=@Membresia);
END;
GO
/* ETL de gasto: recomputa SOLO clientes con valor originalmente ausente.
   Para CLI-V02, $4,920 es el total de sus ventas POS en esta muestra y se usa
   como proxy; no representa gasto anual confirmado. No altera otros valores
   históricos declarados por el CRM. */
CREATE PROCEDURE dbo.sp_ActualizarGastoCRM
AS BEGIN SET NOCOUNT ON;
 UPDATE c SET Gasto_Acumulado_Anual=COALESCE((
 SELECT SUM(f.Total_Venta_MXN) FROM dbo.Fact_Ventas_POS f WHERE f.ID_Cliente=c.ID_Cliente),0)
 FROM dbo.Dim_Clientes c JOIN dbo.Staging_CRM s ON s.ID_Cliente=c.ID_Cliente
 WHERE s.Gasto_Acumulado_Anual IS NULL;
 SELECT * FROM dbo.Dim_Clientes WHERE Gasto_Fue_Imputado=1;
END;
GO
/* Insercion controlada: demostracion reversible (no altera los KPIs) */
BEGIN TRAN;
EXEC dbo.sp_RegistrarClienteCRM @ID_Cliente='CLI-TEST', @Nombre=N'  Prueba Controlada  ',
 @Membresia=N' gold ', @Ciudad=N'León', @Gasto_Anual=0;
ROLLBACK TRAN;
GO
/* 6) CONSULTAS / PRUEBAS */
SELECT * FROM dbo.vw_Calidad_Integracion;
SELECT * FROM dbo.vw_Gold_Ventas_Vinos ORDER BY ID_Venta_POS;
SELECT * FROM dbo.vw_KPI_Membresia_Canal ORDER BY Categoria_Membresia,Canal_Venta;
SELECT * FROM dbo.vw_KPI_Origen_Vino ORDER BY Ingresos_MXN DESC;
EXEC dbo.sp_ObtenerClientePorID @ID_Cliente='CLI-V02';
EXEC dbo.sp_HistorialVentasCliente @ID_Cliente='CLI-V01', @FechaInicio='2026-08-01', @FechaFin='2026-08-03';
EXEC dbo.sp_ConsultarVentasPorCanal @Canal_Venta=N'Boutique';
EXEC dbo.sp_VinosPorPuntaje @Puntaje_Minimo=93.00;
EXEC dbo.sp_ResumenFinanciero;
EXEC dbo.sp_ActualizarGastoCRM;
/* Preguntas de negocio */
-- Q1: Preferencia de etiquetas >93 pts en membresía Platinum:
SELECT SKU_Vino,Nombre_Etiqueta,Puntaje_Guia_Penin_Vivino,
 SUM(Botellas_Vendidas) Botellas,SUM(Total_Venta_MXN) Ingresos_MXN,
 CAST(100.0*SUM(Botellas_Vendidas)/NULLIF((SELECT SUM(Botellas_Vendidas)
  FROM dbo.vw_Gold_Ventas_Vinos WHERE Categoria_Membresia='Platinum'),0) AS DECIMAL(6,2))
  AS Porcentaje_Botellas_Platinum,
 CAST(100.0*SUM(Total_Venta_MXN)/NULLIF((SELECT SUM(Total_Venta_MXN)
  FROM dbo.vw_Gold_Ventas_Vinos WHERE Categoria_Membresia='Platinum'),0) AS DECIMAL(6,2))
  AS Porcentaje_Ingresos_Platinum
FROM dbo.vw_Gold_Ventas_Vinos
WHERE Categoria_Membresia='Platinum' AND Puntaje_Guia_Penin_Vivino>93
GROUP BY SKU_Vino,Nombre_Etiqueta,Puntaje_Guia_Penin_Vivino;
-- Q2: ingresos por ciudad y canal, solo canales observados:
SELECT Ciudad_Entrega,Canal_Venta,SUM(Total_Venta_MXN) Ingresos_MXN
FROM dbo.vw_Gold_Ventas_Vinos GROUP BY Ciudad_Entrega,Canal_Venta;
-- Q3: participación por origen:
SELECT Cepa_Origen AS Origen_Geografico,
 SUM(Botellas_Vendidas) AS Botellas_Vendidas,
 CAST(100.0*SUM(Botellas_Vendidas)/NULLIF((SELECT SUM(Botellas_Vendidas)
  FROM dbo.Fact_Ventas_POS),0) AS DECIMAL(6,2)) AS Participacion_Botellas_Pct,
 SUM(Total_Venta_MXN) Ingresos_MXN,
 CAST(100.0*SUM(Total_Venta_MXN)/NULLIF((SELECT SUM(Total_Venta_MXN)
 FROM dbo.Fact_Ventas_POS),0) AS DECIMAL(6,2)) AS Participacion_Pct
FROM dbo.vw_Gold_Ventas_Vinos GROUP BY Cepa_Origen;
/* Limitaciones: no existen registros de transacciones web ni stock/entradas/salidas.
   Gasto CRM histórico no es comparable directamente con el gasto POS de esta muestra. */

/* ASSERTS cuantitativos esperados sobre muestra oficial */
IF (SELECT COUNT(*) FROM dbo.Fact_Ventas_POS)<>5 THROW 50101,'QA: numero ventas incorrecto',1;
IF (SELECT SUM(Botellas_Vendidas) FROM dbo.Fact_Ventas_POS)<>24 THROW 50102,'QA: botellas incorrectas',1;
IF (SELECT SUM(Total_Venta_MXN) FROM dbo.Fact_Ventas_POS)<>22760 THROW 50103,'QA: ingresos incorrectos',1;
IF (SELECT COUNT(*) FROM dbo.Fact_Ventas_POS WHERE ID_Cliente='CLI-MOSTRADOR')<>1 THROW 50104,'QA: venta anonima perdida',1;
IF (SELECT Gasto_Acumulado_Anual FROM dbo.Dim_Clientes WHERE ID_Cliente='CLI-V02')<>4920 THROW 50105,'QA: imputacion incorrecta',1;
GO
PRINT 'QA de totales ejecutada; ASSERTS aprobados en esta ejecucion.';
