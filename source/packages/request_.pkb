/* Formatted on 31/01/2017 17:27:04 (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE BODY request_
AS
   /**
   * Request Record instance
   */
   r_request   request_type;

   FUNCTION method
      RETURN VARCHAR2
   AS
   BEGIN
      RETURN r_request.method;
   END;

   PROCEDURE method (p_method IN VARCHAR2)
   AS
   BEGIN
      IF UPPER (p_method) IN ('GET', 'POST') OR p_method IS NULL
      THEN
         r_request.method := UPPER (p_method);
      END IF;
   END;

   PROCEDURE headers (p_headers IN dbx.g_assoc_array)
   AS
   BEGIN
      r_request.headers := p_headers;
   END headers;


   FUNCTION header (p_key IN VARCHAR2)
      RETURN VARCHAR2
   AS
   BEGIN
      IF r_request.headers.EXISTS (p_key)
      THEN
         RETURN r_request.headers (p_key);
      ELSE
         RETURN NULL;
      END IF;
   END header;

   FUNCTION headers
      RETURN dbx.g_assoc_array
   AS
   BEGIN
      RETURN r_request.headers;
   END headers;

   PROCEDURE load_cookies (p_cookies IN VARCHAR2 DEFAULT NULL )
   AS
      l_http_cookie   VARCHAR2 (32767);
   BEGIN
      --Load HTTP Cookie string
      l_http_cookie := NVL (p_cookies, OWA_UTIL.get_cgi_env ('HTTP_COOKIE'));

      --Parse Cookie String to request cookies
      r_request.cookies := dbx.query_string_to_array (l_http_cookie, '; ', '=');
   END load_cookies;


   FUNCTION cookie (p_key IN VARCHAR2)
      RETURN VARCHAR2
   AS
   BEGIN
      IF r_request.cookies.EXISTS (p_key)
      THEN
         RETURN r_request.cookies (p_key);
      ELSE
         RETURN NULL;
      END IF;
   END cookie;


   PROCEDURE cookies (p_cookies IN dbx.g_assoc_array)
   AS
   BEGIN
      r_request.cookies := p_cookies;
   END cookies;

   FUNCTION has_cookie (p_key IN VARCHAR2)
      RETURN BOOLEAN
   AS
   BEGIN
      IF r_request.cookies.EXISTS (p_key)
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END has_cookie;


   FUNCTION input (p_key IN VARCHAR2)
      RETURN VARCHAR2
   AS
   BEGIN
      IF r_request.inputs.EXISTS (p_key)
      THEN
         RETURN r_request.inputs (p_key);
      ELSE
         RETURN NULL;
      END IF;
   END input;

   FUNCTION inputs
      RETURN dbx.g_assoc_array
   AS
   BEGIN
      RETURN r_request.inputs;
   END;


   PROCEDURE inputs (p_inputs IN dbx.g_assoc_array)
   AS
   BEGIN
      r_request.inputs := p_inputs;
   END inputs;


   FUNCTION segment_input (p_key IN PLS_INTEGER)
      RETURN VARCHAR2
   AS
   BEGIN
      IF r_request.segment_inputs.EXISTS (p_key)
      THEN
         RETURN r_request.segment_inputs (p_key);
      ELSE
         RETURN NULL;
      END IF;
   END segment_input;


   FUNCTION segment_inputs
      RETURN dbx.g_varchar_array
   AS
   BEGIN
      RETURN r_request.segment_inputs;
   END;

   PROCEDURE segment_inputs (p_segment_inputs IN dbx.g_varchar_array)
   AS
   BEGIN
      r_request.segment_inputs := p_segment_inputs;
   END;


   FUNCTION route
      RETURN VARCHAR2
   AS
   BEGIN
      RETURN r_request.route;
   END route;

   PROCEDURE route (p_uri IN VARCHAR2)
   AS
   BEGIN
      r_request.route := p_uri;
   END;
END request_;
/