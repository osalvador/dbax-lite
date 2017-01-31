/* Formatted on 31/01/2017 16:59:45 (QP5 v5.115.810.9015) */
DECLARE
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
      raise_application_error (-20001, 'XXX El test ha fallado en la linea:' || p_line_number);
   END;
BEGIN
   PRINT ('**********');
   PRINT ('Probando el metodo route_.get');
   PRINT ('**********');   

   request_.method ('GET');

   PRINT ('-- Enrutado basico, la url es /foo tiene que devolver TRUE');
   dbx.g$path  := 'foo';

   IF route_.get ('foo') != TRUE
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;

   --      PRINT ('Enrutado con expresiones regulares');

   PRINT ('**********');
   PRINT ('Probando el metodo route_.post');
   PRINT ('**********');
   request_.method( 'POST');


   PRINT ('-- Enrutado basico, la url es /foo tiene que devolver TRUE');
   dbx.g$path := 'foo';

   IF route_.post ('foo') != TRUE
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;


   PRINT ('**********');
   PRINT ('Probando el metodo route_.match');
   PRINT ('**********');

   PRINT ('-- Enrutado basico, la url es /foo y el m�todo es GET, solo paso como parametro de verbo "get" ');
   request_.method( 'GET');
   dbx.g$path := 'foo';

   IF route_.match ('foo', 'get') != TRUE
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;

   PRINT ('-- Enrutado basico, la url es /foo y el m�todo es POST, solo paso como parametro de verbo "post"');
   request_.method( 'POST');
   dbx.g$path := 'foo';

   IF route_.match ('foo', 'post') != TRUE
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;

   PRINT ('-- Enrutado basico, la url es /foo y el m�todo es POST, paso como parametro de verbo "post,get"');
   request_.method( 'POST');
   dbx.g$path := 'foo';

   IF route_.match ('foo', 'post,get') != TRUE
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;

   PRINT ('-- Enrutado basico, la url es /foo y el m�todo es GET, paso como parametro de verbo "post,get"');
   request_.method( 'GET');
   dbx.g$path := 'foo';

   IF route_.match ('foo', 'post,get') != TRUE
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;

   PRINT('-- Enrutado basico, la url es /foo y el m�todo es GET, paso como parametro de verbo "post , get" con espacios en blanco');
   request_.method( 'GET');
   dbx.g$path := 'foo';

   IF route_.match ('foo', 'post , get') != TRUE
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;


   PRINT ('-- Enrutado basico, la url es /foo y el m�todo es GET, paso como parametro de verbo "dummy" ');
   request_.method( 'GET');
   dbx.g$path := 'foo';

   IF route_.match ('foo', 'dummy') = TRUE
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;



   PRINT ('**********');
   PRINT ('Probando el metodo route_.GET con Parametros de URL');
   PRINT ('**********');

   PRINT('-- Enrutado con parametros, la url es /user/oscar el metodo GET, el parametro que se debe vevolver es el id de usuario oscar');
   request_.method( 'GET');
   dbx.g$path := 'user/oscar';

   DECLARE
      l_param   dbx.g_assoc_array;
   BEGIN
      IF route_.get ('user/{id}', l_param) != TRUE
      THEN
         fail ($$plsql_line);
      ELSE
         PRINT ('   La URL si coincide');

         IF l_param ('id') = 'oscar'
         THEN
            PRINT (q'[   l_param('id') = 'oscar']');
            pass;
         ELSE
            fail ($$plsql_line);
         END IF;
      END IF;
   END;

   PRINT('-- Enrutado con parametros, la url es /user/22/name/Oscar el metodo POST, el parametro que se debe vevolver es el id=22 y usename=Oscar');
   request_.method( 'POST');
   dbx.g$path := 'user/22/name/Oscar';

   DECLARE
      l_param   dbx.g_assoc_array;
   BEGIN
      IF route_.post ('user/{id}/name/{usename}', l_param) != TRUE
      THEN
         fail ($$plsql_line);
      ELSE
         PRINT ('   La URL si coincide');

         IF l_param ('id') = '22'
         THEN
            PRINT (q'[   l_param('id') = ]' || l_param ('id'));

            IF l_param ('usename') = 'Oscar'
            THEN
               PRINT (q'[   l_param('usename') =]' || l_param ('usename'));
               pass;
            ELSE
               fail ($$plsql_line);
            END IF;
         ELSE
            fail ($$plsql_line);
         END IF;
      END IF;
   END;

   PRINT('-- Enrutado con parametros, la url es /user/22/profile/upload/image el metodo GET, el parametro que se debe vevolver es el id=22');
   request_.method( 'GET');
   dbx.g$path := 'user/22/profile/upload/image';

   DECLARE
      l_param   dbx.g_assoc_array;
   BEGIN
      IF route_.get ('user/{id}/profile/upload/image', l_param) != TRUE
      THEN
         fail ($$plsql_line);
      ELSE
         PRINT ('   La URL si coincide');

         PRINT (q'[   l_param('id') = ]' || l_param ('id'));

         IF l_param ('id') = '22'
         THEN
            pass;
         ELSE
            fail ($$plsql_line);
         END IF;
      END IF;
   END;


   PRINT('-- Enrutado con parametros, la url es /user-id/22/user_type/free el metodo GET, el parametro que se debe user-id=22 y user_type=free');
   request_.method( 'GET');
   dbx.g$path := 'user-id/22/user_type/free';

   DECLARE
      l_param   dbx.g_assoc_array;
   BEGIN
      IF route_.get ('user-id/{user-id}/user_type/{user_type}', l_param) != TRUE
      THEN
         fail ($$plsql_line);
      ELSE
         PRINT ('   La URL si coincide');

         PRINT (q'[   l_param('user-id') = ]' || l_param ('user-id'));
         PRINT (q'[   l_param('user_type') = ]' || l_param ('user_type'));

         IF l_param ('user-id') = '22' AND l_param ('user_type') = 'free'
         THEN
            pass;
         ELSE
            fail ($$plsql_line);
         END IF;
      END IF;
   END;

   PRINT('-- Enrutado con parametros opcionales, la url es /user//id/22/type/ el metodo GET,el parametro name y type son opcionales');
   request_.method( 'GET');
   dbx.g$path := 'user//id/22/type/';

   DECLARE
      l_param   dbx.g_assoc_array;
   BEGIN
      IF route_.get ('user/{name}?/id/{id}/type/{type}?', l_param) != TRUE
      THEN
         fail ($$plsql_line);
      ELSE
         PRINT ('   La URL si coincide');

         PRINT (q'[   l_param('id') = ]' || l_param ('id'));

         IF l_param ('id') = '22'
         THEN
            pass;
         ELSE
            fail ($$plsql_line);
         END IF;
      END IF;
   END;


   PRINT('-- Enrutado con parametros opcionales y Advanced Regex Case Insentive, la url es /USER//id/22/type/ el metodo GET,el parametro name y type son opcionales');
   request_.method( 'GET');
   dbx.g$path := 'user//ID/22/type/';

   DECLARE
      l_param   dbx.g_assoc_array;
   BEGIN
      IF route_.get ('user/{name}?/id/{id}/type/{type}?@1,1,i', l_param) != TRUE
      THEN
         fail ($$plsql_line);
      ELSE
         PRINT ('   La URL si coincide');

         PRINT (q'[   l_param('id') = ]' || l_param ('id'));

         IF l_param ('id') = '22'
         THEN
            pass;
         ELSE
            fail ($$plsql_line);
         END IF;
      END IF;
   END;


   PRINT ('-- Enrutado basico, la url est� vacia lo que supone que es el index de la pagina');
   dbx.g$path := '';

   IF route_.get ('/') != TRUE
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;
END;