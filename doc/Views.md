# Views

## Creating Views

Views contain the HTML served by your application and separate your controller / application logic from your presentation logic. Views are stored in package functions or in `wdx_views` table. **dbax** uses [tePLSQL](https://github.com/osalvador/tePLSQL) as template engine, which has the same syntax as [Oracle PSP](http://docs.oracle.com/cd/E11882_01/appdev.112/e41502/adfns_psp.htm#ADFNS016). A simple view might look something like this:

```html
function greeting return clob
as
begin
	return
	'<html>
	    <body>
	        <h1>Hello, ${name}</h1>
	    </body>
	</html>';
end;

```

Since this view is stored in a function, we may return it using the `view_` package like so:

```sql 
if route_.get ('/') then
  view_.data('name', 'James');
  return view_.run(greeting(), 'greeting');
end if;
```

As you can see, the first argument passed to the `view_.run` package corresponds to the view template returned by the function `greeting`. The second argument is the unique name of the view to save it in the `wdx_views` table. Previously we pass data that should be made available to the view. In this case, we are passing the `name` variable, which is displayed in the view using tePLSQL syntax.

Whenever a view is run for the first time, or has changed since the last time it was run, it will be compiled to pure plsql. This is done by performance, as it is much more efficient to execute plsql. This is why the `wdx_views` table is used to store the compiled code of the view.

## Purging views

As mentioned earlier, compiled views are stored in the `wdx_views` table. Sometimes it is necessary to purge or delete all compiled views, for this you can use the `purge_compiled` method:

```sql
exec view_.purge_compiled;
```

## Passing Data To Views

As you saw in the previous example, you may pass a varchar data to views:

```sql
view_.data('name', 'Victoria');
return view_.run(greeting(), 'greeting');
```

In addition to varchar, you can pass other data types:
- `VARCHAR`
- `NUMBER`
- `DATE`
- `dbx.g_assoc_array`
- `SYS_REFCURSOR`

Inside your view, you can then access each value using its corresponding key, such as `<%= key %>`. 

Special attention to `SYS_REFCURSOR` since it is a pointer to a cursor. Therefore you should iterate this cursor in the traditional Oracle way, `LOOP FETCH INTO` or `FETCH BULK COLLECT INTO`:

```html
create or replace function all_users return clob
as
begin
   return q'[
        <html>
           <body>
              <table class="table">
                 <thead>
                    <tr>
                       <th>Username</th>
                       <th>User ID</th>
                       <th>Created</th>
                    </tr>
                 </thead>
                 <tbody>
                    <%! /*Declare type and variable to BULK COLLECT CURSOR */
                       TYPE l_users_type
                       IS
                          TABLE OF sys.all_users%ROWTYPE
                              INDEX BY PLS_INTEGER;
                        
                        l_users   l_users_type;
                    %>

                    <% /* BULK COLLECT the cursor in l_users variable */
                       FETCH l_users_cursor  BULK COLLECT INTO l_users; 
                       CLOSE l_users_cursor;
                    %>
                    
                    <% for i in 1 .. l_users.count loop %>
                    <tr>
                       <td><%= l_users(i).username %></td>
                       <td><%= l_users(i).user_id %></td>
                       <td><%= to_char(l_users(i).created, 'YYYY/MM/DD hh24:mi') %></td>
                    </tr>
                    <% end loop; %>
                 </tbody>
              </table>
           </body>
        </html>]';
end;
```

And then in your router / controller for example: 

```sql 
declare
	l_users_cursor   sys_refcursor;
begin
    if route_.get ('users')
    then
       --Open cursor to pass to view
       OPEN l_users_cursor FOR SELECT * FROM sys.all_users ORDER BY created DESC;

       --Send cursor to view
       view_.data ('l_users_cursor', l_users_cursor);

       return view_.run (all_users (), 'allUsers');
    end if;
end;
```

By default all data are accessible by all rendered views during the request life cycle.
