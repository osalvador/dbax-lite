----

### Examples 

#### Todo MVC Application
An implementation of TodoMVC in dbax

#### CRUD Application
https://scotch.io/tutorials/simple-laravel-crud-with-resource-controllers


----


#### Apache

You need to configure Apache to provide URLs without the *application front controller* in the path. Before serving **dbax** with Apache, be sure to enable and configure the `mod_rewrite` module.

```
Options +FollowSymLinks
RewriteEngine On

RewriteCond %{REQUEST_FILENAME} !-d
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^ index.php [L]
```
