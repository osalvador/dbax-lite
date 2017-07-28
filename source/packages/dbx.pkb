
CREATE OR REPLACE PACKAGE BODY dbx
AS
   --G$PROPERTIES An associative array of application properties
   g$properties   dbx.g_assoc_array;

   FUNCTION get (p_array g_assoc_array, p_key IN VARCHAR2)
      RETURN VARCHAR2
   AS
   BEGIN
      IF p_array.exists (p_key)
      THEN
         RETURN p_array (p_key);
      ELSE
         RETURN NULL;
      END IF;
   END get;


   FUNCTION get_property (p_key IN VARCHAR2)
      RETURN VARCHAR2
   AS
   BEGIN
      IF g$properties.exists (p_key)
      THEN
         RETURN g$properties (p_key);
      ELSE
         RETURN NULL;
      END IF;
   END get_property;

   PROCEDURE set_property (p_key IN VARCHAR2, p_value IN VARCHAR2)
   AS
   BEGIN
      g$properties (p_key) := p_value;
   END set_property;

   /**
   * Set base_path property to application properties.
   */
   PROCEDURE set_base_path
   AS
   BEGIN
      -- If base_path is not defined.
      IF dbx.get_property ('base_path') IS NULL
      THEN
         dbx.set_property ('base_path', request_.header ('SCRIPT_NAME') || '/!' || lower (dbx.g$appid) || '?p=');
      END IF;
   END set_base_path;

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
            dbms_lob.read (p_data
                         , v_amt
                         , v_pos
                         , v_buf);
            v_pos       := v_pos + v_amt;

            htp.prn (v_buf);
         END LOOP;
      END IF;
   EXCEPTION
      WHEN no_data_found
      THEN
         NULL;
   END p;

   PROCEDURE p (p_data IN VARCHAR2)
   AS
   BEGIN
      htp.prn (p_data);
   END p;

   PROCEDURE p (p_data IN NUMBER)
   AS
   BEGIN
      htp.prn (to_char (p_data));
   END p;


   FUNCTION get_path (p_local_path IN VARCHAR2 DEFAULT NULL )
      RETURN VARCHAR2
   AS
   BEGIN
      RETURN dbx.get_property ('base_path') || p_local_path;
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
      l_delimiter          VARCHAR2 (5) := nvl (p_delimiter, '&');
      l_keydelimiter       VARCHAR2 (5) := nvl (p_key_delimiter, '=');
      l_delimiter_length   NUMBER (5) := length (l_delimiter);
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
      IF substr (l_string, -1, 1) <> l_delimiter
      THEN
         l_string    := l_string || l_delimiter;
      END IF;

      l_new       := l_string;

      LOOP
         l_end       := instr (l_new, l_delimiter, 1);
         l_keyvalue  := substr (l_new, 1, l_end - 1);
         l_key       := substr (l_keyvalue, 1, instr (l_keyvalue, l_keydelimiter) - 1);
         l_value     := substr (l_keyvalue, instr (l_keyvalue, l_keydelimiter) + 1);
         EXIT WHEN l_keyvalue IS NULL;

         IF l_key IS NOT NULL
         THEN
            l_assoc_array (l_key) := utl_url.unescape (l_value);
         ELSE
            l_assoc_array (l_value) := NULL;
         END IF;

         l_start     := l_start + (l_end + (l_delimiter_length - 1));
         l_new       := substr (l_string, l_start);
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
      l_delimiter      VARCHAR2 (5) := nvl (p_delimiter, '&');
      l_keydelimiter   VARCHAR2 (5) := nvl (p_key_delimiter, '=');
   BEGIN
      l_key       := p_array.first;

      LOOP
         EXIT WHEN l_key IS NULL;

         l_string    := l_string || l_key || l_keydelimiter || utl_url.escape (p_array (l_key), TRUE) || l_delimiter;
         l_key       := p_array.next (l_key);
      END LOOP;

      RETURN l_string;
   END array_to_query_string;


   FUNCTION tokenizer (p_string IN VARCHAR2, p_delimiter IN VARCHAR2 DEFAULT ',' )
      RETURN g_varchar_array
   AS
      l_array   g_varchar_array;
   BEGIN
          SELECT   regexp_substr (p_string
                                , '[^' || p_delimiter || ']+'
                                , 1
                                , level)
            BULK   COLLECT
            INTO   l_array
            FROM   dual
      CONNECT BY   regexp_substr (p_string
                                , '[^' || p_delimiter || ']+'
                                , 1
                                , level) IS NOT NULL;

      RETURN l_array;
   END tokenizer;


   FUNCTION get_document (p_name IN VARCHAR2)
      RETURN BLOB
   AS
      l_blob_content   BLOB;
   BEGIN
      SELECT   blob_content
        INTO   l_blob_content
        FROM   wdx_documents
       WHERE   name = p_name AND appid = dbx.g$appid;

      RETURN l_blob_content;
   EXCEPTION
      WHEN no_data_found
      THEN
         RETURN NULL;
   END get_document;

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

      l_name      := l_cookies.first;

      LOOP
         EXIT WHEN l_name IS NULL;

         l_return    := l_return || 'Set-Cookie: ' || l_name || '=' || l_cookies (l_name).value;

         IF l_cookies (l_name).domain IS NOT NULL
         THEN
            l_return    := l_return || '; Domain=' || l_cookies (l_name).domain;
         END IF;

         IF l_cookies (l_name).path IS NOT NULL
         THEN
            l_return    := l_return || '; Path=' || l_cookies (l_name).path;
         END IF;

         -- When setting the cookie expiration header
         -- we need to set the nls date language to AMERICAN
         expires_gmt := l_cookies (l_name).expires;

         IF expires_gmt IS NOT NULL
         THEN
            l_return    :=
                  l_return
               || '; Expires='
               || rtrim (to_char (expires_gmt, 'Dy', 'NLS_DATE_LANGUAGE = American'))
               || to_char (expires_gmt, ', DD-Mon-YYYY HH24:MI:SS', 'NLS_DATE_LANGUAGE = American')
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

         l_return    := l_return || chr (13) || chr (10);

         l_name      := l_cookies.next (l_name);
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

      IF l_headers.count () <> 0
      THEN
         l_key       := l_headers.first;

         LOOP
            EXIT WHEN l_key IS NULL;
            htp.prn (l_key || ':' || l_headers (l_key) || chr (13) || chr (10));
            l_key       := l_headers.next (l_key);
         END LOOP;
      END IF;
   END print_http_header;


   PROCEDURE print_owa_page (p_thepage IN htp.htbuf_arr, p_lines IN NUMBER)
   AS
      l_found        BOOLEAN := FALSE;
      l_thepage      htp.htbuf_arr := p_thepage;
      l_start_line   PLS_INTEGER := 1;
   BEGIN
      --Response content start with <!--DBAX-->
      --Buscar la linea en la que sale el comentario, quitarlo e imprimir esa linea.
      FOR i IN 1 .. p_lines
      LOOP
         IF NOT l_found
         THEN
            l_found     := l_thepage (i) LIKE '<!--DBAX-->%';

            IF l_found
            THEN
               l_thepage (i) := replace (l_thepage (i), '<!--DBAX-->');
               htp.prn (l_thepage (i));
               l_start_line := i + 1;
            END IF;
         END IF;
      END LOOP;

      -- Print the rest of lines
      FOR i IN l_start_line .. p_lines
      LOOP
         htp.prn (l_thepage (i));
      END LOOP;
   END print_owa_page;

   PROCEDURE set_request_method
   AS
   BEGIN
      log_.debug ('The real method is:' || request_.header ('REQUEST_METHOD'));

      IF request_.header ('REQUEST_METHOD') = 'POST'
      THEN
         IF request_.header ('X-HTTP-METHOD-OVERRIDE') IS NOT NULL
         THEN
            -- standard method override
            request_.method (upper (request_.header ('X-HTTP-METHOD-OVERRIDE')));
            log_.debug ('Header X-HTTP-METHOD-OVERRIDE found');
         ELSIF request_.header ('HTTP_X_ORACLE_CACHE_ENCRYPT') IS NOT NULL
         THEN
            -- mod_plsql mehotd override
            -- You must send this header X-ORACLE-CACHE-ENCRYPT
            request_.method (upper (request_.header ('HTTP_X_ORACLE_CACHE_ENCRYPT')));
            log_.debug ('Header HTTP_X_ORACLE_CACHE_ENCRYPT found');
         ELSE
            -- No override method
            request_.method (upper (request_.header ('REQUEST_METHOD')));
            log_.debug ('No override method found.');
         END IF;
      ELSE
         -- No override method
         request_.method (upper (request_.header ('REQUEST_METHOD')));
      END IF;
   END set_request_method;

   PROCEDURE set_request (name_array    IN owa_util.vc_arr DEFAULT empty_vc_arr
                        , value_array   IN owa_util.vc_arr DEFAULT empty_vc_arr )
   AS
      l_headers      dbx.g_assoc_array;
      l_get          dbx.g_assoc_array;
      l_post         dbx.g_assoc_array;
      --
      j              PLS_INTEGER;
      l_name_array   VARCHAR2 (255);
   BEGIN
      --Get headers get from CGI ENV
      FOR i IN 1 .. owa.num_cgi_vars
      LOOP
         l_headers (upper (owa.cgi_var_name (i))) := owa.cgi_var_val (i);
      END LOOP;

      --Set request headers
      request_.headers (l_headers);

      --Get QueryString params
      l_get       := dbx.query_string_to_array (request_.header ('QUERY_STRING'));


      IF name_array.exists (1) AND name_array (1) IS NOT NULL
      THEN
         FOR i IN name_array.first .. name_array.last
         LOOP
            --if the parameter ends with [ ] it is an array
            IF name_array (i) LIKE '%[]'
            THEN
               j           := 1;

               --Set Name of the parameter[n]
               l_name_array := substr (name_array (i), 1, instr (name_array (i), '[]') - 1) || '[' || j || ']';

               --Generate Array index
               WHILE l_get.exists (l_name_array)
               LOOP
                  j           := j + 1;
                  l_name_array := substr (name_array (i), 1, instr (name_array (i), '[]') - 1) || '[' || j || ']';
               END LOOP;

               l_get (l_name_array) := convert (value_array (i), request_.header ('REQUEST_CHARSET'), 'AL32UTF8');
               log_.debug ('Request input:' || l_name_array || '=' || l_get (l_name_array));
            ELSE
               l_get (name_array (i)) := convert (value_array (i), request_.header ('REQUEST_CHARSET'), 'AL32UTF8');
               log_.debug ('Request input:' || name_array (i) || '=' || l_get (name_array (i)));
            END IF;
         END LOOP;
      END IF;

      --Set request
      set_request_method;
      log_.debug ('The method is:' || request_.method);
      request_.inputs (l_get);
   END set_request;

   FUNCTION get_error_source_code (p_errorbacktrace IN VARCHAR2, p_errorstack IN VARCHAR2)
      RETURN VARCHAR2
   AS
      l_code_line   PLS_INTEGER;
      l_owner       VARCHAR2 (31);
      l_name        VARCHAR2 (31);
      l_code        VARCHAR2 (32767);
      l_new_type    VARCHAR2 (31);
      l_old_type    VARCHAR2 (31);
   BEGIN
      -- Get Line of code
      l_code_line :=
         regexp_substr (p_errorbacktrace
                      , ', [[:print:]]* (.*?)' || chr (10)
                      , 1
                      , 1
                      , 'n'
                      , 1);
      l_owner     :=
         regexp_substr (p_errorbacktrace
                      , ' [[:print:]]* "(.*?)\.'
                      , 1
                      , 1
                      , 'n'
                      , 1);
      l_name      :=
         regexp_substr (p_errorbacktrace
                      , ' [[:print:]]* "' || l_owner || '\.(.*?)"'
                      , 1
                      , 1
                      , 'n'
                      , 1);

      --If the name is VIEW_ get view's compiled source
      IF l_name = 'VIEW_'
      THEN
         l_code_line :=
            regexp_substr (p_errorstack
                         , 'line (\d*),'
                         , 1
                         , 1
                         , 'n'
                         , 1);

         l_code      := '<h3>View ' || view_.name () || '<small> compiled source code</small></h3>';
         l_code      :=
               l_code
            || '<pre class="prettyprint linenums:'
            || (l_code_line - 9)
            || '"><code class="language-sql">...'
            || chr (10);

         FOR c1
         IN (SELECT   x.rn, x.compiled_source
               FROM   wdx_views t
                    , xmltable ('/x/y' PASSING xmltype(replace (   '<x><y>'
                                || dbms_xmlgen.convert (t.compiled_source, 0)
                                || '</y></x>'
                                                              ,chr (10)
                                                              ,'</y><y>')) COLUMNS rn FOR ORDINALITY, compiled_source
                                VARCHAR2 (4000) PATH '/y') x
              WHERE   t.name = view_.name () AND rn BETWEEN l_code_line - 8 AND l_code_line + 8)
         LOOP
            IF c1.rn = l_code_line
            THEN
               l_code      :=
                     l_code
                  || '<span class="operative">'
                  || dbms_xmlgen.convert (c1.compiled_source, 0)
                  || ' </span>'
                  || chr (10);
            ELSE
               l_code      := l_code || dbms_xmlgen.convert (c1.compiled_source, 0) || chr (10);
            END IF;
         END LOOP;

         l_code      := l_code || '...</code></pre>';
      ELSE
         FOR c1
         IN (  SELECT   *
                 FROM   all_source
                WHERE       name = l_name
                        AND owner = l_owner
                        AND line BETWEEN l_code_line - 8 AND l_code_line + 8
                        AND name <> 'DBAX_CORE'
             ORDER BY   type, line)
         LOOP
            l_new_type  := c1.type;

            IF l_new_type <> l_old_type OR l_old_type IS NULL
            THEN
               IF l_code IS NOT NULL
               THEN
                  l_code      := l_code || '...</code></pre>';
               END IF;

               l_code      := l_code || '<h3>' || c1.type || ' <small> ' || l_owner || '.' || l_name || '</small></h3>';
               l_code      :=
                     l_code
                  || '<pre class="prettyprint linenums:'
                  || (l_code_line - 9)
                  || '"><code class="language-sql">...'
                  || chr (10);
            END IF;

            IF c1.line = l_code_line
            THEN
               l_code      :=
                  l_code || '<span class="operative">' || replace (c1.text, chr (10)) || ' </span>' || chr (10);
            ELSE
               l_code      := l_code || c1.text;
            END IF;

            l_old_type  := l_new_type;
         END LOOP;

         IF l_code IS NOT NULL
         THEN
            l_code      := l_code || '...</code></pre>';
         END IF;
      END IF;

      RETURN l_code;
   END get_error_source_code;

   PROCEDURE raise_exception (p_error_code IN NUMBER, p_error_msg IN VARCHAR2)
   AS
      l_html_error    VARCHAR2 (32767);
      --
      l_log_id        PLS_INTEGER;
      --
      l_http_output   htp.htbuf_arr;
      l_dummy         htp.htbuf_arr;
      l_lines         NUMBER DEFAULT 99999999 ;
   BEGIN
      g_stop_process := TRUE;

      -- delete all existing data in the view
      view_.delete_data;

      -- Get error_style from application properties
      view_.data ('error_style', dbx.get_property ('error_style'));

      view_.data ('errorCode', to_char (p_error_code));
      view_.data ('errorMsg', p_error_msg);

      view_.data ('errorStack', '----- PL/SQL Error Stack -----' || chr (10) || dbms_utility.format_error_stack ());
      view_.data ('errorBacktrace'
                , '----- PL/SQL Error Backtrace -----' || chr (10) || dbms_utility.format_error_backtrace ());

      view_.data ('callStack', dbms_utility.format_call_stack ());

      log_.error ('p_cod_error:' || p_error_code || ' p_msg_error:' || p_error_msg);
      log_.error (chr (10) || view_.get_data_varchar ('errorStack'));
      log_.error (chr (10) || view_.get_data_varchar ('errorBacktrace'));
      log_.error (chr (10) || view_.get_data_varchar ('callStack'));
      l_log_id    := log_.write;

      view_.data ('logId', to_char (l_log_id));
      view_.data ('code'
                , get_error_source_code (view_.get_data_varchar ('errorBacktrace')
                                       , view_.get_data_varchar ('errorStack')));

      l_html_error :=
         q'[<!DOCTYPE html>
