

Sacar todos los enlaces a los md de mi site: 

```sh
osalvador@haciendoti:~$ wget -q https://osalvador.github.io/dbax-lite/ -O - | tr "\t\r\n'" '   "' |  grep -i -o '<a[^>]\+href[ ]*=[ \t]*"\??[^"]\+"' |  sed -e 's/^.*"\([^"]\+\)".*$/\1/g'

?file=docs/Installation.md
?file=docs/Configuration.md
?file=docs/Request-Lifecycle.md
?file=docs/Routing.md
?file=docs/Controllers.md
?file=docs/Requests.md
?file=docs/Responses.md
?file=docs/Session.md
?file=docs/Views.md
?file=docs/tePLSQL-templates.md

```


Descargar la pagina con el html usando phantom como dicen aqui http://stackoverflow.com/questions/14127018/is-there-a-way-to-use-a-command-line-tool-to-view-the-javascript-interpreted-sou

```sh
osalvador@haciendoti:~$ cat save_page.js
var system = require('system');
var page = require('webpage').create();

page.open(system.args[1], function()
{
    console.log(page.content);
    phantom.exit();
});

```


```
phantomjs save_page.js  https://osalvador.github.io/dbax-lite/?file=docs/Installation.md

```