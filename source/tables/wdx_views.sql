--
-- WDX_VIEWS  (Table) 
--
CREATE TABLE WDX_VIEWS
(
  APPID             VARCHAR2(50 BYTE)              NOT NULL,
  NAME              VARCHAR2(300 BYTE)             NOT NULL,
  TITLE             VARCHAR2(300 BYTE)                 NULL,
  SOURCE            CLOB                               NULL,
  COMPILED_SOURCE   CLOB                               NULL,
  DESCRIPTION       VARCHAR2(300 BYTE)                 NULL,
  VISIBLE           VARCHAR2(1 BYTE)               DEFAULT 'Y'                   NOT NULL,
  CREATED_BY        VARCHAR2(100 BYTE)             DEFAULT -1                    NOT NULL,
  CREATED_DATE      DATE                           DEFAULT SYSDATE               NOT NULL,
  MODIFIED_BY       VARCHAR2(100 BYTE)             DEFAULT -1                    NOT NULL,
  MODIFIED_DATE     DATE                           DEFAULT SYSDATE               NOT NULL
);


--
-- WDX_VIEWS_PK  (Index) 
--
--  Dependencies: 
--   WDX_VIEWS (Table)
--
CREATE UNIQUE INDEX WDX_VIEWS_PK ON WDX_VIEWS
(APPID, NAME);


-- 
-- Non Foreign Key Constraints for Table WDX_VIEWS 
-- 
ALTER TABLE WDX_VIEWS ADD (
  CONSTRAINT WDX_VIEWS_PK
 PRIMARY KEY
 (APPID, NAME));


