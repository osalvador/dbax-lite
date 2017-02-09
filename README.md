# dbax Lite Framework
dbax is PL/SQL framework for MVC Web Development of high-performing database-driven Web applications. It's designed to be lightweight and modular, allowing developers to build better and easy to maintain code with PL/SQL to develop Web applications. 

### Features

* **MVC**; which allows great separation between logic and presentation. 
* **Routing**; simple but powerfull url routing. The URLs generated by dbax are clean and search-engine friendly.
* **Modular**; (you can choose which components to use).
* **Write SQL and PL/SQL**; Use all PL/SQL libraries you like.
* **Lightweight**; Just some packages. 
* **Template Engine**; dbax uses [tePLSQL] which has the same syntax as [Oracle PSP].
* **Fast**; dbax has been developed on top of PL/SQL Web Toolkit.
* **Free**; dbax is licensed under the LGPL license so you can use it however you please. 

[tePLSQL]: https://github.com/osalvador/tePLSQL
[Oracle PSP]: http://docs.oracle.com/cd/E11882_01/appdev.112/e41502/adfns_psp.htm#ADFNS016

## Requirements

- Oracle Database 11g or later, compatible with Oracle XE (Express edition).
- HTTP PL/SQL gateway to invoke a PL/SQL stored procedure through an HTTP listener: [ORDS] with JEE container (Tomcat, Glassfish, WebLogic) or [DBMS_EPG] package

[ORDS]: http://www.oracle.com/technetwork/developer-tools/rest-data-services/overview/index.html
[DBMS_EPG]: https://docs.oracle.com/cd/B28359_01/appdev.111/b28419/d_epg.htm

## Installation

Clone the repo and install in your Oracle database. See [Installation](docs/Installation.md) section in the documentation for more information. 

```sh
git clone https://github.com/osalvador/dbax-lite.git
cd dbax-lite/source/install
sqlplus "user/userpass"@SID @dbax-lite-install.sql
```

## Examples 

### Hello World

Simply create the application front controller procedure and invoke the router.

```sql      
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
```


[Download source code >](examples/hello/helloApp.sql)

### Greeting application 

Simple application that greets the user. The [PRG](https://en.wikipedia.org/wiki/Post/Redirect/Get) pattern is used to prevent duplicate form submissions. 

[View Greeting application code >](examples/greeting)

## Contributing

If you have ideas, get in touch directly.

Please inser at the bottom of your commit message the following line using your name and e-mail address .

    Signed-off-by: Your Name <you@example.org>

This can be automatically added to pull requests by committing with:

    git commit --signoff


## License

Copyright 2017 Oscar Salvador Magallanes 

dbax Lite is under LGPL license. 
