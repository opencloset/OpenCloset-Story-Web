use utf8;

package OpenCloset::Story::Web;

# ABSTRACT: OpenCloset story web

use Mojo::Base "Mojolicious";

our $VERSION = '0.001';

use File::ShareDir "dist_dir";
use Path::Tiny;

use OpenCloset::Schema 0.025;

#
# specify plugins explicitly
#
use Mojolicious::Plugin::Authentication;

=attr db

=cut

has db => sub {
    my $self = shift;

    my $schema_class = "OpenCloset::Schema";
    my $schema       = $schema_class->connect(
        $self->config->{db}{dsn},      $self->config->{db}{username},
        $self->config->{db}{password}, $self->config->{db}{options},
        )
        or die "Could not connect to $schema_class using DSN "
        . $self->config->{db}{dsn};

    return $schema;
};

=attr home_path

=cut

has home_path => sub {
    my $path = $ENV{OPENCLOSET_STORY_WEB_HOME} || q{.};
    return path($path)->absolute->stringify;
};

=attr config_file

=cut

has config_file => sub {
    my $self = shift;
    return $ENV{OPENCLOSET_STORY_WEB_CONFIG} if $ENV{OPENCLOSET_STORY_WEB_CONFIG};
    return path( $self->home_path . "/opencloset-story-web.conf" )->absolute->stringify;
};

=attr db_name

=attr db_username

=attr db_password

=cut

has db_name     => sub { $ENV{"OPENCLOSET_STORY_DB_NAME"} || "opencloset" };
has db_username => sub { $ENV{"OPENCLOSET_STORY_DB_USER"} || "opencloset" };
has db_password => sub { $ENV{"OPENCLOSET_STORY_DB_PASS"} || "opencloset" };

