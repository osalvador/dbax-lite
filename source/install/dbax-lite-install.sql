Rem    NAME
Rem      dbax-lite-install.sql
Rem
Rem    DESCRIPTION
Rem 	 dbax lite installation script.
Rem
Rem    REQUIREMENTS
Rem      - Oracle Database 11g or later
Rem
Rem    Example:
Rem      sqlplus "user/userpass" @dbax-lite-install
Rem

whenever sqlerror exit

PROMPT -- Setting optimize level --
whenever sqlerror exit
SET SCAN OFF
ALTER SESSION SET PLSQL_OPTIMIZE_LEVEL = 3;
ALTER SESSION SET plsql_code_type = 'NATIVE';


PROMPT ------------------------------------------;
PROMPT -- Creating Table Views --;
PROMPT ------------------------------------------;
@@../tables/wdx_views.sql;

PROMPT ------------------------------------------;
PROMPT -- Compiling Packages Specs --;
PROMPT ------------------------------------------;

@@../packages/dbax_core.pks;
@@../packages/dbax_teplsql.pks;
@@../packages/tapi_wdx_views.pks;

PROMPT ------------------------------------------;
PROMPT -- Installing Packages Bodies --;
PROMPT ------------------------------------------;


@@../packages/dbax_teplsql.pkb;
@@../packages/dbax_core.pkb;
@@../packages/tapi_wdx_views.pkb;

quit;
/