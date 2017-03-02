# tePLSQL Templates

## Introduction

tePLSQL is the simple, yet powerful templating engine provided with dbax. tePLSQL does not restrict you from using plain PLSQL code in your views. In fact, all tePLSQL views are compiled into plain PLSQL code and cached until they are modified, meaning tePLSQL adds essentially zero overhead to your application. tePLSQL views are typically stored in package functions returning a CLOB. The views will be cached in `WDX_VIEWS` table.


## Nested Templates

### Defining A Layout

The primary benefits of using tePLSQL are nested templates. To get started, let's take a look at a simple example. 


```html
FUNCTION home
      RETURN CLOB
   AS
   BEGIN
      return q'[
<html>
    <head>
        <title>App Name - ${title}</title>
    </head>
    <body>
        <%@ include(pk_app_views.sidebar) %>
        
        <div class="container">
            <!-- Your content goes here -->
            <p>This is my body content.</p>
        </div>
    </body>
</html>]';      
   END;
```

As you can see, this view contains typical HTML mark-up. However, take note of the `<%@ include() %>` directive. Include directive allows you to include a tePLSQL view from within another view.

Now that we have defined a layout for our application, let's define an included page.


### Included template

When defining an included view, all variables that are available in the parent view will be made available to the included view. tePLSQL search the template and include it in a new `DECLARE BEGIN END;` block, which assigned its own scope.

```html
<%@ include(template1) %>
    --template1 include template2
    <%@ include(template2) %>    
      --template3 include template3
        <%@ include(template3) %>    
```

Will be interpreted as:

```sql
DECLARE
BEGIN
--template1
    DECLARE
    BEGIN  
    --template2  
        DECLARE
        BEGIN
        --template3
        END;    
    END;
END;
```

The sidebar view should be like this: 

```html
FUNCTION sidebar
  RETURN CLOB
   AS
   BEGIN   	  
      return q'[<p>This is appended to the master sidebar.</p>]';
END;
```


tePLSQL view may be returned from routes using the `view_` package:

```sql
IF route_.get ('tePLSQL')
THEN
 view_.data('title','Page Title');
 view_.run (pk_app_name.home (), 'home');
END IF;
```

And will be rendered as: 

```html
<html>
    <head>
        <title>App Name - Page Title</title>
    </head>
    <body>
        <p>This is appended to the master sidebar.</p>
        
        <div class="container">
            <!-- Your content goes here -->
            <p>This is my body content.</p>
        </div>
    </body>
</html>
```

## Displaying Data

You may display VARCHAR2 data passed to your tePLSQL views by wrapping the variable with `${varName}`.For example, given the following route:

```sql
IF route_.get ('greeting')
THEN
	view_.data('name','Samantha');
	view_.run (pk_app_name.welcome (), 'welcome');
END IF;
```

You may display the contents of the name variable like so:

```
Hello, ${name}.
```


To display different Data Types (or even VARCHAR2) data you may use the expression `<%= %>` directive. For example, given the following route: 

```sql
IF route_.get ('greeting')
THEN
  -- Varchar
  view_.data('name','Samantha');
  -- Number
  view_.data('Age',33);
  -- Date
  view_.data('Tomorrow',sysdate+1);
  -- Associaative Array
  view_.data('assoc_array',request_.headers ());
  -- CLOB
  view_.data('clob_data', TO_CLOB('This is my CLOB'));

  --SYS_REFCURSOR
  OPEN l_users_cursor FOR SELECT * FROM SYS.all_users order by created desc;
  view_.data ('users_refcursor', l_users_cursor);


  view_.run (pk_app_name.welcome (), 'welcome');
END IF;
```

You may display the contents of the variables like so:

```
Hello, <% name %> you are <%= age %> years old, tomorrow day <%= to_char(Tomorrow, 'DD') %> will be another day. 

Your browser is <%= assoc_array('HTTP_USER_AGENT') %>. And <%= clob_data %> data.
```

> Note: You should iterate SYS_CURSOR in the traditional Oracle way, LOOP FETCH INTO or FETCH BULK COLLECT INTO. [You can view an example in Views section](https://dbax.io/documentation/en/Views.html#views-passing-data-to-views)


> Note: With expression directive `<%= %>` , the name of the variables are not case sensitive. 

Of course, you are not limited to displaying the contents of the variables passed to the view. You may also print the results of any PLSQL function. In fact, you can put any PLSQL code you wish inside of a tePLSQL expression statement:

```
The current UNIX timestamp is <%= systimestamp %>.
```


### Print Data If It Exists

Sometimes you may wish to print a variable, but you aren't sure if the variable has been set. We can express this in simple PLSQL code like so:

```sql
<%= NVL(name, 'Default') %>
```


## Declaration of variables

tePLSQL includes the Declaration block direcetive `<%! %>`, that is the declaration for a set of PL/SQL variables that are visible throughout the template.

You may declare a ROWTYPE array, for example to FETCH BULK COLLECT INTO a collection from SYS_REFCURSOR:

```
<%! TYPE l_users_type
    IS
    TABLE OF sys.all_users%ROWTYPE
    INDEX BY PLS_INTEGER;
                 
    l_users   l_users_type;
%>
```


## Control Structures

In addition to nested templates and displaying data, tePLSQL also provides PLSQL control structures, such as conditional statements and loops.

### If Statements

You may construct if statements using the `if`, `elsif`, `else`, and `end if` statements. These statements work identically to PLSQL:

```
<% if records.count = 1 then %>
    I have one record!
<% elsif records.count > 1 then %>
    I have multiple records!
<% else %>
    I don't have any records!
<% end if; %>
```

### Loops

In addition to conditional statements, tePLSQL provides simple directives for working with PLSQL's loop structures.

```
<% for i in 1 .. 10 loop %>
	The current value is <%= i %>
<%end loop;%>

<% for i in 1 .. users.count loop %>
   <p>This is user <%= users(i).id %> </p>
<% end loop; %>

<% while true loop %>
    <p>I am looping forever.</p>
<% end loop; %>

/* You can even use an Implicit Cursor FOR LOOP Statement*/
<%  for item in (select last_name, job_id 
                 from employees
                  where job_id like '%CLERK%'
                  order by last_name) loop %>     
      <p> Name = <%= item.last_name %>, Job = <%= item.job_id %>
<% end loop; %>
```

### Comments

tePLSQL also allows you to define comments in your views. However, unlike HTML comments, tePLSQL comments are not included in the HTML returned by your application:

```
<% /*This comment will not be present in the rendered HTML*/ %>
```


### PLSQL

In some situations, it's useful to embed PLSQL code into your views. You can use the tePLSQL code block `<% %>` directive to execute a block of plain PLSQL within your template:

```
<%
    /*PLSQL Code*/
%>
```

> Note: While tePLSQL provides this feature, using it frequently may be a signal that you have too much logic embedded within your template.



