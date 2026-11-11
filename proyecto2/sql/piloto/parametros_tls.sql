SET NOCOUNT ON;

EXEC sys.sp_getagentparameterlist @agent_type = 1;
EXEC sys.sp_getagentparameterlist @agent_type = 2;
EXEC sys.sp_getagentparameterlist @agent_type = 3;

