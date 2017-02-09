# configuration

## Introduction

All of the configuration properties for the dbax framework are stored in an associative array. dbax offers a simple api in which you can set or get the properties that you have defined.

You can define the properties you need, as long as they are not reserved by the framework.

## Reserved properties

- `base_path`: contains path to the application front controller.
- `encoding`: contains the response Content-Type charset encoding.
- `error_style`: null or DebugStyle. If set to DebugStyle run-time errors will be displayed with the maximum detail.

## Setting properties

You may use the set_property function to add a series of custom properties to the application:

```sql
-- Custom aplication properties  
dbx.set_property('error_style', 'DebugStyle');
dbx.set_property('base_path', '/greeting');
```


## Retrieving properties

You may easily access your configuration values using the get_property function from anywhere in your application. 

```sql
l_error_style := dbx.get_property ('error_style');
```
