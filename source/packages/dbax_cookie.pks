CREATE OR REPLACE PACKAGE dbax_cookie
AS
   --Global Variables
   TYPE cookie_type
   IS
      RECORD (
         name       VARCHAR2 (4096)
       , VALUE      VARCHAR2 (4096)
       , expires    DATE
       , PATH       VARCHAR2 (255)
       , domain     VARCHAR2 (255)
       , secure     BOOLEAN DEFAULT FALSE
       , httponly   BOOLEAN DEFAULT FALSE
      );

   TYPE g_cookie_array
   IS
      TABLE OF cookie_type
         INDEX BY VARCHAR2 (255);

   /**
   * Load client cookies in g$req_cookie variable.
   *
   * @param  p_cookies       the cookies text, default null.
   */
   PROCEDURE load_cookies (p_cookies IN VARCHAR2 DEFAULT NULL );


   /**
   * Generates the HTTP header with the cookies sent to client
   *
   * @return    the http cookie header
   */
   FUNCTION generate_cookie_header
      RETURN VARCHAR2;
END dbax_cookie;
/