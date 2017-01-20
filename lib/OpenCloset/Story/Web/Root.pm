package OpenCloset::Story::Web::Root;
# ABSTRACT: OpenCloset story web

use Mojo::Base "Mojolicious::Controller";

our $VERSION = '0.007';

sub index_get {
    my $self = shift;

    my $donation_rs = $self->schema->resultset("Donation")->search(
        { -and => [ { message => { "!=" => undef } }, { message => { "!=" => q{} } }, ], },
        { order_by => { -desc => "id" }, },
    );

    my $order_rs = $self->schema->resultset("Order")->search(
        {
            "message"     => { "!=" => undef },
            "return_date" => { "!=" => undef },
        },
        { order_by => { -desc => "id" }, },
    );

    $self->render(
        template       => "index",
        order_count    => $order_rs->count,
        donation_count => $donation_rs->count,
    );
}

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
