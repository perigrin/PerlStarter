{

    package PerlStarter::Project;
    use Moose;

    has id => (
        isa     => 'Str',
        reader  => 'kiokudb_object_id',
        builder => 'generate_uuid'
    );
    has name => (
        isa => 'Str',
        is  => 'ro',
        default => 'Super Cool Project Neo',
    );
    has [qw(short_description full_description)] => (
        isa        => 'Str',
        is         => 'ro',
        lazy_build => 1
    );

    sub _build_short_description {
        "Lorem ipsum dolor sit amet, consectetur
        adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore
        magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco
        laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in
        reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
        pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa
        qui officia deserunt mollit anim id est laborum.";
    }


    sub _build_full_description {
        "<p>Lorem ipsum dolor sit amet, consectetur
        adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore
        magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco
        laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in
        reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla
        pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa
        qui officia deserunt mollit anim id est laborum.</p>\n" x 3;
    }
    

    has thumbnail => (
        isa     => 'Str',
        is      => 'ro',
        default => '/images/perldancer.jpg'
    );

    has [qw( owner category goal level )] => (   isa => 'Str',   is  => 'ro', default => '[TBA]' );

    with qw(
      KiokuDB::Role::ID
      KiokuDB::Role::UUIDs
    );

}
{

    package PerlStarter;
    use Dancer ':syntax';
    our $VERSION = '0.1';
    use KiokuX::Model;

    sub kioku {
        KiokuX::Model->new(
            dsn        => config->{kioku_dsn},
            extra_args => { create => 1, }
        );
    }

    get '/' => sub {
        template 'index', {
            projects => [
                map { PerlStarter::Project->new( name => "Project $_" ) }
                  ( 1 .. 3 )
            ],
            ,    # kioku->search({ class => 'PerlStarter::Project'})->all
        };
    };
    
    get '/project/:id' => sub {
        template 'project', {
            project => PerlStarter::Project->new( id => params->{id})
        };
    };

    true;
}
