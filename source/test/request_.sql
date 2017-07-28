DECLARE
   PROCEDURE print (text IN VARCHAR2)
   AS
   BEGIN
      dbms_output.put_line (text);
   END;

   PROCEDURE pass
   AS
   BEGIN
      print ('   Pass');
   END;

   PROCEDURE fail (p_line_number IN NUMBER)
   AS
   BEGIN
      raise_application_error (-20001, 'XXX El test ha fallado en la linea:' || p_line_number);
   END;
BEGIN
   print ('**********');
   print ('Probando el metodo request_.method');
   print ('**********');

   print ('-- Asignarle un metodo  GET a request y obtener el metodo asignado');
   request_.method ('GET');

   IF request_.method != 'GET'
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;

   print ('-- Asignarle un metodo POST a request y obtener el metodo asignado');
   request_.method ('POST');

   IF request_.method () != 'POST'
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;

   print ('-- Asignarle un metodo que no valido(get o post), el metodo se debe quedar a NULL');
   request_.method (NULL);
   request_.method ('FURUFUFU');

   IF request_.method IS NOT NULL
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;

   print ('-- Asignarle un metodo get en minusculas, se tiene que guardar siempre en mayusculas');
   request_.method ('get');

   IF request_.method = 'get'
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;
END;