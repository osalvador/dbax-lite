# HTTP Requests

## Accessing The Request

To access to the current HTTP request, simply use `request_` package anywere in your code:

```sql
create or replace package body pk_user_controller
as
    /**
    * Store a new user.
    *
    * @return CLOB
    */
    function store return clob
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

```sql
l_uri := request_.path();
```

#### Retrieving The Request URL

To retrieve the full URL for the incoming request you may use the `url` or `full_url` methods. The  `url` method will return the URL without the query string, while the `full_url` method includes the query string:

```sql
--Without Query String...
l_url := request_.url();

-- With Query String...
l_url := request_.full_url();
```

#### Retrieving The Request Method
The `method` method will return the HTTP verb for the request. 

```sql
l_method := request_.method();

if request_.method() = 'POST'
then
	...
end if;
```


## Retrieving Input

#### Retrieving All Input Data
You may also retrieve all of the input data as an associative array (`dbx.g_assoc_array`) using the `inputs` method:

```sql
l_inputs := request_.inputs();
```


#### Retrieving An Input Value
Using a few simple methods, you may access all of the user input from your `request_` package without worrying about which HTTP verb was used for the request. Regardless of the HTTP verb, the input method may be used to retrieve user input:

```sql
l_name = request_.input('name');
```


### Cookies

#### Retrieving Cookies From Requests

To retrieve a cookie value from the request, use the cookie method on a `request_` package:

```sql
l_value := request_.cookie('name');
```

#### Attaching Cookies To Responses

You may attach a cookie to an outgoing `response_` package using the cookie method. You should pass the name, value, and  expiration date:

```sql
response_.cookie('name', 'value', sysdate + interval '20' minutes );
```

The cookie method also accepts a few more arguments which are used less frequently:

```sql
response_.cookie('name', 'value', l_20_minutes, l_path, l_domain, l_secure, l_httpOnly );
```