<html>
   <head>
      <meta http-equiv="content-type" content="text/html; charset=UTF-8">
      <meta charset="utf-8">
      <title>dbax Exception</title>
      <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
      <!-- Latest compiled and minified CSS -->
      <link rel="stylesheet" href="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css">
      <!--[if lt IE 9]>
      <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
      <![endif]-->
       <style>.operative { font-weight: bold; border:1px solid red }</style>
   </head>
   <body>
      <header class="navbar navbar-default navbar-static-top" role="banner">
         <div class="container">
            <div class="navbar-header">
               <a href="https://dbax.io" class="navbar-brand">dbax exception: 500 Internal Server Error</a>
            </div>
         </div>
      </header>
      <!-- Begin Body -->
      <div class="container">
         <div class="row">
            <div class="col-md-12">
               <h1 class="text-danger text-center"><b>Error 500. Internal Server Error (${logId})</b></h1>
                <br>
               <h4 class="text-center">There is a problem with the resource you are looking for, and it cannot be displayed. <code id="http_referer"></code></h4>
               <h4 class="text-center">Contact your administrator with details of the action you performed before error occured with this log id: ${logId}</h4>
               <% if error_style = 'DebugStyle' then %>
               <hr>
               <h2 id="userError">User Error</h2>
               <pre class="prettyprint"><code class="language-sql">Error Code: ${errorCode}</code></pre>
               <pre class="prettyprint"><code class="language-sql">${errorMsg}</code></pre>
               <hr>
               <h2 id="errorStack">Error Stack</h2>
               <pre class="prettyprint"><code class="language-sql">${errorStack}</code></pre>
               <hr>
               <h2 id="errorBacktrace">Error Backtrace</h2>
               <pre class="prettyprint"><code class="language-sql">${errorBacktrace}</code></pre>
               <hr>
               <h2 id="callStack">Call Stack</h2>
               <pre class="prettyprint"><code class="language-sql">${callStack}</code></pre>
               <hr>
               <h2 id="code">Code</h2>
               ${code}
              <hr>
              <% end if; %>
            </div>
         </div>
      </div>
      <!-- script references -->
      <script src="http://code.jquery.com/jquery-1.11.2.min.js"></script>
      <!-- Latest compiled and minified JavaScript -->
      <script src="http://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/js/bootstrap.min.js"></script>
      <script type="text/javascript">
          document.getElementById("http_referer").innerHTML = window.location.pathname;
       </script>
      <script src="https://cdn.rawgit.com/google/code-prettify/master/loader/run_prettify.js?lang=sql&amp;skin=sons-of-obsidian"></script>
   </body>
