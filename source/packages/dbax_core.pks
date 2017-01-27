/* Formatted on 25/01/2017 16:04:54 (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE dbax_core
AS
   /**
   * DBAX_CORE
   * Contains the dispatcher that controls the entire flow of a request.
   */

   --Empty array for dynamic parameter
   empty_vc_arr     OWA_UTIL.vc_arr;
   
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


END dbax_core;
/