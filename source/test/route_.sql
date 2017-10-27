declare
    procedure print (
        text in varchar2
    )
        as
    begin
        dbms_output.put_line(text);
    end;

    procedure pass
        as
    begin
        print('   Pass');
    end;

    procedure fail (
        p_line_number in number
    )
        as
    begin
        raise_application_error(-20001, 'XXX El test ha fallado en la linea:' || p_line_number);
    end;

begin
    print('**********');
    print('Probando el metodo route_.get');
    print('**********');
    request_.method('GET');
    print('-- Enrutado basico, la url es /foo tiene que devolver TRUE');
    dbx.g$path   := 'foo';
    if
        route_.get('foo') != true
    then
        fail($$plsql_line);
    else
        pass;
    end if;

   --      PRINT ('Enrutado con expresiones regulares');

    print('**********');
    print('Probando el metodo route_.post');
    print('**********');
    
    request_.method('POST');
    print('-- Enrutado basico, la url es /foo tiene que devolver TRUE');
    dbx.g$path   := 'foo';
    if
        route_.post('foo') != true
    then
        fail($$plsql_line);
    else
        pass;
    end if;

    print('**********');
    print('Probando el metodo route_.match');
    print('**********');
    
    print('-- Enrutado basico, la url es /foo y el m�todo es GET, solo paso como parametro de verbo "get" ');
    request_.method('GET');
    dbx.g$path   := 'foo';
    if
        route_.match('foo', 'get') != true
    then
        fail($$plsql_line);
    else
        pass;
    end if;

    print('-- Enrutado basico, la url es /foo y el m�todo es POST, solo paso como parametro de verbo "post"');
    request_.method('POST');
    dbx.g$path   := 'foo';
    if
        route_.match('foo', 'post') != true
    then
        fail($$plsql_line);
    else
        pass;
    end if;

    print('-- Enrutado basico, la url es /foo y el m�todo es POST, paso como parametro de verbo "post,get"');
    request_.method('POST');
    dbx.g$path   := 'foo';
    if
        route_.match('foo', 'post,get') != true
    then
        fail($$plsql_line);
    else
        pass;
    end if;

    print('-- Enrutado basico, la url es /foo y el m�todo es GET, paso como parametro de verbo "post,get"');
    request_.method('GET');
    dbx.g$path   := 'foo';
    if
        route_.match('foo', 'post,get') != true
    then
        fail($$plsql_line);
    else
        pass;
    end if;

    print('-- Enrutado basico, la url es /foo y el m�todo es GET, paso como parametro de verbo "post , get" con espacios en blanco');
    request_.method('GET');
    dbx.g$path   := 'foo';
    if
        route_.match('foo', 'post , get') != true
    then
        fail($$plsql_line);
    else
        pass;
    end if;

    print('-- Enrutado basico, la url es /foo y el m�todo es GET, paso como parametro de verbo "dummy" ');
    request_.method('GET');
    dbx.g$path   := 'foo';
    if
        route_.match('foo', 'dummy') = true
    then
        fail($$plsql_line);
    else
        pass;
    end if;

    print('**********');
    print('Probando el metodo route_.GET con Parametros de URL');
    print('**********');
    print('-- Enrutado con parametros, la url es /user/oscar el metodo GET, el parametro que se debe vevolver es el id de usuario oscar'
);
    request_.method('GET');
    dbx.g$path   := 'user/oscar';
    declare
        l_param   dbx.g_assoc_array;
    begin
        if
            route_.get('user/{id}', l_param) != true
        then
            fail($$plsql_line);
        else
            print('   La URL si coincide');
            if
                l_param('id') = 'oscar'
            then
                print(q'[   l_param('id') = 'oscar']');
                pass;
            else
                fail($$plsql_line);
            end if;

        end if;
    end;

    print('-- Enrutado con parametros, la url es /user/22/name/Oscar el metodo POST, el parametro que se debe vevolver es el id=22 y usename=Oscar'
);
    request_.method('POST');
    dbx.g$path   := 'user/22/name/Oscar';
    declare
        l_param   dbx.g_assoc_array;
    begin
        if
            route_.post('user/{id}/name/{usename}', l_param) != true
        then
            fail($$plsql_line);
        else
            print('   La URL si coincide');
            if
                l_param('id') = '22'
            then
                print(q'[   l_param('id') = ]' || l_param('id') );
                if
                    l_param('usename') = 'Oscar'
                then
                    print(q'[   l_param('usename') =]' || l_param('usename') );
                    pass;
                else
                    fail($$plsql_line);
                end if;

            else
                fail($$plsql_line);
            end if;

        end if;
    end;

    print('-- Enrutado con parametros, la url es /user/22/profile/upload/image el metodo GET, el parametro que se debe vevolver es el id=22'
);
    request_.method('GET');
    dbx.g$path   := 'user/22/profile/upload/image';
    declare
        l_param   dbx.g_assoc_array;
    begin
        if
            route_.get('user/{id}/profile/upload/image', l_param) != true
        then
            fail($$plsql_line);
        else
            print('   La URL si coincide');
            print(q'[   l_param('id') = ]' || l_param('id') );
            if
                l_param('id') = '22'
            then
                pass;
            else
                fail($$plsql_line);
            end if;

        end if;
    end;

    print('-- Enrutado con parametros, la url es /user-id/22/user_type/free el metodo GET, el parametro que se debe user-id=22 y user_type=free'
);
    request_.method('GET');
    dbx.g$path   := 'user-id/22/user_type/free';
    declare
        l_param   dbx.g_assoc_array;
    begin
        if
            route_.get('user-id/{user-id}/user_type/{user_type}', l_param) != true
        then
            fail($$plsql_line);
        else
            print('   La URL si coincide');
            print(q'[   l_param('user-id') = ]' || l_param('user-id') );
            print(q'[   l_param('user_type') = ]' || l_param('user_type') );
            if
                l_param('user-id') = '22' and l_param('user_type') = 'free'
            then
                pass;
            else
                fail($$plsql_line);
            end if;

        end if;
    end;

    print('-- Enrutado con parametros opcionales, la url es /user//id/22/type/ el metodo GET,el parametro name y type son opcionales');
    request_.method('GET');
    dbx.g$path   := 'user//id/22/type/';
    declare
        l_param   dbx.g_assoc_array;
    begin
        if
            route_.get('user/{name}?/id/{id}/type/?{type}?', l_param) != true
        then
            fail($$plsql_line);
        else
            print('   La URL si coincide');
            print(q'[   l_param('id') = ]' || l_param('id') );
            if
                l_param('id') = '22'
            then
                pass;
            else
                fail($$plsql_line);
            end if;

        end if;
    end;

    print('-- Enrutado con parametros opcionales y Advanced Regex Case Insentive, la url es /USER//id/22/type/ el metodo GET,el parametro name y type son opcionales'
);
    request_.method('GET');
    dbx.g$path   := 'user//ID/22/type/';
    declare
        l_param   dbx.g_assoc_array;
    begin
        if
            route_.get('user/{name}?/id/{id}/type/{type}?@1,1,i', l_param) != true
        then
            fail($$plsql_line);
        else
            print('   La URL si coincide');
            print(q'[   l_param('id') = ]' || l_param('id') );
            if
                l_param('id') = '22'
            then
                pass;
            else
                fail($$plsql_line);
            end if;

        end if;
    end;

    print('-- Enrutado basico, la url esta vacia lo que supone que es el index de la pagina');
    dbx.g$path   := '';
    if
        route_.get('/') != true
    then
        fail($$plsql_line);
    else
        pass;
    end if;

    print('-- Routes with optional parameters at the end will not match on requests with a trailing slash (i.e. /blog/ will not match, /blog will match).'
);
    request_.method('GET');
    dbx.g$path   := 'blog/';
    declare
        l_param   dbx.g_assoc_array;
    begin
        if
            route_.get('blog/{page}?', l_param) != true
        then
            fail($$plsql_line);
        else
            print('   La URL si coincide');
            pass;
        end if;
    end;

    print('**********');
    print('Enrutado con parametros opcionales. El ejemplo de la documentacion');
    print('**********');
    print('-- El path de entrada es `user` la expresion regular:  user/?{id}?/?{name}?');
    request_.method('GET');
    dbx.g$path   := 'user';
    declare
        l_param   dbx.g_assoc_array;
    begin
        if
            route_.get('user/?{id}?/?{name}?', l_param)
        then
            print(q'[   l_param('id') = ]' || l_param('id') );
            print(q'[   l_param('name') = ]' || l_param('name') );
            pass;
        else
            fail($$plsql_line);
        end if;
    end;

    print('-- El path de entrada es `user/` la expresion regular:  user/?{id}?/?{name}?');
    request_.method('GET');
    dbx.g$path   := 'user/';
    declare
        l_param   dbx.g_assoc_array;
    begin
        if
            route_.get('user/?{id}?/?{name}?', l_param)
        then
            print(q'[   l_param('id') = ]' || l_param('id') );
            print(q'[   l_param('name') = ]' || l_param('name') );
            pass;
        else
            fail($$plsql_line);
        end if;
    end;

    print('-- El path de entrada es `user/id` la expresion regular:  user/?{id}?/?{name}?');
    request_.method('GET');
    dbx.g$path   := 'user/id';
    declare
        l_param   dbx.g_assoc_array;
    begin
        if
            route_.get('user/?{id}?/?{name}?', l_param)
        then
            print(q'[   l_param('id') = ]' || l_param('id') );
            print(q'[   l_param('name') = ]' || l_param('name') );
            pass;
        else
            fail($$plsql_line);
        end if;
    end;

    print('-- El path de entrada es `user/id/` la expresion regular:  user/?{id}?/?{name}?');
    request_.method('GET');
    dbx.g$path   := 'user/id/';
    declare
        l_param   dbx.g_assoc_array;
    begin
        if
            route_.get('user/?{id}?/?{name}?', l_param)
        then
            print(q'[   l_param('id') = ]' || l_param('id') );
            print(q'[   l_param('name') = ]' || l_param('name') );
            pass;
        else
            fail($$plsql_line);
        end if;
    end;

    print('-- El path de entrada es `user/id/name` la expresion regular:  user/?{id}?/?{name}?');
    request_.method('GET');
    dbx.g$path   := 'user/id/name';
    declare
        l_param   dbx.g_assoc_array;
    begin
        if
            route_.get('user/?{id}?/?{name}?', l_param)
        then
            print(q'[   l_param('id') = ]' || l_param('id') );
            print(q'[   l_param('name') = ]' || l_param('name') );
            pass;
        else
            fail($$plsql_line);
        end if;
    end;

    print('-- El path de entrada es `user/id/name/` la expresion regular:  user/?{id}?/?{name}?');
    request_.method('GET');
    dbx.g$path   := 'user/id/name/';
    declare
        l_param   dbx.g_assoc_array;
    begin
        if
            route_.get('user/?{id}?/?{name}?', l_param)
        then
            print(q'[   l_param('id') = ]' || l_param('id') );
            print(q'[   l_param('name') = ]' || l_param('name') );
            pass;
        else
            fail($$plsql_line);
        end if;
    end;

end;