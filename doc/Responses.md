# Responses

## Creating Responses

### Strings & Arrays

All routes and controllers should return a response to be sent back to the user's browser. dbax provides several different ways to return responses. The most basic response is simply returning a string from a route or controller. The framework will automatically convert the string into a full HTTP response:

```sql
if route_.get ('foo') then
	return 'hello World from dbax';
end if;
```


### Response Package

Typically, you won't just be returning simple strings from your route actions. Instead, you will customize your response with `response_` package or `view_` package.

`response_` packaage allows you to customize the response's HTTP status code and headers. A `resoponse_` package provides a variety of methods for building HTTP responses:

```sql
if route_.get ('home') then
	response_.status(200);
	response_.content('text/plain');
	return 'hello World from dbax';
end if;
```

### Attaching Headers To Responses

You may use the header method to add a series of headers to the response before sending it back to the user:

```sql
response_.header('Content-Type', l_type);
response_.header('X-Header-One', 'Header Value');
response_.header('X-Header-Two', 'Header Value');
return l_content;
```


### Attaching Cookies To Responses

The cookie method on response package allows you to easily attach cookies to the response. For example, you may use the cookie method to generate a cookie and fluently attach it to the response instance like so:

```sql
response_.header('Content-Type', l_type);
response_.cookie('name', 'value', sysdate + interval '20' minutes );
return l_content;
```

The cookie method also accepts a few more arguments which are used less frequently:

```sql
response_.cookie('name', 'value', l_20_minutes, l_path, l_domain, l_secure, l_httpOnly );
```

## Redirects

`redirect` are custom responses and contain the proper headers needed to redirect the user to another URL. The simplest method is to use the `dbx.redirect` procedure:

```sql
if route_.get ('dashboard') then
	redirect('/home/dashboard');
	return null;
end if;
```


## Other Response Types

The response helper may be used to generate other types of response instances. When the  response helper is called without arguments, an implementation of the  Illuminate\Contracts\Routing\ResponseFactory contract is returned. This contract provides several helpful methods for generating responses.


### View Responses

If you need control over the response's status and headers but also need to return a view as the response's content, you should use the `view_` package:

```sql
response_.header('Content-Type', l_type);
response_.status(200);
view_.data('l_variable', l_data);
return view_.run(pk_views.hello(), 'hello');
```

Of course, you do not need to pass a custom HTTP status code or custom headers.


### JSON Responses

Por defecto dbax no incluye modulos para la creacion de json, pero usted puede usar el método que quiera para hacerlo y posteriormente personalizar la respuesta: 

By default dbax does not include automatic generation of json responses , but you can use the module you want to do it and then customize the response:

```sql
if route_.get ('user') then
	response_.content('application/json');
	return '{ "name":"John", "age":31, "city":"New York" }';
end if;
```

