CREATE TABLE WDX_DOCUMENTS
(
  APPID         VARCHAR2(50 BYTE)                   NULL,  
  NAME          VARCHAR2(256 BYTE)              NOT NULL,
  MIME_TYPE     VARCHAR2(128 BYTE)                  NULL,
  DOC_SIZE      NUMBER                              NULL,
  DAD_CHARSET   VARCHAR2(128 BYTE)                  NULL,
  LAST_UPDATED  DATE                                NULL,
  CONTENT_TYPE  VARCHAR2(128 BYTE)                  NULL,
  BLOB_CONTENT  BLOB                                NULL,
  USERNAME      VARCHAR2(255 BYTE)                  NULL
);


ALTER TABLE WDX_DOCUMENTS ADD (
  UNIQUE (APPID, NAME));

