package OpenCloset::Story::Web::Root;
# ABSTRACT: OpenCloset story web

use Mojo::Base "Mojolicious::Controller";

our $VERSION = '0.001';

sub index_get { $_[0]->render("index") }
sub about_get { $_[0]->render("about") }

1;

__END__

=for Pod::Coverage

=head1 SYNOPSIS

    ...

=head1 DESCRIPTION

...

=method index_get

=method about_get
