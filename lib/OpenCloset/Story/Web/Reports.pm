package OpenCloset::Story::Web::Reports;
# ABSTRACT: OpenCloset story web

use Mojo::Base "Mojolicious::Controller";

our $VERSION = '0.004';

sub donor_get {
    my $self = shift;

    $self->render(
        template     => "reports-donor",
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
            template     => "reports-donor",
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
        template     => "reports-donor",
        user_rs      => $user_rs,
        preview_size => 256,
        q            => $q,
    );
}

sub donor_id_get {
    my $self = shift;

    my $donor_id = $self->param("id");

    my $donor = $self->schema->resultset("User")->find($donor_id);
    return $self->reply->not_found unless $donor;

    my $donation_rs =
        $donor->donations->search( {}, { order_by => { -desc => "id" }, } );

    my $donated_clothes_count = 0;
    $donated_clothes_count += $_->clothes->count for $donor->donations;

    my $rented_user_count = 0;
    {
        my $rs = $donor->donations->search(
            {
                "clothes.code" => { "!=" => undef },
                "order.id"     => { "!=" => undef },
            },
            {
                join      => [
                    { "clothes" => { "order_details" => { "order" => "user" } } },
                ],
                group_by  => ["user.id"],
            },
        );
        $rented_user_count = $rs->count;
    };

    my $rented_order_count = 0;
    {
        my $rs = $donor->donations->search(
            {
                "clothes.code" => { "!=" => undef },
                "order.id"     => { "!=" => undef },
            },
            {
                join      => [
                    { "clothes" => { "order_details" => "order" } },
                ],
                group_by  => ["order.id"],
            },
        );
        $rented_order_count = $rs->count;
    };

    my $rented_order_message_count = 0;
    {
        my $rs = $donor->donations->search(
            {
                "clothes.code"  => { "!=" => undef },
                "order.id"      => { "!=" => undef },
                "order.message" => { "!=" => undef },
            },
            {
                join      => [
                    { "clothes" => { "order_details" => "order" } },
                ],
                group_by  => ["order.id"],
            },
        );
        $rented_order_message_count = $rs->count;
    };

    $self->render(
        template                   => "reports-donor-id",
        donor                      => $donor,
        donation_rs                => $donation_rs,
        donated_clothes_count      => $donated_clothes_count,
        rented_user_count          => $rented_user_count,
        rented_order_count         => $rented_order_count,
        rented_order_message_count => $rented_order_message_count,
        preview_size               => 256,
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
