package OpenCloset::Story::Web::Reports;
# ABSTRACT: OpenCloset story web

use Mojo::Base "Mojolicious::Controller";

our $VERSION = '0.004';

sub donor_get {
    my $self = shift;

    $self->render(
        template     => "reports-d",
        user_rs      => undef,
        preview_size => 128,
    );
}

sub donor_post {
    my $self = shift;

    my $q    = $self->param("q");
    my $name = $q;
    ( my $phone = $q ) =~ s/\D//g;

    my @cond;
    if ( length $name >= 2 ) {
        push @cond, +{ "me.name" => $name };
    }
    if ( length $phone >= 7 ) {
        push @cond, +{ "user_info.phone" => $phone };
    }

    unless (@cond) {
        $self->render(
            template     => "reports-d",
            user_rs      => undef,
            preview_size => 128,
            q            => $q,
        );
        return;
    }

    my $limit = 24;

    my $user_rs = $self->schema->resultset("User")->search(
        {
            -and => [
                { "donations.id" => { "!=" => undef } },
                -or => \@cond,
            ],
        },
        {
            join     => [
                "donations",
                "user_info",
            ],
            order_by => { -desc  => "me.id" },
            group_by => [ "me.id" ],
            rows     => $limit,
        },
    );

    $self->render(
        template     => "reports-d",
        user_rs      => $user_rs,
        preview_size => 256,
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

=method donor_get

=method donor_post
