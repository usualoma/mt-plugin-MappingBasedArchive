<?php

require_once('archive_lib.php');
require_once('class.mt_entry.php');

ArchiverFactory::add_archiver( 'MappingBased', 'MappingBasedArchiver' );
class MappingBasedArchiver implements ArchiveType {
    public function get_label( $args = NULL ) {
        return 'MappingBased';
    }
    public function get_title( $args ) {
    }
    public function get_archive_list( $args ) {
    }
    public function archive_prev_next( $args, $content, &$repeat, $tag, $at ) {
    }
    public function get_range( $period_start ) {
        return array($period_start, $period_start);
    }
    public function setup_args( &$args ) {}
    public function get_archive_link_sql( $ts, $at, $args ) {}
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
        $path = str_replace($archive_url, '', $path);

        $entry = new Entry;
        $entries = $entry->Find(
            'entry_blog_id = ' . $blog->blog_id .
            ' AND mba_entry_map_file = "' . $db->escape($path) . '"' .
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
    }

    public function prepare_list($row) {
    }
}
