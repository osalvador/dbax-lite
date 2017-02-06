CREATE OR REPLACE PACKAGE dbx
AS
   /*****************
   *  PL/SQL TABLES
   *****************/

   --Global Variables
   TYPE g_assoc_array
   IS
      TABLE OF VARCHAR2 (32767)
         INDEX BY VARCHAR2 (255);

   TYPE g_varchar_array
   IS
      TABLE OF VARCHAR2 (32767)
         INDEX BY BINARY_INTEGER;


   --Empty array for dynamic parameter
   empty_vc_arr     owa_util.vc_arr;

   --G_STOP_PROCESS Boolean that indicates stop dbax engine
   g_stop_process   BOOLEAN := FALSE;

   --G$APPID Current Application ID
   g$appid          VARCHAR2 (50);

   --Username if user is logged
   g$username       VARCHAR2 (255);

   --G$PATH url path
   g$path           VARCHAR2 (2000);


   /**
   * dbax Dispatcher. The dbax framework Kernel. This procedure will be invoked from the application front controller procedure
   *
   * @param     p_appid         the unique application ID
   * @param     name_array      user name parameters from CGI 
   * @param     value_array     user value parameters from CGI
   * @param     router          the application routing function
   */
   PROCEDURE dispatcher (p_appid       IN VARCHAR2
                       , name_array    IN owa_util.vc_arr DEFAULT empty_vc_arr
                       , value_array   IN owa_util.vc_arr DEFAULT empty_vc_arr
                       , router        IN VARCHAR2 DEFAULT NULL );

   /**
   * Retrieve the value from the associative array
   *
   * @param  p_array   the associative array
   * @param  p_key     the array key
   *
   * @return the value if exists
   */
   FUNCTION get (p_array g_assoc_array, p_key IN VARCHAR2)
      RETURN VARCHAR2;

   /**
   * Retrieve a property value from the application properties.
   *
   * @param  p_key        the key name of the propertie
   */
   FUNCTION get_property (p_key IN VARCHAR2)
      RETURN VARCHAR2;

   /**
   * Set a property to application properties
   *
   * @param  p_key          the property key 
   * @param  p_value        the property value
   */      
   PROCEDURE set_property (p_key IN VARCHAR2, p_value IN VARCHAR2);

   /**
   * Prints the received data to the http buffer
   *
   * @param  p_data     the data to be printed in the buffer
   */
   PROCEDURE p (p_data IN CLOB);

   PROCEDURE p (p_data IN VARCHAR2);

   PROCEDURE p (p_data IN NUMBER);


   /**
   * Returns application URL as specified in the application property BASE_PATH.
   * Also you can supply segments to be concatenated to the url.
   *
   * @param  p_local_path     the uri(string)
   */
--   FUNCTION get_path (p_local_path IN VARCHAR2 DEFAULT NULL )
--      RETURN VARCHAR2;

   /**
   * Create a new redirect response to the given path.
   *
   * @param  p_path      the url path. Will be concatenated with the base_path property
   * @param  p_status    the HTTP status code, default 302
   */
   PROCEDURE redirect (p_path IN VARCHAR2, p_status IN PLS_INTEGER DEFAULT 302 );

   /**
   * Create a new redirect response to the given URL
   *
   * @param  p_array     the url to redirect.
   * @param  p_status    the HTTP status code, default 302
   */
   PROCEDURE redirectto (p_url IN VARCHAR2, p_status IN PLS_INTEGER DEFAULT 302 );

   /**
   * Parse a string to an associative array
   *
   * @param  p_string            the query string text
   * @param  p_delimiter         the values delimiter, default &
   * @param  p_key_delimiter     the key=value delimiter, default =
   *
   * @return associative array
   */
   FUNCTION query_string_to_array (p_string          IN VARCHAR2
                                 , p_delimiter       IN VARCHAR2 DEFAULT NULL
                                 , p_key_delimiter   IN VARCHAR2 DEFAULT NULL )
      RETURN g_assoc_array;

   /**
   * Transforms an associative array into a query string
   *
   * @param  p_string            the associative array
   * @param  p_delimiter         the values delimiter, default &
   * @param  p_key_delimiter     the key=value delimiter, default =
   *
   * @return the query string
   */
   FUNCTION array_to_query_string (p_array           IN g_assoc_array
                                 , p_delimiter       IN VARCHAR2 DEFAULT NULL
                                 , p_key_delimiter   IN VARCHAR2 DEFAULT NULL )
      RETURN VARCHAR2;

   /**
   * Breaking up a string into tokens which are seperated by delimiters. The returned value is an array
   *
   * @param  p_string            the string to tokenizer
   * @param  p_delimiter         the Optional delimiter token, default ','
   *
   * @return string array index by integer
   */
   FUNCTION tokenizer (p_string IN VARCHAR2, p_delimiter IN VARCHAR2 DEFAULT ',' )
      RETURN g_varchar_array;

   /**
   * Raise an HTTP 500 error to the user with their description.
   * If enabled, shows to the user all the error trace, as well as the line of code that caused the exception.
   *
   * @param     p_error_code        the user error code number
   * @param     p_error_msg         the user error message text
   */
   PROCEDURE raise_exception (p_error_code IN NUMBER, p_error_msg IN VARCHAR2);
END dbx;
/