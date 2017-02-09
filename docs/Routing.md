# Routing

## Basic Routing

The most basic **dbax** routes simply accept a http verb and URI, providing a very simple and expressive method of defining routes:

```sql      
if route_.get ('foo')
then
 return 'hello world from dbax';
end if;
```


### The Route Procedure

All **dbax** routes are defined in your route function, passed as argument in your procedure front controller. 


### Available Router Methods

The router allows you to register routes that respond to any HTTP verb:


```sql
l_bool := route_.get ('foo');
l_bool := route_.post ('foo');
l_bool := route_.put ('foo');
l_bool := route_.patch ('foo');
l_bool := route_.delete ('foo');
l_bool := route_.options ('foo');
```


Sometimes you may need to register a route that responds to multiple HTTP verbs. You may do so using the `match`method. Or, you may even register a route that responds to all HTTP verbs using the `any_` method:


```sql
l_bool := route_.match ('foo', 'get , post');

l_bool := route_.any_ ('foo');
```


> **NOTE:** The PL/SQL gateways only support GET and POST HTTP verbs. To overcome this problem, dbax uses use the `X-HTTP-Method-Override` header. Pass the method you want to use in the `X-HTTP-Method-Override` header and make your call using the POST method.
	``` 
	X-HTTP-Method-Override: PUT
	X-HTTP-Method-Override: PATCH
	X-HTTP-Method-Override: DELETE
	X-HTTP-Method-Override: OPTIONS
	```

## Route Parameters

### Required Parameters

Of course, sometimes you will need to capture segments of the URI within your route. For example, you may need to capture a user's ID from the URL. You may do so by defining route parameters:


```sql
if route_.get ('user/{id}', l_params )
then 
	return 'User ' || l_params('id');
end if;
```

You may define as many route parameters as required by your route:

```sql
if route_.get ('posts/{post}/comments/{comment}', l_params)
then
	return
	' Post: ' || l_params ('post') ||
	' Comment: ' || l_params ('comment');
end if;

```

Route parameters are always encased within {} braces and should consist of alphabetic characters.

### Optional Parameters

Occasionally you may need to specify a route parameter, but make the presence of that route parameter optional. You may do so by placing a ? mark after the parameter braces:

```sql
if route_.get ('user/{id}?/{name}?', l_param)
then
	return
	' The id: ' || l_param ('id') ||
    ' The name: ' || l_param ('name');
end if;
```


## Route to root path

If you want to define a route to root path, sometimes to the index page, the url pattern will be: 

```sql
l_bool := route_.get ('/');
```

## Case insensitive routes

Occasionally you may need to specify a case insensitive routes. You may do so by using [Oracle advanced regex parameters (position, occurrence and match_parameter)](https://docs.oracle.com/cd/B28359_01/server.111/b28286/functions137.htm#SQLRF06302) with `@` as delimiter: 

```sql
if route_.get ('USER/{id}@1,1,i', l_param)
then
	return 'The id: ' || l_param('id') ;
end if;
```