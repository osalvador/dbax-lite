/* Formatted on 30/01/2017 17:18:07 (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE BODY dbax_teplsql
AS
   PROCEDURE output_clob (p_clob IN CLOB)
   IS
      v_offset       PLS_INTEGER := 1;
      v_new_line     PLS_INTEGER;
      v_chunk_size   PLS_INTEGER := 32767;
   BEGIN
      LOOP
         EXIT WHEN v_offset > DBMS_LOB.getlength (p_clob);

         v_new_line  := INSTR (DBMS_LOB.SUBSTR (p_clob, v_chunk_size, v_offset), CHR (10));

         IF v_new_line > 0
         THEN
            DBMS_OUTPUT.put_line (DBMS_LOB.SUBSTR (p_clob, v_new_line - 1, v_offset));
            v_offset    := v_offset + v_new_line;
         ELSE
            DBMS_OUTPUT.put_line (DBMS_LOB.SUBSTR (p_clob, v_chunk_size, v_offset));
            v_offset    := v_offset + v_chunk_size;
         END IF;
      END LOOP;
   END output_clob;

   /*This function fetch de OWA page to CLOB*/
   FUNCTION dump_owa_page
      RETURN CLOB
   AS
      l_thepage   HTP.htbuf_arr;
      l_lines     NUMBER DEFAULT 99999999 ;
      l_found     BOOLEAN := FALSE;

      l_clob      CLOB;
   --l_string    varchar2(256);
   BEGIN
      OWA.get_page (l_thepage, l_lines);
      DBMS_LOB.createtemporary (l_clob, TRUE);

      --The interpreter prints a comment thats indicates start of HTML content.
      --Delete this comment from page and the rest text of buffer
      FOR i IN 1 .. l_lines
      LOOP
         IF NOT l_found
         THEN
            l_found     := l_thepage (i) LIKE '%<!%';


            IF l_found
            THEN
               l_thepage (i) := REPLACE (l_thepage (i), '<!-- DBAX interpreter -->');
            END IF;
         END IF;

         IF l_found
         THEN
            IF LENGTH (l_thepage (i)) > 0
            THEN
               DBMS_LOB.writeappend (l_clob, LENGTH (l_thepage (i)), l_thepage (i));
            END IF;
         END IF;
      END LOOP;


      RETURN l_clob;
   END dump_owa_page;

   PROCEDURE string_literal_too_long (p_template IN OUT NOCOPY CLOB)
   AS
      l_tmp      CLOB;
      l_result   CLOB;
      i          PLS_INTEGER := 0;
      l_start    PLS_INTEGER := 0;
      l_end      PLS_INTEGER := 0;

      FUNCTION split_clob (p_clob IN CLOB)
         RETURN CLOB
      AS
         l_clob       CLOB;
         l_buffer     VARCHAR2 (32767);
         l_amount     PLS_INTEGER := 32000;
         l_clob_len   PLS_INTEGER := 0;
         l_pos        INTEGER := 1;
      BEGIN
         DBMS_LOB.createtemporary (l_clob, FALSE, DBMS_LOB.call);
         l_clob_len  := DBMS_LOB.getlength (p_clob);

         WHILE l_pos < l_clob_len
         LOOP
            DBMS_LOB.read (p_clob
                         , l_amount
                         , l_pos
                         , l_buffer);

            IF l_pos = 1
            THEN
               l_clob      := l_buffer;
            ELSE
               l_clob      := l_clob || '~'');DBAX_tePLSQL.p(q''~' || l_buffer;
            END IF;

            l_pos       := l_pos + l_amount;
         END LOOP;

         l_clob      := 'DBAX_tePLSQL.p(q''~' || l_clob || '~'');';

         RETURN l_clob;
         DBMS_LOB.freetemporary (l_clob);
      END;
   BEGIN
      LOOP
         i           := i + 1;
         l_tmp       :=
            REGEXP_SUBSTR (p_template
                         , q'@DBAX_tePLSQL.p\(q\'\~(.*?|\s*)\~\'\)\;@'
                         , 1
                         , i
                         , 'inm'
                         , 1);

         IF LENGTH (l_tmp) > 32000
         THEN
            --Split l_tmp into 32000 strings
            l_tmp       := split_clob (l_tmp);

            --Start and End of the expression
            l_start     :=
               REGEXP_INSTR (p_template
                           , q'@DBAX_tePLSQL.p\(q\'\~(.*?|\s*)\~\'\)\;@'
                           , 1
                           , i
                           , 0
                           , 'inm');

            l_end       :=
               REGEXP_INSTR (p_template
                           , q'@DBAX_tePLSQL.p\(q\'\~(.*?|\s*)\~\'\)\;@'
                           , 1
                           , i
                           , 1
                           , 'inm');

            --concatenate result template into first template
            IF (NVL (l_start, 0) > 0)
            THEN
               DBMS_LOB.createtemporary (l_result, FALSE, DBMS_LOB.call);

               IF l_start > 1
               THEN
                  DBMS_LOB.COPY (l_result
                               , p_template
                               , l_start - 1
                               , 1
                               , 1);
               END IF;

               IF LENGTH (l_tmp) > 0
               THEN
                  DBMS_LOB.COPY (l_result
                               , l_tmp
                               , DBMS_LOB.getlength (l_tmp)
                               , DBMS_LOB.getlength (l_result) + 1
                               , 1);
               END IF;

               --Adding the rest of the source to the result variable
               IF l_end <= DBMS_LOB.getlength (p_template)
               THEN
                  DBMS_LOB.COPY (l_result
                               , p_template
                               , DBMS_LOB.getlength (p_template)
                               , DBMS_LOB.getlength (l_result) + 1
                               , l_end);
               END IF;
            END IF;

            p_template  := l_result;

            DBMS_LOB.freetemporary (l_result);
         END IF;

         EXIT WHEN LENGTH (l_tmp) = 0;
      END LOOP;
   END string_literal_too_long;


   /**
   * Receives the template directive key-value data separated by commas
   * and assign this key-values to the associative array
   *
   * @param  p_directive      the key-value data template directive
   * @param  p_vars           the associative array
   */
   /*  PROCEDURE set_template_directive (p_directive IN CLOB, p_vars IN OUT NOCOPY t_assoc_array)
     AS
        l_key         VARCHAR2 (256);
        l_value       VARCHAR2 (256);
        l_directive   VARCHAR2 (32767);
     BEGIN
        l_directive := REGEXP_REPLACE (p_directive, '\s', '');

        FOR c1 IN (    SELECT   REGEXP_REPLACE (REGEXP_SUBSTR (l_directive
                                                             , '[^,]+'
                                                             , 1
                                                             , LEVEL), '\s', '')
                                   text
                         FROM   DUAL
                   CONNECT BY   REGEXP_SUBSTR (l_directive
                                             , '[^,]+'
                                             , 1
                                             , LEVEL) IS NOT NULL)
        LOOP
           l_key       := SUBSTR (c1.text, 1, INSTR (c1.text, '=') - 1);
           l_value     := SUBSTR (c1.text, INSTR (c1.text, '=') + 1);
           p_vars ('template_' || l_key) := l_value;
        END LOOP;
     END set_template_directive;/*/


   PROCEDURE save_compiled_template (p_template_name       IN VARCHAR2
                                   , p_appid               IN VARCHAR2 DEFAULT NULL
                                   , p_template            IN CLOB
                                   , p_compiled_template   IN CLOB)
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;      
   BEGIN
     /* BEGIN
         l_view_rt   := tapi_wdx_views.rt (NVL (p_appid, dbx.g$appid), p_template_name);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_view_rt   := NULL;
      END;

      --insert or update
      IF l_view_rt.appid IS NULL
      THEN
         --INSERT
         l_view_rt.appid := NVL (p_appid, dbx.g$appid);
         l_view_rt.name := p_template_name;
         l_view_rt.source := p_template;
         l_view_rt.compiled_source := p_compiled_template;
         l_view_rt.visible := 'Y';

         tapi_wdx_views.ins (l_view_rt);
      ELSE
         --UPDATE
         l_view_rt.source := p_template;
         l_view_rt.compiled_source := p_compiled_template;
         l_view_rt.modified_date := SYSDATE;

         tapi_wdx_views.upd (l_view_rt, TRUE);
      END IF;*/

      -- TODO: Better a MERGE
      BEGIN
         INSERT INTO wdx_views (appid
                              , name
                              , source
                              , compiled_source
                              , visible
                              , created_by
                              , modified_by)
           VALUES   (NVL (p_appid, dbx.g$appid)
                   , p_template_name
                   , p_template
                   , p_compiled_template
                   , 'Y'
                   , NVL (dbx.g$username, USER)
                   , NVL (dbx.g$username, USER));
      EXCEPTION
         WHEN DUP_VAL_ON_INDEX
         THEN
            UPDATE   wdx_views
               SET   source       = p_template
                   , compiled_source = p_compiled_template
                   , modified_date = SYSDATE
                   , modified_by  = NVL (dbx.g$username, USER)
             WHERE   appid = NVL (p_appid, dbx.g$appid) AND name = p_template_name;
      END;


      COMMIT;
   END save_compiled_template;



   FUNCTION include (p_template_name IN VARCHAR2, p_appid IN VARCHAR2 DEFAULT NULL )
      RETURN CLOB
   AS
      l_template   CLOB;
   BEGIN
      BEGIN
         SELECT   source
           INTO   l_template
           FROM   wdx_views
          WHERE   name = p_template_name AND appid = NVL (p_appid, dbx.g$appid);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            --dbax_log.trace ('INCLUDE Function, NO_DATA_FOUND');
            l_template  := EMPTY_CLOB ();

            --Si no se encuentra el template se ejecuta
            EXECUTE IMMEDIATE 'BEGIN :l_val := ' || p_template_name || '; END;' USING OUT l_template;
      END;

      RETURN l_template;
   END include;


   FUNCTION include_compiled (p_template_name IN VARCHAR2, p_appid IN VARCHAR2 DEFAULT NULL )
      RETURN CLOB
   AS
      l_template   CLOB := EMPTY_CLOB ();
   BEGIN
      BEGIN
         SELECT   compiled_source
           INTO   l_template
           FROM   wdx_views
          WHERE   name = p_template_name AND appid = NVL (p_appid, dbx.g$appid);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_template  := EMPTY_CLOB ();
      END;

      RETURN l_template;
   END include_compiled;



   FUNCTION template_has_changed (p_template_name IN VARCHAR2, p_appid IN VARCHAR2 DEFAULT NULL , p_template IN CLOB)
      RETURN BOOLEAN
   AS
      l_compare   PLS_INTEGER;
   BEGIN
      BEGIN
         SELECT   DBMS_LOB.compare (source, p_template)
           INTO   l_compare
           FROM   wdx_views
          WHERE   name = p_template_name AND appid = NVL (p_appid, dbx.g$appid);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            l_compare   := 1;
      END;
   
      -- 0 = templates are the same
      IF l_compare != 0
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END template_has_changed;

   /**
   * Bind associative array variables in the template
   *
   * @param  p_template      the template
   * @param  p_vars        the associative array
   */
   PROCEDURE bind_vars (p_template IN OUT NOCOPY CLOB, p_vars IN t_assoc_array)
   AS
      l_key   VARCHAR2 (256);
   BEGIN
      IF p_vars.COUNT () <> 0
      THEN
         l_key       := p_vars.FIRST;

         LOOP
            EXIT WHEN l_key IS NULL;
            p_template  := REPLACE (p_template, '${' || l_key || '}', TO_CLOB (p_vars (l_key)));
            l_key       := p_vars.NEXT (l_key);
         END LOOP;
      END IF;
   END bind_vars;

   PROCEDURE bind_vars (p_template IN OUT NOCOPY CLOB, p_vars IN dbx.g_assoc_array)
   AS
      l_key   VARCHAR2 (256);
   BEGIN
      IF p_vars.COUNT () <> 0
      THEN
         l_key       := p_vars.FIRST;

         LOOP
            EXIT WHEN l_key IS NULL;
            p_template  := REPLACE (p_template, '${' || l_key || '}', TO_CLOB (p_vars (l_key)));
            l_key       := p_vars.NEXT (l_key);
         END LOOP;
      END IF;
   END bind_vars;

   /**
   * Parse template marks
   *
   * @param  p_template      the template
   * @param  p_vars        the associative array
   */
   PROCEDURE parse (p_template IN CLOB, p_vars IN t_assoc_array DEFAULT null_assoc_array )
   AS
      l_open_count      PLS_INTEGER;
      l_close_count     PLS_INTEGER;
      l_template_name   VARCHAR2 (300);
   BEGIN
      l_open_count := regexp_count (p_template, '<\%');
      l_close_count := regexp_count (p_template, '\%>');

      IF l_open_count <> l_close_count
      THEN
         IF p_vars.EXISTS ('template_name')
         THEN
            l_template_name := ' ' || p_vars ('template_name');
         END IF;

         raise_application_error (-20001
                                ,    '##Parser Exception processing the template'
                                  || l_template_name
                                  || '. One or more tags (<% %>) are not closed: '
                                  || l_open_count
                                  || ' <> '
                                  || l_close_count
                                  || CHR (10));
      END IF;

      l_open_count := regexp_count (p_template, '<\?dbax');
      l_close_count := regexp_count (p_template, '\?>');

      IF l_open_count <> l_close_count
      THEN
         IF p_vars.EXISTS ('template_name')
         THEN
            l_template_name := ' ' || p_vars ('template_name');
         END IF;

         raise_application_error (-20001
                                ,    '##Parser Exception processing the template'
                                  || l_template_name
                                  || '. One or more tags (<?dbax ?>) are not closed: '
                                  || l_open_count
                                  || ' <> '
                                  || l_close_count
                                  || CHR (10));
      END IF;
   END parse;

   /**
   * Interprets the received template and convert it into executable plsql
   *
   * @param  p_template    the template
   * @param  p_vars        the associative array
   */
   PROCEDURE interpret (p_template IN OUT NOCOPY CLOB, p_vars IN t_assoc_array DEFAULT null_assoc_array )
   AS
      l_vars      t_assoc_array := p_vars;
      l_declare   CLOB;
      l_tmp       CLOB;
      i           PLS_INTEGER := 0;
   BEGIN
      --Parse <% %> tags
      parse (p_template, l_vars);

      --Dos to Unix
      p_template  :=
         REGEXP_REPLACE (p_template
                       , CHR (13) || CHR (10)
                       , CHR (10)
                       , 1
                       , 0
                       , 'nm');

      --Delete all template directives
      p_template  :=
         REGEXP_REPLACE (p_template
                       , '<%@ template([^%>].*?)\s*%>[[:blank:]]*\s$?'
                       , ''
                       , 1
                       , 0
                       , 'n');

      --Escaped chars except \\n
      p_template  :=
         REGEXP_REPLACE (p_template
                       , '\\\\([^n])'
                       , '~'');DBAX_tePLSQL.p(q''[\1]'');DBAX_tePLSQL.p(q''~'
                       , 1
                       , 0
                       , 'n');


      --New lines.
      p_template  :=
         REGEXP_REPLACE (p_template
                       , '(\\\\n)'
                       , CHR (10) --|| '~'');DBAX_tePLSQL.p(q''~'
                       , 1
                       , 0
                       , 'n');


      --Delete the line breaks for lines ending in %>[blanks]CHR(10)
      p_template  :=
         REGEXP_REPLACE (p_template
                       , '(%>[[:blank:]]*?' || CHR (10) || ')'
                       , '%>'
                       , 1
                       , 0
                       , '');

      --Delete new lines with !\n
      p_template  :=
         REGEXP_REPLACE (p_template
                       , '([[:blank:]]*\!\\n[[:blank:]]*' || CHR (10) || '?[[:blank:]]*)'
                       , ''
                       , 1
                       , 0
                       , 'm');

      -- Delete all blanks before <% in the beginning of each line
      p_template  :=
         REGEXP_REPLACE (p_template
                       , '(^[[:blank:]]*<%)'
                       , '<%'
                       , 1
                       , 0
                       , 'm');

      --Merge all declaration blocks into a single block
      l_tmp       := NULL;

      LOOP
         i           := i + 1;
         l_tmp       :=
            REGEXP_SUBSTR (p_template
                         , '<%!([^%>].*?)%>'
                         , 1
                         , i
                         , 'n'
                         , 1);
         l_declare   := l_declare || l_tmp;
         EXIT WHEN LENGTH (l_tmp) = 0;
      END LOOP;

      --Delete declaration blocks from template
      p_template  :=
         REGEXP_REPLACE (p_template
                       , '<%!([^%>].*?)%>'
                       , ''
                       , 1
                       , 0
                       , 'n');

      --Expresison directive
      p_template  :=
         REGEXP_REPLACE (p_template
                       , '<%=([^%>].*?)%>'
                       , '~'');DBAX_tePLSQL.p(\1);DBAX_tePLSQL.p(q''~'
                       , 1
                       , 0
                       , 'n');


      --Variables
      /*p_template  :=
         REGEXP_REPLACE (p_template
                       , '\$\{(\S*)\}'
                       , '~'');DBAX_tePLSQL.p(dbax_utils.get(dbax_core.g$view,''\1''));DBAX_tePLSQL.p(q''~'
                       , 1
                       , 0
                       , 'n');*/


      p_template  := 'DECLARE ' || l_declare || ' BEGIN DBAX_tePLSQL.p(q''~' || p_template || '~''); END;';
   END interpret;

   /**
   * Search for include directives, includes and evaluates the specified templates.
   * Nested include are allowed
   *
   * @param  p_template    the template
   * @param  p_vars        the associative array
   */
   PROCEDURE get_includes (p_template   IN OUT NOCOPY CLOB
                         , p_vars       IN            t_assoc_array DEFAULT null_assoc_array
                         , p_appid      IN            VARCHAR2)
   AS
      l_tmp               CLOB;
      l_result            CLOB;

      l_str_tmp           VARCHAR2 (64);

      TYPE array_t IS TABLE OF VARCHAR2 (64);

      l_strig_tt          array_t;
      l_object_name       VARCHAR2 (64);
      l_template_name     VARCHAR2 (64);
      l_object_type       VARCHAR2 (64);
      l_schema            VARCHAR2 (64);

      l_start             PLS_INTEGER := 0;
      l_end               PLS_INTEGER := 0;
      l_number_includes   PLS_INTEGER := 0;
   BEGIN
      /*
      --Pseudocode
      while there includes
      do
          get include
          interpret template
          concatenate result template into p_template
      done
      */
      WHILE REGEXP_INSTR (p_template, '<%@\s*include\((.*?)\)\s*%>') <> 0
      LOOP
         --Init
         l_str_tmp   := NULL;
         l_object_name := NULL;
         l_template_name := NULL;
         l_object_type := NULL;
         l_schema    := NULL;
         l_tmp       := NULL;
         l_start     := 0;
         l_end       := 0;

         --get include directive
         l_template_name :=
            TRIM (REGEXP_SUBSTR (p_template
                               , '<%@\s*include\((.*?)\)\s*%>'
                               , 1
                               , 1
                               , 'n'
                               , 1));

         IF LENGTH (l_template_name) > 0
         THEN
            --get included template
            l_tmp       := include (l_template_name, p_appid);

            --Start and End of the expression
            l_start     :=
               REGEXP_INSTR (p_template
                           , '<%@\s*include\((.*?)\)\s*%>'
                           , 1
                           , 1
                           , 0
                           , 'n');

            l_end       :=
               REGEXP_INSTR (p_template
                           , '<%@\s*include\((.*?)\)\s*%>'
                           , 1
                           , 1
                           , 1
                           , 'n');

            --concatenate result template into first template
            IF (NVL (l_start, 0) > 0)
            THEN
               DBMS_LOB.createtemporary (l_result, FALSE, DBMS_LOB.call);

               IF l_start > 1
               THEN
                  DBMS_LOB.COPY (l_result
                               , p_template
                               , l_start - 1
                               , 1
                               , 1);
               END IF;

               IF LENGTH (l_tmp) > 0
               THEN
                  DBMS_LOB.COPY (l_result
                               , l_tmp
                               , DBMS_LOB.getlength (l_tmp)
                               , DBMS_LOB.getlength (l_result) + 1
                               , 1);
               END IF;

               --Adding the rest of the source to the result variable
               IF l_end <= DBMS_LOB.getlength (p_template)
               THEN
                  DBMS_LOB.COPY (l_result
                               , p_template
                               , DBMS_LOB.getlength (p_template)
                               , DBMS_LOB.getlength (l_result) + 1
                               , l_end);
               END IF;
            END IF;

            p_template  := l_result;

            DBMS_LOB.freetemporary (l_result);
         END IF;

         l_number_includes := l_number_includes + 1;

         IF l_number_includes >= 50
         THEN
            raise_application_error (-20001, 'Too much include directive in the template, Recursive include?');
         END IF;
      END LOOP;


      --Backward compatibility
      WHILE REGEXP_INSTR (p_template, q'[<\?dbax\s*dbax_core\.include\s*\(\s*'(.*?)'\s*\)\s*;\s*\?>]') <> 0
      LOOP
         --Init
         l_str_tmp   := NULL;
         l_object_name := NULL;
         l_template_name := NULL;
         l_object_type := NULL;
         l_schema    := NULL;
         l_tmp       := NULL;
         l_start     := 0;
         l_end       := 0;

         --get include directive
         l_template_name :=
            TRIM (REGEXP_SUBSTR (p_template
                               , q'[<\?dbax\s*dbax_core\.include\s*\(\s*'(.*?)'\s*\)\s*;\s*\?>]'
                               , 1
                               , 1
                               , 'n'
                               , 1));

         IF LENGTH (l_template_name) > 0
         THEN
            --get included template
            l_tmp       := include (l_template_name, p_appid);

            --Start and End of the expression
            l_start     :=
               REGEXP_INSTR (p_template
                           , q'[<\?dbax\s*dbax_core\.include\s*\(\s*'(.*?)'\s*\)\s*;\s*\?>]'
                           , 1
                           , 1
                           , 0
                           , 'n');

            l_end       :=
               REGEXP_INSTR (p_template
                           , q'[<\?dbax\s*dbax_core\.include\s*\(\s*'(.*?)'\s*\)\s*;\s*\?>]'
                           , 1
                           , 1
                           , 1
                           , 'n');

            --concatenate result template into first template
            IF (NVL (l_start, 0) > 0)
            THEN
               DBMS_LOB.createtemporary (l_result, FALSE, DBMS_LOB.call);

               IF l_start > 1
               THEN
                  DBMS_LOB.COPY (l_result
                               , p_template
                               , l_start - 1
                               , 1
                               , 1);
               END IF;

               IF LENGTH (l_tmp) > 0
               THEN
                  DBMS_LOB.COPY (l_result
                               , l_tmp
                               , DBMS_LOB.getlength (l_tmp)
                               , DBMS_LOB.getlength (l_result) + 1
                               , 1);
               END IF;

               --Adding the rest of the source to the result variable
               IF l_end <= DBMS_LOB.getlength (p_template)
               THEN
                  DBMS_LOB.COPY (l_result
                               , p_template
                               , DBMS_LOB.getlength (p_template)
                               , DBMS_LOB.getlength (l_result) + 1
                               , l_end);
               END IF;
            END IF;

            p_template  := l_result;

            DBMS_LOB.freetemporary (l_result);
         END IF;

         l_number_includes := l_number_includes + 1;

         IF l_number_includes >= 50
         THEN
            raise_application_error (-20001, 'Too much include directive in the template, Recursive include?');
         END IF;
      END LOOP;
   END get_includes;

   PROCEDURE PRINT (p_data IN CLOB)
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
   END PRINT;

   PROCEDURE PRINT (p_data IN VARCHAR2)
   AS
   BEGIN
      HTP.prn (p_data);
   END PRINT;

   PROCEDURE PRINT (p_data IN NUMBER)
   AS
   BEGIN
      HTP.prn (TO_CHAR (p_data));
   END PRINT;

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

   FUNCTION compile (p_template_name IN VARCHAR2, p_appid IN VARCHAR2, p_error_template OUT NOCOPY CLOB)
      RETURN CLOB
   AS
      l_template   CLOB;
      v_cur_hdl    INTEGER;
   BEGIN
      --Get template
      l_template  := include (p_template_name, p_appid);

      --dbax_log.trace ('Compile Function. p_template_name:' || p_template_name);
      --dbax_log.trace ('Compile Function. l_template:' || l_template);
      --Parse <% %> tags
      parse (l_template);

      --Get Includes
      get_includes (p_template => l_template, p_appid => p_appid);

      --Interpret the template
      interpret (l_template);

      --Code blocks directive
      l_template  :=
         REGEXP_REPLACE (l_template
                       , '<%([^%>].*?)%>'
                       , '~''); \1 DBAX_tePLSQL.p(q''~'
                       , 1
                       , 0
                       , 'n');

      l_template  :=
         REGEXP_REPLACE (l_template
                       , '<\?dbax([^\?>].*?)\?>'
                       , '~''); \1 DBAX_tePLSQL.p(q''~'
                       , 1
                       , 0
                       , 'n');

      --Delete all null code blocks
      l_template  :=
         REGEXP_REPLACE (l_template
                       , q'@DBAX_tePLSQL.p\(q\'\~\~\'\)\;@'
                       , ''
                       , 1
                       , 0
                       , 'n');

      --Avoid PLS-00172: string literal too long
      string_literal_too_long (l_template);

      v_cur_hdl   := DBMS_SQL.open_cursor;
      DBMS_SQL.parse (v_cur_hdl, l_template, DBMS_SQL.native);
      DBMS_SQL.close_cursor (v_cur_hdl);

      --minified html
      --l_template := REGEXP_REPLACE(l_template, '[ ]{2,}',' ');
      --l_template := REPLACE(l_template, CHR(10));

      RETURN l_template;
   EXCEPTION
      WHEN OTHERS
      THEN
         --Return error
         p_error_template := p_error_template || ('### tePLSQL Compile Error ###');
         p_error_template := p_error_template || (CHR (10));
         p_error_template := p_error_template || (SQLERRM || ' ' || DBMS_UTILITY.format_error_backtrace ());
         p_error_template := p_error_template || (CHR (10));
         p_error_template :=
            p_error_template
            || ('### Processing template ' || p_template_name || ' from ' || p_appid || ' application ###');
         p_error_template := p_error_template || (CHR (10));
         p_error_template := p_error_template || (l_template);
         --dbax_log.error (p_error_template);
         RAISE;
   END compile;

   FUNCTION compile (p_template IN CLOB, p_appid IN VARCHAR2, p_error_template OUT NOCOPY CLOB)
      RETURN CLOB
   AS
      l_template   CLOB;
      v_cur_hdl    INTEGER;
   BEGIN
      --Get template
      l_template  := p_template;

      --dbax_log.trace ('Compile Function. l_template:' || l_template);

      --Parse <% %> tags
      parse (l_template);

      --Get Includes
      get_includes (p_template => l_template, p_appid => p_appid);

      --Interpret the template
      interpret (l_template);

      --Code blocks directive
      l_template  :=
         REGEXP_REPLACE (l_template
                       , '<%([^%>].*?)%>'
                       , '~''); \1 DBAX_tePLSQL.p(q''~'
                       , 1
                       , 0
                       , 'n');

      l_template  :=
         REGEXP_REPLACE (l_template
                       , '<\?dbax([^\?>].*?)\?>'
                       , '~''); \1 DBAX_tePLSQL.p(q''~'
                       , 1
                       , 0
                       , 'n');

      --Delete all null code blocks
      l_template  :=
         REGEXP_REPLACE (l_template
                       , q'@DBAX_tePLSQL.p\(q\'\~\~\'\)\;@'
                       , ''
                       , 1
                       , 0
                       , 'n');

      --Avoid PLS-00172: string literal too long
      string_literal_too_long (l_template);

      v_cur_hdl   := DBMS_SQL.open_cursor;
      DBMS_SQL.parse (v_cur_hdl, l_template, DBMS_SQL.native);
      DBMS_SQL.close_cursor (v_cur_hdl);

      --minified html
      --l_template := REGEXP_REPLACE(l_template, '[ ]{2,}',' ');
      --l_template := REPLACE(l_template, CHR(10));

      RETURN l_template;
   EXCEPTION
      WHEN OTHERS
      THEN
         --Return error
         p_error_template := p_error_template || ('### tePLSQL Compile Error ###');
         p_error_template := p_error_template || (CHR (10));
         p_error_template := p_error_template || (SQLERRM || ' ' || DBMS_UTILITY.format_error_backtrace ());
         p_error_template := p_error_template || (CHR (10));
         p_error_template := p_error_template || ('### Processing template ');
         p_error_template := p_error_template || (CHR (10));
         p_error_template := p_error_template || (l_template);
         --dbax_log.error (p_error_template);
         RAISE;
   END compile;


  /* PROCEDURE compile_all (p_appid IN VARCHAR2, p_error_template OUT NOCOPY CLOB)
   AS
      l_compiled_view    CLOB;
      l_error_template   CLOB;
      l_view_rt          tapi_wdx_views.wdx_views_rt;

      l_actual_appid     VARCHAR2 (50) := dbx.g$appid;
   BEGIN
      FOR c1 IN (SELECT   * FROM table (tapi_wdx_views.tt (p_appid)))
      LOOP
         dbx.g$appid := c1.appid;

         l_compiled_view := dbax_teplsql.compile (c1.name, p_appid, l_error_template);

         l_view_rt   := c1;
         l_view_rt.compiled_source := l_compiled_view;
         l_view_rt.modified_date := SYSDATE;
         tapi_wdx_views.upd (l_view_rt);
      END LOOP;

      dbx.g$appid := l_actual_appid;
   EXCEPTION
      WHEN OTHERS
      THEN
         dbx.g$appid := l_actual_appid;
         p_error_template := l_error_template;
         --dbax_log.error (p_error_template);
         RAISE;
   END compile_all;*/

   /*PROCEDURE compile_dependencies (p_template_name IN VARCHAR2, p_appid IN VARCHAR2, p_error_template OUT NOCOPY CLOB)
   AS
      l_compiled_view   CLOB;
      l_view_rt         tapi_wdx_views.wdx_views_rt;
   BEGIN
      FOR c1 IN (SELECT   *
                   FROM   wdx_views
                  WHERE   (REGEXP_INSTR (source
                                       , '<%@\s*include\(\s*' || p_template_name || '\s*\)\s*%>'
                                       , 1
                                       , 1
                                       , 0
                                       , 'i') <> 0
                           OR REGEXP_INSTR (source
                                          ,    '<\?dbax\s*dbax_core\.include\s*\(\s*'''
                                            || p_template_name
                                            || '''\s*\)\s*;\s*\?>'
                                          , 1
                                          , 1
                                          , 0
                                          , 'i') <> 0)
                          AND appid = p_appid)
      LOOP
         l_compiled_view := dbax_teplsql.compile (c1.name, p_appid, p_error_template);

         l_view_rt.appid := c1.appid;
         l_view_rt.name := c1.name;
         l_view_rt.compiled_source := l_compiled_view;
         l_view_rt.modified_date := SYSDATE;
         tapi_wdx_views.upd (l_view_rt, TRUE);
      END LOOP;
   END compile_dependencies;*/


   PROCEDURE purge_compiled (p_appid IN VARCHAR2)
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      UPDATE   wdx_views a
         SET   compiled_source = NULL
       WHERE   UPPER (appid) = UPPER (p_appid);

      COMMIT;
   END purge_compiled;


   PROCEDURE execute (p_template_name   IN VARCHAR2 DEFAULT NULL
                    , p_appid           IN VARCHAR2 DEFAULT NULL
                    , p_vars            IN t_assoc_array DEFAULT null_assoc_array
                    , p_template        IN CLOB DEFAULT NULL )
   AS
      l_template         CLOB;
      l_error_template   CLOB;
   BEGIN
      IF p_template_name IS NULL AND p_template IS NULL
      THEN
         RETURN;
      END IF;

      --Get template
      IF p_template_name IS NOT NULL AND p_template IS NOT NULL
      THEN
         --Si ambos parametros no son nulos se trata del model de dbax lite
         --Comprobar si el template ha cambiado para ejecutar solo el compilado

         IF template_has_changed (p_template_name => p_template_name, p_appid => p_appid, p_template => p_template)
         THEN
            -- sino compilarlo y ejecutarlo y guardarlo
            l_template  := compile (p_template, p_appid, l_error_template);

            -- Save compiled Template
            save_compiled_template (p_template_name => p_template_name
                                  , p_appid     => p_appid
                                  , p_template  => p_template
                                  , p_compiled_template => l_template);
         ELSE
            -- si el template está compilado ejecutar ese
            l_template  := include_compiled (p_template_name, p_appid);
         END IF;
      ELSIF p_template IS NULL
      THEN
         l_template  := include_compiled (p_template_name, p_appid);

         --If template is not compiled
         IF LENGTH (l_template) = 0 OR LENGTH (l_template) IS NULL
         THEN
            -- sino compilarlo y ejecutarlo y guardarlo
            l_template  := compile (p_template_name, p_appid, l_error_template);

            -- Save compiled Template
            save_compiled_template (p_template_name => p_template_name
                                  , p_appid     => p_appid
                                  , p_template  => p_template
                                  , p_compiled_template => l_template);
         END IF;
      ELSE
         --compile the template
         l_template  := compile (p_template, p_appid, l_error_template);
      END IF;

      --Bind the variables into template
      IF p_vars.COUNT () = 0
      THEN
         bind_vars (l_template, dbx.g$view);
      ELSE
         bind_vars (l_template, p_vars);
      END IF;

      --Null all variables not binded
      l_template  := REGEXP_REPLACE (l_template, '\$\{\S*\}', '');

      --DBMS_OUTPUT.put_line ('l_template = ' || l_template);

      --dbax_log.trace ('Executing this template:' || l_template);

      EXECUTE IMMEDIATE l_template;
   END execute;
END dbax_teplsql;
/