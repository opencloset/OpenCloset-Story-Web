package OpenCloset::Story::Web::Reports;
# ABSTRACT: OpenCloset story web

use Mojo::Base "Mojolicious::Controller";

our $VERSION = '0.004';

sub donation_get {
    my $self = shift;

    $self->render(
        template     => "reports-d",
        donation_rs  => undef,
        preview_size => 128,
    );
}

1;

__END__

=for Pod::Coverage

=head1 SYNOPSIS

    ...

=head1 DESCRIPTION

...

=method donation_get