</html>]';

      --HTTP Response
      htp.init;
      owa_util.mime_header ('text/html', FALSE, dbx.get_property ('encoding'));
      owa_util.status_line (500);
      owa_util.http_header_close;

      --Run view
      view_.run (l_html_error, '500');
   END raise_exception;


   PROCEDURE execute_app_router (p_router IN VARCHAR2)
   AS
      l_response   CLOB;
   BEGIN
      -- Execute Routing
      BEGIN
         EXECUTE IMMEDIATE 'BEGIN :l_val := ' || p_router || '; END;' USING OUT l_response;

         IF NOT g_stop_process
         THEN
            --Print response to the buffer
            dbx.p (l_response);
         END IF;
      EXCEPTION
         WHEN OTHERS
         THEN
            IF sqlcode = -06550
            THEN
               raise_exception (100, 'Error trying to execute the controller: ' || upper (p_router));
            ELSIF sqlcode = -06503
            THEN
               --Function returned without value
               NULL;
            ELSE
               raise_exception (sqlcode, sqlerrm || chr (10) || 'Executing router: ' || upper (p_router));
            END IF;
      END;
   END execute_app_router;

   PROCEDURE dispatcher (p_appid       IN VARCHAR2
                       , name_array    IN owa_util.vc_arr DEFAULT empty_vc_arr
                       , value_array   IN owa_util.vc_arr DEFAULT empty_vc_arr
                       , router        IN VARCHAR2 DEFAULT NULL )
   AS
      l_path          VARCHAR2 (4000);
      --
      l_http_output   htp.htbuf_arr;
      l_lines         NUMBER DEFAULT 99999999 ;
   BEGIN
      /***************
      * Defining the application
      ***************/
      htp.prn ('<!--DBAX-->');
      dbx.g$appid := p_appid;
      dbx.g$properties ('appid') := p_appid;

      --Set Request parameters
      set_request (name_array, value_array);

      --Set base_path propertie
      set_base_path;

      /***************
      * Get URI to route
      ***************/

      --If is a queryString model, get de URL to route from reserved parameter 'p'
      IF request_.input ('p') IS NOT NULL
      THEN
         l_path      := '/' || p_appid || request_.input ('p');
      ELSE
         l_path      := request_.header ('PATH_INFO');
      END IF;

      --Split the URL
      IF instr (l_path, '/', 2) > 0
      THEN
         l_path      := substr (l_path, instr (l_path, '/', 2) + 1);
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
      log_.debug ('Request path:' || g$path);
      execute_app_router (router);


      IF NOT dbx.g_stop_process
      THEN
         /***************
         *  Print Page
         ***************/

         -- Get page from owa buffer
         owa.get_page (l_http_output, l_lines);

         htp.init;
         owa_util.mime_header (nvl (response_.content, 'text/html')
                             , FALSE
                             , nvl (dbx.get_property ('encoding'), 'UTF-8'));
         owa_util.status_line (nstatus => nvl (response_.status, 200), creason => NULL, bclose_header => FALSE);
         htp.prn (generate_cookie_header);
         print_http_header;
         owa_util.http_header_close;

         print_owa_page (l_http_output, l_lines);
      ELSE
         NULL;
      END IF;

      session_.save;
      log_.write;
   EXCEPTION
      WHEN OTHERS
      THEN
         session_.save;
         raise_exception (sqlcode, sqlerrm);
         log_.write;
   END dispatcher;
END dbx;
