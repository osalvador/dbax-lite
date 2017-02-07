CREATE OR REPLACE PROCEDURE hello (name_array    IN owa_util.vc_arr DEFAULT dbx.empty_vc_arr
                                 , value_array   IN owa_util.vc_arr DEFAULT dbx.empty_vc_arr )
AS
   -- Unique application ID Name
   l_appid CONSTANT   VARCHAR2 (100) := 'HELLO';
BEGIN
   -- Aplication properties
   dbx.set_property('error_style', 'DebugStyle');   
   -- dbax framework kernel 
   dbx.dispatcher (p_appid     => l_appid
                 , name_array  => name_array
                 , value_array => value_array
                 , router      => 'PK_APP_HELLO.ROUTER');
END hello;
/

CREATE OR REPLACE PACKAGE pk_app_hello
AS   
   FUNCTION router
      RETURN CLOB;
END;
/

CREATE OR REPLACE PACKAGE BODY pk_app_hello
AS
   FUNCTION router
      RETURN CLOB
   AS
   BEGIN
      if route_.get ('/')
      then
       return 'Hello World from dbax';
      end if;      
   END;
END;
/