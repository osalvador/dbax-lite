/* Formatted on 27/01/2017 16:09:05 (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE dbx
AS
   --Global Variables
   TYPE g_assoc_array
   IS
      TABLE OF VARCHAR2 (32767)
         INDEX BY VARCHAR2 (255);

   --G$VIEW An associative array of variables (constants) to be replaced in the views referenced by ${name}
   g$view           dbx.g_assoc_array;

   --G$PROPERTIES An associative array of application properties
   g$properties     dbx.g_assoc_array;

   /**
   * G$SERVER An associative array of variables passed via OWA CGI Environment and
   * containing information such as headers, paths, and script locations created by the web server
   */
   --g$server         dbx.g_assoc_array;

   --G$HEADERS HTTP response headers
   --g$http_header    dbx.g_assoc_array;

   --G$STATUS_LINE  HTTP response status code.
   --g$status_line    PLS_INTEGER := 200;

   --Mime Type for response
   --g$content_type   VARCHAR2 (100) := 'text/html';

   --G_STOP_PROCESS Boolean that indicates stop dbax engine
   g_stop_process   BOOLEAN := FALSE;

   --MVC
   --G$CONTROLLER MVC controller to be executed
   --g$controller     VARCHAR2 (100);

   --G$VIEW_NAME MVC view to be exeqcuted
   --g$view_name      VARCHAR2 (300);

   --G$PARAMETER MVC URL parameters ../<pramamter1>/<pramamter2>/<pramamterN>
   --g$parameter      DBMS_UTILITY.lname_array;

   --Application Variables

   --G$APPID Current Application ID
   g$appid          VARCHAR2 (50);

   --Username if user is logged
   g$username       VARCHAR2 (255);

   --G$PATH url path
   g$path           VARCHAR2 (2000);



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
   * Gets property value of the current application.
   *
   * @param  p_key        the key name of the propertie
   */
   FUNCTION get_property (p_key IN VARCHAR2)
      RETURN VARCHAR2;

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
   FUNCTION get_path (p_local_path IN VARCHAR2 DEFAULT NULL )
      RETURN VARCHAR2;

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
      RETURN DBMS_UTILITY.maxname_array;
END dbx;