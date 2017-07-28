CREATE OR REPLACE PACKAGE BODY log_
AS
   --Default Log level is DEBUG
   g_log   CLOB;

   FUNCTION get_log_level
      RETURN PLS_INTEGER
   AS
      l_returnvalue   PLS_INTEGER;
      l_log_level     VARCHAR2 (10);
   BEGIN
      l_log_level := nvl (dbx.get_property ('log_level'), 'debug');

      l_returnvalue :=
         CASE l_log_level
            WHEN k_log_level_emergency_str THEN k_log_level_emergency
            WHEN k_log_level_alert_str THEN k_log_level_alert
            WHEN k_log_level_critical_str THEN k_log_level_critical
            WHEN k_log_level_error_str THEN k_log_level_error
            WHEN k_log_level_warning_str THEN k_log_level_warning
            WHEN k_log_level_notice_str THEN k_log_level_notice
            WHEN k_log_level_info_str THEN k_log_level_info
            WHEN k_log_level_debug_str THEN k_log_level_debug
            ELSE -1
         END;

      RETURN l_returnvalue;
   END get_log_level;

   FUNCTION get_log_level_str (p_log_level IN NUMBER)
      RETURN VARCHAR2
   AS
      l_returnvalue   wdx_log.log_level%TYPE;
   BEGIN
      l_returnvalue :=
         CASE p_log_level
            WHEN k_log_level_emergency THEN k_log_level_emergency_str
            WHEN k_log_level_alert THEN k_log_level_alert_str
            WHEN k_log_level_critical THEN k_log_level_critical_str
            WHEN k_log_level_error THEN k_log_level_error_str
            WHEN k_log_level_warning THEN k_log_level_warning_str
            WHEN k_log_level_notice THEN k_log_level_notice_str
            WHEN k_log_level_info THEN k_log_level_info_str
            WHEN k_log_level_debug THEN k_log_level_debug_str
            ELSE to_char (p_log_level)
         END;

      RETURN l_returnvalue;
   END get_log_level_str;

   FUNCTION write_log (p_wdx_log_rec IN wdx_log%ROWTYPE)
      RETURN wdx_log.id%TYPE
   AS
      l_id   wdx_log.id%TYPE;
   BEGIN
      INSERT INTO wdx_log
         VALUES   p_wdx_log_rec
      RETURNING   id      INTO   l_id;

      RETURN l_id;
   END write_log;

   FUNCTION write
      RETURN NUMBER
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
      v_cgi_env   VARCHAR2 (32000);
      l_log_rt    wdx_log%ROWTYPE;
      l_id_log    wdx_log.id%TYPE;
   BEGIN
      IF g_log IS NOT NULL
      THEN
         --If DEBUG OR ERROR
         IF get_log_level IN (0, 1, 2, 3, 7) AND owa.num_cgi_vars IS NOT NULL
         THEN
            g_log       :=
               g_log || chr (10) || to_char (systimestamp, 'dd-mm-yyyy hh24:mi:ss.ff') || ' debug CGI ENV ' || chr (10);

            FOR i IN 1 .. owa.num_cgi_vars
            LOOP
               g_log       := g_log || chr (9) || owa.cgi_var_name (i) || ' = ' || owa.cgi_var_val (i) || chr (10);
            END LOOP;
         END IF;

         l_log_rt.appid := dbx.g$appid;
         l_log_rt.session_id := session_.getid;
         l_log_rt.log_level := get_log_level_str (get_log_level ());
         l_log_rt.log_message := g_log;
         l_log_rt.created_by := user;
         l_log_rt.created_date := systimestamp;

         l_id_log    := write_log (l_log_rt);
         COMMIT;
      END IF;

      g_log       := NULL;

      RETURN l_id_log;
   EXCEPTION
      WHEN OTHERS
      THEN
         --Log never raise error
         BEGIN
            g_log       := g_log || chr (10) || sqlerrm || ' ' || dbms_utility.format_error_backtrace ();

            l_log_rt.appid := nvl (dbx.g$appid, 'NULL');
            l_log_rt.session_id := session_.getid;
            l_log_rt.log_level := get_log_level_str (1); --Alert
            l_log_rt.log_message := g_log;
            l_log_rt.created_by := user;
            l_log_rt.created_date := systimestamp;

            l_id_log    := write_log (l_log_rt);
            COMMIT;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;

         g_log       := NULL;
         RETURN l_id_log;
   END write;

   PROCEDURE write
   AS
      l_id_log   PLS_INTEGER;
   BEGIN
      l_id_log    := write;
   END write;

   PROCEDURE emergency (p_message IN CLOB)
   AS
      oname           VARCHAR2 (100);
      pname           VARCHAR2 (100);
      lnumb           VARCHAR2 (100);
      callr           VARCHAR2 (100);
      who_called_me   VARCHAR2 (400);
   BEGIN
      owa_util.who_called_me (oname
                            , pname
                            , lnumb
                            , callr);
      who_called_me := oname || '.' || pname || ':' || lnumb;

      IF k_log_level_emergency <= get_log_level ()
      THEN
         g_log       :=
               g_log
            || chr (10)
            || to_char (systimestamp, 'dd-mm-yyyy hh24:mi:ss.ff')
            || ' '
            || k_log_level_emergency_str
            || chr (9)
            || who_called_me
            || ' '
            || p_message;
      END IF;
   END emergency;

   PROCEDURE alert (p_message IN CLOB)
   AS
      oname           VARCHAR2 (100);
      pname           VARCHAR2 (100);
      lnumb           VARCHAR2 (100);
      callr           VARCHAR2 (100);
      who_called_me   VARCHAR2 (400);
   BEGIN
      owa_util.who_called_me (oname
                            , pname
                            , lnumb
                            , callr);
      who_called_me := oname || '.' || pname || ':' || lnumb;

      IF k_log_level_alert <= get_log_level ()
      THEN
         g_log       :=
               g_log
            || chr (10)
            || to_char (systimestamp, 'dd-mm-yyyy hh24:mi:ss.ff')
            || ' '
            || k_log_level_alert_str
            || chr (9)
            || who_called_me
            || ' '
            || p_message;
      END IF;
   END alert;

   PROCEDURE critical (p_message IN CLOB)
   AS
      oname           VARCHAR2 (100);
      pname           VARCHAR2 (100);
      lnumb           VARCHAR2 (100);
      callr           VARCHAR2 (100);
      who_called_me   VARCHAR2 (400);
   BEGIN
      owa_util.who_called_me (oname
                            , pname
                            , lnumb
                            , callr);
      who_called_me := oname || '.' || pname || ':' || lnumb;

      IF k_log_level_critical <= get_log_level ()
      THEN
         g_log       :=
               g_log
            || chr (10)
            || to_char (systimestamp, 'dd-mm-yyyy hh24:mi:ss.ff')
            || ' '
            || k_log_level_critical_str
            || chr (9)
            || who_called_me
            || ' '
            || p_message;
      END IF;
   END critical;

   PROCEDURE error (p_message IN CLOB)
   AS
      oname           VARCHAR2 (100);
      pname           VARCHAR2 (100);
      lnumb           VARCHAR2 (100);
      callr           VARCHAR2 (100);
      who_called_me   VARCHAR2 (400);
   BEGIN
      owa_util.who_called_me (oname
                            , pname
                            , lnumb
                            , callr);
      who_called_me := oname || '.' || pname || ':' || lnumb;

      IF k_log_level_error <= get_log_level ()
      THEN
         g_log       :=
               g_log
            || chr (10)
            || to_char (systimestamp, 'dd-mm-yyyy hh24:mi:ss.ff')
            || ' '
            || k_log_level_error_str
            || chr (9)
            || who_called_me
            || ' '
            || p_message;
      END IF;
   END error;

   PROCEDURE warning (p_message IN CLOB)
   AS
      oname           VARCHAR2 (100);
      pname           VARCHAR2 (100);
      lnumb           VARCHAR2 (100);
      callr           VARCHAR2 (100);
      who_called_me   VARCHAR2 (400);
   BEGIN
      owa_util.who_called_me (oname
                            , pname
                            , lnumb
                            , callr);
      who_called_me := oname || '.' || pname || ':' || lnumb;

      IF k_log_level_warning <= get_log_level ()
      THEN
         g_log       :=
               g_log
            || chr (10)
            || to_char (systimestamp, 'dd-mm-yyyy hh24:mi:ss.ff')
            || ' '
            || k_log_level_warning_str
            || chr (9)
            || who_called_me
            || ' '
            || p_message;
      END IF;
   END warning;

   PROCEDURE notice (p_message IN CLOB)
   AS
      oname           VARCHAR2 (100);
      pname           VARCHAR2 (100);
      lnumb           VARCHAR2 (100);
      callr           VARCHAR2 (100);
      who_called_me   VARCHAR2 (400);
   BEGIN
      owa_util.who_called_me (oname
                            , pname
                            , lnumb
                            , callr);
      who_called_me := oname || '.' || pname || ':' || lnumb;

      IF k_log_level_notice <= get_log_level ()
      THEN
         g_log       :=
               g_log
            || chr (10)
            || to_char (systimestamp, 'dd-mm-yyyy hh24:mi:ss.ff')
            || ' '
            || k_log_level_notice_str
            || chr (9)
            || who_called_me
            || ' '
            || p_message;
      END IF;
   END notice;

   PROCEDURE info (p_message IN CLOB)
   AS
      oname           VARCHAR2 (100);
      pname           VARCHAR2 (100);
      lnumb           VARCHAR2 (100);
      callr           VARCHAR2 (100);
      who_called_me   VARCHAR2 (400);
   BEGIN
      owa_util.who_called_me (oname
                            , pname
                            , lnumb
                            , callr);
      who_called_me := oname || '.' || pname || ':' || lnumb;

      IF k_log_level_info <= get_log_level ()
      THEN
         g_log       :=
               g_log
            || chr (10)
            || to_char (systimestamp, 'dd-mm-yyyy hh24:mi:ss.ff')
            || ' '
            || k_log_level_info_str
            || chr (9)
            || who_called_me
            || ' '
            || p_message;
      END IF;
   END info;

   PROCEDURE debug (p_message IN CLOB)
   AS
      oname           VARCHAR2 (100);
      pname           VARCHAR2 (100);
      lnumb           VARCHAR2 (100);
      callr           VARCHAR2 (100);
      who_called_me   VARCHAR2 (400);
   BEGIN
      owa_util.who_called_me (oname
                            , pname
                            , lnumb
                            , callr);
      who_called_me := oname || '.' || pname || ':' || lnumb;

      IF k_log_level_debug <= get_log_level ()
      THEN
         g_log       :=
               g_log
            || chr (10)
            || to_char (systimestamp, 'dd-mm-yyyy hh24:mi:ss.ff')
            || ' '
            || k_log_level_debug_str
            || chr (9)
            || who_called_me
            || ' '
            || p_message;
      END IF;
   END debug;
END log_;
/