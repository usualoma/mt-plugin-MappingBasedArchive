package MT::Plugin::MappingBasedArchive::TemplateMap;

use strict;
use warnings;
use utf8;

sub cleanup_entry_map {
    my ( $cb, $obj, $original ) = @_;

    return 1 unless $obj->id;
    return 1 if $obj->archive_type ne 'MappingBased';

    MT->model('templatemap')->count({
        id => $obj->id,
        file_template => $obj->file_template || '',
    }) and return 1;

    MT->model('mba_entry_map')->remove({
        templatemap_id => $obj->id,
    });

    1;
}

1;
