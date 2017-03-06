CREATE OR REPLACE PACKAGE BODY response_
AS
   /**
   * Response Record instance
   */
   r_response   response_type;

   PROCEDURE header (p_key IN VARCHAR2, p_value IN VARCHAR2)
   AS
   BEGIN
      r_response.headers (p_key) := p_value;
   END header;


   FUNCTION header (p_key IN VARCHAR2)
      RETURN VARCHAR2
   AS
   BEGIN
      IF r_response.headers.exists (p_key)
      THEN
         RETURN r_response.headers (p_key);
      ELSE
         RETURN NULL;
      END IF;
   END header;

   FUNCTION headers
      RETURN dbx.g_assoc_array
   AS
   BEGIN
      RETURN r_response.headers;
   END headers;

   FUNCTION status
      RETURN PLS_INTEGER
   AS
   BEGIN
      RETURN r_response.status;
   END status;


   PROCEDURE status (p_status IN PLS_INTEGER)
   AS
   BEGIN
      r_response.status := p_status;
   END status;


   FUNCTION content
      RETURN VARCHAR2
   AS
   BEGIN
      RETURN r_response.content;
   END content;

   PROCEDURE content (p_content IN VARCHAR2)
   AS
   BEGIN
      r_response.content := p_content;
   END content;


   FUNCTION cookie (p_name IN VARCHAR2)
      RETURN cookie_type
   AS
   BEGIN
      IF r_response.cookies.exists (p_name)
      THEN
         RETURN r_response.cookies (p_name);
      ELSE
         RETURN NULL;
      END IF;
   END cookie;

   FUNCTION cookies
      RETURN g_cookie_array
   AS
   BEGIN
      RETURN r_response.cookies;
   END cookies;


   PROCEDURE cookie (p_name       IN VARCHAR2
                   , p_value      IN VARCHAR2
                   , p_expires    IN DATE DEFAULT NULL
                   , p_path       IN VARCHAR2 DEFAULT NULL
                   , p_domain     IN VARCHAR2 DEFAULT NULL
                   , p_secure     IN BOOLEAN DEFAULT FALSE
                   , p_httponly   IN BOOLEAN DEFAULT TRUE )
   AS
   BEGIN
      IF p_name IS NOT NULL
      THEN
         r_response.cookies (p_name).name := p_name;
         r_response.cookies (p_name).value := p_value;
         r_response.cookies (p_name).expires := p_expires;
         r_response.cookies (p_name).path := p_path;
         r_response.cookies (p_name).domain := p_domain;
         r_response.cookies (p_name).secure := p_secure;
         r_response.cookies (p_name).httponly := p_httponly;
      END IF;
   END cookie;


   PROCEDURE forget_cookie (p_name IN VARCHAR2)
   AS
   BEGIN
      cookie (p_name => p_name, p_value => NULL, p_expires => sysdate - 100);
   END forget_cookie;


   FUNCTION download (p_file_content IN BLOB, p_file_name IN VARCHAR2, p_content IN VARCHAR2)
      RETURN CLOB
   AS
      l_blob_content   BLOB := p_file_content;
   BEGIN
      dbx.g_stop_process := TRUE;

      htp.init;
      owa_util.mime_header (nvl (p_content, 'application/octet-stream'), FALSE, dbx.get_property ('encoding'));
      htp.p ('Content-Length: ' || dbms_lob.getlength (l_blob_content));
      htp.p ('Content-Disposition: attachment; filename="' || p_file_name || '"');
      owa_util.status_line (200);
      owa_util.http_header_close;

      wpg_docload.download_file (l_blob_content);

      RETURN NULL;
   END download;

   FUNCTION clob2blob (p_clob IN CLOB)
      RETURN BLOB
   IS
      v_blob            BLOB;
      l_dest_offset     INTEGER := 1;
      l_source_offset   INTEGER := 1;
      l_lang_context    INTEGER := dbms_lob.default_lang_ctx;
      l_warning         INTEGER := dbms_lob.warn_inconvertible_char;
   BEGIN
      --Paso el CLOB a BLOB
      dbms_lob.createtemporary (v_blob, TRUE);


      dbms_lob.converttoblob (dest_lob    => v_blob
                            , src_clob    => p_clob
                            , amount      => dbms_lob.getlength (p_clob)
                            , dest_offset => l_dest_offset
                            , src_offset  => l_source_offset
                            , blob_csid   => dbms_lob.default_csid
                            , lang_context => l_lang_context
                            , warning     => l_warning);

      -- Free temporary BLOBs.
      --DBMS_LOB.freetemporary (v_blob);
      RETURN v_blob;
   END clob2blob;


   FUNCTION download (p_file_content IN CLOB, p_file_name IN VARCHAR2, p_content IN VARCHAR2 DEFAULT NULL )
      RETURN CLOB
   AS
   BEGIN
      RETURN download (clob2blob (p_file_content), p_file_name, p_content);
   END download;
END response_;
/