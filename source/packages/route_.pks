CREATE OR REPLACE PACKAGE route_
AS
   /************************************************************************
   *                            ROUTING
   *        Procedures and functions to manage Application Routing
   *************************************************************************/
   /**
   * Register a new route with the given verbs.
   *
   * @param     p_methods          the comma separated http verbs or REQUEST_METHOD
   * @param     p_url_pattern      the url pattern
   * @return    boolean
   */
   FUNCTION match (p_uri IN VARCHAR2, p_http_verbs IN VARCHAR2 DEFAULT NULL )
      RETURN BOOLEAN;

   FUNCTION match (p_uri IN VARCHAR2, p_http_verbs IN VARCHAR2 DEFAULT NULL , p_parameters OUT dbx.g_assoc_array)
      RETURN BOOLEAN;

   /**
   * Register a new route responding to all verbs
   *
   * @param     p_url_pattern      the url pattern
   * @return    boolean
   */
   FUNCTION any_ (p_uri IN VARCHAR2)
      RETURN BOOLEAN;

   /**
   * Register a new route responding to all verbs
   *
   * @param     p_url_pattern      the url pattern
   * @param     p_parameters       OUT. the associative array with URI parameters
   * @return    boolean
   */
   FUNCTION any_ (p_uri IN VARCHAR2, p_parameters OUT dbx.g_assoc_array)
      RETURN BOOLEAN;

   /**
   * Register a new GET route with the router
   *
   * @param     p_url_pattern      the url pattern
   * @return    boolean
   */
   FUNCTION get (p_uri IN VARCHAR2)
      RETURN BOOLEAN;

   /**
   * Register a new GET route with the router
   *
   * @param     p_url_pattern      the url pattern
   * @param     p_parameters       OUT. the associative array with URI parameters
   * @return    boolean
   */
   FUNCTION get (p_uri IN VARCHAR2, p_parameters OUT dbx.g_assoc_array)
      RETURN BOOLEAN;

   /**
   * Register a new POST route with the router
   *
   * @param     p_url_pattern      the url pattern
   * @return    boolean
   */
   FUNCTION post (p_uri IN VARCHAR2)
      RETURN BOOLEAN;

   /**
   * Register a new POST route with the router
   *
   * @param     p_url_pattern      the url pattern
   * @param     p_parameters       OUT. the associative array with URI parameters
   * @return    boolean
   */
   FUNCTION post (p_uri IN VARCHAR2, p_parameters OUT dbx.g_assoc_array)
      RETURN BOOLEAN;

   /**
   * Register a new PUT route with the router
   *
   * @param     p_url_pattern      the url pattern
   * @return    boolean
   */
   FUNCTION put (p_uri IN VARCHAR2)
      RETURN BOOLEAN;

   /**
   * Register a new PUT route with the router
   *
   * @param     p_url_pattern      the url pattern
   * @param     p_parameters       OUT. the associative array with URI parameters
   * @return    boolean
   */
   FUNCTION put (p_uri IN VARCHAR2, p_parameters OUT dbx.g_assoc_array)
      RETURN BOOLEAN;

   /**
   * Register a new DLETE route with the router
   *
   * @param     p_url_pattern      the url pattern
   * @return    boolean
   */
   FUNCTION delete (p_uri IN VARCHAR2)
      RETURN BOOLEAN;
      
   /**
   * Register a new DLETE route with the router
   *
   * @param     p_url_pattern      the url pattern
   * @param     p_parameters       OUT. the associative array with URI parameters
   * @return    boolean
   */
   FUNCTION delete (p_uri IN VARCHAR2, p_parameters OUT dbx.g_assoc_array)
      RETURN BOOLEAN;

   /**
   * Register a new PATCH route with the router
   *
   * @param     p_url_pattern      the url pattern
   * @return    boolean
   */
   FUNCTION patch (p_uri IN VARCHAR2)
      RETURN BOOLEAN;

   /**
   * Register a new PATCH route with the router
   *
   * @param     p_url_pattern      the url pattern
   * @param     p_parameters       OUT. the associative array with URI parameters
   * @return    boolean
   */
   FUNCTION patch (p_uri IN VARCHAR2, p_parameters OUT dbx.g_assoc_array)
      RETURN BOOLEAN;


   /**
   * Register a new OPTIONS route with the router
   *
   * @param     p_url_pattern      the url pattern
   * @return    boolean
   */
   FUNCTION options (p_uri IN VARCHAR2)
      RETURN BOOLEAN;

   /**
   * Register a new OPTIONS route with the router
   *
   * @param     p_url_pattern      the url pattern
   * @param     p_parameters       OUT. the associative array with URI parameters
   * @return    boolean
   */
   FUNCTION options (p_uri IN VARCHAR2, p_parameters OUT dbx.g_assoc_array)
      RETURN BOOLEAN;


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
END route_;
/