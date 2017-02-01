# Controllers

## Introduction

Instead of defining all of your request handling logic in route function, you may wish to organize this behavior using Controller package. Controllers can group related request handling logic into a single package. 

## Basic Controllers

### Defining Controllers

Below is an example of a basic controller package:

```sql
create or replace package body pk_user_controller
as
    /**
     * Show the profile for the given user.
     *
     * @param  int  $id
     * @return Response
     */
   function show(p_id in pls_integer) return clob
   as
   begin
      view_.data('user', p_id);
      return view_.run(pk_user_views.profile(), 'profile');
   end;
end pk_user_controller;
```


You can define a route to this controller action like so:

```sql
if route_.get ('/user/{id}', l_url_params)
then
	return pk_user_controller.show( l_url_params ('id') );
end if;
```

Now, when a request matches the specified route URI, the show method on the `pk_user_controller` package will be executed.


