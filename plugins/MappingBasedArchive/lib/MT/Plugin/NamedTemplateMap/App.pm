package MT::Plugin::NamedTemplateMap::App;

use strict;
use warnings;
use utf8;

use MT::Plugin::MappingBasedArchive::Util;

sub param_edit_template {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $blog = $app->blog;

    return 1 if !$blog;

    my $after = MT->version_number >= 7
        ? $tmpl->getElementById('useful-links')
        : $tmpl->getElementById('header_include');
    my $plugin_tmpl = MT->version_number >= 7
        ? 'edit_template.tmpl'
        : 'edit_template.v6.tmpl';
    foreach my $t ( @{ plugin()->load_tmpl($plugin_tmpl)->tokens } ) {
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

    my $plugin_tmpl = MT->version_number >= 7
        ? 'edit_template_map_dialog.tmpl'
        : 'edit_template_map_dialog.v6.tmpl';
    plugin()->load_tmpl( $plugin_tmpl, \%params );
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
