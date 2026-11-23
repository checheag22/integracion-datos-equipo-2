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
