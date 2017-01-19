/* Formatted on 17/01/2017 15:00:52 (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE dbax_core
AS
   /**
   * DBAX_CORE
   * The core of dbax. Contains the dispatcher that controls the entire flow of a request.
   * It also contains the superglobal variables.
   */

   --Global Variables
   TYPE g_assoc_array
   IS
      TABLE OF VARCHAR2 (32767)
         INDEX BY VARCHAR2 (255);

   --G$VAR An associative array of variables to be used where you want
   g$var            g_assoc_array;

   --G$VIEW An associative array of variables (constants) to be replaced in the views referenced by ${name}
   g$view           g_assoc_array;

   --G$GET An associative array of variables passed via the URL parameters.
   g$get            g_assoc_array;

   --G$POST An associative array of variables passed via the HTTP POST
   g$post           g_assoc_array;

   /**
   * G$SERVER An associative array of variables passed via OWA CGI Environment and
   * containing information such as headers, paths, and script locations created by the web server
   */
   g$server         g_assoc_array;

   --G$HEADERS HTTP response headers
   g$http_header    g_assoc_array;

   --G$STATUS_LINE  HTTP response status code.
   g$status_line    PLS_INTEGER := 200;

   --Mime Type for response
   g$content_type   VARCHAR2 (100) := 'text/html';

   --G_STOP_PROCESS Boolean that indicates stop dbax engine
   g_stop_process   BOOLEAN := FALSE;

   --MVC
   --G$CONTROLLER MVC controller to be executed
   g$controller     VARCHAR2 (100);

   --G$VIEW_NAME MVC view to be exeqcuted
   g$view_name      VARCHAR2 (300);

   --G$PARAMETER MVC URL parameters ../<pramamter1>/<pramamter2>/<pramamterN>
   g$parameter      DBMS_UTILITY.lname_array;

   --Application Variables

   --G$APPID Current Application ID
   g$appid          VARCHAR2 (50);

   --Username if user is logged
   g$username       VARCHAR2 (255);

   --Empty array for dynamic parameter
   empty_vc_arr     OWA_UTIL.vc_arr;

   --G$PATH url path
   g$path           VARCHAR2 (2000);


   /**
   * Central procedure that dispatches requests to controllers. AKA front controller.
   *
   * @param  p_appid        the application id of the request
   * @param  name_array     vc_arr with the name of the arguments
   * @param  value_array    vc_arr with the values of the arguments
   */
   PROCEDURE dispatcher (p_appid       IN VARCHAR2
                       , name_array    IN OWA_UTIL.vc_arr DEFAULT empty_vc_arr
                       , value_array   IN OWA_UTIL.vc_arr DEFAULT empty_vc_arr
                       , router        IN VARCHAR2 DEFAULT NULL );

   /**
   * Gets property value of the current application.
   *
   * @param  p_key        the key name of the propertie
   */
   FUNCTION get_property (p_key IN VARCHAR2)
      RETURN VARCHAR2;

   /**
   * Load the view to be executed.
   *
   * @param  p_name        the name of the view
   * @param  p_appid       the application id of the view. If null, dbax uses g$appid
   */
   PROCEDURE load_view (p_name IN VARCHAR2, p_appid IN VARCHAR2 DEFAULT NULL );


   /**
   * Returns application URL as specified in the application property BASE_PATH.
   * Also you can supply segments to be concatenated to the url.
   *
   * @param  p_local_path     the uri(string)
   */
   FUNCTION get_path (p_local_path IN VARCHAR2 DEFAULT NULL )
      RETURN VARCHAR2;

   /**
   * Return regex parameters from dbax url pattern
   *
   * @param     p_string             the dbax url pattern with regex_string@position,occurrence,match_parameter
   * @return    p_pattern            the regex pattern
   * @return    p_postion            the regex position
   * @return    p_occurrence         the regex occurrence
   * @return    p_match_parameter    the regex match_parameters
   */
   PROCEDURE regex_parameters (p_string            IN     VARCHAR2
                             , p_pattern              OUT VARCHAR2
                             , p_postion              OUT PLS_INTEGER
                             , p_occurrence           OUT PLS_INTEGER
                             , p_match_parameter      OUT VARCHAR2);

   /**
   * For security. You can use the Validation Function to determine if the requested procedure in the URL should be allowed for processing.
   * You can configure this function in your gateway (Oracle ORDS, mod_plsql, DBMS_EPG...)
   *
   * @param  procedure_name     the procedure to be executed
   */
   FUNCTION request_validation_function (procedure_name IN VARCHAR2)
      RETURN BOOLEAN;


   FUNCTION route (p_url_pattern IN VARCHAR2)
      RETURN BOOLEAN;
      
END dbax_core;
/