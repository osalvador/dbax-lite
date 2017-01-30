CREATE OR REPLACE PACKAGE BODY dbx
AS
   FUNCTION get (p_array g_assoc_array, p_key IN VARCHAR2)
      RETURN VARCHAR2
   AS
   BEGIN
      IF p_array.EXISTS (p_key)
      THEN
         RETURN p_array (p_key);
      ELSE
         RETURN NULL;
      END IF;
   END get;

   FUNCTION get_property (p_key IN VARCHAR2)
      RETURN VARCHAR2
   AS
      l_value   VARCHAR2 (3000) := NULL;
   BEGIN
      l_value     := g$properties (LOWER (p_key));

      IF l_value IS NULL
      THEN
         l_value     := g$properties (UPPER (p_key));
      END IF;

      RETURN l_value;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_property;

   PROCEDURE p (p_data IN CLOB)
   AS
      v_pos   INTEGER;
      v_amt   BINARY_INTEGER := 32000;
      v_buf   VARCHAR2 (32767);
   BEGIN
      IF p_data IS NOT NULL
      THEN
         v_pos       := 1;

         LOOP
            DBMS_LOB.read (p_data
                         , v_amt
                         , v_pos
                         , v_buf);
            v_pos       := v_pos + v_amt;

            HTP.prn (v_buf);
         END LOOP;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
   END p;

   PROCEDURE p (p_data IN VARCHAR2)
   AS
   BEGIN
      HTP.prn (p_data);
   END p;

   PROCEDURE p (p_data IN NUMBER)
   AS
   BEGIN
      HTP.prn (TO_CHAR (p_data));
   END p;


   FUNCTION get_path (p_local_path IN VARCHAR2 DEFAULT NULL )
      RETURN VARCHAR2
   AS
   BEGIN
      RETURN dbx.get_property ('BASE_PATH') || p_local_path;
   END get_path;


   PROCEDURE redirect (p_path IN VARCHAR2, p_status IN PLS_INTEGER DEFAULT 302 )
   AS
   BEGIN
      response_.header ('Location', get_path (p_path));
      response_.status (302);
   END redirect;


   PROCEDURE redirectto (p_url IN VARCHAR2, p_status IN PLS_INTEGER DEFAULT 302 )
   AS
   BEGIN
      response_.header ('Location', p_url);
      response_.status (302);
   END redirectto;


   FUNCTION query_string_to_array (p_string          IN VARCHAR2
                                 , p_delimiter       IN VARCHAR2 DEFAULT NULL
                                 , p_key_delimiter   IN VARCHAR2 DEFAULT NULL )
      RETURN g_assoc_array
   AS
      l_string             VARCHAR2 (4000) := p_string;
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
      l_assoc_array        dbx.g_assoc_array;
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
   END query_string_to_array;

   FUNCTION array_to_query_string (p_array           IN g_assoc_array
                                 , p_delimiter       IN VARCHAR2 DEFAULT NULL
                                 , p_key_delimiter   IN VARCHAR2 DEFAULT NULL )
      RETURN VARCHAR2
   AS
      l_key            VARCHAR2 (4000);
      l_string         VARCHAR2 (4000);
      l_delimiter      VARCHAR2 (5) := NVL (p_delimiter, '&');
      l_keydelimiter   VARCHAR2 (5) := NVL (p_key_delimiter, '=');
   BEGIN
      l_key       := p_array.FIRST;

      LOOP
         EXIT WHEN l_key IS NULL;

         l_string    := l_string || l_key || l_keydelimiter || utl_url.escape (p_array (l_key), TRUE) || l_delimiter;
         l_key       := p_array.NEXT (l_key);
      END LOOP;

      RETURN l_string;
   END array_to_query_string;


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
   
   /**********************************************************************
   *                    Code from dbax_cookie
   ***********************************************************************/
   
  
   /**
   * Generates the HTTP header with the cookies sent to client
   *
   * @return    the http cookie header
   */
   FUNCTION generate_cookie_header
      RETURN VARCHAR2
   AS
      l_name        VARCHAR2 (4000);
      l_return      VARCHAR2 (32000);
      expires_gmt   DATE;
      l_cookies     response_.g_cookie_array;
   BEGIN
      --Get cookies
      l_cookies   := response_.cookies;

      l_name      := l_cookies.FIRST;

      LOOP
         EXIT WHEN l_name IS NULL;

         l_return    := l_return || 'Set-Cookie: ' || l_name || '=' || l_cookies (l_name).VALUE;

         IF l_cookies (l_name).domain IS NOT NULL
         THEN
            l_return    := l_return || '; Domain=' || l_cookies (l_name).domain;
         END IF;

         IF l_cookies (l_name).PATH IS NOT NULL
         THEN
            l_return    := l_return || '; Path=' || l_cookies (l_name).PATH;
         END IF;

         -- When setting the cookie expiration header
         -- we need to set the nls date language to AMERICAN
         expires_gmt := l_cookies (l_name).expires;

         IF expires_gmt IS NOT NULL
         THEN
            l_return    :=
                  l_return
               || '; Expires='
               || RTRIM (TO_CHAR (expires_gmt, 'Dy', 'NLS_DATE_LANGUAGE = American'))
               || TO_CHAR (expires_gmt, ', DD-Mon-YYYY HH24:MI:SS', 'NLS_DATE_LANGUAGE = American')
               || ' GMT';
         END IF;

         IF l_cookies (l_name).secure
         THEN
            l_return    := l_return || '; Secure';
         END IF;

         IF l_cookies (l_name).httponly
         THEN
            l_return    := l_return || '; HttpOnly';            
         END IF;

         l_return    := l_return || CHR (10);

         l_name      := l_cookies.NEXT (l_name);
      END LOOP;

      RETURN l_return;
   END generate_cookie_header;   
   
   /**********************************************************************
   *                    Code from dbax_core
   ***********************************************************************/
   
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
      request_.load_cookies;

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
         HTP.prn (generate_cookie_header);

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
   
END dbx;