sub _load_config {
    my $app = shift;

    my $db_name     = $app->db_name;
    my $db_username = $app->db_username;
    my $db_password = $app->db_password;

    $app->defaults(
        page_title_short => q{},
        q                => q{},
        %{
            $app->plugin(
                Config => {
                    file    => $app->config_file,
                    default => {
                        hypnotoad => {
                            listen   => ["http://*:8008"],
                            workers  => 4,
                            pid_file => 'hypnotoad.pid',
                        },
                        db => {
                            dsn      => "dbi:mysql:$db_name:127.0.0.1",
                            username => $db_username,
                            password => $db_password,
                            options  => {
                                mysql_enable_utf8 => 1,
                                quote_char        => q{`},
                                on_connect_do     => "SET NAMES utf8",
                                RaiseError        => 1,
                                AutoCommit        => 1,
                            },
                        },
                        cookie => {
                            domain => undef,
                            name   => q{opencloset-story-web},
                            path   => q{/},
                        },
                        site      => { name => "OpenCloset::Story::Web", },
                        copyright => "2015-2016 THE OPEN CLOSET",
                        secrets   => [],
                        extra_static_paths   => [ "assets", "static" ],
                        extra_renderer_paths => ["templates"],
                        links                => [
                            {
                                name => "홈페이지",
                                url  => "https://theopencloset.net",
                            },
                            {
                                name => "방문 예약",
                                url  => "https://visit.theopencloset.net",
                            },
                            {
                                name => "온라인 예약",
                                url  => "https://online.theopencloset.net",
                            },
                            {
                                name => "정장 기증",
                                url  => "https://donation.theopencloset.net",
                            },
                            {
                                name => "열린봉사자 모집",
                                url  => "https://volunteer.theopencloset.net",
                            },
                        ],
                        page => {
                            "error" => {
                                title       => "오류",
                                title_short => "오류",
                                url         => q{},
                                breadcrumb  => [],
                            },
                            "code-404" => {
                                title       => "페이지를 찾을 수 없습니다",
                                title_short => "404 Not Found",
                                url         => q{},
                                breadcrumb  => [
                                    qw/
                                        index
                                        error
                                        code-404
                                        /
                                ],
                            },
                            "code-500" => {
                                title       => "내부 서버 오류입니다",
                                title_short => "500 Internal Server Error",
                                url         => q{},
                                breadcrumb  => [
                                    qw/
                                        index
                                        error
                                        code-500
                                        /
                                ],
                            },
                            "index" => {
                                title       => "첫 화면",
                                title_short => "첫 화면",
                                url         => "/",
                                breadcrumb  => [],
                            },
                            "login" => {
                                title       => "로그인",
                                title_short => "로그인",
                                url         => "/login",
                                breadcrumb  => [],
                            },
                            "about" => {
                                title       => "소개",
                                title_short => "소개",
                                url         => "/about",
                                breadcrumb  => [
                                    qw/
                                        index
                                        about
                                        /
                                ],
                            },
                            "letters-d" => {
                                title       => "기증 이야기",
                                title_short => "기증 이야기",
                                url         => "/letters/d",
                                breadcrumb  => [
                                    qw/
                                        index
                                        letters-d
                                        /
                                ],
                            },
                            "letters-o" => {
                                title       => "대여 이야기",
                                title_short => "대여 이야기",
                                url         => "/letters/o",
                                breadcrumb  => [
                                    qw/
                                        index
                                        letters-o
                                        /
                                ],
                            },
                            "letters-d-id" => {
                                title       => "%s님의 기증 이야기",
                                title_short => "%s님",
                                url         => "/letters/d/%s",
                                breadcrumb  => [
                                    qw/
                                        index
                                        letters-d
                                        letters-d-id
                                        /
                                ],
                            },
                        },
                    },
                },
            )
        }
    );

    # add the files directories to array of static content folders
    for my $dir ( reverse @{ $app->config->{extra_static_paths} } ) {
        # convert relative paths to relative one (to home dir)
        $dir = $app->_to_abs($dir);
        unshift @{ $app->static->paths }, $dir if -d $dir;
    }

    for my $dir ( reverse @{ $app->config->{extra_renderer_paths} } ) {
        # convert relative paths to relative one (to home dir)
        $dir = $app->_to_abs($dir);
        unshift @{ $app->renderer->paths }, $dir if -d $dir;
    }

    $app->sessions->cookie_domain( $app->config->{cookie}{domain} );
    $app->sessions->cookie_name( $app->config->{cookie}{name} );
    $app->sessions->cookie_path( $app->config->{cookie}{path} );
    $app->secrets( $app->config->{secrets} ) if @{ $app->config->{secrets} };
}

sub _to_abs {
    my ( $self, $dir ) = @_;

    $dir = $self->home->rel_dir($dir) unless $dir =~ m{^/};

    return $dir;
}

=method startup

=cut

sub startup {
    my $app = shift;

    # set home folder
    $app->home->parse( $app->home_path );

    {
        # setup logging path
        # code stolen from Mojolicious.pm
        my $mode = $app->mode;

        $app->log->path( $app->home->rel_file("log/$mode.log") )
            if -w $app->home->rel_file("log");
    }

    $app->_load_config;

    {
        # use content from directories under lib/OpenCloset/Story/Web/files or using File::ShareDir
        my $lib_base = path( path(__FILE__)->absolute->dirname . "/Web/files" );

        my $public = path("$lib_base/public");
        $app->static->paths->[-1] =
              $public->is_dir
            ? $public->stringify
            : path( dist_dir("OpenCloset-Story-Web") . "/public" )->stringify;

        my $templates = path("$lib_base/templates");
        $app->renderer->paths->[-1] =
              $templates->is_dir
            ? $templates->stringify
            : path( dist_dir("OpenCloset-Story-Web") . "/templates" )->stringify;
    }

    # use commands from OpenCloset::Story::Web::Command namespace
    push @{ $app->commands->namespaces }, "OpenCloset::Story::Web::Command";

    #
    # Helpers
    #
    $app->helper( schema => sub { shift->app->db } );

    #
    # Routing
    #
    my $r = $app->routes;
    $r->get("/login")->to("login#login_get");
    $r->post("/login")->to("login#login_post");
    $r->any("/logout")->to("login#logout_get");

    #
    # Test
    #
    $r->get("/")->to("root#index_get");
    $r->get("/about")->to("root#about_get");

    $r->get("/letters/d")->to("letters#donation_get");
    $r->get("/letters/d/scroll")->to("letters#donation_scroll_get");
    $r->post("/letters/d")->to("letters#donation_post");
    $r->get("/letters/d/:id")->to("letters#donation_id_get");

    $r->get("/letters/o")->to("letters#order_get");
    $r->get("/letters/o/scroll")->to("letters#order_scroll_get");
    $r->post("/letters/o")->to("letters#order_post");

    my $if_auth = $r->under(
        sub {
            my $self = shift;

            my $req = $self->req;
            if ( !$self->is_user_authenticated && $req->url->path ne "/login" ) {
                $self->redirect_to( $self->url_for("/login") );
                return;
            }

            return 1;
        }
    );

    #
    # Plugins
    #
    #$app->plugin( "OpenCloset::Story::Web::Plugin::FooBar", { ... } );

    $app->plugin(
        "AssetPack" => { pipes => [qw(Sass Css CoffeeScript JavaScript Combine)] } );
    {
        # use content from directories under lib/OpenCloset/Story/Web/files or using File::ShareDir
        my $lib_base = path( path(__FILE__)->absolute->dirname . "/Web/files" );

        my $public = path("$lib_base/public");
        my $final =
              $public->is_dir
            ? $public->stringify
            : path( dist_dir("OpenCloset-Story-Web") . "/public" )->stringify;
        push @{ $app->asset->store->paths }, $final;
    }
    $app->asset->process unless $ARGV[0] && $ARGV[0] eq "setup";

    $app->plugin(
        "authentication" => {
            autoload_user => 1,
            load_user     => sub {
                my ( $app, $uid ) = @_;

                my $user_obj = $app->schema->resultset("User")->find($uid);
                return $user_obj;
            },
            session_key   => "access_token",
            validate_user => sub {
                my ( $self, $username, $password, $extradata ) = @_;

                my $user_obj = $self->schema->resultset("User")->find(
                    {
                        email    => $username,
                        password => $password,
                    }
                );

                return unless $user_obj;
                return $user_obj->id;
            },
        }
    );
}

1;
__END__

=head1 SYNOPSIS

    $ mkdir -p service/opencloset-story-web
    $ cd service/opencloset-story-web
    $ opencloset-story-web.pl setup
    $ opencloset-story-web.pl daemon


=head1 INSTALLATION

L<OpenCloset::Story::Web> uses well-tested and widely-used CPAN modules, so installation should be as simple as

    $ cpanm --mirror=https://cpan.theopencloset.net --mirror=http://cpan.silex.kr --mirror-only OpenCloset::Story::Web

when using L<App::cpanminus>. Of course you can use your favorite CPAN client or install manually by cloning the L</"Source Code">.


=head1 SETUP

=head2 Environment

Although most of L<OpenCloset::Story::Web> is controlled by a configuration file, a few properties must be set before that file can be read.
These properties are controlled by the following environment variables.

=for :list
* C<OPENCLOSET_STORY_WEB_HOME>
This is the directory where L<OpenCloset::Story::Web> expects additional files.
These include the configuration file and log files.
The default value is the current working directory (C<cwd>).
* C<OPENCLOSET_STORY_WEB_CONFIG>
This is the full path to a configuration file.
The default is a file named F<opencloset-story-web.conf> in the C<OPENCLOSET_STORY_WEB_HOME> path,
however this file need not actually exist, defaults may be used instead.


=head1 RUNNING THE APPLICATION

    $ opencloset-story-web.pl daemon

After the database has been setup, you can run C<opencloset-story-web.pl daemon> to start the server.

You may also use L<morbo> (Mojolicious' development server) or L<hypnotoad> (Mojolicious' production server).
You may even use any other server that Mojolicious supports, however for full functionality it must support websockets.
When doing so you will need to know the full path to the C<opencloset-story-web.pl> application.
A useful recipe might be

    $ hypnotoad `which opencloset-story-web.pl`

where you may replace C<hypnotoad> with your server of choice.


=head2 Logging

Logging in L<OpenCloset::Story::Web> is the same as in L<Mojolicious|Mojolicious::Lite/Logging>.
Messages will be printed to C<STDERR> unless a directory named F<log> exists in the C<OPENCLOSET_STORY_WEB_HOME> path,
in which case messages will be logged to a file in that directory.


=head2 Extra Static Paths

By default, if L<OpenCloset::Story::Web> detects a folder named F<static> inside the C<OPENCLOSET_STORY_WEB_HOME> path,
that path is added to the list of folders for serving static files.
The name of this folder may be changed in the configuration file via the key C<extra_static_paths>,
which expects an array reference of strings representing paths.
If any path is relative it will be relative to C<OPENCLOSET_STORY_WEB_HOME>.


=head2 Extra Renderer Paths

By default, if L<OpenCloset::Story::Web> detects a folder named F<templates> inside the C<OPENCLOSET_STORY_WEB_HOME> path,
that path is added to the list of folders for serving templates.
The name of this folder may be changed in the configuration file via the key C<extra_renderer_paths>,
which expects an array reference of strings representing paths.
If any path is relative it will be relative to C<OPENCLOSET_STORY_WEB_HOME>.
