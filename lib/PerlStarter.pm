use 5.12.2;

{

    package PerlStarter::User;
    use Moose;
    with qw(KiokuX::User);
}

{

    package PerlStarter::Project;
    use Moose;
    use Digest::SHA1 qw(sha1_hex);

    with qw( KiokuDB::Role::ID );

    sub id { shift->kiokudb_object_id(@_) }

    sub kiokudb_object_id { sha1_hex( shift->name ) }

    has [qw(name description benefits category more_info)] => (
        isa      => 'Str',
        is       => 'ro',
        required => 1,
    );

    has user => (
        isa      => 'PerlStarter::User',
        is       => 'ro',
        required => 1,
    );

    has amount => ( isa => 'Num', is => 'ro', required => 1 );

    has thumbnail => (
        isa     => 'Str',
        is      => 'ro',
        default => '/images/perldancer.jpg'
    );

}

{

    package PerlStarter;
    use Dancer ':syntax';
    our $VERSION = '0.1';
    use KiokuX::Model;
    use KiokuX::User::Util qw(crypt_password);
    use Try::Tiny;

    set session   => 'Simple';
    set kioku_dsn => 'dbi:SQLite:site.db';
    set template  => 'template_toolkit';

    sub kioku {
        KiokuX::Model->new(
            dsn        => config->{kioku_dsn},
            extra_args => { create => 1, }
        );
    }

    get '/' => sub {
        my $projects = undef;
        try {
            my $k     = kioku();
            my $scope = $k->new_scope;
            my $projects =
              [ $k->search( { class => 'PerlStarter::Project' } )->all ];
            template 'index.tt', { projects => $projects };
        }
        catch {
            template 'index.tt', { error => $_ };
        }
    };

    # This must come before the more generic /project/:id path
    # otherwise that one will clobber this one
    any [ 'get', 'post' ] => '/project/new' => sub {
        return redirect '/login' unless session->{user};
        return template 'project/new.tt' unless request->method() eq 'POST';
        try {
            my $k     = kioku();
            my $scope = $k->new_scope;
            my $conf  = params();
            $conf->{user} = $k->lookup( session->{user}->kiokudb_object_id );
            my $project = PerlStarter::Project->new($conf);
            $k->store($project);
            redirect "/project/${\$project->kiokudb_object_id}";
        }
        catch {
            template 'project/new.tt', { error => $_ };
        }

    };

    get '/project/:id' => sub {
        try {
            my $k       = kioku();
            my $scope   = $k->new_scope;
            my $project = $k->lookup( params->{id} );
            template 'project/page.tt', { project => $project };
        }
        catch {
            template 'project/new.tt', { error => $_ };
        }
    };

    get '/logout' => sub {
        session->destroy;
        redirect '/';
    };

    any [ 'get', 'post' ] => '/login' => sub {
        return template 'login.tt' unless request->method() eq 'POST';
        try {
            my $k     = kioku();
            my $scope = $k->new_scope;
            my $user  = $k->lookup( 'user:' . params->{username} )
              or die 'Invalid username';
            $user->check_password( params->{password} )
              or die "Invalid password";
            session user => $user;
            redirect '/';
        }
        catch {
            template 'login.tt', { error => $_ };
        }
    };

    any [ 'get', 'post' ] => '/register' => sub {
        return template 'register.tt'
          unless request->method() eq 'POST';
        try {
            my $k     = kioku();
            my $scope = $k->new_scope;

            die 'password mismatch'
              unless params->{password} eq params->{confirm};
            debug "adding ${\params->{username}} => ${\params->{password}}";
            my $user = PerlStarter::User->new(
                id       => params->{username},
                password => crypt_password( params->{password} ),
            );
            $k->store( session->{user} );
            session user => $k->lookup( $user->kiokudb_object_id );
            redirect '/login';
        }
        catch {
            template 'register.tt', { error => $_ };
        }
    };

    true;
}
