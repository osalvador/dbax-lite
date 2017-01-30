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


   /*PROCEDURE log_array (p_array IN g_assoc_array)
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
   END log_array;*/


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
      e_stop_process exception;
      e_inactive_app exception;
   BEGIN
      /***************
      * Defining the application
      ***************/
      HTP.prn ('<!--DBAX-->');
      dbx.g$appid := p_appid;
      dbx.g$properties ('appid') := p_appid;

      --Set Request parameters
      set_request (name_array, value_array);


      /***************
      * Obtener la URL para enrutar
      ***************/

      --If is a queryString model, get de URL to route from reserved parameter 'p' in dbx.g$get or dbx.g$post array
      IF request_.input ('p') IS NOT NULL
      THEN
         l_path      := '/' || p_appid || request_.input ('p');
      ELSE
         l_path      := request_.header ('PATH_INFO');
      END IF;

      --Split the URL
      IF INSTR (l_path, '/', 2) > 0
      THEN
         l_path      := SUBSTR (l_path, INSTR (l_path, '/', 2) + 1);
      ELSE
         l_path      := '/';
      END IF;

      IF l_path IS NULL
      THEN
         l_path      := '/';
      END IF;


      /******************
      *   Load cookies
      ******************/
      dbax_cookie.load_cookies;

      /******************
      *  Start Session
      ******************/
      IF NOT session_.is_started
      THEN
         session_.init;
      END IF;


      /***************
      *  Routing
      ***************/
      dbx.g$path  := l_path;
      execute_app_router (router);


      /***************
      *  Print Page
      ***************/

      -- Get page from owa buffer
      OWA.get_page (l_http_output, l_lines);

      IF NOT dbx.g_stop_process
      THEN
         HTP.init;
         OWA_UTIL.mime_header (NVL(response_.content, 'text/html'), FALSE, dbx.get_property ('ENCODING'));
         OWA_UTIL.status_line (nstatus => NVL(response_.status, 200), creason => NULL, bclose_header => FALSE);
         HTP.prn (dbax_cookie.generate_cookie_header);

         print_http_header;
         OWA_UTIL.http_header_close;

         print_owa_page (l_http_output, l_lines);
      ELSE
         NULL;
      END IF;

      session_.save;
   --TODO
   --dbax_log.close_log;
   --   EXCEPTION
   --      WHEN e_stop_process
   --      THEN
   --         --dbax_session.save_sesison_variable;
   --         --dbax_log.close_log;
   --         --TODO
   --         NULL;
   --      WHEN OTHERS
   --      THEN
   --         --dbax_session.save_sesison_variable;
   --         --dbax_exception.raise (SQLCODE, SQLERRM);
   --         --dbax_log.close_log;
   --         --TODO
   --         raise;
   END dispatcher;

   --Establece los parametros globales dbx.g$get y dbx.g$set en funcion de la request realizada
   PROCEDURE set_request (name_array    IN OWA_UTIL.vc_arr DEFAULT empty_vc_arr
                        , value_array   IN OWA_UTIL.vc_arr DEFAULT empty_vc_arr )
   AS
      l_headers      dbx.g_assoc_array;
      l_get          dbx.g_assoc_array;
      l_post         dbx.g_assoc_array;
      --
      j              PLS_INTEGER;
      l_name_array   VARCHAR2 (255);
   BEGIN
      --Get headers get from CGI ENV
      FOR i IN 1 .. OWA.num_cgi_vars
      LOOP
         l_headers (OWA.cgi_var_name (i)) := OWA.cgi_var_val (i);
      END LOOP;

      --Set request headers
      request_.headers (l_headers);

      --Get QueryString params
      l_get       := dbx.query_string_to_array (request_.header ('QUERY_STRING'));

      IF request_.header ('REQUEST_METHOD') = 'GET'
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
                  WHILE l_get.EXISTS (l_name_array)
                  LOOP
                     j           := j + 1;
                     l_name_array := SUBSTR (name_array (i), 1, INSTR (name_array (i), '[]') - 1) || '[' || j || ']';
                  END LOOP;

                  l_get (LOWER (l_name_array)) :=
                     CONVERT (value_array (i), request_.header ('REQUEST_CHARSET'), 'AL32UTF8');
               --dbax_log.debug (LOWER (l_name_array) || ':' || dbx.g$get (LOWER (l_name_array)));
               ELSE
                  l_get (LOWER (name_array (i))) :=
                     CONVERT (value_array (i), request_.header ('REQUEST_CHARSET'), 'AL32UTF8');
               --dbax_log.debug (LOWER (name_array (i)) || ':' || dbx.g$get (LOWER (name_array (i))));
               END IF;
            END LOOP;
         END IF;
      ELSIF request_.header ('REQUEST_METHOD') = 'POST'
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
                  WHILE l_post.EXISTS (l_name_array)
                  LOOP
                     j           := j + 1;
                     l_name_array := SUBSTR (name_array (i), 1, INSTR (name_array (i), '[]') - 1) || '[' || j || ']';
                  END LOOP;

                  l_post (LOWER (l_name_array)) :=
                     CONVERT (value_array (i), request_.header ('REQUEST_CHARSET'), 'AL32UTF8');
               --dbax_log.debug (LOWER (l_name_array) || ':' || dbx.g$post (LOWER (l_name_array)));
               ELSE
                  l_post (LOWER (name_array (i))) :=
                     CONVERT (value_array (i), request_.header ('REQUEST_CHARSET'), 'AL32UTF8');
               --dbax_log.debug (LOWER (name_array (i)) || ':' || dbx.g$post (LOWER (name_array (i))));
               END IF;
            END LOOP;
         END IF;
      END IF;

      --Set request
      request_.method (request_.header ('REQUEST_METHOD'));

      IF request_.method = 'GET'
      THEN
         request_.inputs (l_get);
      ELSE
         request_.inputs (l_post);
      END IF;
   END set_request;


   PROCEDURE print_http_header
   AS
      l_key       VARCHAR2 (256);
      l_headers   dbx.g_assoc_array;
   BEGIN
      l_headers   := response_.headers;

      IF l_headers.COUNT () <> 0
      THEN
         l_key       := l_headers.FIRST;

         LOOP
            EXIT WHEN l_key IS NULL;
            HTP.p (l_key || ':' || l_headers (l_key));
            l_key       := l_headers.NEXT (l_key);
         END LOOP;
      END IF;
   END print_http_header;
END dbax_core;
/