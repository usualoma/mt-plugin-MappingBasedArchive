package MT::Plugin::MappingBasedArchive::Entry;

use strict;
use warnings;
use utf8;

use MT::Plugin::MappingBasedArchive::Util;

sub rebuild_entry_map {
    my ( $cb, $obj ) = @_;

    my $blog = $obj->blog;

    my %old_maps;
    for my $m (
        MT->model('mba_entry_map')->load( { entry_id => $obj->id, } ) )
    {
        $m->remove;
        $old_maps{ $m->file } = $m;
    }

    my @entries = ($obj);
    if ( !MT->model('entry')->exist( $obj->id ) ) {
        @entries = ();
    }

    for my $obj (
        MT->model('templatemap')->load(
            {   blog_id      => $obj->blog_id,
                archive_type => 'MappingBased',
            }
        )
        )
    {
        my $file_tmpl  = build_file_template( $obj->file_template );
        my $title_tmpl = build_file_template( $obj->ntm_title_template );
        my $sort_tmpl  = build_file_template( $obj->ntm_sort_template );

        require MT::Template::Context;
        require MT::Builder;
        my $build = MT::Builder->new;

        for my $entry (@entries) {
            my ( $file, $title, $sort );

            my $ctx = MT::Template::Context->new;
            $ctx->{__stash}{blog}    = $blog;
            $ctx->{__stash}{entry}   = $entry;
            $ctx->{__stash}{author}  = $entry->author;
            $ctx->{__stash}{builder} = $build;
            $ctx->{archive_type}     = 'MappingBased';

            $file = $ctx->build($file_tmpl);

            if ( $entry->status == MT->model('entry')->RELEASE ) {
                $title = $ctx->build($title_tmpl) if $title_tmpl;
                $sort  = $ctx->build($sort_tmpl)  if $sort_tmpl;

                my $entry_map = MT->model('mba_entry_map')->new;
                $entry_map->set_values(
                    {   blog_id        => $blog->id,
                        templatemap_id => $obj->id,
                        entry_id       => $entry->id,
                        file           => $file || '',
                        title          => $title || '',
                        sort_data      => $sort || '',
                    }
                );
                $entry_map->save
                    or die;
            }

            delete $old_maps{$file};
        }
    }

    if (%old_maps) {
        my $base_url = $blog->archive_url;
        $base_url .= '/' unless $base_url =~ m|/$|;

        for my $m ( values %old_maps ) {
            my $fi
                = MT->model('fileinfo')
                ->load( { url => $base_url . $m->file, } )
                or next;
            MT->instance->publisher->rebuild_from_fileinfo($fi);
        }
    }

    1;
}

1;
