package MT::Plugin::MappingBasedArchive::Template;

use strict;
use warnings;
use utf8;

use MT::ArchiveType::MappingBased;

sub archive_list {
    my ( $ctx, $args, $cond ) = @_;

    my $templatemap;
    if (my $name = $args->{name}) {
        $templatemap = MT->model('templatemap')->load({
            blog_id => $ctx->stash('blog_id'),
            ntm_name => $name,
        });
        if ($templatemap) {
            $args->{archive_type} = $templatemap->archive_type;
        }
    }

    local $ctx->{__stash}{mba_templatemap} = $templatemap;

    $ctx->super_handler($args, $cond);
}

sub archive_link {
    my ( $ctx, $args ) = @_;

    my $mba_entry_map = $ctx->stash('mba_entry_map')
        or return $ctx->super_handler($args);

    my %old_cache = %{ MT::Request->instance->cache('file') || {} };
    MT::Request->instance->cache('mba_entry_map', $mba_entry_map);

    my $out = $ctx->super_handler($args);

    MT::Request->instance->cache('mba_entry_map', undef);
    MT::Request->instance->cache('file', \%old_cache);

    $out;
}

sub archive_previous_next {
    my ( $ctx, $args, $cond ) = @_;

    my $entry_map = $ctx->stash('mba_entry_map')
        or return $ctx->super_handler( $args, $cond );

    my $tmp_entry_map
        = lc( $ctx->stash('tag') ) eq 'archiveprevious'
        ? MT::ArchiveType::MappingBased->previous_entry_map($entry_map)
        : MT::ArchiveType::MappingBased->next_entry_map($entry_map);
    local $ctx->{__stash}{mba_entry_map} = $tmp_entry_map;
    $tmp_entry_map
        ? $ctx->slurp( $args, $cond )
        : $ctx->else( $args, $cond );
}

1;
