# Errors

## Introduction
When you start a new dbax project, error and exception handling is already configured for you. The `dbx.raise_exception`  procedure is where all exceptions triggered by your application are logged and then rendered back to the user. We'll dive deeper into this procedure throughout this documentation.


## Configuration

### Error detail

The `error_style` property determines how much information about an error is actually displayed to the user. By default, this property is not set for security reasons.

For local development, you should set the `error_style` property to `DebugStyle`. In your production environment, this value should always be false or null. If the value is set to `DebugStyle` in production, you risk exposing sensitive information about your application's end users.

#### NO DebugStyle response 

![NO DebugStyle error response](https://raw.githubusercontent.com/osalvador/dbax-lite/gh-pages/docs/No-DebugStyle-error-response.gif)

#### DebugStyle response 

![DebugStyle error response](https://raw.githubusercontent.com/osalvador/dbax-lite/gh-pages/docs/DebugStyle-error-response.gif)

## The Exception Handler

All exceptions are handled by the framework and raises with `dbx.raise_exception` procedure. This procedure  report and render the exception. Report the exception to the log using the `log_` library and the `error` log level. Then render given exception into an HTTP response that should be sent back to the browser.

## Custom HTTP Exceptions

usted puede invocar directamente al procedimiento `dbx.raise_exception` si quiere generar una excepcion HTTP 500 personalizada. 

```sql
	--Raise custom exception
	dbx.raise_exception('99', 'Functional error description');
```

The procedure immediately raise an exception which will be rendered with the error description text.


![Custom error response](https://raw.githubusercontent.com/osalvador/dbax-lite/gh-pages/docs/Custom-error-response.gif)