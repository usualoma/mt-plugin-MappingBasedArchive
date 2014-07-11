<?php

require_once('archive_lib.php');
require_once('class.mt_entry.php');
require_once('class.mt_mba_entry_map.php');

function mapping_based_archive_entry_map_cmp($a, $b) {
    $numeric = '/^[-]?[0-9]+(\.[0-9]+)?$/';
    $ad = $a[2];
    $bd = $b[2];
    if (! $ad && ! $bd) {
        $ad = $a[1];
        $bd = $b[1];
    }

    if ($ad === $bd) {
        return 0;
    }

    return preg_match($numeric, $ad) && preg_match($numeric, $bd)
       ? ($a < $b ? -1 : 1) : strcmp($ad, $bd);
}

function mapping_based_archive_load_entry_map($d) {
    static $mba_entry_map;
    if (! $mba_entry_map) {
        $mba_entry_map = new MBAEntryMap;
    }

    $mt = MT::get_instance();
    $maps = $mba_entry_map->Find(
        'mba_entry_map_file = "' . $mt->db()->escape($d[1]) . '"',
        false, false,
        array(
            'limit' => 1
        )
    );
    return array(
        $d[0],
        $maps[0]
    );
}

ArchiverFactory::add_archiver( 'MappingBased', 'MappingBasedArchiver' );
class MappingBasedArchiver implements ArchiveType {
    public function get_mba_entry_maps() {
        $mt = MT::get_instance();
        $ctx =& $mt->context();
        $maps = $ctx->stash('mba_entry_maps');
        if (! $maps) {
            $db =& $mt->db();

            $map = $ctx->stash('mba_templatemap');
            if (! $map) {
                return array();
            }
            $templatemap_id = $map->id;

            $blog_id = $args['blog_id'];

            $sql = "
                    SELECT count(*) AS mba_entry_map_count,
                           mba_entry_map_file,
                           mba_entry_map_sort_data
                      FROM mt_mba_entry_map
                     WHERE mba_entry_map_templatemap_id = $templatemap_id
                       AND mba_entry_map_file != ''
                     GROUP BY mba_entry_map_file, mba_entry_map_sort_data";

            $results = $db->SelectLimit($sql);

            $maps = empty($results) ? array() : $results->GetArray();
            usort($maps, 'mapping_based_archive_entry_map_cmp');
            $maps = array_map('mapping_based_archive_load_entry_map', $maps);
            $ctx->stash('mba_entry_maps', $maps);
        }
        return $maps;
    }
    public function get_label( $args = NULL ) {
        return 'MappingBased';
    }
    public function get_title( $args ) {
        $mt = MT::get_instance();
        $ctx =& $mt->context();

        $map = $ctx->stash('mba_entry_map');
        if ($map) {
            return $map->title;
        }
    }
    public function get_archive_list( $args ) {
        $maps = $this->get_mba_entry_maps();
        if ($args['sort_order'] === 'descend') {
            $maps = array_reverse($maps);
        }
        return $maps;
    }
    public function archive_prev_next( $args, $content, &$repeat, $tag, $at ) {
        $mt = MT::get_instance();
        $ctx =& $mt->context();
        $localvars = array('mba_entry_map');
        if (!isset($content)) {
            $ctx->localize($localvars);
            $map = $ctx->stash('mba_entry_map');

            $is_prev = $tag == 'archiveprevious';

            $next_map = null;
            $maps = $this->get_mba_entry_maps();
            if ($is_prev) {
                for ($i = sizeof($maps)-1; $i >= 0; $i--) {
                    if ($maps[$i][1]->file === $map->file) {
                        $next_map = $maps[$i-1][1];
                    }
                }
            }
            else {
                for ($i = 0; $i < sizeof($maps); $i++) {
                    if ($maps[$i][1]->file === $map->file) {
                        $next_map = $maps[$i+1][1];
                    }
                }
            }

            if ($next_map) {
                $ctx->stash('mba_entry_map', $next_map);
            } else {
                $ctx->restore($localvars);
                $repeat = false;
            }
        } else {
            $ctx->restore($localvars);
        }
        return $content;
    }
    public function get_range( $period_start ) {
        return array('', '');
    }
    public function setup_args( &$args ) {}
    public function get_archive_link_sql( $ts, $at, $args ) {
        $mt = MT::get_instance();
        $ctx =& $mt->context();

        $map = $ctx->stash('mba_entry_map');
        if (! $map) {
            return;
        }

        $blog = $ctx->stash('blog');
        $url = preg_replace('#^https?://[^/]*#', '', rtrim($blog->archive_url(), '/') . '/' . ltrim($map->file));

        $sql = " fileinfo_templatemap_id = " . $map->templatemap_id . "
                 AND fileinfo_url = '" . $mt->db()->escape($url) . "'";
        return $sql;
    }
    public function is_date_based() {
        return true;
    }
    public function template_params() {
        $mt = MT::get_instance();
        $db =& $mt->db();
        $ctx =& $mt->context();

        if (version_compare(PHP_VERSION, '5.3.0') >= 0) {
            $ref = new ReflectionProperty(get_class($mt), 'request');
            $ref->setAccessible(true);
            $path = $ref->getValue($mt);
        }
        else {
            $mt_data = (array)$mt;
            $path = $mt_data["\0*\0request"];
        }

        $fileinfo = $mt->resolve_url($path);
        $blog = $ctx->stash('blog');

        $archive_url = preg_replace('#^https?://[^/]*#', '', $blog->archive_url());
        $map_file = $db->escape(str_replace($archive_url, '', $fileinfo->url));

        $entry = new Entry;
        $entries = $entry->Find(
            'entry_blog_id = ' . $blog->blog_id .
            ' AND mba_entry_map_file = "' . $map_file . '"' .
            ' ORDER BY entry_authored_on DESC',
            false, false,
            array(
                'join' => array(
                    'mt_mba_entry_map' => array(
                        'condition' => 'mba_entry_map_entry_id = entry_id',
                    )
                )
            )
        );
        $ctx->stash('entries', $entries);

        $mba_entry_map = new MBAEntryMap;
        $maps = $mba_entry_map->Find(
            'mba_entry_map_file = "' . $map_file . '"',
            false, false,
            array(
                'limit' => 1
            )
        );
        $ctx->stash('mba_entry_map', $maps[0]);
    }

