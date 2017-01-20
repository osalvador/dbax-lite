/* Formatted on 20/01/2017 15:48:25 (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE BODY dbax_core
AS
   PROCEDURE print_http_header;

   PROCEDURE set_request (name_array    IN OWA_UTIL.vc_arr DEFAULT empty_vc_arr
                        , value_array   IN OWA_UTIL.vc_arr DEFAULT empty_vc_arr );

   PROCEDURE print_owa_page (p_thepage IN HTP.htbuf_arr, p_lines IN NUMBER)
   AS
      l_found     BOOLEAN := FALSE;
      l_thepage   HTP.htbuf_arr := p_thepage;
   BEGIN
      --Response content start with <!--DBAX-->
      FOR i IN 1 .. p_lines
      LOOP
         IF NOT l_found
         THEN
            l_found     := l_thepage (i) LIKE '%<!%';

            IF l_found
            THEN
               l_thepage (i) := REPLACE (l_thepage (i), '<!--DBAX-->');
            END IF;
         END IF;

         IF l_found
         THEN
            HTP.prn (l_thepage (i));
         END IF;
      END LOOP;
   END print_owa_page;

   FUNCTION tokenizer (p_string IN VARCHAR2, p_delimiter IN VARCHAR2 DEFAULT ',' )
      RETURN DBMS_UTILITY.maxname_array
   AS
      l_array   DBMS_UTILITY.maxname_array;
   BEGIN
          SELECT   REGEXP_SUBSTR (p_string
                                , '[^' || p_delimiter || ']+'
                                , 1
                                , LEVEL)
            BULK   COLLECT
            INTO   l_array
            FROM   DUAL
      CONNECT BY   REGEXP_SUBSTR (p_string
                                , '[^' || p_delimiter || ']+'
                                , 1
                                , LEVEL) IS NOT NULL;

      RETURN l_array;
   END tokenizer;

   FUNCTION query_string_to_array (p_url             IN VARCHAR2
                                 , p_delimiter       IN VARCHAR2 DEFAULT NULL
                                 , p_key_delimiter   IN VARCHAR2 DEFAULT NULL )
      RETURN g_assoc_array
   AS
      l_string             VARCHAR2 (4000) := p_url;
      l_delimiter          VARCHAR2 (5) := NVL (p_delimiter, '&');
      l_keydelimiter       VARCHAR2 (5) := NVL (p_key_delimiter, '=');
      l_delimiter_length   NUMBER (5) := LENGTH (l_delimiter);
      l_start              NUMBER (5) := 1;
      l_end                NUMBER (5) := 0;
      --
      l_new                VARCHAR2 (4000);
      l_keyvalue           VARCHAR2 (4000);
      l_key                VARCHAR2 (4000);
      l_value              VARCHAR2 (4000);
      --
      l_assoc_array        g_assoc_array;
   BEGIN
      IF SUBSTR (l_string, -1, 1) <> l_delimiter
      THEN
         l_string    := l_string || l_delimiter;
      END IF;

      l_new       := l_string;

      LOOP
         l_end       := INSTR (l_new, l_delimiter, 1);
         l_keyvalue  := SUBSTR (l_new, 1, l_end - 1);
         l_key       := SUBSTR (l_keyvalue, 1, INSTR (l_keyvalue, l_keydelimiter) - 1);
         l_value     := SUBSTR (l_keyvalue, INSTR (l_keyvalue, l_keydelimiter) + 1);
         EXIT WHEN l_keyvalue IS NULL;

         IF l_key IS NOT NULL
         THEN
            l_assoc_array (l_key) := utl_url.unescape (l_value);
         ELSE
            l_assoc_array (l_value) := NULL;
         END IF;

         l_start     := l_start + (l_end + (l_delimiter_length - 1));
         l_new       := SUBSTR (l_string, l_start);
      END LOOP;

      RETURN l_assoc_array;
   --Print Associative array
   /*l_key       := l_table.FIRST;

   LOOP
      EXIT WHEN l_key IS NULL;
      DBMS_OUTPUT.put_line (l_key || '=' || l_table (l_key));
      l_key       := l_table.NEXT (l_key);
   END LOOP;*/
   END query_string_to_array;

   FUNCTION get (p_array IN g_assoc_array, p_name IN VARCHAR2)
      RETURN VARCHAR2
   AS
   BEGIN
      IF p_array.EXISTS (p_name)
      THEN
         RETURN p_array (p_name);
      ELSE
         RETURN NULL;
      END IF;
   END get;

   --FUNCTION get_property (p_key IN wdx_properties.key%TYPE)
   FUNCTION get_property (p_key IN VARCHAR2)
      RETURN VARCHAR2
   AS
      l_value   VARCHAR2 (3000) := NULL;
   BEGIN
      l_value     := dbax_core.g$view (LOWER (p_key));

      IF l_value IS NULL
      THEN
         l_value     := dbax_core.g$view (UPPER (p_key));
      END IF;

      RETURN l_value;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_property;

   /**
   * Gets the regex variables from the string
   */
   PROCEDURE regex_parameters (p_string            IN     VARCHAR2
                             , p_pattern              OUT VARCHAR2
                             , p_postion              OUT PLS_INTEGER
                             , p_occurrence           OUT PLS_INTEGER
                             , p_match_parameter      OUT VARCHAR2)
   AS
      l_regex_pos   PLS_INTEGER;
      l_param_tab   DBMS_UTILITY.maxname_array;
   BEGIN
      l_regex_pos := INSTR (p_string, '@', -1);

      IF l_regex_pos <> 0
      THEN
         p_pattern   := SUBSTR (p_string, 1, l_regex_pos - 1);

         l_param_tab := tokenizer (SUBSTR (p_string, l_regex_pos + 1));

         IF l_param_tab.EXISTS (1) AND l_param_tab (1) IS NOT NULL
         THEN
            p_postion   := l_param_tab (1);
         ELSE
            p_postion   := 1;
         END IF;

         IF l_param_tab.EXISTS (2)
         THEN
            p_occurrence := l_param_tab (2);
         ELSE
            p_occurrence := 0;
         END IF;

         IF l_param_tab.EXISTS (3)
         THEN
            p_match_parameter := l_param_tab (3);
         END IF;
      ELSE
         --Default values
         p_pattern   := p_string;
         p_postion   := 1;
         p_occurrence := NULL; --The default value of REGEX_INSTR is 1, but default value for REGEX_REPLACE is 0.
         p_match_parameter := NULL;
      END IF;
   END regex_parameters;



   PROCEDURE execute_app_router (p_router IN VARCHAR2)
   AS
      l_procedure   VARCHAR2 (100);
   BEGIN
      l_procedure := 'BEGIN ' || p_router || '; END;';

      -- Execute Routing
      BEGIN
         EXECUTE IMMEDIATE l_procedure;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF SQLCODE = -06550
            THEN
               --dbax_exception.raise (100, 'Error trying to execute the controller: ' || upper(p_controller) );
               HTP.p ('<br> ' || SQLERRM || 'Error trying to execute the router: ' || UPPER (l_procedure));
               --TODO
               RAISE;
            ELSIF SQLCODE = -06503
            THEN
               --Function returned without value
               NULL;
            ELSE
               --dbax_exception.raise (SQLCODE, SQLERRM || CHR(10) || 'Executing controller: ' || upper(p_controller));
               HTP.p (SQLERRM || '<br>Executing router: ' || UPPER (l_procedure));
               --TODO
               RAISE;
            END IF;
      END;
   END execute_app_router;


   PROCEDURE log_array (p_array IN g_assoc_array)
   AS
      l_key   VARCHAR2 (256);
   BEGIN
      IF p_array.COUNT () <> 0
      THEN
         l_key       := p_array.FIRST;

         LOOP
            EXIT WHEN l_key IS NULL;
            ----dbax_log.debug (l_key || '=' || p_array (l_key));
            --TODO
            l_key       := p_array.NEXT (l_key);
         END LOOP;
      END IF;
   END log_array;


   PROCEDURE dispatcher (p_appid       IN VARCHAR2
                       , name_array    IN OWA_UTIL.vc_arr DEFAULT empty_vc_arr
                       , value_array   IN OWA_UTIL.vc_arr DEFAULT empty_vc_arr
                       , router        IN VARCHAR2 DEFAULT NULL )
   AS
      l_path          VARCHAR2 (4000);
      l_check_auth    VARCHAR2 (4);
      l_ret_arr       DBMS_UTILITY.maxname_array;
      --
      l_http_output   HTP.htbuf_arr;
      l_lines         NUMBER DEFAULT 99999999 ;
      --
      --l_application_rt   tapi_wdx_applications.wdx_applications_rt;
      --
      e_stop_process exception;
      e_inactive_app exception;
   BEGIN
      -- 1. Definir la aplicacion
      -- 2. Obtener la URL para enrutar
      -- 2. Realizar Enrutado
      -- 3. A partir de la URL enrutada, o no, recuperar el Controlador, La funcion y los Parametros
      -- 4. Buscar la pagina en la cach¿. (por la URL)
      -- 4.1 SEGURIDAD. realiza un tratamiento de seguridad sobre la entrada que tengamos, tanto de la informaci¿n que haya en la URL como de la informaci¿n que haya en un posible POST
      -- 5. Invocar al controlador.funci¿n, los parametros podr¿n est¿r en un array global por ah¿...
      -- 6. Interpretar las vistas que el controlador ha cargado
      -- 7. Meter el HTML generado en la cach¿, si procede
      -- 8. Imprimir la pagina

      /***************
      *  1. Defining the application
      ***************/
      HTP.prn ('<!--DBAX-->');
      g$appid     := p_appid;

      --Defining log level
      --dbax_log.open_log (get_property ('LOG_LEVEL'));
      --dbax_log.info ('Start Dispatcher');
      --dbax_log.info ('g$appid=' || g$appid);


      --Set Request parameters
      set_request (name_array, value_array);

      /***************
      * 4.1 Obtener la URL para enrutar
      ***************/

      --If is a queryString model, get de URL to route from reserved parameter 'p' in g$get or g$post array
      IF g$get.EXISTS ('p')
      THEN
         l_path      := '/' || p_appid || g$get ('p');
      ELSIF g$post.EXISTS ('p')
      THEN
         l_path      := '/' || p_appid || g$post ('p');
      ELSE
         l_path      := g$server ('PATH_INFO');
      END IF;

      --Split the URL
      IF INSTR (l_path, '/', 2) > 0
      THEN
         l_path      := SUBSTR (l_path, INSTR (l_path, '/', 2) + 1);
      ELSE
         l_path      := 'NULL';
      END IF;

      IF l_path IS NULL
      THEN
         l_path      := 'NULL';
      END IF;

      /***************
      *  2. Routing
      ***************/
      g$path      := l_path;
      execute_app_router (router);


      /***************
      * 3.1 Load User's cookies
      * Las cookies mejor cargarlas directamente en el controlador de la aplicacion cuando las necesiten
      * o incluso en el router antes de evaluar las rutas.
      * Incluir cookies en dbax_core
      ***************/
      --dbax_cookie.load_cookies;


      /***************
      *  8. Print Page
      ***************/

      -- Get page from owa buffer
      OWA.get_page (l_http_output, l_lines);

      IF NOT g_stop_process
      THEN
         HTP.init;
         OWA_UTIL.mime_header (g$content_type, FALSE, get_property ('ENCODING'));
         OWA_UTIL.status_line (nstatus => g$status_line, creason => NULL, bclose_header => FALSE);
         --HTP.prn (dbax_cookie.generate_cookie_header);
         --TODO
         --dbax_log.debug ('Print HTTP Header');
         print_http_header;
         OWA_UTIL.http_header_close;

         --dbax_log.debug ('Print HTTP Data');
         print_owa_page (l_http_output, l_lines);

         IF g$view_name IS NOT NULL
         THEN
            --dbax_log.debug ('Execute view: ' || g$view_name);

            dbax_teplsql.execute (p_template_name => g$view_name);
         END IF;
      ELSE
         --dbax_log.debug ('Stop Process: TRUE');
         NULL;
      END IF;
   --dbax_session.save_sesison_variable;
   --TODO
   --dbax_log.close_log;
   EXCEPTION
      WHEN e_stop_process
      THEN
         --dbax_session.save_sesison_variable;
         --dbax_log.close_log;
         --TODO
         NULL;
      WHEN OTHERS
      THEN
         --dbax_session.save_sesison_variable;
         --dbax_exception.raise (SQLCODE, SQLERRM);
         --dbax_log.close_log;
         --TODO
         NULL;
   END dispatcher;

   FUNCTION get_path (p_local_path IN VARCHAR2 DEFAULT NULL )
      RETURN VARCHAR2
   AS
   BEGIN
      RETURN get_property ('BASE_PATH') || p_local_path;
   END get_path;

   PROCEDURE load_view (p_name IN VARCHAR2, p_appid IN VARCHAR2 DEFAULT NULL )
   AS
      l_source   CLOB;
   BEGIN
      SELECT /*+ result_cache */
            title, name
        INTO   dbax_core.g$view ('title'), g$view_name
        FROM   wdx_views
       WHERE   UPPER (name) = UPPER (p_name) AND appid = NVL (p_appid, g$appid) AND visible = 'Y';
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
   END load_view;


   FUNCTION request_validation_function (procedure_name IN VARCHAR2)
      RETURN BOOLEAN
   IS
      l_procedure_name   VARCHAR2 (300) := request_validation_function.procedure_name;
   BEGIN
      --      FOR c1 IN (SELECT   1
      --                   FROM   wdx_request_valid_function a
      --                  WHERE   UPPER (l_procedure_name) LIKE UPPER (a.procedure_name))
      --      LOOP
      RETURN TRUE;
   --      END LOOP;
   --TODO

   --      RETURN FALSE;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN FALSE;
   END request_validation_function;

   --Establece los parametros globales g$get y g$set en funcion de la request realizada
   PROCEDURE set_request (name_array    IN OWA_UTIL.vc_arr DEFAULT empty_vc_arr
                        , value_array   IN OWA_UTIL.vc_arr DEFAULT empty_vc_arr )
   AS
      l_query_string   g_assoc_array;
      --
      j                PLS_INTEGER;
      l_name_array     VARCHAR2 (255);
   BEGIN
      --Set server parameters get from CGI ENV
      FOR i IN 1 .. OWA.num_cgi_vars
      LOOP
         g$server (OWA.cgi_var_name (i)) := OWA.cgi_var_val (i);
      END LOOP;

      --dbax_log.info ('REQUEST_METOD=' || g$server ('REQUEST_METHOD'));

      --Get QueryString params
      g$get       := query_string_to_array (get (g$server, 'QUERY_STRING'));

      IF g$server ('REQUEST_METHOD') = 'GET'
      THEN
         IF name_array.EXISTS (1) AND name_array (1) IS NOT NULL
         THEN
            FOR i IN name_array.FIRST .. name_array.LAST
            LOOP
               --if the parameter ends with [ ] it is an array
               IF name_array (i) LIKE '%[]'
               THEN
                  j           := 1;

                  --Set Name of the parameter[n]
                  l_name_array := SUBSTR (name_array (i), 1, INSTR (name_array (i), '[]') - 1) || '[' || j || ']';

                  --Generate Array index
                  WHILE g$get.EXISTS (l_name_array)
                  LOOP
                     j           := j + 1;
                     l_name_array := SUBSTR (name_array (i), 1, INSTR (name_array (i), '[]') - 1) || '[' || j || ']';
                  END LOOP;

                  g$get (LOWER (l_name_array)) := CONVERT (value_array (i), g$server ('REQUEST_CHARSET'), 'AL32UTF8');
               --dbax_log.debug (LOWER (l_name_array) || ':' || g$get (LOWER (l_name_array)));
               ELSE
                  g$get (LOWER (name_array (i))) := CONVERT (value_array (i), g$server ('REQUEST_CHARSET'), 'AL32UTF8');
               --dbax_log.debug (LOWER (name_array (i)) || ':' || g$get (LOWER (name_array (i))));
               END IF;
            END LOOP;
         END IF;
      ELSIF g$server ('REQUEST_METHOD') = 'POST'
      THEN
         IF name_array.EXISTS (1) AND name_array (1) IS NOT NULL
         THEN
            FOR i IN name_array.FIRST .. name_array.LAST
            LOOP
               --if the parameter ends with [ ] it is an array
               IF name_array (i) LIKE '%[]'
               THEN
                  j           := 1;

                  --Set Name of the parameter[n]
                  l_name_array := SUBSTR (name_array (i), 1, INSTR (name_array (i), '[]') - 1) || '[' || j || ']';

                  --Generate Array index
                  WHILE g$post.EXISTS (l_name_array)
                  LOOP
                     j           := j + 1;
                     l_name_array := SUBSTR (name_array (i), 1, INSTR (name_array (i), '[]') - 1) || '[' || j || ']';
                  END LOOP;

                  g$post (LOWER (l_name_array)) := CONVERT (value_array (i), g$server ('REQUEST_CHARSET'), 'AL32UTF8');
               --dbax_log.debug (LOWER (l_name_array) || ':' || g$post (LOWER (l_name_array)));
               ELSE
                  g$post (LOWER (name_array (i))) := CONVERT (value_array (i), g$server ('REQUEST_CHARSET'), 'AL32UTF8');
               --dbax_log.debug (LOWER (name_array (i)) || ':' || g$post (LOWER (name_array (i))));
               END IF;
            END LOOP;
         END IF;
      END IF;
   END set_request;

   PROCEDURE print_http_header
   AS
      l_key   VARCHAR2 (256);
   BEGIN
      IF g$http_header.COUNT () <> 0
      THEN
         l_key       := g$http_header.FIRST;

         LOOP
            EXIT WHEN l_key IS NULL;
            HTP.p (l_key || ':' || g$http_header (l_key));
            --dbax_log.debug ('HTTP Header ' || l_key || ':' || g$http_header (l_key));
            l_key       := g$http_header.NEXT (l_key);
         END LOOP;
      END IF;
   END print_http_header;


   /************************************************************************
   *                            ROUTING
   *        Procedures and functions to manage Application Routing
   *************************************************************************/

   FUNCTION get_url_parameters (p_user_url_pattern IN VARCHAR2, p_url_pattern IN VARCHAR2)
      RETURN g_assoc_array
   AS
      l_parameter_value    VARCHAR2 (3000);
      l_user_url_pattern   VARCHAR2 (2000);
      l_url_parameters     g_assoc_array;
      --
      l_position           PLS_INTEGER;
      l_occurrence         PLS_INTEGER;
      l_match_parameter    VARCHAR2 (100);
   BEGIN
      --Obtengo el advanced regex de la URL
      regex_parameters (p_user_url_pattern
                      , l_user_url_pattern
                      , l_position
                      , l_occurrence
                      , l_match_parameter);


      FOR v_reg IN (    SELECT   REGEXP_SUBSTR (l_user_url_pattern
                                              , '{(.*?)}'
                                              , 1
                                              , LEVEL
                                              , 'n'
                                              , 1)
                                    var_name, LEVEL
                          FROM   DUAL
                    CONNECT BY   REGEXP_SUBSTR (l_user_url_pattern
                                              , '{(.*?)}'
                                              , 1
                                              , LEVEL
                                              , 'n'
                                              , 1) IS NOT NULL)
      LOOP
         l_parameter_value :=
            REGEXP_SUBSTR (g$path
                         , p_url_pattern
                         , l_position
                         , NVL (l_occurrence, 1)
                         , l_match_parameter
                         , v_reg.LEVEL);
         l_url_parameters (v_reg.var_name) := l_parameter_value;
      END LOOP;

      RETURN l_url_parameters;
   END get_url_parameters;


   FUNCTION router (p_url_pattern IN VARCHAR2, p_parameters OUT g_assoc_array)
      RETURN BOOLEAN
   AS
      l_path              VARCHAR2 (2000);
      l_url_pattern       VARCHAR2 (2000);
      l_position          PLS_INTEGER;
      l_occurrence        PLS_INTEGER;
      l_match_parameter   VARCHAR2 (100);
      l_ret_arr           DBMS_UTILITY.maxname_array;
      --
      l_retval            PLS_INTEGER := 0;
      l_return            VARCHAR2 (1000);
      l_replace_string    VARCHAR2 (1000);
      --
      l_is_parameter      BOOLEAN := FALSE;
   BEGIN
      l_url_pattern := p_url_pattern;

      --Si el url_pattern contiene una {} sustituirlo por ([[:print:]]+)
      IF INSTR (l_url_pattern, '{') > 0 AND INSTR (l_url_pattern, '}') > 0
      THEN
         l_url_pattern :=
            REGEXP_REPLACE (l_url_pattern
                          , '{(.*?)}'
                          , '([[:print:]].*?)'
                          , 1
                          , 0
                          , 'n');

         l_is_parameter := TRUE;
      END IF;

      regex_parameters (l_url_pattern
                      , l_url_pattern
                      , l_position
                      , l_occurrence
                      , l_match_parameter);

      l_url_pattern := '^' || l_url_pattern || '(/|$)';

      BEGIN
         l_retval    :=
            REGEXP_INSTR (g$path
                        , l_url_pattern
                        , l_position
                        , NVL (l_occurrence, 1)
                        , '0'
                        , l_match_parameter);

         IF l_retval > 0
         THEN
            --dbax_log.debug ('Route Matched:' || c1.route_name || ' URL_PATTERN:' || c1.url_pattern);

            IF l_is_parameter
            THEN
               p_parameters := get_url_parameters (p_url_pattern, l_url_pattern);
            END IF;

            l_path      :=
               REGEXP_REPLACE (g$path
                             , l_url_pattern
                             , l_replace_string || '/'
                             , l_position
                             , NVL (l_occurrence, 0)
                             , l_match_parameter);


            --Tokenizer the Url
            -- The l_path has <parameter1>/<parameterN>
            l_ret_arr   := tokenizer (l_path, '/');

            --Parameters are the rest of the url
            IF l_ret_arr.EXISTS (1)
            THEN
               FOR i IN 1 .. l_ret_arr.LAST
               LOOP
                  g$parameter (i) := l_ret_arr (i);
               --dbax_log.info ('Paramter g$parameter(' || i || ') = ' || g$parameter (i));
               --HTP.p ('<br>Paramter g$parameter(' || i || ') = ' || g$parameter (i));
               END LOOP;
            END IF;

            RETURN TRUE;
         ELSE
            RETURN FALSE;
         END IF;
      --      EXCEPTION
      --         WHEN OTHERS
      --         THEN
      --
      --            --HTP.p (SQLERRM);
      --            DBMS_OUTPUT.PUT_LINE ( 'SQLERRM = ' || SQLERRM );
      --      --                     dbax_log.error(   'Routing error with '
      --      --                                    || c1.route_name
      --      --                                    || ' route. Check the advanced parameters to REGEXP_INSTR in the URL Pattern. '
      --      --                                    || SQLERRM);
      --            RETURN FALSE;
      END;
   END router;


   FUNCTION route (p_http_verbs IN VARCHAR2, p_url_pattern IN VARCHAR2, p_parameters OUT g_assoc_array)
      RETURN BOOLEAN
   AS
      l_http_verbs   DBMS_UTILITY.maxname_array;
   BEGIN
      l_http_verbs := tokenizer (p_http_verbs, ',');

      IF l_http_verbs.EXISTS (1)
      THEN
         FOR i IN 1 .. l_http_verbs.LAST
         LOOP
            IF g$server ('REQUEST_METHOD') = UPPER (TRIM (l_http_verbs (i))) AND router (p_url_pattern, p_parameters)
            THEN
               RETURN TRUE;
            END IF;
         END LOOP;
      END IF;

      RETURN FALSE;
   END route;

   FUNCTION route (p_http_verbs IN VARCHAR2, p_url_pattern IN VARCHAR2)
      RETURN BOOLEAN
   AS
      l_dummy   g_assoc_array;
   BEGIN
      RETURN route (p_http_verbs, p_url_pattern, l_dummy);
   END;

   FUNCTION route_get (p_url_pattern IN VARCHAR2, p_parameters OUT g_assoc_array)
      RETURN BOOLEAN
   AS
   BEGIN
      IF g$server ('REQUEST_METHOD') = 'GET' AND router (p_url_pattern, p_parameters)
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END route_get;

   FUNCTION route_get (p_url_pattern IN VARCHAR2)
      RETURN BOOLEAN
   AS
      l_dummy   g_assoc_array;
   BEGIN
      RETURN route_get (p_url_pattern, l_dummy);
   END;

   FUNCTION route_post (p_url_pattern IN VARCHAR2, p_parameters OUT g_assoc_array)
      RETURN BOOLEAN
   AS
   BEGIN
      IF g$server ('REQUEST_METHOD') = 'POST' AND router (p_url_pattern, p_parameters)
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END route_post;

   FUNCTION route_post (p_url_pattern IN VARCHAR2)
      RETURN BOOLEAN
   AS
      l_dummy   g_assoc_array;
   BEGIN
      RETURN route_post (p_url_pattern, l_dummy);
   END;
END dbax_core;
/