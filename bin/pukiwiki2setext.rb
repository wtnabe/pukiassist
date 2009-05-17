#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

=begin

もっとも基本的な PukiWiki の文法を解釈して setext っぽく変換する。
基本、適当。

Usage : ruby pukiwiki2setext.rb FILES ...

=end

class TooSmallHeading < StandardError; end

class PukiWiki2Setext
  COMMENT        = /^\/\//
  HEADING        = /^(\*+)/
  UNORDERED_LIST = /^(-+)/
  ORDERED_LIST   = /^(\++)/
  BLOCK_PLUGIN   = /^#/
  INLINE_PLUGIN  = /&[a-zA-Z0-9]+(:?\([^()]+\)(:?\{[^{}]+\})?)?;/

  def initialize
    @past = nil;
  end

  def read( file )
    return open( file )
  end
  
  def convert( lines )
    dat = []

    count = 0
    lines.each_line { |line|
      line   = delete_inline_plugin( line.chomp )
      count += 1

      str = ''
      begin
        case line
        when COMMENT, BLOCK_PLUGIN
          ; # remove
        when HEADING
          dat += convert_heading( line )
        when UNORDERED_LIST
          str = convert_ul( line )
        when ORDERED_LIST
          str = convert_ol( line )
        else
          str = line
        end
      rescue => e
        raise e, "Error ! Line Number #{count}"
      end

      dat << str if ( str.size > 0 )
    }

    return dat
  end

  def convert_heading( line )
    underline_chr = ['=', '-']

    if ( line =~ HEADING )
      depth = $1.length - 1
      line.sub!( HEADING, '' )
      if ( depth and depth < underline_chr.size )
        return ['', line, underline_chr[depth] * width( line.tosjis )]
      else
        raise TooSmallHeading
      end
    else
      return line
    end
  end

  def convert_ul( line )
    bullet = '*'
    if ( line =~ UNORDERED_LIST )
      depth = $1.length - 1
      line.sub!( UNORDERED_LIST, '' )
      return ' ' + '  ' * depth + bullet + ' ' + line
    else
      return line
    end
  end

  def convert_ol( line )
    bullet = '1.'
    if ( line =~ ORDERED_LIST )
      depth = $1.length - 1
      line.sub!( ORDERED_LIST, '' )
      return ' ' + '  ' * depth + bullet + ' ' + line
    else
      return line
    end
  end

  def delete_inline_plugin( line )
    line = line.sub( INLINE_PLUGIN, '' )
    if ( line === INLINE_PLUGIN )
      return delete_inline_plugin( line )
    else
      return line
    end
  end

  def width( string )
    if ( string.respond_to?( :bytesize ) )
      return string.bytesize
    else
      return string.size
    end
  end
end

if ( __FILE__ == $0 )
  text = []
  ARGV.each { |f|
    if ( File.exist?( f ) )
      text = open( f ).read
    end
  }
  puts PukiWiki2Setext.new.convert( text ).join( "\n" )
end