    public function prepare_list($row) {
        $mt = MT::get_instance();
        $ctx =& $mt->context();

        $ctx->stash('mba_entry_map', $row[1]);
    }
}


$mt = MT::get_instance();
$ctx = &$mt->context();

global $mapping_based_archive_orig_handlers;
$mapping_based_archive_orig_handlers = array();
$mapping_based_archive_orig_handlers['mtarchivelist']
    = $ctx->add_container_tag('archivelist', 'mapping_based_archive_archivelist');

function mapping_based_archive_archivelist(&$args, $content, &$ctx, &$repeat) {
    $tag = $ctx->this_tag();

    $localvars = array('mba_templatemap', 'mba_entry_map');

    if (!isset($content)) {
        $mt = MT::get_instance();
        $ctx->localize($localvars);

        if ($args['name']) {
            $templatemap_class = new TemplateMap();
            $templatemaps = $templatemap_class->Find(
                'templatemap_blog_id = ' . $ctx->stash('blog_id')
                . ' AND templatemap_ntm_name = "' . $mt->db()->escape($args['name']) . '"'
            );
            if ($templatemaps) {
                $templatemap = $templatemaps[0];
                $args['archive_type'] = $templatemap->archive_type;
                $ctx->stash('mba_templatemap', $templatemap);
            }
        }
    }

    global $mapping_based_archive_orig_handlers;
    $fn = $mapping_based_archive_orig_handlers[$tag];
    $result = $fn($args, $content, $ctx, $repeat);

    if (!$repeat) {
        $ctx->restore($localvars);
    }

    return $result;
}
