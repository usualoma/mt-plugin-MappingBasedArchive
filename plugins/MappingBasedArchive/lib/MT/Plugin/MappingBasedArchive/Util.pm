package MT::Plugin::MappingBasedArchive::Util;

use strict;
use warnings;
use utf8;

our @EXPORT = qw(plugin);
use base qw(Exporter);

sub plugin {
    MT->component('MappingBasedArchive');
}

1;
