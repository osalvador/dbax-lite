# configuration

## Introduction

All of the configuration properties for the **dbax** framework are stored in an associative array. **dbax** offers a simple api in which you can set or get the properties that you have defined.

You can define the properties you need, as long as they are not reserved by the framework.

## Reserved properties


## Setting properties

## Retrieving properties

Accessing Configuration Values

You may easily access your configuration values using the global config helper function from anywhere in your application. The configuration values may be accessed using "dot" syntax, which includes the name of the file and option you wish to access. A default value may also be specified and will be returned if the configuration option does not exist:

$value = config('app.timezone');
To set configuration values at runtime, pass an array to the config helper:

config(['app.timezone' => 'America/Chicago']);