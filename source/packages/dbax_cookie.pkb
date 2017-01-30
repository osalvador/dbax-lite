CREATE OR REPLACE PACKAGE BODY dbax_cookie
AS

   PROCEDURE load_cookies (p_cookies IN VARCHAR2 DEFAULT NULL )
   AS
      l_http_cookie   VARCHAR2 (32767);
   BEGIN
      --Load HTTP Cookie string
      l_http_cookie := NVL (p_cookies, OWA_UTIL.get_cgi_env ('HTTP_COOKIE'));

      --Parse Cookie String to request cookie
      request_.cookies (dbx.query_string_to_array (l_http_cookie, '; ', '='));
   END load_cookies;

   FUNCTION generate_cookie_header
      RETURN VARCHAR2
   AS
      l_name        VARCHAR2 (4000);
      l_return      VARCHAR2 (32000);
      expires_gmt   DATE;
      l_cookies     g_cookie_array;
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
END dbax_cookie;
/