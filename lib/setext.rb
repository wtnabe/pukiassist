# -*- coding: utf-8 -*-

require 'kconv'
require File.dirname( __FILE__ ) + '/../bin/pukiwiki2setext'

=begin

 * PukiWiki の raw data を setext 形式に変換して出力する
 * Windows ユーザーとのやりとり前提なので SJIS/CRLF 形式に変換する

=end

module PukiAssist
  class Setext
    class RawDataNotExist < StandardError; end

    def initialize( pukiwiki, opt = {} )
      @conf = {
        'filename_suffix' => '-setext.txt'
      }
      if ( opt.is_a?( Hash ) )
        @conf.merge!( opt )
      end
      @pukiwiki = pukiwiki
    end

    def raw_path
      if ( !@raw_path )
        @raw_path = @pukiwiki.path
      end

      return @raw_path
    end

    def raw_path_available?
      if ( File.exist?( raw_path ) and File.file?( raw_path ) and
           File.readable?( raw_path ) )
        return true
      else
        raise RawDataNotExist, "#{RawDataNotExist}: #{raw_path}"
      end
    end

    def write
      if ( raw_path_available? and path )
        File.open( path, 'wb' ) { |f|
          f.puts( (PukiWiki2Setext.new.convert( File.open( raw_path ).read.toutf8 ).join( "\r\n" ) + "\r\n").tosjis )
        }
      end
    end

    def path
      if ( !@path )
        @path = raw_path.sub( @pukiwiki.filename_suffix,
                              @conf['filename_suffix'] )
      end

      return @path
    end

    def filename
      return File.basename( path )
    end
  end
end
