package MT::Plugin::MappingBasedArchive::App;

use strict;
use warnings;
use utf8;

sub build_file_filter {
    my ( $cb, %param ) = @_;

    return 1 unless $param{template_map};

    $param{context}->stash('mba_entry_map_terms', {
        blog_id        => $param{blog}->id,
        templatemap_id => $param{template_map}->id,
        file           => $param{template_map}{__saved_output_file},
    });

    1;
}

sub rebuild_options {
    my ($cb, $app, $options) = @_;

    rebuild_entry_map($app) if $app->mode ne 'rebuild_confirm';

    1;
}

sub rebuild_entry_map {
    my ($app) = @_;

    $app ||= MT->instance;

    my $blog = $app->blog
        or return;


    my $per_req = $app->config->EntriesPerRebuild * 10;
    my $i = 0;


    my $entry_count = MT->model('entry')->count({
        blog_id => $blog->id,
        status => MT->model('entry')->RELEASE,
    });

    for my $obj (MT->model('templatemap')->load({
        blog_id => $blog->id,
        archive_type => 'MappingBased',
    })) {
        my $entry_map_count = MT->model('mba_entry_map')->count({
            templatemap_id => $obj->id,
        });

        next if $entry_map_count == $entry_count;

        my $iter = MT->model('entry')->load_iter(
            {
                blog_id => $blog->id,
                status  => MT->model('entry')->RELEASE,
            },
            {
                join => MT->model('mba_entry_map')->join_on(
                    undef,
                    {
                        entry_id => \'IS NULL',
                    },
                    {
                        type      => 'LEFT',
                        condition => {
                            entry_id => \'= entry_id',
                            templatemap_id => $obj->id,
                        },
                    },
                ),
            }
        );


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

        while (my $entry = $iter->()) {
            my $file;

            local $ctx->{__stash}{entry} = $entry;
            local $ctx->{__stash}{author} = $entry->author;
            local $ctx->{archive_type} = 'MappingBased';

            require MT::Builder;
            my $build  = MT::Builder->new;
            my $tokens = $build->compile( $ctx, $file_tmpl )
                or return $blog->error( $build->errstr() );
            $file = $build->build( $ctx, $tokens );

            my $entry_map = MT->model('mba_entry_map')->new;
            $entry_map->set_values({
                blog_id => $blog->id,
                templatemap_id => $obj->id,
                entry_id => $entry->id,
                file => $file || '',
            });
            $entry_map->save
                or die;


            $i++;
            if ($i > $per_req) {
                # redirect
                $app->redirect(
                    $app->uri(
                        args => {
                            (map {$_ => scalar $app->param($_)} $app->param),
                            _ => time(),
                        },
                    ),
                );
                $app->param('offset', -($app->config->EntriesPerRebuild));
                return;
            }
        }
    }
}

1;
