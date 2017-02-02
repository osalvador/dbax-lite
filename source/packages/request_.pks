CREATE OR REPLACE PACKAGE request_
AS
   /**
   * Request Record Type
   */
   TYPE request_type
   IS
      RECORD (
         method           VARCHAR2 (32) -- HTTP_METHOD
       , headers          dbx.g_assoc_array --
       , cookies          dbx.g_assoc_array --
       , inputs           dbx.g_assoc_array -- G$GET or G$POST input parameters
       , segment_inputs   dbx.g_varchar_array -- URL input segment parameters
       , route            VARCHAR2 (32767) -- Matched route
      );

   /**
   * Get the request method.
   *
   * @return the value if exists
   */
   FUNCTION method
      RETURN VARCHAR2;

   /**
   * Get the real request method.
   *
   * @return the value if exists
   */
   FUNCTION real_method
      RETURN VARCHAR2;

   /**
   * Set the request method.
   *
   * @param p_method    the request method
   */
   PROCEDURE method (p_method IN VARCHAR2);

   /**
   * Set a header arry to the request.
   *
   * @param  p_headers     the header array
   */
   PROCEDURE headers (p_headers IN dbx.g_assoc_array);

   /**
   * Retrieve a header from the request
   *
   * @param  p_key     the header key
   *
   * @return the value if exists
   */
   FUNCTION header (p_key IN VARCHAR2)
      RETURN VARCHAR2;

   /**
   * Retrieve a header array from the request
   *
   * @return the array if exists
   */
   FUNCTION headers
      RETURN dbx.g_assoc_array;

   /**
   * Load client cookies in request_type
   *
   * @param  p_cookies       the cookies text, default null.
   */
   PROCEDURE load_cookies (p_cookies IN VARCHAR2 DEFAULT NULL );

   /**
   * Retrieve a cookie from the request
   *
   * @param  p_key     the cookie key
   *
   * @return the value if exists
   */
   FUNCTION cookie (p_key IN VARCHAR2)
      RETURN VARCHAR2;

   /**
   * Set the cookie to the request
   *
   * @param  p_key     the cookie key
   *
   * @return the value if exists
   */
   PROCEDURE cookies (p_cookies IN dbx.g_assoc_array);

   /**
   * Determine if a cookie is set on the request.
   *
   * @param  p_key     the cookie key
   *
   * @return the value if exists
   */
   FUNCTION has_cookie (p_key IN VARCHAR2)
      RETURN BOOLEAN;

   /**
   * Retrieve an input item from the request.
   *
   * @param  p_key     the input key
   *
   * @return the value if exists
   */
   FUNCTION input (p_key IN VARCHAR2)
      RETURN VARCHAR2;

   /**
   * Retrieve an input array from the request.
   *
   * @return the inputs array
   */
   FUNCTION inputs
      RETURN dbx.g_assoc_array;

   /**
   * Set the input array to the request.
   *
   * @param  p_inputs     the input array
   */
   PROCEDURE inputs (p_inputs IN dbx.g_assoc_array);

   /**
   * Retrieve an input segment item from the request.
   *
   * @param  p_key     the input array key
   *
   * @return the value if exists
   */
   FUNCTION segment_input (p_key IN PLS_INTEGER)
      RETURN VARCHAR2;

   /**
   * Retrieve an input segment array from the request.
   *
   * @return the inputs segment array
   */
   FUNCTION segment_inputs
      RETURN dbx.g_varchar_array;

   /**
   * Set an input segment array to the request.
   *
   * @return the inputs segment array
   */
   PROCEDURE segment_inputs (p_segment_inputs IN dbx.g_varchar_array);

   /**
   * Get the route handling the request.
   *
   * @return the route uri
   */
   FUNCTION route
      RETURN VARCHAR2;

   /**
   * Set the route handling the request.
   *
   * @param  p_uri     the route uri
   */
   PROCEDURE route (p_uri IN VARCHAR2);

   /**
   * Get the URL (no query string) for the request.
   *
   * @return the inputs segment array
   */
   FUNCTION url
      RETURN VARCHAR2;

   /**
   * Get the full URL for the request.
   *
   * @return the inputs segment array
   */
   FUNCTION full_url
      RETURN VARCHAR2;
END request_;
/