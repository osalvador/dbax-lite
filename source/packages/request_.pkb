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
      r_request.method := p_method;
   END;

   PROCEDURE headers (p_headers in dbx.g_assoc_array)
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
      RETURN DBMS_UTILITY.lname_array
   AS
   BEGIN
      RETURN r_request.segment_inputs;
   END;

   PROCEDURE segment_inputs (p_segment_inputs IN DBMS_UTILITY.lname_array)
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