# HTTP Requests


## Accessing The Request

To access to the current HTTP request, simply use `request_` package anywere in your code:

```plsql
create or replace package body pk_user_controller
as
   /**
    * Store a new user.
    *
    * @return Response
    */
   function store
      return clob
   as
      l_name varchar2(4000);
   begin
      l_name := request_.input('name');

      ...
   end;
end pk_user_controller;
```

### Request Path & Method

The `request_` package provides a variety of methods for examining the HTTP request for your application. We will discuss a few of the most important methods below.

#### Retrieving The Request Path

The `path` method returns the request's path information. So, if the incoming request is targeted at `http://domain.com/foo/bar`, the `path` method will return `foo/bar`:

```plsql
l_uri := request_.path();
```

#### Retrieving The Request URL

To retrieve the full URL for the incoming request you may use the `url` or `fullUrl` methods. The  `url` method will return the URL without the query string, while the `fullUrl` method includes the query string:

```plsql
--Without Query String...
l_url := request_.url();

-- With Query String...
l_url := request_.fullUrl();
```

#### Retrieving The Request Method
The `method` method will return the HTTP verb for the request. 

```plsql
l_method := request_.method();

if request_.method() = 'POST'
then
	...
end if;
```


## Retrieving Input

#### Retrieving All Input Data
You may also retrieve all of the input data as an associative array (`dbx.g_assoc_array`) using the `inputs` method:

```plsql
declare
	l_inputs dbx.g_assoc_array;
begin
	l_inputs := request_.inputs();
end;
```


#### Retrieving An Input Value
Using a few simple methods, you may access all of the user input from your `request_` package without worrying about which HTTP verb was used for the request. Regardless of the HTTP verb, the input method may be used to retrieve user input:

```plsql
l_name = request_.input('name');
```


### Cookies

#### Retrieving Cookies From Requests

To retrieve a cookie value from the request, use the cookie method on a `request_` package:

```plsql
l_value := request_.cookie('name');
```

#### Attaching Cookies To Responses

You may attach a cookie to an outgoing `response_` package using the cookie method. You should pass the name, value, and  expiration date:

```plsql
response_.cookie('name', 'value', sysdate + interval '20' minutes );
```

The cookie method also accepts a few more arguments which are used less frequently:

```plsql
response_.cookie('name', 'value', l_20_minutes, l_path, l_domain, l_secure, l_httpOnly );
```
