package MT::ArchiveType::MappingBased;

use strict;
use base qw( MT::ArchiveType::Date );

use MT::Util qw(start_end_day);
use MT::Plugin::MappingBasedArchive::Util;

sub name {
    return 'MappingBased';
}

sub order {
    return 200;
}

sub archive_label {
    return plugin()->translate('MAPPING_BASED_ADV');
}

sub default_archive_templates {
    my @templates;

    my $blog = MT->instance->blog;

    if ( my $field_class = MT->model('field') ) {
        if ($blog) {
            my @fields = $field_class->load(
                {   blog_id  => [ 0, $blog->id ],
                    obj_type => 'entry',
                    type     => [qw(select radio)],
                }
            );
            for my $f (@fields) {
                my $tag = $f->tag;
                my $t
                    = qq{<mt:If tag="$tag" lower_case="1"><mt:$tag />/%i</mt:If>};
                push @templates,
                    {
                    label    => $t,
                    template => $t,
                    };
            }
        }
    }

    if ( eval "require AnotherCustomFields::Util" ) {
        if ($blog) {
            my $fields = AnotherCustomFields::Util::load_field_info('entry');
            for my $field (@$fields) {
                my $blog_id = $blog ? $blog->id : 0;
                if ( $field->{field_blog_id} ) {
                    next if ( !$field->{field_blog_id}->{$blog_id} );
                }

                next
                    unless grep { ( $field->{field_type} || '' ) eq $_ }
                    qw(select radio);

                my $tag = $field->{field_tag};
                my $t
                    = qq{<mt:If tag="$tag" lower_case="1"><mt:$tag />/%i</mt:If>};
                push @templates,
                    {
                    label    => $t,
                    template => $t,
                    };
            }
        }
    }

    if (@templates) {
        $templates[0]{default} = 1;
    }
    else {
        @templates = (
            {   label    => '<mt:EntryId />/%i',
                template => '<mt:EntryId />/%i',
                default  => 1
            }
        );
    }

    return \@templates;
}

sub template_params {
    +{};
}

sub archive_file {
    my $self = shift;
    my ($ctx) = @_;

    my $entry_map = MT::Request->instance->cache('mba_entry_map')
        or return '';

    my $ext = do {
        if ( my $blog = $ctx->stash('blog') ) {
            $blog->file_extension;
        }
        else {
            '';
        }
    };

    my $file = $entry_map->file;
    $file =~ s/\.$ext\z// if $ext;

    $file;
}

sub archive_title {
    my $self = shift;
    my ($ctx) = @_;
    $ctx->stash('mba_entry_map')->title;
}

sub date_range {
    my $obj = shift;
    my ($base) = @_;
    ( $base, $base );
}

sub _mba_entry_maps_iter {
    my $self = shift;
    my ( $templatemap_id, $order ) = @_;

    my $cache_key = 'mba_entry_maps:' . $templatemap_id;

    my $rows = MT::Request->instance->cache($cache_key);

    if ( !$rows ) {
        $rows = [];

        my $iter = MT->model('mba_entry_map')->count_group_by(
            {   templatemap_id => $templatemap_id,
                file           => { not => '' },
            },
            { group => [qw(file sort_data)], }
        );

        while ( my @row = $iter->() ) {
            push @$rows, \@row;
        }
        my $numeric = qr/^[-]?[0-9]+(\.[0-9]+)?$/;
        $rows = [
            sort {
                my $ad = $a->[2];
                my $bd = $b->[2];
                if (! $ad && ! $bd) {
                    $ad = $a->[1];
                    $bd = $b->[1];
                }

                $ad =~ m/$numeric/
                    && $bd =~ m/$numeric/ ? $ad <=> $bd : $ad cmp $bd;
            } @$rows
        ];

        MT::Request->instance->cache( $cache_key, $rows );
    }

    if ( $order && lc($order) eq 'descend' ) {
        $rows = [ reverse @$rows ];
    }
    else {
        $rows = [@$rows];
    }

    sub {
        my $row = shift @$rows;

        return if !$row;

        return (
            $row->[0],
            scalar MT->model('mba_entry_map')->load(
                {   templatemap_id => $templatemap_id,
                    file           => $row->[1],
                },
                { limit => 1 }
            )
        );
    };
}

sub archive_group_iter {
    my $self = shift;
    my ( $ctx, $args ) = @_;

    my $templatemap = $ctx->stash('mba_templatemap')
        or MT->model('templatemap')->load(
        {   blog_id      => $ctx->stash('blog_id'),
            archive_type => 'MappingBased',
        },
        ) or return sub { };

    my $iter = $self->_mba_entry_maps_iter( $templatemap->id,
        $args->{sort_order} );

    sub {
        my ( $count, $mba_entry_map ) = $iter->();

        return if !$count;

        my $terms = {
            templatemap_id => $templatemap->id,
            file           => $mba_entry_map->file,
        };
        return $count,
            mba_entry_map_terms => $terms,
            mba_entry_map       => $mba_entry_map;
    };
}

sub archive_group_entries {
    my $self = shift;
    my ( $ctx, %param ) = @_;

    my $terms = $ctx->stash('mba_entry_map_terms')
        or return [];

    my @entries = MT->model('entry')->load(
        undef,
        {   join => MT->model('mba_entry_map')->join_on( 'entry_id', $terms ),
            'sort'    => 'authored_on',
            direction => 'descend',
        }
    );

    \@entries;
}

sub archive_entries_count {
    my $obj = shift;
    my ( $blog, $at, $entry ) = @_;

    1;
}

sub next_entry_map {
    my $class = shift;
    my ($entry_map) = @_;

    my $iter = $class->_mba_entry_maps_iter( $entry_map->templatemap_id );

    while ( my $em = $iter->() ) {
        last if $em->file eq $entry_map->file;
    }

    $iter->();
}

sub previous_entry_map {
    my $class = shift;
    my ($entry_map) = @_;

    my $last_map;
    my $iter = $class->_mba_entry_maps_iter( $entry_map->templatemap_id );

    while ( my $em = $iter->() ) {
        return $last_map if $em->file eq $entry_map->file;
        $last_map = $em;
    }
}

1;
