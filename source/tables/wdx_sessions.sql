--
-- WDX_SESSIONS  (Table) 
--
--  Dependencies: 
--   WDX_APPLICATIONS (Table)
--
CREATE TABLE WDX_SESSIONS
(
  APPID             VARCHAR2(50 BYTE)           NOT NULL,
  SESSION_ID        VARCHAR2(256 BYTE)              NULL,
  USERNAME          VARCHAR2(255 BYTE)              NULL,
  EXPIRED           CHAR(1 BYTE)                    NULL,
  LAST_ACCESS       TIMESTAMP(6)                    NULL,
  CGI_ENV           VARCHAR2(4000 BYTE)             NULL,
  SESSION_VARIABLE  VARCHAR2(4000 BYTE)             NULL,
  CREATED_BY        VARCHAR2(100 BYTE)          DEFAULT -1                    NOT NULL,
  CREATED_DATE      DATE                        DEFAULT SYSDATE               NOT NULL,
  MODIFIED_BY       VARCHAR2(100 BYTE)          DEFAULT -1                    NOT NULL,
  MODIFIED_DATE     DATE                        DEFAULT SYSDATE               NOT NULL
);


--
-- WDX_SESSIONS_PK  (Index) 
--
--  Dependencies: 
--   WDX_SESSIONS (Table)
--
CREATE UNIQUE INDEX WDX_SESSIONS_PK ON WDX_SESSIONS
(APPID, SESSION_ID);


-- 
-- Non Foreign Key Constraints for Table WDX_SESSIONS 
-- 
ALTER TABLE WDX_SESSIONS ADD (
  CHECK (expired in (0,1)));

ALTER TABLE WDX_SESSIONS ADD (
  CONSTRAINT WDX_SESSIONS_PK
 PRIMARY KEY
 (APPID, SESSION_ID));


