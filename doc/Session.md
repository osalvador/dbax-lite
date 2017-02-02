# Session

## Introduction

Since HTTP driven applications are stateless, sessions provide a way to store information about the user across multiple requests. **dbax** includes an expressive API for access to session information.

## Using The Session

### Retrieving Data

The `session_` package is the primary way to working with session data. 

```sql
if route_.get ('home') then
	l_value := session_.get('key');
	
	return null;
end if;

```

#### Retrieving All Session Data

If you would like to retrieve all the data in the session, you may use the `gel_all` function:

```sql
l_data := session_.get_all();
```

#### Determining If An Item Exists In The Session

To determine if a value is present in the session, you may use the `has` function. The `has` function returns true if the value is present and is not null:

```sql
if session_.has('users') then
	...
end if;
```


### Storing Data

To store data in the session, you will typically use the `set` function:

```sql
session_.set('key', 'value');
```


#### Retrieving & Deleting An Item

The pull method will retrieve and delete an item from the session in a single statement:

```sql 
l_value = session_.pull('key');
```

### Deleting Data

The delete method will remove a piece of data from the session. If you would like to remove all data from the session, you may use the flush method:

```sql
session_.delete('key');

session_.flush;
```