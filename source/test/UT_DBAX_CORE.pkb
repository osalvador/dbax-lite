/* Formatted on 20/01/2017 15:22:17 (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE BODY ut_dbax_core
AS
   PROCEDURE PRINT (text IN VARCHAR2)
   AS
   BEGIN
      DBMS_OUTPUT.put_line (text);
   END;

   PROCEDURE pass
   AS
   BEGIN
      PRINT ('   Pass');
   END;

   PROCEDURE fail (p_line_number IN NUMBER)
   AS
   BEGIN
      PRINT ('XXX El test ha fallado en la linea:' || p_line_number);
   END;

   PROCEDURE routing
   AS
   BEGIN
      PRINT ('**********');
      PRINT ('Probando el metodo DBAX_CORE.ROUTE_GET');
      PRINT ('**********');
      dbax_core.g$server ('REQUEST_METHOD') := 'GET';


      PRINT ('-- Enrutado basico, la url es /foo tiene que devolver TRUE');
      dbax_core.g$path := 'foo';

      IF dbax_core.route_get ('foo') != TRUE
      THEN
         PRINT ('XXX El test ha fallado XXX');
         RETURN;
      ELSE
         PRINT ('   Pass');
      END IF;

      --      PRINT ('Enrutado con expresiones regulares');

      PRINT ('**********');
      PRINT ('Probando el metodo DBAX_CORE.ROUTE_POST');
      PRINT ('**********');
      dbax_core.g$server ('REQUEST_METHOD') := 'POST';


      PRINT ('-- Enrutado basico, la url es /foo tiene que devolver TRUE');
      dbax_core.g$path := 'foo';

      IF dbax_core.route_post ('foo') != TRUE
      THEN
         PRINT ('XXX El test ha fallado XXX');
         RETURN;
      ELSE
         PRINT ('   Pass');
      END IF;


      PRINT ('**********');
      PRINT ('Probando el metodo DBAX_CORE.ROUTE');
      PRINT ('**********');

      PRINT ('-- Enrutado basico, la url es /foo y el método es GET, solo paso como parametro de verbo "get" ');
      dbax_core.g$server ('REQUEST_METHOD') := 'GET';
      dbax_core.g$path := 'foo';

      IF dbax_core.route ('get', 'foo') != TRUE
      THEN
         PRINT ('XXX El test ha fallado XXX');
         RETURN;
      ELSE
         PRINT ('   Pass');
      END IF;

      PRINT ('-- Enrutado basico, la url es /foo y el método es POST, solo paso como parametro de verbo "post"');
      dbax_core.g$server ('REQUEST_METHOD') := 'POST';
      dbax_core.g$path := 'foo';

      IF dbax_core.route ('post', 'foo') != TRUE
      THEN
         PRINT ('XXX El test ha fallado XXX');
         RETURN;
      ELSE
         PRINT ('   Pass');
      END IF;

      PRINT ('-- Enrutado basico, la url es /foo y el método es POST, paso como parametro de verbo "post,get"');
      dbax_core.g$server ('REQUEST_METHOD') := 'POST';
      dbax_core.g$path := 'foo';

      IF dbax_core.route ('post,get', 'foo') != TRUE
      THEN
         PRINT ('XXX El test ha fallado XXX');
         RETURN;
      ELSE
         PRINT ('   Pass');
      END IF;

      PRINT ('-- Enrutado basico, la url es /foo y el método es GET, paso como parametro de verbo "post,get"');
      dbax_core.g$server ('REQUEST_METHOD') := 'GET';
      dbax_core.g$path := 'foo';

      IF dbax_core.route ('post,get', 'foo') != TRUE
      THEN
         PRINT ('XXX El test ha fallado XXX');
         RETURN;
      ELSE
         PRINT ('   Pass');
      END IF;

      PRINT('-- Enrutado basico, la url es /foo y el método es GET, paso como parametro de verbo "post , get" con espacios en blanco');
      dbax_core.g$server ('REQUEST_METHOD') := 'GET';
      dbax_core.g$path := 'foo';

      IF dbax_core.route ('post , get', 'foo') != TRUE
      THEN
         PRINT ('XXX El test ha fallado XXX');
         RETURN;
      ELSE
         PRINT ('   Pass');
      END IF;


      PRINT ('-- Enrutado basico, la url es /foo y el método es GET, paso como parametro de verbo "dummy" ');
      dbax_core.g$server ('REQUEST_METHOD') := 'GET';
      dbax_core.g$path := 'foo';

      IF dbax_core.route ('dummy', 'foo') = TRUE
      THEN
         PRINT ('XXX El test ha fallado XXX');
         RETURN;
      ELSE
         PRINT ('   Pass');
      END IF;



      PRINT ('**********');
      PRINT ('Probando el metodo DBAX_CORE.ROUTE_GET con Parametros de URL');
      PRINT ('**********');

      PRINT('-- Enrutado con parametros, la url es /user/oscar el metodo GET, el parametro que se debe vevolver es el id de usuario oscar');
      dbax_core.g$server ('REQUEST_METHOD') := 'GET';
      dbax_core.g$path := 'user/oscar';

      DECLARE
         l_param   dbax_core.g_assoc_array;
      BEGIN
         IF dbax_core.route_get ('user/{id}', l_param) != TRUE
         THEN
            PRINT ('XXX El test ha fallado XXX');
            RETURN;
         ELSE
            PRINT ('   La URL si coincide');

            IF l_param ('id') = 'oscar'
            THEN
               PRINT (q'[   l_param('id') = 'oscar']');
               PRINT ('   Pass');
            ELSE
               PRINT ('XXX El test ha fallado XXX');
               RETURN;
            END IF;
         END IF;
      END;

      PRINT('-- Enrutado con parametros, la url es /user/22/name/Oscar el metodo POST, el parametro que se debe vevolver es el id=22 y usename=Oscar');
      dbax_core.g$server ('REQUEST_METHOD') := 'POST';
      dbax_core.g$path := 'user/22/name/Oscar';

      DECLARE
         l_param   dbax_core.g_assoc_array;
      BEGIN
         IF dbax_core.route_post ('user/{id}/name/{usename}', l_param) != TRUE
         THEN
            fail ($$plsql_line);
            RETURN;
         ELSE
            PRINT ('   La URL si coincide');

            IF l_param ('id') = '22'
            THEN
               PRINT (q'[   l_param('id') = ]' || l_param ('id'));

               IF l_param ('usename') = 'Oscar'
               THEN
                  PRINT (q'[   l_param('usename') =]' || l_param ('usename'));
                  PRINT ('   Pass');
               ELSE
                  fail ($$plsql_line);
                  RETURN;
               END IF;
            ELSE
               fail ($$plsql_line);
               RETURN;
            END IF;
         END IF;
      END;

      PRINT('-- Enrutado con parametros, la url es /user/22/profile/upload/image el metodo GET, el parametro que se debe vevolver es el id=22');
      dbax_core.g$server ('REQUEST_METHOD') := 'GET';
      dbax_core.g$path := 'user/22/profile/upload/image';

      DECLARE
         l_param   dbax_core.g_assoc_array;
      BEGIN
         IF dbax_core.route_get ('user/{id}/profile/upload/image', l_param) != TRUE
         THEN
            fail ($$plsql_line);
            RETURN;
         ELSE
            PRINT ('   La URL si coincide');

            PRINT (q'[   l_param('id') = ]' || l_param ('id'));

            IF l_param ('id') = '22'
            THEN
               pass;
            ELSE
               fail ($$plsql_line);
               RETURN;
            END IF;
         END IF;
      END;


      PRINT('-- Enrutado con parametros, la url es /user-id/22/user_type/free el metodo GET, el parametro que se debe user-id=22 y user_type=free');
      dbax_core.g$server ('REQUEST_METHOD') := 'GET';
      dbax_core.g$path := 'user-id/22/user_type/free';

      DECLARE
         l_param   dbax_core.g_assoc_array;
      BEGIN
         IF dbax_core.route_get ('user-id/{user-id}/user_type/{user_type}', l_param) != TRUE
         THEN
            fail ($$plsql_line);
            RETURN;
         ELSE
            PRINT ('   La URL si coincide');

            PRINT (q'[   l_param('user-id') = ]' || l_param ('user-id'));
            PRINT (q'[   l_param('user_type') = ]' || l_param ('user_type'));

            IF l_param ('user-id') = '22' AND l_param ('user_type') = 'free'
            THEN
               pass;
            ELSE
               fail ($$plsql_line);
               RETURN;
            END IF;
         END IF;
      END;

      PRINT('-- Enrutado con parametros opcionales, la url es /user//id/22/type/ el metodo GET,el parametro name y type son opcionales');
      dbax_core.g$server ('REQUEST_METHOD') := 'GET';
      dbax_core.g$path := 'user//id/22/type/';

      DECLARE
         l_param   dbax_core.g_assoc_array;
      BEGIN
         IF dbax_core.route_get ('user/{name}?/id/{id}/type/{type}?', l_param) != TRUE
         THEN
            fail ($$plsql_line);
            RETURN;
         ELSE
            PRINT ('   La URL si coincide');

            PRINT (q'[   l_param('id') = ]' || l_param ('id'));            

            IF l_param ('id') = '22'
            THEN
               pass;
            ELSE
               fail ($$plsql_line);
               RETURN;
            END IF;
         END IF;
      END;


      PRINT('-- Enrutado con parametros opcionales y Advanced Regex Case Insentive, la url es /USER//id/22/type/ el metodo GET,el parametro name y type son opcionales');
      dbax_core.g$server ('REQUEST_METHOD') := 'GET';
      dbax_core.g$path := 'user//ID/22/type/';

      DECLARE
         l_param   dbax_core.g_assoc_array;
      BEGIN
         IF dbax_core.route_get ('user/{name}?/id/{id}/type/{type}?@1,1,i', l_param) != TRUE
         THEN
            fail ($$plsql_line);
            RETURN;
         ELSE
            PRINT ('   La URL si coincide');

            PRINT (q'[   l_param('id') = ]' || l_param ('id'));            

            IF l_param ('id') = '22'
            THEN
               pass;
            ELSE
               fail ($$plsql_line);
               RETURN;
            END IF;
         END IF;
      END;


      PRINT ('-- Enrutado basico, la url está vacia lo que supone que es el index de la pagina');
      dbax_core.g$path := '';

      IF dbax_core.route_get ('/') != TRUE
      THEN
         PRINT ('XXX El test ha fallado XXX');
         RETURN;
      ELSE
         PRINT ('   Pass');
      END IF;


   END;
END ut_dbax_core;