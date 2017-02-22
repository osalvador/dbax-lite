CREATE OR REPLACE PACKAGE BODY view_
AS
   /**************************
   * Global Private Variables
   ***************************/
   TYPE t_assoc_number
   IS
      TABLE OF NUMBER
         INDEX BY VARCHAR2 (255);

   TYPE t_assoc_date
   IS
      TABLE OF DATE
         INDEX BY VARCHAR2 (255);

   TYPE t_assoc_assoc
   IS
      TABLE OF dbx.g_assoc_array
         INDEX BY VARCHAR2 (255);

   /*TYPE t_assoc_varray
   IS
      TABLE OF dbx.g_varchar_array
         INDEX BY VARCHAR2 (255);*/

   TYPE t_assoc_clob
   IS
      TABLE OF clob
         INDEX BY VARCHAR2 (255);

   TYPE t_assoc_refcursor
   IS
      TABLE OF PLS_INTEGER
         INDEX BY VARCHAR2 (255);

   g_assoc_varchar     dbx.g_assoc_array;
   g_assoc_number      t_assoc_number;
   g_assoc_date        t_assoc_date;
   g_assoc_clob        t_assoc_clob;
   g_assoc_assoc       t_assoc_assoc;
   g_assoc_refcursor   t_assoc_refcursor;

   g_view_name         VARCHAR2 (300);


   PROCEDURE output_clob (p_clob IN CLOB)
   IS
      v_offset       PLS_INTEGER := 1;
      v_new_line     PLS_INTEGER;
      v_chunk_size   PLS_INTEGER := 32767;
   BEGIN
      LOOP
         EXIT WHEN v_offset > dbms_lob.getlength (p_clob);

         v_new_line  := instr (dbms_lob.substr (p_clob, v_chunk_size, v_offset), chr (10));

         IF v_new_line > 0
         THEN
            dbms_output.put_line (dbms_lob.substr (p_clob, v_new_line - 1, v_offset));
            v_offset    := v_offset + v_new_line;
         ELSE
            dbms_output.put_line (dbms_lob.substr (p_clob, v_chunk_size, v_offset));
            v_offset    := v_offset + v_chunk_size;
         END IF;
      END LOOP;
   END output_clob;

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
         dbms_lob.createtemporary (l_clob, FALSE, dbms_lob.call);
         l_clob_len  := dbms_lob.getlength (p_clob);

         WHILE l_pos < l_clob_len
         LOOP
            dbms_lob.read (p_clob
                         , l_amount
                         , l_pos
                         , l_buffer);

            IF l_pos = 1
            THEN
               l_clob      := l_buffer;
            ELSE
               l_clob      := l_clob || '~'');dbx.p(q''~' || l_buffer;
            END IF;

            l_pos       := l_pos + l_amount;
         END LOOP;

         l_clob      := 'dbx.p(q''~' || l_clob || '~'');';

         RETURN l_clob;
         dbms_lob.freetemporary (l_clob);
      END;
   BEGIN
      LOOP
         i           := i + 1;
         l_tmp       :=
            regexp_substr (p_template
                         , q'@dbx.p\(q\'\~(.*?|\s*)\~\'\)\;@'
                         , 1
                         , i
                         , 'inm'
                         , 1);

         IF length (l_tmp) > 32000
         THEN
            --Split l_tmp into 32000 strings
            l_tmp       := split_clob (l_tmp);

            --Start and End of the expression
            l_start     :=
               regexp_instr (p_template
                           , q'@dbx.p\(q\'\~(.*?|\s*)\~\'\)\;@'
                           , 1
                           , i
                           , 0
                           , 'inm');

            l_end       :=
               regexp_instr (p_template
                           , q'@dbx.p\(q\'\~(.*?|\s*)\~\'\)\;@'
                           , 1
                           , i
                           , 1
                           , 'inm');

            --concatenate result template into first template
            IF (nvl (l_start, 0) > 0)
            THEN
               dbms_lob.createtemporary (l_result, FALSE, dbms_lob.call);

               IF l_start > 1
               THEN
                  dbms_lob.copy (l_result
                               , p_template
                               , l_start - 1
                               , 1
                               , 1);
               END IF;

               IF length (l_tmp) > 0
               THEN
                  dbms_lob.copy (l_result
                               , l_tmp
                               , dbms_lob.getlength (l_tmp)
                               , dbms_lob.getlength (l_result) + 1
                               , 1);
               END IF;

               --Adding the rest of the source to the result variable
               IF l_end <= dbms_lob.getlength (p_template)
               THEN
                  dbms_lob.copy (l_result
                               , p_template
                               , dbms_lob.getlength (p_template)
                               , dbms_lob.getlength (l_result) + 1
                               , l_end);
               END IF;
            END IF;

            p_template  := l_result;

            dbms_lob.freetemporary (l_result);
         END IF;

         EXIT WHEN length (l_tmp) = 0;
      END LOOP;
   END string_literal_too_long;

   PROCEDURE save_compiled_template (p_template_name       IN VARCHAR2
                                   , p_appid               IN VARCHAR2 DEFAULT NULL
                                   , p_template            IN CLOB
                                   , p_compiled_template   IN CLOB)
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      -- TODO: Do a MERGE
      BEGIN
         INSERT INTO wdx_views (appid
                              , name
                              , source
                              , compiled_source
                              , visible
                              , created_by
                              , modified_by)
           VALUES   (nvl (p_appid, dbx.g$appid)
                   , nvl (p_template_name, 'NONAME')
                   , p_template
                   , p_compiled_template
                   , 'Y'
                   , nvl (dbx.g$username, user)
                   , nvl (dbx.g$username, user));
      EXCEPTION
         WHEN dup_val_on_index
         THEN
            UPDATE   wdx_views
               SET   source       = p_template
                   , compiled_source = p_compiled_template
                   , modified_date = sysdate
                   , modified_by  = nvl (dbx.g$username, user)
             WHERE   appid = nvl (p_appid, dbx.g$appid) AND name = nvl (p_template_name, 'NONAME');
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
          WHERE   name = p_template_name AND appid = nvl (p_appid, dbx.g$appid);
      EXCEPTION
         WHEN no_data_found
         THEN
            -- An included view must return a VARCHAR or CLOB
            EXECUTE IMMEDIATE 'BEGIN :l_val := ' || p_template_name || '; END;' USING OUT l_template;
      END;

      RETURN l_template;
   END include;


   FUNCTION include_compiled (p_template_name IN VARCHAR2, p_appid IN VARCHAR2 DEFAULT NULL )
      RETURN CLOB
   AS
      l_template   CLOB := empty_clob ();
   BEGIN
      BEGIN
         SELECT   compiled_source
           INTO   l_template
           FROM   wdx_views
          WHERE   name = p_template_name AND appid = nvl (p_appid, dbx.g$appid);
      EXCEPTION
         WHEN no_data_found
         THEN
            l_template  := empty_clob ();
      END;

      RETURN l_template;
   END include_compiled;


   /**
     * Search for include directives, includes and evaluates the specified templates.
     * Nested include are allowed
     *
     * @param  p_template    the template
     * @param  p_vars        the associative array
     */
   PROCEDURE get_includes (p_template IN OUT NOCOPY CLOB, p_appid IN VARCHAR2)
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
      WHILE regexp_instr (p_template, '<%@\s*include\((.*?)\)\s*%>') <> 0
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
            trim (regexp_substr (p_template
                               , '<%@\s*include\((.*?)\)\s*%>'
                               , 1
                               , 1
                               , 'n'
                               , 1));

         IF length (l_template_name) > 0
         THEN
            --get included template
            l_tmp       := include (l_template_name, p_appid);

            --Start and End of the expression
            l_start     :=
               regexp_instr (p_template
                           , '<%@\s*include\((.*?)\)\s*%>'
                           , 1
                           , 1
                           , 0
                           , 'n');

            l_end       :=
               regexp_instr (p_template
                           , '<%@\s*include\((.*?)\)\s*%>'
                           , 1
                           , 1
                           , 1
                           , 'n');

            --concatenate result template into first template
            IF (nvl (l_start, 0) > 0)
            THEN
               dbms_lob.createtemporary (l_result, FALSE, dbms_lob.call);

               IF l_start > 1
               THEN
                  dbms_lob.copy (l_result
                               , p_template
                               , l_start - 1
                               , 1
                               , 1);
               END IF;

               IF length (l_tmp) > 0
               THEN
                  dbms_lob.copy (l_result
                               , l_tmp
                               , dbms_lob.getlength (l_tmp)
                               , dbms_lob.getlength (l_result) + 1
                               , 1);
               END IF;

               --Adding the rest of the source to the result variable
               IF l_end <= dbms_lob.getlength (p_template)
               THEN
                  dbms_lob.copy (l_result
                               , p_template
                               , dbms_lob.getlength (p_template)
                               , dbms_lob.getlength (l_result) + 1
                               , l_end);
               END IF;
            END IF;

            p_template  := l_result;

            dbms_lob.freetemporary (l_result);
         END IF;

         l_number_includes := l_number_includes + 1;

         IF l_number_includes >= 50
         THEN
            raise_application_error (-20001, 'Too much include directive in the template, Recursive include?');
         END IF;
      END LOOP;
   END get_includes;


   /**
   * Check if a view has changed from the cachedview
   */
   FUNCTION template_has_changed (p_template_name IN VARCHAR2, p_appid IN VARCHAR2 DEFAULT NULL , p_template IN CLOB)
      RETURN BOOLEAN
   AS
      l_compare   PLS_INTEGER;
   BEGIN
      BEGIN
         SELECT   dbms_lob.compare (source, p_template)
           INTO   l_compare
           FROM   wdx_views
          WHERE   name = p_template_name AND appid = nvl (p_appid, dbx.g$appid);
      EXCEPTION
         WHEN no_data_found
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
   PROCEDURE bind_vars (p_template IN OUT NOCOPY CLOB, p_vars IN dbx.g_assoc_array)
   AS
      l_key   VARCHAR2 (256);
   BEGIN
      IF p_vars.count () <> 0
      THEN
         l_key       := p_vars.first;

         LOOP
            EXIT WHEN l_key IS NULL;
            p_template  := replace (p_template, '${' || l_key || '}', to_clob (p_vars (l_key)));
            l_key       := p_vars.next (l_key);
         END LOOP;
      END IF;
   END bind_vars;

   /**
   * Parse template marks
   *
   * @param  p_template      the template
   * @param  p_vars        the associative array
   */
   PROCEDURE parse (p_template IN CLOB)
   AS
      l_open_count      PLS_INTEGER;
      l_close_count     PLS_INTEGER;
      l_template_name   VARCHAR2 (300);
   BEGIN
      l_open_count := regexp_count (p_template, '<\%');
      l_close_count := regexp_count (p_template, '\%>');

      IF l_open_count <> l_close_count
      THEN
         raise_application_error (-20001
                                ,    '##Parser Exception processing the template'
                                  || l_template_name
                                  || '. One or more tags (<% %>) are not closed: '
                                  || l_open_count
                                  || ' <> '
                                  || l_close_count
                                  || chr (10));
      END IF;
   END parse;

   /**
   * Interprets the received template and convert it into executable plsql
   *
   * @param  p_template    the template
   * @param  p_vars        the associative array
   */
   PROCEDURE interpret (p_template IN OUT NOCOPY CLOB)
   AS
      l_declare   CLOB;
      l_tmp       CLOB;
      i           PLS_INTEGER := 0;
   BEGIN
      --Parse <% %> tags
      parse (p_template);

      --Dos to Unix
      p_template  :=
         regexp_replace (p_template
                       , chr (13) || chr (10)
                       , chr (10)
                       , 1
                       , 0
                       , 'nm');

      --Delete all template directives
      p_template  :=
         regexp_replace (p_template
                       , '<%@ template([^%>].*?)\s*%>[[:blank:]]*\s$?'
                       , ''
                       , 1
                       , 0
                       , 'n');

      --Escaped chars except \\n
      p_template  :=
         regexp_replace (p_template
                       , '\\\\([^n])'
                       , '~'');dbx.p(q''[\1]'');dbx.p(q''~'
                       , 1
                       , 0
                       , 'n');


      --New lines.
      p_template  :=
         regexp_replace (p_template
                       , '(\\\\n)'
                       , chr (10) --|| '~'');dbx.p(q''~'
                       , 1
                       , 0
                       , 'n');


      --Delete the line breaks for lines ending in %>[blanks]CHR(10)
      p_template  :=
         regexp_replace (p_template
                       , '(%>[[:blank:]]*?' || chr (10) || ')'
                       , '%>'
                       , 1
                       , 0
                       , '');

      --Delete new lines with !\n
      p_template  :=
         regexp_replace (p_template
                       , '([[:blank:]]*\!\\n[[:blank:]]*' || chr (10) || '?[[:blank:]]*)'
                       , ''
                       , 1
                       , 0
                       , 'm');

      -- Delete all blanks before <% in the beginning of each line
      p_template  :=
         regexp_replace (p_template
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
            regexp_substr (p_template
                         , '<%!([^%>].*?)%>'
                         , 1
                         , i
                         , 'n'
                         , 1);
         l_declare   := l_declare || l_tmp;
         EXIT WHEN length (l_tmp) = 0;
      END LOOP;

      --Delete declaration blocks from template
      p_template  :=
         regexp_replace (p_template
                       , '<%!([^%>].*?)%>'
                       , ''
                       , 1
                       , 0
                       , 'n');

      --Expresison directive
      p_template  :=
         regexp_replace (p_template
                       , '<%=([^%>].*?)%>'
                       , '~'');dbx.p(\1);dbx.p(q''~'
                       , 1
                       , 0
                       , 'n');


      --Variables
      /*p_template  :=
         REGEXP_REPLACE (p_template
                       , '\$\{(\S*)\}'
                       , '~'');dbx.p(dbax_utils.get(dbax_core.g$view,''\1''));dbx.p(q''~'
                       , 1
                       , 0
                       , 'n');*/


      p_template  := 'DECLARE ' || l_declare || ' BEGIN dbx.p(q''~' || p_template || '~''); END;';
   END interpret;


   PROCEDURE set_template_data (p_template IN OUT NOCOPY CLOB)
   AS
      l_key        VARCHAR2 (256);
      l_tmp_clob   CLOB;
   BEGIN
      -------------------
      -- VARCHAR Array --
      -------------------
      l_key       := g_assoc_varchar.first;

      IF l_key IS NOT NULL
      THEN
         --Open declaration blok
         l_tmp_clob  := '<%!';

         LOOP
            EXIT WHEN l_key IS NULL;


            l_tmp_clob  :=
               l_tmp_clob || l_key || ' VARCHAR2(32767) :=  view_.get_data_varchar(''' || l_key || ''');' || chr (10);

            l_key       := g_assoc_varchar.next (l_key);
         END LOOP;

         --Close declaration blok
         l_tmp_clob  := l_tmp_clob || '%>';

         p_template  := p_template || l_tmp_clob;

         l_tmp_clob  := '';
      END IF;

      -------------------
      -- NNUMBER Array --
      -------------------
      l_key       := g_assoc_number.first;

      IF l_key IS NOT NULL
      THEN
         --Open declaration blok
         l_tmp_clob  := '<%!';

         LOOP
            EXIT WHEN l_key IS NULL;

            l_tmp_clob  := l_tmp_clob || l_key || ' NUMBER :=  view_.get_data_num(''' || l_key || ''');' || chr (10);

            l_key       := g_assoc_number.next (l_key);
         END LOOP;

         --Close declaration blok
         l_tmp_clob  := l_tmp_clob || '%>';

         p_template  := p_template || l_tmp_clob;

         l_tmp_clob  := '';
      END IF;

      -------------------
      -- DATE Array --
      -------------------
      l_key       := g_assoc_date.first;

      IF l_key IS NOT NULL
      THEN
         --Open declaration blok
         l_tmp_clob  := '<%!';

         LOOP
            EXIT WHEN l_key IS NULL;

            l_tmp_clob  := l_tmp_clob || l_key || ' DATE :=  view_.get_data_date(''' || l_key || ''');' || chr (10);

            l_key       := g_assoc_date.next (l_key);
         END LOOP;

         --Close declaration blok
         l_tmp_clob  := l_tmp_clob || '%>';

         p_template  := p_template || l_tmp_clob;

         l_tmp_clob  := '';
      END IF;


      -------------------
      -- CLOB Array --
      -------------------
      l_key       := g_assoc_clob.first;

      IF l_key IS NOT NULL
      THEN
         --Open declaration blok
         l_tmp_clob  := '<%!';

         LOOP
            EXIT WHEN l_key IS NULL;

            l_tmp_clob  := l_tmp_clob || l_key || ' CLOB :=  view_.get_data_clob(''' || l_key || ''');' || chr (10);

            l_key       := g_assoc_clob.next (l_key);
         END LOOP;

         --Close declaration blok
         l_tmp_clob  := l_tmp_clob || '%>';

         p_template  := p_template || l_tmp_clob;

         l_tmp_clob  := '';
      END IF;
      
      -------------------
      -- Assoc Array --
      -------------------
      l_key       := g_assoc_assoc.first;

      IF l_key IS NOT NULL
      THEN
         --Open declaration blok
         l_tmp_clob  := '<%!';

         LOOP
            EXIT WHEN l_key IS NULL;

            l_tmp_clob  :=
               l_tmp_clob || l_key || ' dbx.g_assoc_array :=  view_.get_data_assoc(''' || l_key || ''');' || chr (10);

            l_key       := g_assoc_assoc.next (l_key);
         END LOOP;

         --Close declaration blok
         l_tmp_clob  := l_tmp_clob || '%>';

         p_template  := p_template || l_tmp_clob;

         l_tmp_clob  := '';
      END IF;

      -------------------
      -- Cursor Array --
      -------------------
      l_key       := g_assoc_refcursor.first;

      IF l_key IS NOT NULL
      THEN
         --Open declaration blok
         l_tmp_clob  := '<%!';

         LOOP
            EXIT WHEN l_key IS NULL;

            l_tmp_clob  :=
               l_tmp_clob || l_key || ' sys_refcursor :=  view_.get_data_refcursor(''' || l_key || ''');' || chr (10);

            l_key       := g_assoc_refcursor.next (l_key);
         END LOOP;

         --Close declaration blok
         l_tmp_clob  := l_tmp_clob || '%>';

         p_template  := p_template || l_tmp_clob;

         l_tmp_clob  := '';
      END IF;
   END set_template_data;


   FUNCTION compile (p_template_name IN VARCHAR2, p_appid IN VARCHAR2, p_error_template OUT NOCOPY CLOB)
      RETURN CLOB
   AS
      l_template   CLOB;
      v_cur_hdl    INTEGER;
   BEGIN
      --Get template
      l_template  := include (p_template_name, p_appid);

      --Parse <% %> tags
      parse (l_template);

      --Get Includes
      get_includes (p_template => l_template, p_appid => p_appid);

      --Interpret the template
      interpret (l_template);

      --Code blocks directive
      l_template  :=
         regexp_replace (l_template
                       , '<%([^%>].*?)%>'
                       , '~''); \1 dbx.p(q''~'
                       , 1
                       , 0
                       , 'n');

      --Delete all null code blocks
      l_template  :=
         regexp_replace (l_template
                       , q'@dbx.p\(q\'\~\~\'\)\;@'
                       , ''
                       , 1
                       , 0
                       , 'n');

      --Avoid PLS-00172: string literal too long
      string_literal_too_long (l_template);

      v_cur_hdl   := dbms_sql.open_cursor;
      dbms_sql.parse (v_cur_hdl, l_template, dbms_sql.native);
      dbms_sql.close_cursor (v_cur_hdl);

      --minified html
      --l_template := REGEXP_REPLACE(l_template, '[ ]{2,}',' ');
      --l_template := REPLACE(l_template, CHR(10));

      RETURN l_template;
   EXCEPTION
      WHEN OTHERS
      THEN
         --Return error
         p_error_template := p_error_template || ('### tePLSQL Compile Error ###');
         p_error_template := p_error_template || (chr (10));
         p_error_template := p_error_template || (sqlerrm || ' ' || dbms_utility.format_error_backtrace ());
         p_error_template := p_error_template || (chr (10));
         p_error_template :=
            p_error_template
            || ('### Processing template ' || p_template_name || ' from ' || p_appid || ' application ###');
         p_error_template := p_error_template || (chr (10));
         p_error_template := p_error_template || (l_template);
         --dbax_log.error (p_error_template);
         RAISE;
   END compile;

   FUNCTION local_compile (p_template IN CLOB, p_appid IN VARCHAR2)
      RETURN CLOB
   AS
      l_template   CLOB;
      v_cur_hdl    INTEGER;
   BEGIN
      --Get template
      l_template  := p_template;

      -- Set template data variables
      set_template_data (l_template);

      --dbax_log.trace ('Compile Function. l_template:' || l_template);

      --Parse <% %> tags
      parse (l_template);

      --Get Includes
      get_includes (p_template => l_template, p_appid => p_appid);

      --Interpret the template
      interpret (l_template);

      --Code blocks directive
      l_template  :=
         regexp_replace (l_template
                       , '<%([^%>].*?)%>'
                       , '~''); \1 dbx.p(q''~'
                       , 1
                       , 0
                       , 'n');

      --Delete all null code blocks
      l_template  :=
         regexp_replace (l_template
                       , q'@dbx.p\(q\'\~\~\'\)\;@'
                       , ''
                       , 1
                       , 0
                       , 'n');

      --Avoid PLS-00172: string literal too long
      string_literal_too_long (l_template);

      /**
      * I do not parse the template because it is going to be executed
      */
      /*v_cur_hdl   := DBMS_SQL.open_cursor;
      DBMS_SQL.parse (v_cur_hdl, l_template, DBMS_SQL.native);
      DBMS_SQL.close_cursor (v_cur_hdl);*/


      RETURN l_template;
   END local_compile;

   FUNCTION compile (p_template IN CLOB, p_appid IN VARCHAR2, p_error_template OUT NOCOPY CLOB)
      RETURN CLOB
   AS
      l_template   CLOB;
      v_cur_hdl    INTEGER;
   BEGIN
      --Get template
      l_template  := p_template;

      -- Set template data variables
      set_template_data (l_template);

      --dbax_log.trace ('Compile Function. l_template:' || l_template);

      --Parse <% %> tags
      parse (l_template);

      --Get Includes
      get_includes (p_template => l_template, p_appid => p_appid);

      --Interpret the template
      interpret (l_template);

      --Code blocks directive
      l_template  :=
         regexp_replace (l_template
                       , '<%([^%>].*?)%>'
                       , '~''); \1 dbx.p(q''~'
                       , 1
                       , 0
                       , 'n');

      --Delete all null code blocks
      l_template  :=
         regexp_replace (l_template
                       , q'@dbx.p\(q\'\~\~\'\)\;@'
                       , ''
                       , 1
                       , 0
                       , 'n');

      --Avoid PLS-00172: string literal too long
      string_literal_too_long (l_template);


      v_cur_hdl   := dbms_sql.open_cursor;
      dbms_sql.parse (v_cur_hdl, l_template, dbms_sql.native);
      dbms_sql.close_cursor (v_cur_hdl);

      --minified html
      --l_template := REGEXP_REPLACE(l_template, '[ ]{2,}',' ');
      --l_template := REPLACE(l_template, CHR(10));

      RETURN l_template;
   EXCEPTION
      WHEN OTHERS
      THEN
         --Return error
         p_error_template := p_error_template || ('### tePLSQL Compile Error ###');
         p_error_template := p_error_template || (chr (10));
         p_error_template := p_error_template || (sqlerrm || ' ' || dbms_utility.format_error_backtrace ());
         p_error_template := p_error_template || (chr (10));
         p_error_template := p_error_template || ('### Processing template ');
         p_error_template := p_error_template || (chr (10));
         p_error_template := p_error_template || (l_template);
         --dbax_log.error (p_error_template);
         RAISE;
   END compile;


   PROCEDURE purge_compiled (p_appid IN VARCHAR2)
   AS
      PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
      UPDATE   wdx_views a
         SET   compiled_source = NULL
       WHERE   upper (appid) = upper (p_appid);

      COMMIT;
   END purge_compiled;


   PROCEDURE execute (p_template_name   IN VARCHAR2 DEFAULT NULL
                    , p_appid           IN VARCHAR2 DEFAULT NULL
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
            l_template  := local_compile (p_template, p_appid);

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
         IF length (l_template) = 0 OR length (l_template) IS NULL
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
         l_template  := local_compile (p_template, p_appid);

         -- Save compiled Template
         save_compiled_template (p_template_name => p_template_name
                               , p_appid     => p_appid
                               , p_template  => p_template
                               , p_compiled_template => l_template);
      END IF;


      --Bind the variables into template
      bind_vars (l_template, g_assoc_varchar);

      --Null all variables not binded
      l_template  := regexp_replace (l_template, '\$\{\S*\}', '');


      --dbax_log.trace ('Executing this template:' || l_template);

      EXECUTE IMMEDIATE l_template;
   EXCEPTION
      WHEN OTHERS
      THEN
         dbx.raise_exception (sqlcode, 'Executing view: ' || p_template_name || chr (10) || sqlerrm);
   END execute;

   PROCEDURE name (p_name IN VARCHAR2)
   AS
   BEGIN
      g_view_name := p_name;
   END;

   FUNCTION name
      RETURN VARCHAR2
   AS
   BEGIN
      RETURN g_view_name;
   END;

   PROCEDURE run (p_view IN CLOB, p_name IN VARCHAR2)
   AS
   BEGIN
      --Set view name
      name (p_name);
      --Execute view
      execute (p_template_name => p_name, p_template => p_view);

      -- Delete view data
      g_assoc_varchar.delete;
      g_assoc_number.delete;
      g_assoc_date.delete;
      g_assoc_assoc.delete;
      g_assoc_refcursor.delete;
   END run;

   FUNCTION run (p_view IN CLOB, p_name IN VARCHAR2)
      RETURN VARCHAR2
   AS
   BEGIN
      run (p_view, p_name);
      RETURN NULL;
   END;

   PROCEDURE data (p_name IN VARCHAR2, p_value IN VARCHAR2)
   AS
   BEGIN
      g_assoc_varchar (p_name) := p_value;
   END;

   FUNCTION get_data_varchar (p_name IN VARCHAR2)
      RETURN VARCHAR2
   AS
   BEGIN
      IF g_assoc_varchar.exists (p_name)
      THEN
         RETURN g_assoc_varchar (p_name);
      ELSE
         RETURN NULL;
      END IF;
   END;

   PROCEDURE data (p_name IN VARCHAR2, p_value IN NUMBER)
   AS
   BEGIN
      g_assoc_number (p_name) := p_value;
   END;

   FUNCTION get_data_num (p_name IN VARCHAR2)
      RETURN NUMBER
   AS
   BEGIN
      IF g_assoc_number.exists (p_name)
      THEN
         RETURN g_assoc_number (p_name);
      ELSE
         RETURN NULL;
      END IF;
   END;

   PROCEDURE data (p_name IN VARCHAR2, p_value IN DATE)
   AS
   BEGIN
      g_assoc_date (p_name) := p_value;
   END;

   FUNCTION get_data_date (p_name IN VARCHAR2)
      RETURN DATE
   AS
   BEGIN
      IF g_assoc_date.exists (p_name)
      THEN
         RETURN g_assoc_date (p_name);
      ELSE
         RETURN NULL;
      END IF;
   END;


   PROCEDURE data (p_name IN VARCHAR2, p_value IN CLOB)
   AS
   BEGIN
      g_assoc_clob (p_name) := p_value;
   END;

   FUNCTION get_data_clob (p_name IN VARCHAR2)
      RETURN CLOB
   AS
   BEGIN
      IF g_assoc_clob.exists (p_name)
      THEN
         RETURN g_assoc_clob (p_name);
      ELSE
         RETURN NULL;
      END IF;
   END;

   PROCEDURE data (p_name IN VARCHAR2, p_value IN dbx.g_assoc_array)
   AS
   BEGIN
      g_assoc_assoc (p_name) := p_value;
   END;

   FUNCTION get_data_assoc (p_name IN VARCHAR2)
      RETURN dbx.g_assoc_array
   AS
      l_null_assoc   dbx.g_assoc_array;
   BEGIN
      IF g_assoc_assoc.exists (p_name)
      THEN
         RETURN g_assoc_assoc (p_name);
      ELSE
         RETURN l_null_assoc;
      END IF;
   END;

   PROCEDURE data (p_name IN VARCHAR2, p_cursor IN sys_refcursor)
   AS
      l_cursor_id    PLS_INTEGER;
      l_ref_cursor   sys_refcursor;
   BEGIN
      l_ref_cursor := p_cursor;
      l_cursor_id := dbms_sql.to_cursor_number (l_ref_cursor);

      g_assoc_refcursor (p_name) := l_cursor_id;
   END;

   FUNCTION get_data_refcursor (p_name IN VARCHAR2)
      RETURN sys_refcursor
   AS
      l_ref_cursor   sys_refcursor;
   BEGIN
      IF g_assoc_refcursor.exists (p_name)
      THEN
         l_ref_cursor := dbms_sql.to_refcursor (g_assoc_refcursor (p_name));
         RETURN l_ref_cursor;
      ELSE
         RETURN NULL;
      END IF;
   END;
END view_;
/