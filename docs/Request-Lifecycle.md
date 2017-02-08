# Request Lifecycle

## Introduction

When using any tool in the "real world", you feel more confident if you understand how that tool works. Application development is no different. When you understand how your development tools function, you feel more comfortable and confident using them.

The goal of this document is to give you a good, high-level overview of how the **dbax** framework works. By getting to know the overall framework better, everything feels less "magical" and you will be more confident building your applications. If you don't understand all of the terms right away, don't lose heart! Just try to get a basic grasp of what is going on, and your knowledge will grow as you explore other sections of the documentation.


## Lifecycle Overview

<div class="mxgraph" style="max-width:100%;border:1px solid transparent;" data-mxgraph="{&quot;highlight&quot;:&quot;#0000ff&quot;,&quot;lightbox&quot;:false,&quot;nav&quot;:true,&quot;resize&quot;:true,&quot;toolbar&quot;:&quot;zoom&quot;,&quot;xml&quot;:&quot;&lt;mxfile userAgent=\&quot;Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2987.21 Safari/537.36\&quot; version=\&quot;6.0.3.5\&quot; editor=\&quot;www.draw.io\&quot; type=\&quot;google\&quot;&gt;&lt;diagram name=\&quot;Page-1\&quot;&gt;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&lt;/diagram&gt;&lt;/mxfile&gt;&quot;}"></div>
<script type="text/javascript" src="https://www.draw.io/js/viewer.min.js"></script>

### First Things

The entry point for all requests to a **dbax** application is the public *application front controller procedure*  All requests are directed to this procedure by your PLSQL Gateway (ORDS / DBMS_EPG) configuration. The *application front controller procedure* doesn't contain much code. Rather, it is simply a starting point for loading the rest of the framework.

The *application front controller procedure* loads your application properties and inject to the framework the routing function of your application. Then start the dispatcher. 

Application front controller procedure example: 

```sql
CREATE OR REPLACE PROCEDURE greeting (name_array    IN owa_util.vc_arr DEFAULT dbx.empty_vc_arr
                                    , value_array   IN owa_util.vc_arr DEFAULT dbx.empty_vc_arr )
AS
   -- Unique application ID Name
   l_appid CONSTANT   VARCHAR2 (100) := 'GREETING';
BEGIN
   -- Custom aplication properties  
   dbx.set_property('error_style', 'DebugStyle');   
   -- dbax framework kernel 
   dbx.dispatcher (p_appid     => l_appid
                 , name_array  => name_array
                 , value_array => value_array
                 , router      => 'PK_APP_GREETING.ROUTER');
END greeting;
/
```


### HTTP / Dispatcher

Next, the incoming request is sent to either the HTTP dispatcher. This dispatcher serve as the central location that all requests flow through.

The HTTP Dispatcher detect user inputs, load cookies, start user session and perform other tasks that need to be done before the routing is actually handled.

The method signature for the HTTP Dispatcher's handle method is quite simple: receive a user's request and application router and return a response to the user. Think of the Dispatcher as being a big black box that represents your entire application. Feed it HTTP requests and it will return HTTP responses.

Once the application has been bootstrapped, the request will be handed off to the application router for dispatching. The router will dispatch the request to a route or controller.
