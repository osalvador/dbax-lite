CREATE OR REPLACE PACKAGE route_
AS


   /************************************************************************
   *                            ROUTING
   *        Procedures and functions to manage Application Routing
   *************************************************************************/
   /**
   * Basic route function
   *
   * @param     p_methods          the comma separated http verbs or REQUEST_METHOD
   * @param     p_url_pattern      the url pattern
   * @return    boolean
   */
   FUNCTION match (p_uri IN VARCHAR2, p_http_verbs IN VARCHAR2 DEFAULT NULL)
      RETURN BOOLEAN;

   FUNCTION match (p_uri IN VARCHAR2, p_http_verbs IN VARCHAR2 DEFAULT NULL, p_parameters OUT dbx.g_assoc_array)
      RETURN BOOLEAN;

   /**
   * Route function for GET requests
   *
   * @param     p_url_pattern      the url pattern
   * @return    boolean
   */
   FUNCTION get (p_uri IN VARCHAR2)
      RETURN BOOLEAN;

   FUNCTION get (p_uri IN VARCHAR2, p_parameters OUT dbx.g_assoc_array)
      RETURN BOOLEAN;

   /**
   * Route function for POST requests
   *
   * @param     p_url_pattern      the url pattern
   * @return    boolean
   */
   FUNCTION post (p_uri IN VARCHAR2)
      RETURN BOOLEAN;

   FUNCTION post (p_uri IN VARCHAR2, p_parameters OUT dbx.g_assoc_array)
      RETURN BOOLEAN;
/**
* Not implemented because pl/sql gateways only accept get and post verbs
*/
--FUNCTION route_post (p_url_pattern IN VARCHAR2)
--  RETURN BOOLEAN;
--FUNCTION route_post (p_url_pattern IN VARCHAR2)
--  RETURN BOOLEAN;
--FUNCTION route_post (p_url_pattern IN VARCHAR2)
--  RETURN BOOLEAN;
--FUNCTION route_post (p_url_pattern IN VARCHAR2)
--  RETURN BOOLEAN;


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

end route_; 
/