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
