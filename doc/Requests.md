# HTTP Requests


## Accessing The Request

To obtain an instance of the current HTTP request via dependency injection, you should type-hint the Illuminate\Http\Request class on your controller method. The incoming request instance will automatically be injected by the service container:

```sql
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class UserController extends Controller
{
    /**
     * Store a new user.
     *
     * @param  Request  $request
     * @return Response
     */
    public function store(Request $request)
    {
        $name = $request->input('name');

        //
    }
}
```

### Request Path & Method

The Illuminate\Http\Request instance provides a variety of methods for examining the HTTP request for your application and extends the Symfony\Component\HttpFoundation\Request class. We will discuss a few of the most important methods below.


#### Retrieving The Request Path

The path method returns the request's path information. So, if the incoming request is targeted at  http://domain.com/foo/bar, the path method will return foo/bar:

```
$uri = $request->path();
```

#### Retrieving The Request URL

To retrieve the full URL for the incoming request you may use the url or fullUrl methods. The  url method will return the URL without the query string, while the fullUrl method includes the query string:

```
// Without Query String...
$url = $request->url();

// With Query String...
$url = $request->fullUrl();
```

#### Retrieving The Request Method
The method method will return the HTTP verb for the request. You may use the isMethod method to verify that the HTTP verb matches a given string:

```
$method = $request->method();

if ($request->isMethod('post')) {
    //
}
```


## Retrieving Input

#### Retrieving All Input Data
You may also retrieve all of the input data as an array using the all method:

```
$input = $request->all();
```


#### Retrieving An Input Value
Using a few simple methods, you may access all of the user input from your Illuminate\Http\Request instance without worrying about which HTTP verb was used for the request. Regardless of the HTTP verb, the input method may be used to retrieve user input:

```
$name = $request->input('name');
```


### Cookies

#### Retrieving Cookies From Requests

All cookies created by the Laravel framework are encrypted and signed with an authentication code, meaning they will be considered invalid if they have been changed by the client. To retrieve a cookie value from the request, use the cookie method on a Illuminate\Http\Request instance:

```
$value = $request->cookie('name');
```

#### Attaching Cookies To Responses

You may attach a cookie to an outgoing Illuminate\Http\Response instance using the cookie method. You should pass the name, value, and number of minutes the cookie should be considered valid to this method:

``` 
return response('Hello World')->cookie(
    'name', 'value', $minutes
);
```

The cookie method also accepts a few more arguments which are used less frequently. Generally, these arguments have the same purpose and meaning as the arguments that would be given to PHP's native setcookie method:

```
return response('Hello World')->cookie(
    'name', 'value', $minutes, $path, $domain, $secure, $httpOnly
);
```