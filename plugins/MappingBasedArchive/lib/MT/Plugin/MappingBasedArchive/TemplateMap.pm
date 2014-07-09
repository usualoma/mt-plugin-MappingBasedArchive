package MT::Plugin::MappingBasedArchive::TemplateMap;

use strict;
use warnings;
use utf8;

sub cleanup_entry_map {
    my ( $cb, $obj, $original ) = @_;

    return 1 unless $obj->id;
    return 1 if $obj->archive_type ne 'MappingBased';

    my $updated;
    for my $k (qw(name sort_template title_template)) {
        my $ck = "ntm_$k";
        $updated ||= $obj->{changed_cols}->{$ck}
            and last;
    }
    $updated ||= !MT->model('templatemap')->exist({
        id => $obj->id,
        file_template => $obj->file_template || '',
    });

    return 1 unless $updated;

    MT->model('mba_entry_map')->remove({
        templatemap_id => $obj->id,
    });

    1;
}

1;
