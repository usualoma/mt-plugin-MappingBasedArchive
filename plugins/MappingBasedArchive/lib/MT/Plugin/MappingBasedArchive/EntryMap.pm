package MT::Plugin::MappingBasedArchive::EntryMap;

use strict;
use warnings;
use utf8;

use MT::Plugin::MappingBasedArchive::Util;
use base qw( MT::Object );

__PACKAGE__->install_properties(
    {   column_defs => {
            id             => 'integer not null auto_increment',
            blog_id        => 'integer not null',
            entry_id       => 'integer not null',
            templatemap_id => 'integer not null',
            file           => 'string(255)',
            title          => 'string(255)',
            sort_data      => 'string(255)',
        },

        indexes => {
            'blog_file' => {
                columns =>
                    [ 'blog_id', 'templatemap_id', 'file', 'entry_id' ],
                unique => 1,
            },
            'entry_id'       => 1,
            'templatemap_id' => 1,
        },

        child_of => 'MT::Blog',
        audit    => 1,

        datasource  => 'mba_entry_map',
        primary_key => 'id',
    }
);

1;
