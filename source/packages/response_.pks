CREATE OR REPLACE PACKAGE response_
AS
   /**
   * Response cookie type
   */
   TYPE cookie_type
   IS
      RECORD (
         name       VARCHAR2 (4096)
       , value      VARCHAR2 (4096)
       , expires    DATE
       , path       VARCHAR2 (255)
       , domain     VARCHAR2 (255)
       , secure     BOOLEAN DEFAULT FALSE
       , httponly   BOOLEAN DEFAULT FALSE
      );

   TYPE g_cookie_array
   IS
      TABLE OF cookie_type
         INDEX BY VARCHAR2 (255);


   /**
   * Response Record Type
   */
   TYPE response_type
   IS
      RECORD (
         headers   dbx.g_assoc_array -- HTTP Headers
       , status    PLS_INTEGER -- HTTP Status code
       , content   VARCHAR2 (100) -- HTTP Content Type
       , cookies   g_cookie_array -- Cookies to be sent to the response
      );


   /**
   * Set a header to the response.
   *
   * @param  p_key     the header filed name
   * @param  p_value   the header value
   */
   PROCEDURE header (p_key IN VARCHAR2, p_value IN VARCHAR2);

   /**
   * Retrieve a header from the response
   *
   * @param  p_key     the header key
   *
   * @return the value if exists
   */
   FUNCTION header (p_key IN VARCHAR2)
      RETURN VARCHAR2;

   /**
   * Retrieve a header array from the response
   *
   * @return the array if exists
   */
   FUNCTION headers
      RETURN dbx.g_assoc_array;

   /**
   * Get the status code for the response.
   *
   * @return    the http status code
   */
   FUNCTION status
      RETURN PLS_INTEGER;

   /**
   * Set the status code to the response.
   *
   * @param     p_status    the http status code
   */
   PROCEDURE status (p_status IN PLS_INTEGER);


   /**
   * Get the content of the response
   *
   * @return    the http content type
   */
   FUNCTION content
      RETURN VARCHAR2;

   /**
   * Set the content to the response.
   *
   * @param     p_content    the http status code
   */
   PROCEDURE content (p_content IN VARCHAR2);

   /**
   * Retrieve a cookie from the response
   *
   * @param     p_name     the cookie key
   *
   * @return the cookie record if exists
   */
   FUNCTION cookie (p_name IN VARCHAR2)
      RETURN cookie_type;

   /**
   * Retrieve a cookie array from the response
   *
   * @return the cookie record if exists
   */
   FUNCTION cookies
      RETURN g_cookie_array;

   /**
   *  Add a cookie to the response.
   *
   * @param     p_name      the name of the cookie
   * @param     p_value     the value to be held by the cookie
   * @param     p_expires   the date when the cookie should be discarded by the browser
   * @param     p_path      the path below which the cookie should be supplied by the browser
   * @param     p_domain    the web site domain to which this cookie applies
   * @param     p_secure    A secure cookie can only be transmitted over an encrypted connection
   * @param     p_httponly  An HttpOnly cookie cannot be accessed by client-side APIs, such as JavaScript
   */
   PROCEDURE cookie (p_name       IN VARCHAR2
                   , p_value      IN VARCHAR2
                   , p_expires    IN DATE DEFAULT NULL
                   , p_path       IN VARCHAR2 DEFAULT NULL
                   , p_domain     IN VARCHAR2 DEFAULT NULL
                   , p_secure     IN BOOLEAN DEFAULT FALSE
                   , p_httponly   IN BOOLEAN DEFAULT TRUE );

   /**
   * Expire the given cookie.
   *
   * @param    p_name      the cookie name
   */
   PROCEDURE forget_cookie (p_name IN VARCHAR2);



   /**
   * Create a new file download response.
   *
   * @param     p_file_content      the blob or clob file content
   * @param     p_file_name         the file name
   * @param     p_content           the file content type
   */
   FUNCTION download (p_file_content IN BLOB, p_file_name IN VARCHAR2, p_content IN VARCHAR2 default null)
      RETURN CLOB;
      
   FUNCTION download (p_file_content IN CLOB, p_file_name IN VARCHAR2, p_content IN VARCHAR2 default null)
      RETURN CLOB;            
END response_;
/