use 5.10.1;
# ABSTRACT: turns baubles into trinkets

{

    package PerlStarter;
    use Dancer ':syntax';
    our $VERSION = '0.1';
    use KiokuX::Model;
    use KiokuDB::Backend::DBI;    
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
            template 'index', { projects => $projects };
        }
        catch {
            template 'index', { error => $_ };
        }
    };

    # This must come before the more generic /project/:id path
    # otherwise that one will clobber this one
    any [ 'get', 'post' ] => '/project/new' => sub {
        return redirect '/login' unless session->{user};
        return template 'project/new' unless request->method() eq 'POST';
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
            template 'project/new', { error => $_ };
        }

    };

    get '/project/:id' => sub {
        try {
            my $k       = kioku();
            my $scope   = $k->new_scope;
            my $project = $k->lookup( params->{id} );
            template 'project/page', { project => $project };
        }
        catch {
            template 'project/new', { error => $_ };
        }
    };

    post '/project/:id/pledges' => sub {
        my ( $k, $scope, $project );

        try {
            $k       = kioku;
            $scope   = $k->new_scope;
            $project = $k->lookup( params->{id} );
        }
        catch {
            template 'project/new', { error => $_ };
        };

        try {
            my $conf = params;
            $conf->{user}    = $k->lookup( session->{user}->kiokudb_object_id );
            $conf->{project} = $project;
            my $pledge = PerlStarter::Pledge->new($conf);
            $project->add_pledge($pledge);
            $k->store($project);
            redirect "/project/${\$project->id}";
        }
        catch {
            template 'project/page' => {
                project => $project,
                error   => $_
            };
        };
    };

    any [ 'get', 'post' ] => '/logout' => sub {
        session->destroy;
        redirect '/';
    };

    any [ 'get', 'post' ] => '/login' => sub {
        return template 'login' unless request->method() eq 'POST';

        try {
            my $k     = kioku();
            my $scope = $k->new_scope;
            my $user  = $k->lookup( 'user:' . params->{username} )
              or die 'Invalid username';
            $user->check_password( params->{password} )
              or die "Invalid password";
            session user => $user;
            redirect params->{next_resource} || '/';
        }
        catch {
            template 'login', { error => $_ };
        }
    };

    any [ 'get', 'post' ] => '/register' => sub {
        return template 'register' unless request->method() eq 'POST';

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
            $k->store($user);
            session user => $k->lookup( $user->kiokudb_object_id );
            redirect params->{next_resource} || '/';
        }
        catch {
            template 'register', { error => $_ };
        }
    };

    true;
}

# all of the packages below will use DateTIme so let's load it here.
use DateTime;

{

    package PerlStarter::User;
    use Moose;
    with qw(KiokuX::User);

    has created_timestamp => (
        isa      => 'DateTime',
        is       => 'ro',
        init_arg => undef,
        default  => sub { DateTime->now },
    );

}

{

    package PerlStarter::Project;
    use Moose;
    use List::Util qw(sum);
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

    has pledges => (
        isa     => 'ArrayRef[PerlStarter::Pledge]',
        traits  => ['Array'],
        default => sub { [] },
        lazy    => 1,
        handles => {
            add_pledge   => 'push',
            list_pledges => 'elements',
            has_pledges  => 'count',
        }
    );

    sub total_pledged {
        my $self = shift;
        return '0.00' unless $self->has_pledges;
        sum map { $_->amount } $self->list_pledges;
    }

    has created_timestamp => (
        isa      => 'DateTime',
        is       => 'ro',
        init_arg => undef,
        default  => sub { DateTime->now },
    );

}
{

    package PerlStarter::Pledge;
    use Moose;

    has user => (
        isa      => 'PerlStarter::User',
        is       => 'ro',
        required => 1,
    );

    has project => (
        isa      => 'PerlStarter::Project',
        is       => 'ro',
        required => 1,
    );

    has amount => ( isa => 'Num', is => 'ro', required => 1 );

    has created_timestamp => (
        isa      => 'DateTime',
        is       => 'ro',
        init_arg => undef,
        default  => sub { DateTime->now },
    );

}

1;
__END__
