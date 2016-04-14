package OpenCloset::Story::Web::Login;
# ABSTRACT: OpenCloset story web

use Mojo::Base "Mojolicious::Controller";

our $VERSION = '0.003';

sub login_get {
    my $self = shift;

    my $from = $self->param("from") || q{};

    $self->stash( from => $from );
    $self->render("login");
}

sub login_post {
    my $self = shift;

    my $username = $self->param("email");
    my $password = $self->param("password");
    my $from     = $self->param("from");

    if ( $self->authenticate( $username, $password ) ) {
        my $user = $self->current_user;

        if ($from) {
            $self->app->log->debug("redirect to: $from");
            $self->redirect_to( $self->url_for($from) );
        }
        else {
            $self->redirect_to( $self->url_for("/") );
        }
    }
    else {
        $self->redirect_to( $self->url_for("/login") );
    }
}

sub logout_get {
    my $self = shift;

    $self->session( expires => 1 );
    $self->redirect_to( $self->url_for("/") );
}

1;

__END__

=for Pod::Coverage

=head1 SYNOPSIS

    ...

=head1 DESCRIPTION

...

=method login_get

=method login_post

=method logout_get
