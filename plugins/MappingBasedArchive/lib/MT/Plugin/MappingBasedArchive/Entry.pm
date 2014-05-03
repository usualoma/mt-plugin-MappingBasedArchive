package MT::Plugin::MappingBasedArchive::Entry;

use strict;
use warnings;
use utf8;

sub post_save {
    my ( $cb, $obj ) = @_;

    my $blog = $obj->blog;

    my %old_maps;
    for my $m (MT->model('mba_entry_map')->load({
        entry_id => $obj->id,
    })) {
        $m->remove;
        $old_maps{$m->file} = $m;
    }

    my @entries = ($obj);
    for my $obj (MT->model('templatemap')->load({
        blog_id => $obj->blog_id,
        archive_type => 'MappingBased',
    })) {
        my $file_tmpl = $obj->file_template;
        if ( $file_tmpl =~ m/<\$?MT/i ) {
            $file_tmpl
                =~ s!(<\$?MT[^>]+?>)|(%[_-]?[A-Za-z])!$1 ? $1 : '<MTFileTemplate format="'. $2 . '">'!gie;
        }
        else {
            $file_tmpl = qq{<MTFileTemplate format="$file_tmpl">};
        }

        require MT::Template::Context;
        my $ctx = MT::Template::Context->new;
        $ctx->stash( 'blog', $blog );

        for my $entry (@entries) {
            my $file;

            local $ctx->{__stash}{entry} = $entry;
            local $ctx->{__stash}{author} = $entry->author;
            local $ctx->{archive_type} = 'MappingBased';

            require MT::Builder;
            my $build  = MT::Builder->new;
            my $tokens = $build->compile( $ctx, $file_tmpl )
                or return $blog->error( $build->errstr() );
            defined( $file = $build->build( $ctx, $tokens ) )
                or return $blog->error( $build->errstr() );

            next unless $file;

            if ($entry->status == MT->model('entry')->RELEASE) {
                my $entry_map = MT->model('mba_entry_map')->new;
                $entry_map->set_values({
                    blog_id => $blog->id,
                    templatemap_id => $obj->id,
                    entry_id => $entry->id,
                    file => $file,
                });
                $entry_map->save
                    or die;
            }

            delete $old_maps{$file};
        }
    }

    if (%old_maps) {
        my $base_url = $blog->archive_url;
        $base_url .= '/' unless $base_url =~ m|/$|;

        for my $m (values %old_maps) {
            my $fi = MT->model('fileinfo')->load({
                url => $base_url . $m->file,
            }) or next;
            MT->instance->publisher->rebuild_from_fileinfo($fi);
        }
    }

    1;
}

1;
