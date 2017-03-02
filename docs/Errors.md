# Errors

## Introduction
When you start a new dbax project, error and exception handling is already configured for you. The `dbx.raise_exception`  procedure is where all exceptions triggered by your application are logged and then rendered back to the user. We'll dive deeper into this procedure throughout this documentation.


## Configuration

### Error detail

The `error_style` property determines how much information about an error is actually displayed to the user. By default, this property is not set for security reasons.

For local development, you should set the `error_style` property to `DebugStyle`. In your production environment, this value should always be false or null. If the value is set to `DebugStyle` in production, you risk exposing sensitive information about your application's end users.

#### NO DebugStyle response 

![NO DebugStyle error response](https://raw.githubusercontent.com/osalvador/dbax-lite/gh-pages/docs/No-DebugStyle-error-response.png)

#### DebugStyle response 

![DebugStyle error response](https://raw.githubusercontent.com/osalvador/dbax-lite/gh-pages/docs/DebugStyle-error-response.gif)

## The Exception Handler

All exceptions are handled by the framework and raises with `dbx.raise_exception` procedure. This procedure  report and render the exception. Report the exception to the log using the `log_` library and the `error` log level. Then render given exception into an HTTP response that should be sent back to the browser.


## Custom HTTP Exceptions

La forma mas elegante de lanzar una excepcion personalizada es usando el procedimiento de estandar de Oracle `raise_application_error`. Typically, you invoke this procedure to raise a user-defined exception and return its error code and error message to the invoker.


```sql
	--Raise user-defined exception
	raise_application_error( -20001, 'Functional error description');
```


You can even directly invoke the `dbx.raise_exception` procedure if you want to generate a custom HTTP 500 exception. Always remember to `RETURN` your function because `dbx.raise_exception` only reports and renders the exception produced.

```sql
	--Raise custom exception
	dbx.raise_exception('99', 'Functional error description');
	RETURN NULL;
```


The procedure immediately report and render the exception with the error description text.


![Custom error response](https://raw.githubusercontent.com/osalvador/dbax-lite/gh-pages/docs/Custom-error-response.png)

