package OpenCloset::Story::Web::Reports;
# ABSTRACT: OpenCloset story web

use Mojo::Base "Mojolicious::Controller";

our $VERSION = '0.004';

use OpenCloset::Constants::Category;

sub donors_get {
    my $self = shift;

    $self->render(
        template     => "reports-donors",
        user_rs      => undef,
        preview_size => 128,
    );
}

sub donors_post {
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
            template     => "reports-donors",
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
        template     => "reports-donors",
        user_rs      => $user_rs,
        preview_size => 256,
        q            => $q,
    );
}

sub donors_id_get {
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
        template                   => "reports-donors-id",
        donor                      => $donor,
        donation_rs                => $donation_rs,
        donated_clothes_count      => $donated_clothes_count,
        rented_user_count          => $rented_user_count,
        rented_order_count         => $rented_order_count,
        rented_order_message_count => $rented_order_message_count,
        preview_size               => 256,
    );
}

sub donations_id_get {
    my $self = shift;

    my $donation_id = $self->param("id");

    my $donation_rs = $self->schema->resultset("Donation");
    my $donation    = $donation_rs->find($donation_id);
    $self->app->log->debug( $donation->id );
    return $self->reply->not_found unless $donation;

    my $donor = $donation->user;

    my $donated_clothes_count = $donation->clothes->count;

    my $donated_items = +{};
    {
        my $rs = $donation_rs->search(
            {
                "me.id"        => $donation_id,
                "clothes.code" => { "!=" => undef },
            },
            {
                join      => ["clothes"],
                group_by  => ["clothes.category"],
                "columns" => [
                    { category => "clothes.category" },
                    {
                        count => { count => "clothes.category", -as => "clothes_category_count" },
                    },
                ],
            },
        );

        my %result;
        while ( my $row = $rs->next ) {
            my %clothes = $row->get_columns;
            my $category_to_string =
                $OpenCloset::Constants::Category::LABEL_MAP{ $clothes{category} };
            $result{$category_to_string} = $clothes{count};
        }

        $donated_items = \%result;
    }

    my $rented_order_count = 0;
    {
        my $rs = $donation_rs->search(
            {
                "me.id"        => $donation_id,
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

    my $rented_category_count     = +{};
    my $rented_category_count_all = 0;
    {
        my $rs = $donation_rs->search(
            {
                "me.id"        => $donation_id,
                "clothes.code" => { "!=" => undef },
                "order.id"     => { "!=" => undef },
            },
            {
                join => [
                    { "clothes" => { "order_details" => "order" } },
                ],
                group_by  => ["clothes.category"],
                "columns" => [
                    { category => "clothes.category" },
                    { count    => { count => "clothes.category" } },
                ],
            },
        );

        my %result;
        while ( my $row = $rs->next ) {
            my %clothes = $row->get_columns;
            my $category_to_string =
                $OpenCloset::Constants::Category::LABEL_MAP{ $clothes{category} };
            $result{$category_to_string} = $clothes{count};
            $rented_category_count_all += $clothes{count};
        }

        $rented_category_count = \%result;
    }

    my $acceptance_order_count = 0;
    {
        my $rs = $donation_rs->search(
            {
                "me.id"        => $donation_id,
                "clothes.code" => { "!=" => undef },
                "order.id"     => { "!=" => undef },
                "order.pass"   => 1,
            },
            {
                join      => [
                    { "clothes" => { "order_details" => "order" } },
                ],
                group_by  => ["order.id"],
            },
        );
        $acceptance_order_count = $rs->count;
    };

    my $order_message_count = 0;
    my $order_message;
    {
        my $rs = $donation_rs->search(
            {
                "me.id"         => $donation_id,
                "clothes.code"  => { "!=" => undef },
                "order.id"      => { "!=" => undef },
                "order.message" => { "!=" => undef },
            },
            {
                join      => [
                    { "clothes" => { "order_details" => "order" } },
                ],
                group_by  => ["order.id"],
                order_by  => { -desc => "order.id" },
                "columns" => [
                    { order_message => "order.message" },
                ],
            },
        );
        $order_message_count = $rs->count;
        $order_message = $rs->first->get_column("order_message") if $order_message_count;
    };

    $self->render(
        template                  => "reports-donations-id",
        donor                     => $donor,
        donation                  => $donation,
        donated_clothes_count     => $donated_clothes_count,
        donated_items             => $donated_items,
        rented_order_count        => $rented_order_count,
        rented_category_count     => $rented_category_count,
        rented_category_count_all => $rented_category_count_all,
        acceptance_order_count    => $acceptance_order_count,
        order_message_count       => $order_message_count,
        order_message             => $order_message,
        preview_size              => 256,
    );
}

1;

__END__

=for Pod::Coverage

=head1 SYNOPSIS

    ...

=head1 DESCRIPTION

...

=method donors_get

=method donors_post

=method donors_id_get

=method donations_id_get
