<?php
/**
 * page の内容をそのまま HTML に整形せずに返す
 *
 * @since 2008-12-17
 */
function plugin_raw_action() {
  global $vars, $_title_invalidwn, $_msg_invalidiwn;
 
  $page = isset( $vars['page'] ) ? $vars['page'] : '';
 
  if ( is_page( $page ) ) {
    check_readable( $page, true, true );
    header_lastmod( $page );
    header( 'Content-Type: text/plain; charset='. SOURCE_ENCODING );
    print join( '', get_source( $page ) );
    exit;
  } else {
    return array( 'msg' => $_title_invalidwn,
                  'body' => str_replace( '$1', htmlspecialchars( $page ),
                                         str_replace( '$2', 'WikiName', $_msg_invalidiwn ) )
                  );
  }
}
