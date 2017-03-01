# Logging

## Introduction

When you start a new dbax application, logging is already configured for you. dbax utilizes the `log_` library, which provides simple but powerful API. dbax stores your logs in the `WDX_LOG` table saving all the messages of a complete request of the user in a single row.


## Configuration

### Log Severity Levels
When using `log_`, log messages may have different levels of severity. By default, dbax writes all log levels to storage. However, in your production environment, you may wish to configure the minimum severity that should be logged by adding the `log_level` property.

Once this option has been configured, dbax will log all levels greater than or equal to the specified severity. For example, a default `log_level` of `error` will log *error*, *critical*, *alert*, and *emergency* messages:

```sql
   -- Aplication properties
   dbx.set_property ('log_level', 'error');
```


> Note: dbax `log_` recognizes the following severity levels - from least severe to most severe: `debug`, `info`, `notice`, `warning`, `error`, `critical`, `alert`, `emergency`.

## Logging your application

By default, dbax is configured to create a log row for your application per user request. You may write information to the logs using `log_` package: 

```sql
	log_.info('Info message');
```

The logger provides the eight logging levels defined in [RFC 5424](https://tools.ietf.org/html/rfc5424): *emergency*, *alert*, *critical*, *error*, *warning*, *notice*, *info* and *debug*.

```sql
	log_.emergency('This is emergency message');
	log_.alert('This is alert message');
	log_.critical('This is critical message');
	log_.error('This is error message');
	log_.warning('This is warning message');
	log_.notice('This is notice message');
	log_.info('This is info message');
	log_.debug('This is debug message');
```

## Review your logs

dbax stores its logs in the `WDX_LOG` table, saving all the messages of a complete request of the user in a single row. The `LOG_MESSAGE` field is where log messages are stored. 

```
select * from WDX_LOG;

ID| APPID      |SESSION_ID          |LOG_LEVEL|LOG_MESSAGE|CREATED_BY |CREATED_DATE    
--|------------|--------------------|---------|-----------|-----------|------------------------|
1	HELLO		01112451000198580		debug	(CLOB)		ANONYMOUS	28/02/17 09:37:41,320773000
2	HELLO		01112451000198580		debug	(CLOB)		ANONYMOUS	28/02/17 09:39:58,996656000
3	GREETING	01112451000163191		debug	(CLOB)		ANONYMOUS	28/02/17 09:40:27,073755000
4	GREETING	01112451000163191		debug	(CLOB)		ANONYMOUS	28/02/17 09:42:20,663604000 
```


### LOG_MESSAGE content

The messages stored in the `LOG_MESSAGE` field contains the following structure: 

`[TIMESTAMP] [LOG_LEVEL] [[SCHEMA].[PACKAGE]:[LINE_NUMBER]] [LOG_MESSAGE]`

- `[TIMESTAMP]` the timestamp of the message.
- `[LOG_LEVEL]` the log level of the message.
- `[[SCHEMA].[PACKAGE]:[LINE_NUMBER]]` the shema name, package name and the package line number where the message is written. 
- `[LOG_MESSAGE]` the log message sent. 

Log message content example: 

```
28-02-2017 09:49:00.104420000 debug	DBAX_THIN.DBX:427 Request input:p=/
28-02-2017 09:49:00.104781000 debug	DBAX_THIN.DBX:427 Request input:inputName=Oscar
28-02-2017 09:49:00.105064000 debug	DBAX_THIN.DBX:427 Request input:inputAge=33
28-02-2017 09:49:00.106905000 info	DBAX_THIN.PK_APP_GREETING:58 Saved to session_:l_input_name=Oscar
28-02-2017 09:49:00.107413000 info	DBAX_THIN.PK_APP_GREETING:59 Saved to session_:l_input_age=33
28-02-2017 09:49:00.108845000 debug CGI ENV 
	host = localhost:8090
	connection = keep-alive
	content-length = 25
	pragma = no-cache
	cache-control = no-cache
	origin = http://localhost:8090
	upgrade-insecure-requests = 1
	user-agent = Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.74 Safari/537.36
	content-type = application/x-www-form-urlencoded
	accept = text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8
	dnt = 1
	referer = http://localhost:8090/greeting/
	accept-encoding = gzip, deflate, br
	accept-language = en-GB,en;q=0.8,es;q=0.6
	cookie = DBAXSESSID=01112451000163191
	APEX_LISTENER_VERSION = 3.0.9.348.07.16
	DAD_NAME = 
	DOC_ACCESS_PATH = 
	DOCUMENT_TABLE = 
	GATEWAY_IVERSION = 3
	GATEWAY_INTERFACE = CGI/1.1
	HTTP_ACCEPT = text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8
	HTTP_ACCEPT_ENCODING = gzip, deflate, br
	HTTP_ACCEPT_LANGUAGE = en-GB,en;q=0.8,es;q=0.6
	HTTP_ACCEPT_CHARSET = 
	HTTP_IF_MODIFIED_SINCE = 
	HTTP_IF_NONE_MATCH = 
	HTTP_HOST = localhost:8090
	HTTP_ORACLE_ECID = 
	HTTP_PORT = 8090
	HTTP_REFERER = http://localhost:8090/greeting/
	HTTP_USER_AGENT = Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.74 Safari/537.36
	PATH_ALIAS =  
	PATH_INFO = /!greeting
	PLSQL_GATEWAY = WebDb
	QUERY_STRING = p=%2F
	REMOTE_ADDR = 127.0.0.1
	REMOTE_USER = DBAX_THIN
	REQUEST_CHARSET = AL32UTF8
	REQUEST_IANA_CHARSET = UTF-8
	REQUEST_METHOD = POST
	REQUEST_PROTOCOL = http
	REQUEST_SCHEME = http
	SCRIPT_NAME = /ords
	SCRIPT_PREFIX = 
	SERVER_NAME = localhost
	SERVER_PORT = 8090
	SERVER_PROTOCOL = HTTP/1.1
	SERVER_SOFTWARE = Mod-Apex
	WEB_AUTHENT_PREFIX =  
	HTTP_COOKIE = DBAXSESSID=01112451000163191
```


dbax logger automatically prints all CGI Environment to the log when the `log_level` is *error*, *critical*, *alert*, *emergency* or *debug*.

