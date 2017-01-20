# Routing

## Basic Routing

The most basic dbax routes simply accept a http verb and URI, providing a very simple and expressive method of defining routes:

```sql      
if dbax_core.route_get ('foo')
then
 htp.p('Hello World');
 return;
end if;
```


**The Route Procedure**

All dbax routes are defined in your route procedure, passed as argument in your procedure front controller. 


**Available Router Methods**

The router allows you to register routes that respond to GET and POST HTTP verbs:

```sql
l_bool := dbax_core.route_get ('foo');
l_bool := dbax_core.route_post ('foo');
```


Sometimes you may need to register a route that responds to multiple HTTP verbs. You may do so using the route method: 

```sql
l_bool := dbax_core.route ('get , post','foo');
```


## Route Parameters

### Required Parameters

Of course, sometimes you will need to capture segments of the URI within your route. For example, you may need to capture a user's ID from the URL. You may do so by defining route parameters:


```sql
if dbax_core.route_get ('user/{id}', l_params )
then
 htp.p('User ' || l_params('id'));
 return;
end if;

```

You may define as many route parameters as required by your route:

```sql
if dbax_core.route_get ('posts/{post}/comments/{comment}', l_params )
then
 htp.p('Post ' || l_params('post'));
 htp.p('Comment ' || l_params('comment'));
 return;
end if;

```

Route parameters are always encased within {} braces and should consist of alphabetic characters.

### Optional Parameters

Occasionally you may need to specify a route parameter, but make the presence of that route parameter optional. You may do so by placing a ? mark after the parameter braces:

```sql
if dbax_core.route_get ('user/{id}?/{name}?', l_param)
then
 htp.p('The id=' ||l_param('id') );
 htp.p('The name=' ||l_param('name') );
 return;
end if;
```


### TODO

NULL en el parametro para indicar la url vacia

advanced regex para indicar case insensitive. 