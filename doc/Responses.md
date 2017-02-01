# Responses

## Creating Responses

### Strings & Arrays

All routes and controllers should return a response to be sent back to the user's browser. Laravel provides several different ways to return responses. The most basic response is simply returning a string from a route or controller. The framework will automatically convert the string into a full HTTP response:

Route::get('/', function () {
    return 'Hello World';
});
In addition to returning strings from your routes and controllers, you may also return arrays. The framework will automatically convert the array into a JSON response:

Route::get('/', function () {
    return [1, 2, 3];
});


### Response Objects

Typically, you won't just be returning simple strings or arrays from your route actions. Instead, you will be returning full Illuminate\Http\Response instances or views.

Returning a full Response instance allows you to customize the response's HTTP status code and headers. A Response instance inherits from the Symfony\Component\HttpFoundation\Response class, which provides a variety of methods for building HTTP responses:

Route::get('home', function () {
    return response('Hello World', 200)
                  ->header('Content-Type', 'text/plain');
});