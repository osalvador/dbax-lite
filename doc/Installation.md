# Installation


## Server Requirements

The **dbax** framework has a few system requirements, you will need to make sure your server meets the following requirements:

- Oracle Database 11g or greater. [Oracle Express edition](http://www.oracle.com/technetwork/database/database-technologies/express-edition/overview/index.html) (free edition) is also compatible. 
	- [How to get an Oracle database](#how-to-get-an-oracle-database)
- PL/SQL Gateway. [Oracle Rest Data Services](http://www.oracle.com/technetwork/developer-tools/rest-data-services/overview/index.html) enabling the pl/sql gateway, this is the first option. Or [DBMS_EPG](https://docs.oracle.com/cd/B28359_01/appdev.111/b28419/d_epg.htm#CHDIDGIG).
	- Configure PL/SQL Gateway
		- [ORDS](#ords-installation)
		- [DBMS_EPG](#dbms_epg-configuration)
- [Web server configuracion for pretty URLs](#web-server-configuration)
	- [Nginx](#nginx)
	- [Tomcat](#tomcat)


## Installing dbax

To install **dbax** you will need to have a user with the `RESOURCE` role. Then installation process is very simple, just download the source code and compile it.

```sh
git clone https://github.com/osalvador/dbax-lite.git
cd dbax-lite/source/install
sqlplus "user/userpass"@SID @dbax-lite-install.sql
```


RESOURCE role has the following grants:

```sql
CREATE PROCEDURE	
CREATE SEQUENCE
CREATE TABLE	
CREATE TRIGGER	
CREATE TYPE	
```


## How to get an Oracle database

### For development environment

**Oracle Database 11g Express Edition**

From Oracle page:

> Oracle Database 11g Express Edition (Oracle Database XE) is an entry-level, small-footprint database based on the Oracle Database 11g Release 2 code base. It's free to develop, deploy, and distribute; fast to download; and simple to administer.

[Oracle Express edition](http://www.oracle.com/technetwork/database/database-technologies/express-edition/overview/index.html)

**Oracle Pre-Built Developer VMs (for Oracle VM VirtualBox)**

Oracle provides pre-built developer virtual machines available for free download.

From Oracle page:

> Learning your way around a new software stack is challenging enough without having to spend multiple cycles on the install process. Instead, we have packaged such stacks into pre-built Oracle VM VirtualBox appliances that you can download, install, and experience as a single unit. Just downloaded/assemble the files, import into VirtualBox (available for free), import, and go (but not for production use or redistribution)!


The recommended virtual machine is [Database App Development VM](http://www.oracle.com/technetwork/community/developer-vm/index.html#dbapp)

[Pre-Built Developer VMs (for Oracle VM VirtualBox)](http://www.oracle.com/technetwork/community/developer-vm/index.html)

**Docker Image**

Unofficial docker image: [Oralce XE 11g](https://hub.docker.com/r/wnameless/oracle-xe-11g/)


### For production environment

**Oracle Database 11g Express Edition**

> Oracle Database 11g Express Edition (Oracle Database XE) is an entry-level, small-footprint database based on the Oracle Database 11g Release 2 code base. It's free to develop, deploy, and distribute; fast to download; and simple to administer. 

[Oracle Express edition](http://www.oracle.com/technetwork/database/database-technologies/express-edition/overview/index.html)

**Amazon RDS for Oracle Database**

> Oracle® Database is a relational database management system developed by Oracle. Amazon RDS makes it easy to set up, operate, and scale Oracle Database deployments in the cloud. With Amazon RDS, you can deploy multiple editions of Oracle Database in minutes with cost-efficient and re-sizable hardware capacity. Amazon RDS frees you up to focus on application development by managing time-consuming database administration tasks including provisioning, backups, software patching, monitoring, and hardware scaling.

[Amazon RDS for Oracle Database](https://aws.amazon.com/en/rds/oracle/)

## Configure a PL/SQL Gateway

### ORDS Installation 


### DBMS_EPG configuration 

```sql
BEGIN
   DBMS_EPG.drop_dad ('DBAX');
END;

BEGIN
   DBMS_EPG.create_dad (dad_name => 'DBAX', PATH => '/dbax/*');
END;

BEGIN
   DBMS_EPG.set_dad_attribute (dad_name     => 'DBAX',
                               attr_name    => 'error-style',
                               attr_value   => 'DebugStyle');

   DBMS_EPG.set_dad_attribute (dad_name     => 'DBAX',
                               attr_name    => 'database-username',
                               attr_value   => '<DBAX USERNAME>');

   DBMS_EPG.set_dad_attribute (dad_name     => 'DBAX',
                               attr_name    => 'session-state-management',
                               attr_value   => 'StatelessWithFastResetPackageState');                               
END;

BEGIN
   DBMS_EPG.authorize_dad (dad_name => 'DBAX', USER => '<DBAX USERNAME>');   
END;
```


## Web Server Configuration

### Pretty URLs

**dbax** uses the query string parameter `p` to identify the URI entered by the user. In this way and with a simple rewrite of urls **dbax** has pretty and clean urls. 

#### Nginx

If you are using Nginx, the following directive in your site configuration will direct all requests to the *application fron contrller* in your PL/SQL Gateway, making a reverse proxy:

From: **http://example.com/home**

To: **http://127.0.0.1:8080/ords/!example?p=/home**

```
location / {    
    rewrite  ^/(.*) /ords/!example?p=/$1  break;

    proxy_pass  http://127.0.0.1:8080;
}
```


From: **http://example.com/greeting/home**

To: **http://127.0.0.1:8080/ords/!greeting?p=/home**

```
 location /greeting/ {
        rewrite  ^/(.*) /ords/!greeting?p=$1  break;        

        proxy_pass  http://127.0.0.1:8080;
    }

```

#### Tomcat

Tomcat from version 8 implements [URL rewrite functionality](https://tomcat.apache.org/tomcat-8.0-doc/rewrite.html) in a way that is very similar to mod_rewrite from Apache HTTP Server.

Essentially, all you need to do is include the rewrite valve class `org.apache.catalina.valves.rewrite.RewriteValve` in your application's context. This can be either the global `context.xml` or in the context block of a host in the server.xml; both found in Tomcat's `${TOMCAT_HOME}/conf` directory. Then drop a `rewrite.config` file containing your rewrites into the WEB-INF folder of `${TOMCAT_HOME}/webapps/ROOT/WEB-INF` or wherever your application's root WEB-INF is. Using the global `context.xml` will effect all virtual host setups you've defined in your `server.xml` so if you have multiple apps running, it may be best to do a per host setup of the rewrite valve.


**Global Configuration**

Set the rewrite valve in Tomcat's `context.xml` located in `${TOMCAT_HOME}/conf/context.xml`:

```xml
<?xml version='1.0' encoding='utf-8'?>
<!-- The contents of this file will be loaded for each web application -->
<Context>

 	<!-- REWRITE VALVE -->
    <Valve className="org.apache.catalina.valves.rewrite.RewriteValve" />
    <!-- // -->
	

    <!-- Default set of monitored resources. If one of these changes, the    -->
    <!-- web application will be reloaded.                                   -->
    <WatchedResource>WEB-INF/web.xml</WatchedResource>
    <WatchedResource>${catalina.base}/conf/web.xml</WatchedResource>
</Context>
```

**Making it all happen with `rewrite.config`**

Now you can drop your rewrite.config right into the WEB-INF there. Here's an example `rewrite.config` that rewrites the URL to greeting application. The file must be located in `${TOMCAT_HOME}/webapps/ROOT/WEB-INF/rewrite.config`


Rewrite From: **http://host:port/greeting/home**

To: **http://host:port/ords/!greeting?p=/home**

```
RewriteRule /greeting(.*?)$ /ords/!greeting?p=$1 [L]
```

