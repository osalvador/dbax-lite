CREATE OR REPLACE PACKAGE dbax_teplsql
AS
   /**
   *  Template engine for dbax based on tePLSQL https://github.com/osalvador/teplsql
   *
   *  Remember initialize owa and dbax_core.g$appid before execute template
   *
   * DECLARE
   *    param_val          OWA.vc_arr;
   * BEGIN
   *    param_val (1) := 1;
   *    OWA.init_cgi_env (param_val);
   *    dbax_core.g$appid := 'SOME_APP';
   *    ...
   * END;
   */

   --Define Associative Array
   TYPE t_assoc_array
   IS
      TABLE OF VARCHAR2 (32767)
         INDEX BY VARCHAR2 (255);

   null_assoc_array   t_assoc_array;

   /**
   * Output CLOB data to the DBMS_OUTPUT.PUT_LINE
   *
   * @param  p_clob     the CLOB to print to the DBMS_OUTPUT
   */
   PROCEDURE output_clob (p_clob IN CLOB);

   /**
   * Prints received data into the buffer
   *
   * @param  p_data     the data to print into buffer
   */
   PROCEDURE PRINT (p_data IN CLOB);

   PROCEDURE p (p_data IN CLOB);

   PROCEDURE PRINT (p_data IN VARCHAR2);

   PROCEDURE p (p_data IN VARCHAR2);

   PROCEDURE PRINT (p_data IN NUMBER);

   PROCEDURE p (p_data IN NUMBER);

   /**
   *  Return returns the source code view or template
   *
   *  @param   p_temaplte_name     the name of the view
   *  @param   p_appid             the appid of the view, optional default is dbax_core.g$appid
   *  @return  view source code
   */
   FUNCTION include (p_template_name IN VARCHAR2, p_appid IN VARCHAR2 DEFAULT NULL )
      RETURN CLOB;

   /**
   *  Returns the compiled source code of the view
   *
   *  @param   p_temaplte_name     the name of the view
   *  @param   p_appid             the appid of the view
   *  @return  p_error_template    the compiled source code with error
   *  @return  compiled source code
   */
   FUNCTION compile (p_template_name IN VARCHAR2, p_appid IN VARCHAR2, p_error_template OUT NOCOPY CLOB)
      RETURN CLOB;

   FUNCTION compile (p_template IN CLOB, p_appid IN VARCHAR2, p_error_template OUT NOCOPY CLOB)
      RETURN CLOB;


   /**
   *  This procedure bind view variables and Execute template.
   *  If p_template is null then get template source from wdx_views.
   *  If p_vars is null then get view variables from dbax_core.g$view
   *
   *  @param   p_temaplte_name     the name of the view
   *  @param   p_appid             the appid of the view
   *  @param   p_vars              the variables to be binded
   *  @param   p_template          the template to be executed
   */
   PROCEDURE execute (p_template_name   IN VARCHAR2 DEFAULT NULL
                    , p_appid           IN VARCHAR2 DEFAULT NULL
                    , p_vars            IN t_assoc_array DEFAULT null_assoc_array
                    , p_template        IN CLOB DEFAULT NULL );


   /**
   *  Purge all compiled source
   *   
   *  @param   p_appid             the appid of the view
   */
   PROCEDURE purge_compiled (p_appid IN VARCHAR2);
END dbax_teplsql;
/