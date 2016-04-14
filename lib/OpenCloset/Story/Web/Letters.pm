package OpenCloset::Story::Web::Letters;
# ABSTRACT: OpenCloset story web

use Mojo::Base "Mojolicious::Controller";

our $VERSION = '0.001';

sub donation_get {
    my $self = shift;

    my $limit = 24;

    my $donation_rs = $self->schema->resultset("Donation")->search(
        { -and => [ { message => { "!=" => undef } }, { message => { "!=" => q{} } }, ], },
        {
            order_by => { -desc => "id" },
            rows     => $limit,
        },
    );

    $self->render(
        template     => "letters-d",
        donation_rs  => $donation_rs,
        preview_size => 128,
    );
}

sub donation_scroll_get {
    my $self = shift;

    my $page = $self->param("page") || 1;

    my $limit = 24;

    my $donation_rs = $self->schema->resultset("Donation")->search(
        { -and => [ { message => { "!=" => undef } }, { message => { "!=" => q{} } }, ], },
        {
            order_by => { -desc => "id" },
            page     => $page,
            rows     => $limit,
        },
    );

    $self->render(
        template     => "letters-d-scroll",
        donation_rs  => $donation_rs,
        preview_size => 128,
        page         => $page,
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
            template     => "letters-o",
            donation_rs  => undef,
            preview_size => 128,
            q            => $q,
        );
        return;
    }

    my $limit = 24;

    my $donation_rs = $self->schema->resultset("Donation")->search(
        {
            -and => [
                { "me.message" => { "!=" => undef } },
                { "me.message" => { "!=" => q{} } },
                { -or          => \@cond },
            ],
        },
        {
            join     => { "user" => "user_info" },
            order_by => { -desc  => "me.id" },
            rows     => $limit,
        },
    );

    $self->render(
        template     => "letters-d",
        donation_rs  => $donation_rs,
        preview_size => 128,
        q            => $q,
    );
}

sub donation_id_get {
    my $self = shift;

    my $id = $self->param("id");

    my $next_donation_id;
    {
        my $donation = $self->schema->resultset("Donation")->search(
            {
                -and => [
                    { "me.message" => { "!=" => undef } },
                    { "me.message" => { "!=" => q{} } },
                    { "me.id"      => { "<"  => $id } },
                ],
            },
            {
                order_by => { -desc => "id" },
                rows     => $1,
            },
        )->first;
        $next_donation_id = $donation->id if $donation;
    }

    my $prev_donation_id;
    {
        my $donation = $self->schema->resultset("Donation")->search(
            {
                -and => [
                    { "me.message" => { "!=" => undef } },
                    { "me.message" => { "!=" => q{} } },
                    { "me.id"      => { ">"  => $id } },
                ],
            },
            {
                order_by => { -asc => "id" },
                rows     => $1,
            },
        )->first;
        $prev_donation_id = $donation->id if $donation;
    }

    my $donation = $self->schema->resultset("Donation")->find($id);
    return $self->reply->not_found unless $donation;

    $self->render(
        template         => "letters-d-id",
        donation         => $donation,
        next_donation_id => $next_donation_id,
        prev_donation_id => $prev_donation_id,
    );
}

sub donation_id_order_get {
    my $self = shift;

    my $id = $self->param("id");

    my $donation = $self->schema->resultset("Donation")->find($id);
    return $self->reply->not_found unless $donation;

    my %order_info;
    my $clothes_rs = $donation->clothes;
    while ( my $clothes = $clothes_rs->next ) {
        my $order_rs = $clothes->orders;
        while ( my $order = $order_rs->next ) {
            if ( $order_info{ $order->id } ) {
                push @{ $order_info{ $order->id }{category} }, $clothes->category;
            }
            else {
                $order_info{ $order->id }{obj}      = $order;
                $order_info{ $order->id }{category} = [ $clothes->category ];
            }
        }
    }

    $self->render(
        template     => "letters-d-id-o",
        order_info   => \%order_info,
        donation     => $donation,
        preview_size => 128,
    );
}

sub order_get {
    my $self = shift;

    my $limit = 24;

    my $order_rs = $self->schema->resultset("Order")->search(
        {
            -and => [
                { "me.message"     => { "!=" => undef } },
                { "me.message"     => { "!=" => q{} } },
                { "me.return_date" => { "!=" => undef } },
            ],
        },
        {
            order_by => { -desc => "id" },
            rows     => $limit,
        },
    );

    $self->render(
        template     => "letters-o",
        order_rs     => $order_rs,
        preview_size => 128,
    );
}

sub order_scroll_get {
    my $self = shift;

    my $page = $self->param("page") || 1;

    my $limit = 24;

    my $order_rs = $self->schema->resultset("Order")->search(
        {
            "message"     => { "!=" => undef },
            "return_date" => { "!=" => undef },
        },
        {
            order_by => { -desc => "id" },
            page     => $page,
            rows     => $limit,
        },
    );

    $self->render(
        template     => "letters-o-scroll",
        order_rs     => $order_rs,
        preview_size => 128,
        page         => $page,
    );
}

sub order_post {
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
            template     => "letters-o",
            order_rs     => undef,
            preview_size => 128,
            q            => $q,
        );
        return;
    }

    my $limit = 24;

    my $order_rs = $self->schema->resultset("Order")->search(
        {
            -and => [
                { "me.message"     => { "!=" => undef } },
                { "me.message"     => { "!=" => q{} } },
                { "me.return_date" => { "!=" => undef } },
                { -or              => \@cond },
            ],
        },
        {
            join     => { "user" => "user_info" },
            order_by => { -desc  => "me.id" },
            rows     => $limit,
        },
    );

    $self->render(
        template     => "letters-o",
        order_rs     => $order_rs,
        preview_size => 128,
        q            => $q,
    );
}

sub order_id_get {
    my $self = shift;

    my $id = $self->param("id");

    my $next_order_id;
    {
        my $order = $self->schema->resultset("Order")->search(
            {
                -and => [
                    { "me.message"     => { "!=" => undef } },
                    { "me.message"     => { "!=" => q{} } },
                    { "me.return_date" => { "!=" => undef } },
                    { "me.id"          => { "<"  => $id } },
                ],
            },
            {
                order_by => { -desc => "id" },
                rows     => $1,
            },
        )->first;
        $next_order_id = $order->id if $order;
    }

    my $prev_order_id;
    {
        my $order = $self->schema->resultset("Order")->search(
            {
                -and => [
                    { "me.message"     => { "!=" => undef } },
                    { "me.message"     => { "!=" => q{} } },
                    { "me.return_date" => { "!=" => undef } },
                    { "me.id"          => { ">"  => $id } },
                ],
            },
            {
                order_by => { -asc => "id" },
                rows     => $1,
            },
        )->first;
        $prev_order_id = $order->id if $order;
    }

    my $order = $self->schema->resultset("Order")->find($id);
    return $self->reply->not_found unless $order;

    $self->render(
        template      => "letters-o-id",
        order         => $order,
        next_order_id => $next_order_id,
        prev_order_id => $prev_order_id,
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

=method donation_scroll_get

=method donation_post

=method order_get

=method order_scroll_get

=method order_post
