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
      raise_application_error (-20001, 'XXX The test failed in the line:' || p_line_number);
   END;
BEGIN
   dbx.g$appid := 'TEST_LOG_';

   EXECUTE IMMEDIATE 'truncate table wdx_log';

   print ('**********');
   print ('Log Levels without log_level property defined');
   print ('**********');

   dbx.set_property ('log_level', NULL);

   print ('-- Log emergency');
   log_.emergency ('This is an emergency message');
   print ('-- Log alert');
   log_.alert ('This is an alert message');
   print ('-- Log critical');
   log_.critical ('This is critical message');
   print ('-- Log error');
   log_.error ('This is an error message');
   print ('-- Log warning');
   log_.warning ('This is an warning message');
   print ('-- Log notice');
   log_.notice ('This is an notice message');
   print ('-- Log info');
   log_.info ('This is an info message');
   print ('-- Log debug');
   log_.debug ('This is an debug message');

   IF log_.write IS NULL
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;

   print ('**********');
   print ('Log Levels with log_level property defined to EMERGENCY');
   print ('**********');

   dbx.set_property ('log_level', 'emergency');

   print ('-- Log emergency');
   log_.emergency ('This is an emergency message');
   print ('-- Log alert');
   log_.alert ('This is an alert message');
   print ('-- Log critical');
   log_.critical ('This is critical message');
   print ('-- Log error');
   log_.error ('This is an error message');
   print ('-- Log warning');
   log_.warning ('This is an warning message');
   print ('-- Log notice');
   log_.notice ('This is an notice message');
   print ('-- Log info');
   log_.info ('This is an info message');
   print ('-- Log debug');
   log_.debug ('This is an debug message');

   IF log_.write IS NULL
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;


   print ('**********');
   print ('Log Levels with log_level property defined to ALERT');
   print ('**********');

   dbx.set_property ('log_level', 'alert');

   print ('-- Log emergency');
   log_.emergency ('This is an emergency message');
   print ('-- Log alert');
   log_.alert ('This is an alert message');
   print ('-- Log critical');
   log_.critical ('This is critical message');
   print ('-- Log error');
   log_.error ('This is an error message');
   print ('-- Log warning');
   log_.warning ('This is an warning message');
   print ('-- Log notice');
   log_.notice ('This is an notice message');
   print ('-- Log info');
   log_.info ('This is an info message');
   print ('-- Log debug');
   log_.debug ('This is an debug message');

   IF log_.write IS NULL
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;

   print ('**********');
   print ('Log Levels with log_level property defined to CRITICAL');
   print ('**********');

   dbx.set_property ('log_level', 'critical');

   print ('-- Log emergency');
   log_.emergency ('This is an emergency message');
   print ('-- Log alert');
   log_.alert ('This is an alert message');
   print ('-- Log critical');
   log_.critical ('This is critical message');
   print ('-- Log error');
   log_.error ('This is an error message');
   print ('-- Log warning');
   log_.warning ('This is an warning message');
   print ('-- Log notice');
   log_.notice ('This is an notice message');
   print ('-- Log info');
   log_.info ('This is an info message');
   print ('-- Log debug');
   log_.debug ('This is an debug message');

   IF log_.write IS NULL
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;

   print ('**********');
   print ('Log Levels with log_level property defined to ERROR');
   print ('**********');

   dbx.set_property ('log_level', 'error');

   print ('-- Log emergency');
   log_.emergency ('This is an emergency message');
   print ('-- Log alert');
   log_.alert ('This is an alert message');
   print ('-- Log critical');
   log_.critical ('This is critical message');
   print ('-- Log error');
   log_.error ('This is an error message');
   print ('-- Log warning');
   log_.warning ('This is an warning message');
   print ('-- Log notice');
   log_.notice ('This is an notice message');
   print ('-- Log info');
   log_.info ('This is an info message');
   print ('-- Log debug');
   log_.debug ('This is an debug message');

   IF log_.write IS NULL
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;

   print ('**********');
   print ('Log Levels with log_level property defined to WARNING');
   print ('**********');

   dbx.set_property ('log_level', 'warning');

   print ('-- Log emergency');
   log_.emergency ('This is an emergency message');
   print ('-- Log alert');
   log_.alert ('This is an alert message');
   print ('-- Log critical');
   log_.critical ('This is critical message');
   print ('-- Log error');
   log_.error ('This is an error message');
   print ('-- Log warning');
   log_.warning ('This is an warning message');
   print ('-- Log notice');
   log_.notice ('This is an notice message');
   print ('-- Log info');
   log_.info ('This is an info message');
   print ('-- Log debug');
   log_.debug ('This is an debug message');

   IF log_.write IS NULL
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;

   print ('**********');
   print ('Log Levels with log_level property defined to NOTICE');
   print ('**********');

   dbx.set_property ('log_level', 'notice');

   print ('-- Log emergency');
   log_.emergency ('This is an emergency message');
   print ('-- Log alert');
   log_.alert ('This is an alert message');
   print ('-- Log critical');
   log_.critical ('This is critical message');
   print ('-- Log error');
   log_.error ('This is an error message');
   print ('-- Log warning');
   log_.warning ('This is an warning message');
   print ('-- Log notice');
   log_.notice ('This is an notice message');
   print ('-- Log info');
   log_.info ('This is an info message');
   print ('-- Log debug');
   log_.debug ('This is an debug message');

   IF log_.write IS NULL
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;

   print ('**********');
   print ('Log Levels with log_level property defined to INFO');
   print ('**********');

   dbx.set_property ('log_level', 'info');

   print ('-- Log emergency');
   log_.emergency ('This is an emergency message');
   print ('-- Log alert');
   log_.alert ('This is an alert message');
   print ('-- Log critical');
   log_.critical ('This is critical message');
   print ('-- Log error');
   log_.error ('This is an error message');
   print ('-- Log warning');
   log_.warning ('This is an warning message');
   print ('-- Log notice');
   log_.notice ('This is an notice message');
   print ('-- Log info');
   log_.info ('This is an info message');
   print ('-- Log debug');
   log_.debug ('This is an debug message');

   IF log_.write IS NULL
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;

   print ('**********');
   print ('Log Levels with log_level property defined to DEBUG');
   print ('**********');

   dbx.set_property ('log_level', 'debug');

   print ('-- Log emergency');
   log_.emergency ('This is an emergency message');
   print ('-- Log alert');
   log_.alert ('This is an alert message');
   print ('-- Log critical');
   log_.critical ('This is critical message');
   print ('-- Log error');
   log_.error ('This is an error message');
   print ('-- Log warning');
   log_.warning ('This is an warning message');
   print ('-- Log notice');
   log_.notice ('This is an notice message');
   print ('-- Log info');
   log_.info ('This is an info message');
   print ('-- Log debug');
   log_.debug ('This is an debug message');

   IF log_.write IS NULL
   THEN
      fail ($$plsql_line);
   ELSE
      pass;
   END IF;
END;