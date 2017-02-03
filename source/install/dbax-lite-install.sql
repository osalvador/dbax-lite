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
Rem      sqlplus "user/userpass"@SID @dbax-lite-install
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
@@../tables/wdx_sessions.sql;

PROMPT ------------------------------------------;
PROMPT -- Compiling Packages Specs --;
PROMPT ------------------------------------------;

@@../packages/dbx.pks;
@@../packages/request_.pks;
@@../packages/response_.pks;
@@../packages/route_.pks;
@@../packages/session_.pks;
@@../packages/view_.pks;


PROMPT ------------------------------------------;
PROMPT -- Installing Packages Bodies --;
PROMPT ------------------------------------------;

@@../packages/dbx.pkb;
@@../packages/request_.pkb;
@@../packages/response_.pkb;
@@../packages/route_.pkb;
@@../packages/session_.pkb;
@@../packages/view_.pkb;

quit;
/