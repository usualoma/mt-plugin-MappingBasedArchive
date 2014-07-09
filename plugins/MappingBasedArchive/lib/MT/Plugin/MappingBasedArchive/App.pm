package MT::Plugin::MappingBasedArchive::App;

use strict;
use warnings;
use utf8;

use MT::Plugin::MappingBasedArchive::Util;

sub build_file_filter {
    my ( $cb, %param ) = @_;

    return 1 unless $param{template_map};

    my $terms = {
        blog_id        => $param{blog}->id,
        templatemap_id => $param{template_map}->id,
        file           => $param{template_map}{__saved_output_file},
    };
    $param{context}->stash( 'mba_entry_map_terms', $terms );
    $param{context}->stash( 'mba_entry_map',
        scalar MT->model('mba_entry_map')->load( $terms, { limit => 1 } ) );

    1;
}

sub pre_run {
    my ( $cb, $app ) = @_;

    if ( $app->mode eq 'view' && $app->param('_type') eq 'template' ) {
        rebuild_entry_map($app);
    }
}

sub rebuild_options {
    my ( $cb, $app, $options ) = @_;

    rebuild_entry_map($app) if $app->mode ne 'rebuild_confirm';

    1;
}

sub rebuild_entry_map {
    my ($app) = @_;

    $app ||= MT->instance;

    my $blog = $app->blog
        or return;

    my $redirect = sub {
        $app->redirect(
            $app->uri(
                args => {
                    (   map { $_ => scalar $app->param($_) }
                        grep { $_ ne '_' } $app->param
                    ),
                    @_,
                },
            ),
        );
        $app->param( 'offset', -( $app->config->EntriesPerRebuild ) );
    };

    my $per_req = $app->config->EntriesPerRebuild * 10;
    my $i       = 0;

    my $entry_count = MT->model('entry')->count(
        {   blog_id => $blog->id,
            status  => MT->model('entry')->RELEASE,
        }
    );

    for my $obj (
        MT->model('templatemap')->load(
            {   blog_id      => $blog->id,
                archive_type => 'MappingBased',
            }
        )
        )
    {
        my $entry_map_count = MT->model('mba_entry_map')
            ->count( { templatemap_id => $obj->id, } );

        next if $entry_map_count == $entry_count;

        my $iter = MT->model('entry')->load_iter(
            {   blog_id => $blog->id,
                status  => MT->model('entry')->RELEASE,
            },
            {   join => MT->model('mba_entry_map')->join_on(
                    undef,
                    { entry_id => \'IS NULL', },
                    {   type      => 'LEFT',
                        condition => {
                            entry_id       => \'= entry_id',
                            templatemap_id => $obj->id,
                        },
                    },
                ),
            }
        );

        my $file_tmpl  = build_file_template( $obj->file_template );
        my $title_tmpl = build_file_template( $obj->ntm_title_template );
        my $sort_tmpl  = build_file_template( $obj->ntm_sort_template );

        require MT::Template::Context;
        require MT::Builder;
        my $build = MT::Builder->new;

        while ( my $entry = $iter->() ) {
            my ( $file, $title, $sort );

            my $ctx = MT::Template::Context->new;
            $ctx->{__stash}{blog}    = $blog;
            $ctx->{__stash}{entry}   = $entry;
            $ctx->{__stash}{author}  = $entry->author;
            $ctx->{__stash}{builder} = $build;
            $ctx->{archive_type}     = 'MappingBased';

            $file  = $ctx->build($file_tmpl);
            $title = $ctx->build($title_tmpl) if $title_tmpl;
            $sort  = $ctx->build($sort_tmpl) if $sort_tmpl;

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

            $i++;
            if ( $i > $per_req ) {
                return $redirect->( _ => time() );
            }
        }
    }

    $redirect->() if $app->param('_');
    return;
}

1;
