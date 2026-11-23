#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="mcr.microsoft.com/mssql/server:2022-latest"
NAME="vinicola-sql-demo-$(date +%s)-$$"
SA_PASSWORD="Aa1!$(openssl rand -hex 18)"
SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
LOG="$ROOT/docs/evidencia-ejecucion-sqlserver-2026-11-23.txt"

cleanup() {
  docker rm -f "$NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

if docker ps --format '{{.Names}}' | rg -q "^${NAME}$"; then
  echo "Nombre temporal inesperadamente ocupado; se cancela."
  exit 1
fi

docker run -d --name "$NAME" \
  -e ACCEPT_EULA=Y -e MSSQL_PID=Developer -e MSSQL_SA_PASSWORD="$SA_PASSWORD" \
  -v "$ROOT/src:/scripts:ro" "$IMAGE" >/dev/null

ready=0
for _ in $(seq 1 60); do
  if docker exec -e SQLCMDPASSWORD="$SA_PASSWORD" "$NAME" "$SQLCMD" -S localhost -U sa -C -b -Q "SELECT 1" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 2
done
if [[ "$ready" != 1 ]]; then
  echo "SQL Server no quedó disponible dentro del límite; no se ejecutaron los scripts."
  docker logs "$NAME" | tail -30
  exit 1
fi

{
  echo "Demo limpia · SQL Server 2022 Developer · $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "Contenedor desechable, sin puertos publicados; scripts montados de solo lectura."
  echo "Base temporal creada por 01_ddl_arquitectura_der.sql."
  for file in 01_ddl_arquitectura_der.sql 02_etl_ingesta_bronce.sql 03_etl_limpieza_plata.sql 04_vistas_gold_bi.sql; do
    echo
    echo "===== $file ====="
    docker exec -e SQLCMDPASSWORD="$SA_PASSWORD" "$NAME" "$SQLCMD" -S localhost -U sa -C -b -W -s ' | ' -i "/scripts/$file"
  done
  echo
  echo "===== Reejecución idempotente de los cuatro archivos ====="
  for file in 01_ddl_arquitectura_der.sql 02_etl_ingesta_bronce.sql 03_etl_limpieza_plata.sql 04_vistas_gold_bi.sql; do
    echo
    echo "----- $file -----"
    docker exec -e SQLCMDPASSWORD="$SA_PASSWORD" "$NAME" "$SQLCMD" -S localhost -U sa -C -b -W -s ' | ' -i "/scripts/$file"
  done
  echo
  echo "===== Resumen compacto para exposición ====="
  docker exec -e SQLCMDPASSWORD="$SA_PASSWORD" "$NAME" "$SQLCMD" -S localhost -U sa -C -b -W -s ' | ' -d DB_Vinicola_Integration -Q "SET NOCOUNT ON; SELECT c.Control,c.Resultado FROM oro.vw_Calidad_Integracion q CROSS APPLY (VALUES (N'POS Bronce → IDs → Oro',CONCAT(q.POS_Filas_Bronce,N' → ',q.POS_Ids_Unicos_Bronce,N' → ',q.POS_Transacciones_Oro)),(N'Duplicados / POS inválidos',CONCAT(q.POS_Duplicados_Descartables,N' / ',q.POS_Filas_Invalidas_Bronce)),(N'Ratings válidos / inválidos',CONCAT(q.Ratings_Vinos_Validos_Plata,N' / ',q.Ratings_Filas_Invalidas_Bronce))) c(Control,Resultado) UNION ALL SELECT N'Oro total',CONCAT(COUNT(*),N' ventas · ',SUM(Botellas_Vendidas),N' botellas · $',CONVERT(VARCHAR(20),SUM(Total_Venta_MXN)),N' MXN') FROM oro.Fact_Ventas_POS UNION ALL SELECT N'POS-805 vigente',CONVERT(NVARCHAR(16),(SELECT Fecha_Hora FROM oro.Fact_Ventas_POS WHERE ID_Venta_POS='POS-805'),120)"
  echo
  echo "===== Procedimientos almacenados ====="
  docker exec -e SQLCMDPASSWORD="$SA_PASSWORD" "$NAME" "$SQLCMD" -S localhost -U sa -C -b -W -s ' | ' -d DB_Vinicola_Integration -Q "SET NOCOUNT ON; EXEC plata.sp_ObtenerClientePorID @ID_Cliente='CLI-V01'; EXEC plata.sp_HistorialVentasCliente @ID_Cliente='CLI-V01',@FechaInicio='2026-08-01',@FechaFin='2026-08-03'; EXEC plata.sp_VinosPorPuntaje @Puntaje_Minimo=93; EXEC plata.sp_ResumenFinanciero; EXEC plata.sp_ConsultarVentasPorCanal; BEGIN TRAN; EXEC plata.sp_RegistrarClienteCRM @ID_Cliente='CLI-QA-TEMP',@Nombre=N'Cliente de verificación',@Membresia=N'Standard',@Ciudad=N'León',@Gasto_Confirmado=1; ROLLBACK TRAN; SELECT COUNT(*) AS ClienteTemporalTrasRollback FROM plata.Dim_Clientes WHERE ID_Cliente='CLI-QA-TEMP';"
  echo
  echo "===== Chequeo de reejecución ====="
  docker exec -e SQLCMDPASSWORD="$SA_PASSWORD" "$NAME" "$SQLCMD" -S localhost -U sa -C -b -W -s ' | ' -d DB_Vinicola_Integration -Q "SET NOCOUNT ON; EXEC plata.usp_ProcesarPlata; SELECT COUNT(*) AS Ventas_Oro_Tras_Reproceso,SUM(Botellas_Vendidas) AS Botellas,SUM(Total_Venta_MXN) AS Ingresos_MXN FROM oro.Fact_Ventas_POS;"
  echo
  echo "===== Resultado verificable para captura ====="
  docker exec -e SQLCMDPASSWORD="$SA_PASSWORD" "$NAME" "$SQLCMD" -S localhost -U sa -C -b -W -s ' | ' -d DB_Vinicola_Integration -Q "SET NOCOUNT ON; SELECT c.Control,c.Resultado FROM oro.vw_Calidad_Integracion q CROSS APPLY (VALUES (N'POS Bronce → IDs → Oro',CONCAT(q.POS_Filas_Bronce,N' → ',q.POS_Ids_Unicos_Bronce,N' → ',q.POS_Transacciones_Oro)),(N'Duplicados / POS inválidos',CONCAT(q.POS_Duplicados_Descartables,N' / ',q.POS_Filas_Invalidas_Bronce)),(N'Ratings válidos / inválidos',CONCAT(q.Ratings_Vinos_Validos_Plata,N' / ',q.Ratings_Filas_Invalidas_Bronce))) c(Control,Resultado) UNION ALL SELECT N'Oro total',CONCAT(COUNT(*),N' ventas · ',SUM(Botellas_Vendidas),N' botellas · $',CONVERT(VARCHAR(20),SUM(Total_Venta_MXN)),N' MXN') FROM oro.Fact_Ventas_POS UNION ALL SELECT N'POS-805 vigente',CONVERT(NVARCHAR(16),(SELECT Fecha_Hora FROM oro.Fact_Ventas_POS WHERE ID_Venta_POS='POS-805'),120) UNION ALL SELECT N'Reejecución',CONCAT(COUNT(*),N' ventas · ',SUM(Botellas_Vendidas),N' botellas · $',CONVERT(VARCHAR(20),SUM(Total_Venta_MXN)),N' MXN') FROM oro.Fact_Ventas_POS UNION ALL SELECT N'Cliente tras rollback',CONVERT(VARCHAR(2),(SELECT COUNT(*) FROM plata.Dim_Clientes WHERE ID_Cliente='CLI-QA-TEMP'));"
  echo
  echo "Demo ejecutada desde cero; el contenedor se elimina al cerrar esta terminal."
} 2>&1 | tee "$LOG"

echo
echo "EVIDENCIA VISIBLE: deja esta terminal abierta para capturar la consola."
read -r -p "Presiona Enter cuando hayas terminado de ver/capturar la evidencia para eliminar el contenedor temporal."
