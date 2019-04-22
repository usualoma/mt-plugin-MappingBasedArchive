package MT::Plugin::NamedTemplateMap::App;

use strict;
use warnings;
use utf8;

use MT::Plugin::MappingBasedArchive::Util;

sub param_edit_template {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $blog = $app->blog;

    return 1 if !$blog;

    my $after = $tmpl->getElementById('useful-links');
    foreach my $t ( @{ plugin()->load_tmpl('edit_template.tmpl')->tokens } ) {
        $tmpl->insertBefore( $t, $after );
    }
}

sub edit_template_map_dialog {
    my ($app) = @_;

    return $app->error( $app->translate('No permissions') )
        unless $app->can_do('edit_templates');

    my $blog = $app->blog or return;

    my %params = ();
    my $map_id = $app->param('templatemap_id')
        or return;

    my $map = $app->model('templatemap')->load(
        {   id      => $map_id,
            blog_id => $blog->id,
        }
    ) or return;
    $params{templatemap_id} = $map->id;
    $params{$_} = $map->$_
        for qw(file_template ntm_name ntm_title_template ntm_sort_template);

    plugin()->load_tmpl( 'edit_template_map_dialog.tmpl', \%params );
}

sub post_save_template {
    my $cb = shift;
    my ( $app, $obj, $original ) = @_;

    my $blog = $app->blog or return 1;

    my $q    = $app->param;
    my $type = $q->param('type');

    if (   $type eq 'custom'
        || $type eq 'index'
        || $type eq 'widget'
        || $type eq 'widgetset' )
    {
        #
    }
    else {
        my @p = $q->param;
        my %static_maps;
        for my $p (@p) {
            $p =~ /^templatemap_ntm_name_(\d+)$/
                or next;
            my $map_id = $1;
            my $map    = $app->model('templatemap')->load(
                {   id      => $map_id,
                    blog_id => $blog->id,
                }
            ) or next;

            for my $k (qw(name sort_template title_template)) {
                my $ck = "ntm_$k";
                my $v = $q->param("templatemap_${ck}_${map_id}") || '';
                if ( ( $map->$ck || '' ) ne $v ) {
                    $map->$ck($v);
                }
            }

            $map->save;
        }
    }

    1;
}

1;
