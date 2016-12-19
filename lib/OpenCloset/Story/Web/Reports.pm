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

sub donation_post {
    my $self = shift;

    my $q    = $self->param("q");
    my $name = $q;
    ( my $phone = $q ) =~ s/\D//g;

    my @cond;
    if ( length $name >= 2 ) {
        push @cond, +{ "user.name" => $name };
    }
    if ( length $phone >= 7 ) {
        push @cond, +{ "user_info.phone" => $phone };
    }

    unless (@cond) {
        $self->render(
            template     => "reports-d",
            donation_rs  => undef,
            preview_size => 128,
            q            => $q,
        );
        return;
    }

    my $limit = 24;

    my $donation_rs = $self->schema->resultset("Donation")->search(
        { -or => \@cond },
        {
            join     => { "user" => "user_info" },
            order_by => { -desc  => "me.id" },
            rows     => $limit,
        },
    );

    $self->render(
        template     => "reports-d",
        donation_rs  => $donation_rs,
        preview_size => 128,
        q            => $q,
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
