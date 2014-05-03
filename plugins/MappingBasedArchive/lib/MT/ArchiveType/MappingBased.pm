package MT::ArchiveType::MappingBased;

use strict;
use base qw( MT::ArchiveType::Date );

use MT::Util qw(start_end_day);
use MT::Plugin::MappingBasedArchive::Util;

sub name {
    return 'MappingBased';
}

sub archive_label {
    return plugin()->translate('MAPPING_BASED_ADV');
}

sub default_archive_templates {
    my @templates;

    my $blog = MT->instance->blog;

    if (my $field_class = MT->model('field')) {
        if ($blog) {
            my @fields = $field_class->load({
                blog_id  => [0, $blog->id],
                obj_type => 'entry',
                type     => [qw(select radio)],
            });
            for my $f (@fields) {
                my $tag = $f->tag;
                my $t = qq{<mt:If tag="$tag"><mt:$tag />/%i</mt:If>};
                push @templates, {
                    label    => $t,
                    template => $t,
                };
            }
        }
    }

    if (eval "require AnotherCustomFields::Util") {
        if ($blog) {
            my $fields = AnotherCustomFields::Util::load_field_info('entry');
            for my $field (@$fields) {
                my $blog_id = $blog ? $blog->id : 0;
                if ($field->{field_blog_id}) {
                    next if (!$field->{field_blog_id}->{$blog_id});
                }

                next unless grep { ($field->{field_type} || '') eq $_ } qw(select radio);

                my $tag = $field->{field_tag};
                my $t = qq{<mt:If tag="$tag"><mt:$tag />/%i</mt:If>};
                push @templates, {
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
            {
                label    => '<mt:EntryId />/%i',
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
    undef;
}

sub archive_title {
    '';
}

sub date_range {
    my $obj = shift;
    my ($base) = @_;
    ( $base, $base );
}

sub archive_group_iter {
    sub {};
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

    # FIXME
    0;
}

1;
