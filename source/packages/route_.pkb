CREATE OR REPLACE PACKAGE BODY route_
AS
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
      l_param_tab   dbx.g_varchar_array;
   BEGIN
      l_regex_pos := instr (p_string, '@', -1);

      IF l_regex_pos <> 0
      THEN
         p_pattern   := substr (p_string, 1, l_regex_pos - 1);

         l_param_tab := dbx.tokenizer (substr (p_string, l_regex_pos + 1));

         IF l_param_tab.exists (1) AND l_param_tab (1) IS NOT NULL
         THEN
            p_postion   := l_param_tab (1);
         ELSE
            p_postion   := 1;
         END IF;

         IF l_param_tab.exists (2)
         THEN
            p_occurrence := l_param_tab (2);
         ELSE
            p_occurrence := 0;
         END IF;

         IF l_param_tab.exists (3)
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

   FUNCTION get_url_parameters (p_user_url_pattern IN VARCHAR2, p_url_pattern IN VARCHAR2)
      RETURN dbx.g_assoc_array
   AS
      l_parameter_value    VARCHAR2 (3000);
      l_user_url_pattern   VARCHAR2 (2000);
      l_url_parameters     dbx.g_assoc_array;
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


      FOR v_reg IN (    SELECT   regexp_substr (l_user_url_pattern
                                              , '{(.*?)}'
                                              , 1
                                              , level
                                              , 'n'
                                              , 1)
                                    var_name, level
                          FROM   dual
                    CONNECT BY   regexp_substr (l_user_url_pattern
                                              , '{(.*?)}'
                                              , 1
                                              , level
                                              , 'n'
                                              , 1) IS NOT NULL)
      LOOP
         l_parameter_value :=
            regexp_substr (dbx.g$path
                         , p_url_pattern
                         , l_position
                         , nvl (l_occurrence, 1)
                         , l_match_parameter
                         , v_reg.level);
         l_url_parameters (v_reg.var_name) := l_parameter_value;
      END LOOP;

      RETURN l_url_parameters;
   END get_url_parameters;


   FUNCTION router (p_url_pattern IN VARCHAR2, p_parameters OUT dbx.g_assoc_array)
      RETURN BOOLEAN
   AS
      l_path              VARCHAR2 (2000);
      l_url_pattern       VARCHAR2 (2000);
      l_position          PLS_INTEGER;
      l_occurrence        PLS_INTEGER;
      l_match_parameter   VARCHAR2 (100);
      l_ret_arr           dbx.g_varchar_array;
      l_segment_inputs    dbx.g_varchar_array;
      --
      l_retval            PLS_INTEGER := 0;
      l_return            VARCHAR2 (1000);
      l_replace_string    VARCHAR2 (1000);
      --
      l_is_parameter      BOOLEAN := FALSE;
   BEGIN
      l_url_pattern := p_url_pattern;

      --Si el url_pattern contiene una {} sustituirlo por ([[:print:]].*+)
      IF instr (l_url_pattern, '{') > 0 AND instr (l_url_pattern, '}') > 0
      THEN
         l_url_pattern :=
            regexp_replace (l_url_pattern
                          , '{(.*?)}'
                          , '([[:print:]][^/]*)'
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
            regexp_instr (nvl (dbx.g$path, '/')
                        , l_url_pattern
                        , l_position
                        , nvl (l_occurrence, 1)
                        , '0'
                        , l_match_parameter);

         IF l_retval > 0
         THEN
            log_.debug ('Route Matched:' || dbx.g$path || ' URL_PATTERN:' || l_url_pattern);

            IF l_is_parameter
            THEN
               p_parameters := get_url_parameters (p_url_pattern, l_url_pattern);
            END IF;

            l_path      :=
               regexp_replace (dbx.g$path
                             , l_url_pattern
                             , l_replace_string || '/'
                             , l_position
                             , nvl (l_occurrence, 0)
                             , l_match_parameter);


            --Tokenizer the Url
            -- The l_path has <parameter1>/<parameterN>
            l_ret_arr   := dbx.tokenizer (l_path, '/');

            --Parameters are the rest of the url
            IF l_ret_arr.exists (1)
            THEN
               FOR i IN 1 .. l_ret_arr.last
               LOOP
                  l_segment_inputs (i) := l_ret_arr (i);
               --dbax_log.info ('Paramter g$parameter(' || i || ') = ' || g$parameter (i));
               --HTP.p ('<br>Paramter g$parameter(' || i || ') = ' || g$parameter (i));
               END LOOP;
            END IF;

            -- Populate Request object
            request_.segment_inputs (l_segment_inputs);
            request_.route (p_url_pattern);

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


   FUNCTION match (p_uri IN VARCHAR2, p_http_verbs IN VARCHAR2 DEFAULT NULL , p_parameters OUT dbx.g_assoc_array)
      RETURN BOOLEAN
   AS
      l_http_verbs   dbx.g_varchar_array;
   BEGIN
      l_http_verbs := dbx.tokenizer (p_http_verbs, ',');

      IF l_http_verbs.exists (1)
      THEN
         FOR i IN 1 .. l_http_verbs.last
         LOOP
            IF request_.method = upper (trim (l_http_verbs (i))) AND router (p_uri, p_parameters)
            THEN
               RETURN TRUE;
            END IF;
         END LOOP;
      END IF;

      RETURN FALSE;
   END match;

   FUNCTION match (p_uri IN VARCHAR2, p_http_verbs IN VARCHAR2 DEFAULT NULL )
      RETURN BOOLEAN
   AS
      l_dummy   dbx.g_assoc_array;
   BEGIN
      RETURN match (p_uri, p_http_verbs, l_dummy);
   END match;

   FUNCTION any_ (p_uri IN VARCHAR2, p_parameters OUT dbx.g_assoc_array)
      RETURN BOOLEAN
   AS
   BEGIN
      IF router (p_uri, p_parameters)
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END any_;

   FUNCTION any_ (p_uri IN VARCHAR2)
      RETURN BOOLEAN
   AS
      l_dummy   dbx.g_assoc_array;
   BEGIN
      IF router (p_uri, l_dummy)
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END any_;

   FUNCTION get (p_uri IN VARCHAR2, p_parameters OUT dbx.g_assoc_array)
      RETURN BOOLEAN
   AS
   BEGIN
      IF request_.method = 'GET' AND router (p_uri, p_parameters)
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END get;

   FUNCTION get (p_uri IN VARCHAR2)
      RETURN BOOLEAN
   AS
      l_dummy   dbx.g_assoc_array;
   BEGIN
      RETURN get (p_uri, l_dummy);
   END get;

   FUNCTION post (p_uri IN VARCHAR2, p_parameters OUT dbx.g_assoc_array)
      RETURN BOOLEAN
   AS
   BEGIN
      IF request_.method = 'POST' AND router (p_uri, p_parameters)
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END post;

   FUNCTION post (p_uri IN VARCHAR2)
      RETURN BOOLEAN
   AS
      l_dummy   dbx.g_assoc_array;
   BEGIN
      RETURN post (p_uri, l_dummy);
   END post;

   FUNCTION put (p_uri IN VARCHAR2, p_parameters OUT dbx.g_assoc_array)
      RETURN BOOLEAN
   AS
   BEGIN
      IF request_.method = 'PUT' AND router (p_uri, p_parameters)
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END put;

   FUNCTION put (p_uri IN VARCHAR2)
      RETURN BOOLEAN
   AS
      l_dummy   dbx.g_assoc_array;
   BEGIN
      RETURN put (p_uri, l_dummy);
   END put;

   FUNCTION delete (p_uri IN VARCHAR2, p_parameters OUT dbx.g_assoc_array)
      RETURN BOOLEAN
   AS
   BEGIN
      IF request_.method = 'DELETE' AND router (p_uri, p_parameters)
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END delete;

   FUNCTION delete (p_uri IN VARCHAR2)
      RETURN BOOLEAN
   AS
      l_dummy   dbx.g_assoc_array;
   BEGIN
      RETURN "DELETE" (p_uri, l_dummy);
   END delete;


   FUNCTION patch (p_uri IN VARCHAR2, p_parameters OUT dbx.g_assoc_array)
      RETURN BOOLEAN
   AS
   BEGIN
      IF request_.method = 'PATCH' AND router (p_uri, p_parameters)
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END patch;

   FUNCTION patch (p_uri IN VARCHAR2)
      RETURN BOOLEAN
   AS
      l_dummy   dbx.g_assoc_array;
   BEGIN
      RETURN patch (p_uri, l_dummy);
   END patch;
   
   
   FUNCTION options (p_uri IN VARCHAR2, p_parameters OUT dbx.g_assoc_array)
      RETURN BOOLEAN
   AS
   BEGIN
      IF request_.method = 'OPTIONS' AND router (p_uri, p_parameters)
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END options;

   FUNCTION options (p_uri IN VARCHAR2)
      RETURN BOOLEAN
   AS
      l_dummy   dbx.g_assoc_array;
   BEGIN
      RETURN options (p_uri, l_dummy);
   END options;   
   
END route_;
/