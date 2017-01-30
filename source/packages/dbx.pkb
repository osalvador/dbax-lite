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
END dbx;