
package MT::Plugin::DefaultGravator;

use strict;

use Digest::MD5 qw(md5_hex);
use MT::Util qw(trim encode_url);

our $MT_DEFAULT_USERPIC = 'images/default-userpic-90.jpg';

sub init_app {
    my ( $cb, $app ) = @_;

    # Configs.
    my $base_url = $app->config->DefaultGravatorBaseURL;
    my $default_image = $app->config->DefaultGravatorDefaultImage;
    my $rating = $app->config->DefaultGravatorRating;

    # If default is 'mt', use default-userpic in mt-static.
    $default_image = MT->static_path . $MT_DEFAULT_USERPIC
        if lc($default_image) eq 'mt';

    # Redefine subroutines.
    no warnings qw( redefine );

    # Redefine MT::Author::userpic_url to return Gravator.
    my $userpic_url = \&MT::Author::userpic_url;
    *MT::Author::userpic_url = sub {
        my ( $author, %param ) = @_;
        my @info = $userpic_url->(@_) if wantarray;
        return wantarray? @info: $info[0] if $info[0]; # Userpic uploaded.

        # Build Gravator url.
        my $size = $param{Width} || 90;
        my $hash = md5_hex( lc( trim( $author->email ) ) );
        my $url = "$base_url$hash";

        my %params;
        $params{s} = $size if $size;
        $params{d} = $default_image if $default_image;
        $params{r} = $rating if $rating;
        my $url_param = join '&', map { $_ . '=' . encode_url($params{$_}) } keys %params;
        $url .= "?$url_param" if $url_param;

        # Return the url or info.
        @info = ( $url, %param );
        wantarray? @info: $info[0];
    };

    # Redfine MT::Author::userpic_html to return Gravator for user editing screen.
    my $userpic_html = \&MT::Author::userpic_html;
    *MT::Author::userpic_html = sub {
        my ( $author ) = @_;

        # Assume Gravator url is as not defined.
        my $url = $author->userpic_url(@_);
        return if $url =~ m!^$base_url!i;

        # Run the original.
        $userpic_html->(@_);
    };
}

1;
