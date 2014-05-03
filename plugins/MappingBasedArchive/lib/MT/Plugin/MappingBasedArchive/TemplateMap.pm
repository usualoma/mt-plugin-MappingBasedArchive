package MT::Plugin::MappingBasedArchive::TemplateMap;

use strict;
use warnings;
use utf8;

sub pre_save {
    my ( $cb, $obj, $original ) = @_;

    return 1 unless $obj->id;
    return 1 if $obj->archive_type ne 'MappingBased';

    MT->model('templatemap')->count({
        id => $obj->id,
        file_template => $obj->file_template,
    }) and return 1;

    MT->model('mba_entry_map')->remove({
        templatemap_id => $obj->id,
    });

    1;
}

sub post_save {
    my ( $cb, $obj ) = @_;

    return 1 if $obj->archive_type ne 'MappingBased';

    my $blog = MT->model('blog')->load($obj->blog_id);

    MT->model('mba_entry_map')->count({
        templatemap_id => $obj->id,
    }) and return 1;

    my @entries = MT->model('entry')->load({
        blog_id => $obj->blog_id,
    });

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

    1;
}

sub post_remove {
    my ( $cb, $obj ) = @_;

    return if $obj->archive_type ne 'MappingBased';

    my $blog = MT->model('blog')->load($obj->blog_id);

    MT->model('mba_entry_map')->remove({
        templatemap_id => $obj->id,
    });
}

sub build_file_filter {
    my ( $cb, %param ) = @_;

    $param{context}->stash('mba_entry_map_terms', {
        blog_id        => $param{blog}->id,
        templatemap_id => $param{template_map}->id,
        file           => $param{template_map}{__saved_output_file},
    });

    1;
}

1;
