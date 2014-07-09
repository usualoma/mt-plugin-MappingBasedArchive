package MT::Plugin::MappingBasedArchive::Util;

use strict;
use warnings;
use utf8;

our @EXPORT = qw(plugin build_file_template);
use base qw(Exporter);

sub plugin {
    MT->component('MappingBasedArchive');
}

sub build_file_template {
    my ($file_tmpl) = @_;

    return $file_tmpl unless $file_tmpl;

    if ( $file_tmpl =~ m/<\$?MT/i ) {
        $file_tmpl
            =~ s!(<\$?MT[^>]+?>)|(%[_-]?[A-Za-z])!$1 ? $1 : '<MTFileTemplate format="'. $2 . '">'!gie;
    }
    else {
        $file_tmpl = qq{<MTFileTemplate format="$file_tmpl">};
    }

    $file_tmpl;
}

1;
