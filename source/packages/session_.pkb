CREATE OR REPLACE PACKAGE BODY session_
AS
   --g$session User Session Asocciative Array
   g$session   dbx.g_assoc_array;


   PROCEDURE load_session_variable (p_session_variable IN VARCHAR2)
   AS
      l_assoc_array   dbx.g_assoc_array;
      l_key           VARCHAR2 (4000);
   BEGIN
      l_assoc_array := dbx.query_string_to_array (p_session_variable);

      --Concatenate with g$session array
      l_key       := l_assoc_array.first;

      LOOP
         EXIT WHEN l_key IS NULL;
         g$session (l_key) := l_assoc_array (l_key);
         l_key       := l_assoc_array.next (l_key);
      END LOOP;
   END load_session_variable;

   FUNCTION valid_session (p_session_id IN VARCHAR2)
      RETURN BOOLEAN
   AS
   BEGIN
      FOR c1 IN (SELECT   1
                   FROM   wdx_sessions
                  WHERE   session_id = p_session_id AND appid = dbx.g$appid AND expired = '0')
      LOOP
         RETURN TRUE;
      END LOOP;

      RETURN FALSE;
   END valid_session;

   PROCEDURE update_session (p_username IN VARCHAR2 DEFAULT NULL )
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
      v_cgi_env          VARCHAR2 (32000);
      v_username         VARCHAR2 (256) := nvl (p_username, 'ANONYMOUS');
      l_session_exists   BOOLEAN := FALSE;
   BEGIN
      --Guardo el entorno del usuario
      FOR i IN 1 .. owa.num_cgi_vars
      LOOP
         v_cgi_env   := v_cgi_env || owa.cgi_var_name (i) || ' = ' || owa.cgi_var_val (i) || chr (10);
      END LOOP;

      v_cgi_env   := substr (v_cgi_env, 1, 4000);

      IF g$session.exists ('sessid')
      THEN
         FOR c1 IN (SELECT   appid, session_id, session_variable
                      FROM   wdx_sessions
                     WHERE   session_id = g$session ('sessid') AND appid = dbx.g$appid)
         LOOP
            l_session_exists := TRUE;

            load_session_variable (c1.session_variable);

            UPDATE   wdx_sessions
               SET /*expired = 0,*/
                  last_access = systimestamp, cgi_env = v_cgi_env
             WHERE   appid = c1.appid AND session_id = c1.session_id;
         END LOOP;
      END IF;

      IF NOT l_session_exists
      THEN
         --Gaurdo la session
         INSERT INTO wdx_sessions (appid
                                 , session_id
                                 , username
                                 , expired
                                 , created_date
                                 , last_access
                                 , cgi_env)
           VALUES   (nvl (dbx.g$appid, 'DEFAULT')
                   , g$session ('sessid')
                   , upper (v_username)
                   , 0
                   , systimestamp
                   , NULL
                   , v_cgi_env);
      END IF;

      COMMIT;
   END update_session;

   FUNCTION get_session (p_cookies IN VARCHAR2 DEFAULT NULL )
      RETURN VARCHAR2
   AS
      --v_my_session     OWA_COOKIE.cookie;
      l_cookie_name    VARCHAR2 (2000);
      l_cookie_value   VARCHAR2 (200);
      l_session_id     VARCHAR2 (200);
      --
      v_owner          VARCHAR2 (32767);
      v_name           VARCHAR2 (32767);
      v_lineno         NUMBER;
      v_caller_t       VARCHAR2 (32767);
      v_whois          VARCHAR2 (32767);
   BEGIN
      l_cookie_name := nvl (dbx.get_property ('session_cookie_name'), 'DBAXSESSID');

      IF p_cookies IS NOT NULL
      THEN
         request_.load_cookies (p_cookies);
      END IF;

      IF get ('sessid') IS NULL
      THEN
         IF request_.cookie (l_cookie_name) IS NULL
         THEN
            --No cookie session
            g$session ('sessid') := NULL;
            RETURN NULL;
         ELSE
            l_session_id := request_.cookie (l_cookie_name);

            IF valid_session (l_session_id)
            THEN
               --The session is valid
               g$session ('sessid') := l_session_id;
            ELSE
               g$session ('sessid') := NULL;
               RETURN NULL;
            END IF;
         END IF;
      ELSIF NOT valid_session (g$session ('sessid'))
      THEN
         RETURN NULL;
      END IF;

      update_session;

      RETURN get ('sessid');
   END get_session;

   /* Inicia una nueva session, se genera el ticket en al tabla de sesiones. Se define la caducidad de la misma*/

   PROCEDURE init (p_username IN VARCHAR2 DEFAULT NULL , p_session_expires IN DATE DEFAULT NULL )
   AS
      l_session_id    VARCHAR2 (50);
      l_cookie_name   VARCHAR2 (255);
   BEGIN
      l_cookie_name := nvl (dbx.get_property ('session_cookie_name'), 'DBAXSESSID');

      --Generate unique dbax session id
      l_session_id := dbms_session.unique_session_id || round (dbms_random.value (10000, 99999));
      --Creo cookie
      response_.cookie (p_name      => l_cookie_name
                      , p_value     => l_session_id
                      , p_expires   => p_session_expires
                      , p_path      => '/');

      --Global user session variable
      g$session ('sessid') := l_session_id;

      update_session (p_username);
   END init;

   FUNCTION is_started
      RETURN BOOLEAN
   AS
   BEGIN
      IF get_session () IS NOT NULL
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END is_started;

   /*Finaliza una sesion. Borra las cookies del usaurio y borra las variables globales*/
   PROCEDURE session_end
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
      l_session_id    VARCHAR2 (50);
      l_cookie_name   VARCHAR2 (255) := nvl (dbx.get_property ('session_cookie_name'), 'DBAXSESSID');
   BEGIN
      l_session_id := get_session ();

      UPDATE   wdx_sessions
         SET   expired = '1', last_access = systimestamp
       WHERE   session_id = l_session_id AND appid = dbx.g$appid;

      COMMIT;

      --Remove cookie Session
      response_.forget_cookie (l_cookie_name);

      --Remove g$session
      g$session.delete;
   END session_end;

   PROCEDURE save
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
      l_session_variable   VARCHAR2 (4000);
   BEGIN
      IF g$session.exists ('sessid')
      THEN
         l_session_variable := dbx.array_to_query_string (g$session);

         FOR c1 IN (SELECT   appid, session_id
                      FROM   wdx_sessions
                     WHERE   session_id = g$session ('sessid') AND appid = dbx.g$appid)
         LOOP
            UPDATE   wdx_sessions
               SET   session_variable = l_session_variable
             WHERE   appid = c1.appid AND session_id = c1.session_id;
         END LOOP;

         COMMIT;
      END IF;
   END save;

   PROCEDURE flush
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
      l_session_id   VARCHAR2 (50);
   BEGIN
      l_session_id := get_session ();

      UPDATE   wdx_sessions
         SET   session_variable = NULL
       WHERE   session_id = l_session_id AND appid = dbx.g$appid;

      COMMIT;

      --Remove g$session
      g$session.delete;
   END flush;

   FUNCTION has (p_key IN VARCHAR2)
      RETURN BOOLEAN
   AS
   BEGIN
      IF g$session.exists (p_key) AND g$session.exists (p_key) IS NOT NULL
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END;

   FUNCTION get (p_key IN VARCHAR2)
      RETURN VARCHAR2
   AS
   BEGIN
      IF g$session.exists (p_key)
      THEN
         RETURN g$session (p_key);
      ELSE
         RETURN NULL;
      END IF;
   END get;

   FUNCTION get_all
      RETURN dbx.g_assoc_array
   AS
   BEGIN
      RETURN g$session;
   END;

   FUNCTION getid
      RETURN VARCHAR2
   AS
   BEGIN
      RETURN get_session ();
   END getid;


   PROCEDURE set (p_key IN VARCHAR2, p_value IN VARCHAR2)
   AS
   BEGIN
      g$session (p_key) := p_value;
   END set;

   PROCEDURE delete (p_key IN VARCHAR2)
   AS
   BEGIN
      g$session.delete (p_key);
   END delete;


   PROCEDURE finish
   AS
   BEGIN
      session_end;
   END finish;


   FUNCTION pull (p_key IN VARCHAR2)
      RETURN VARCHAR2
   AS
      l_value   VARCHAR2 (4000);
   BEGIN
      l_value     := get (p_key);

      IF l_value IS NOT NULL
      THEN
         session_.delete (p_key);
         RETURN l_value;
      ELSE
         RETURN NULL;
      END IF;
   END;
END session_;
/