CREATE OR REPLACE PACKAGE view_
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

   /**
   * Output CLOB data to the DBMS_OUTPUT.PUT_LINE
   *
   * @param  p_clob     the CLOB to print to the DBMS_OUTPUT
   */
   PROCEDURE output_clob (p_clob IN CLOB);

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
                    , p_template        IN CLOB DEFAULT NULL );

   /**
   *  Purge all compiled source
   *
   *  @param   p_appid             the appid of the view
   */
   PROCEDURE purge_compiled (p_appid IN VARCHAR2);

   /**
   * Run or execute the view
   *
   * @param     p_view      the view template
   * @param     p_name      the name of the view.
   */
   PROCEDURE run (p_view IN CLOB, p_name IN VARCHAR2);

   FUNCTION run (p_view IN CLOB, p_name IN VARCHAR2)
      RETURN VARCHAR2;

   /**
   * Set the name of the view
   *
   * @param     p_name      the view name
   */
   PROCEDURE name (p_name IN VARCHAR2);

   /**
   * Get the name of the view
   *
   * @return the view name
   */
   FUNCTION name
      RETURN VARCHAR2;

   /**
   * Set data to view
   */
   PROCEDURE data (p_name IN VARCHAR2, p_value IN VARCHAR2);

   PROCEDURE data (p_name IN VARCHAR2, p_value IN NUMBER);

   PROCEDURE data (p_name IN VARCHAR2, p_value IN DATE);

   PROCEDURE data (p_name IN VARCHAR2, p_value IN dbx.g_assoc_array);

   --PROCEDURE data (p_name IN VARCHAR2, p_value IN dbx.g_varchar_array);
   
   PROCEDURE data (p_name IN VARCHAR2, p_value IN CLOB);

   PROCEDURE data (p_name IN VARCHAR2, p_cursor IN sys_refcursor);

   FUNCTION get_data_varchar (p_name IN VARCHAR2)
      RETURN VARCHAR2;

   FUNCTION get_data_num (p_name IN VARCHAR2)
      RETURN NUMBER;

   FUNCTION get_data_date (p_name IN VARCHAR2)
      RETURN DATE;

   FUNCTION get_data_assoc (p_name IN VARCHAR2)
      RETURN dbx.g_assoc_array;

   FUNCTION get_data_clob (p_name IN VARCHAR2)
      RETURN clob;

   FUNCTION get_data_refcursor (p_name IN VARCHAR2)
      RETURN sys_refcursor;
END view_;
/