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
   PRINT ('Seccion');
   PRINT ('**********');
   
   
   PRINT ('-- Prueba unitaria');
   
   IF true = TRUE
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;

END;