# -*- coding: utf-8 -*-

require 'open-uri'
require 'kconv'

=begin

PukiWiki 上の calendar2 プラグインを利用したページの処理を行う

 * Mechanize を利用した新規ページ作成
 * 同梱の raw プラグインを利用した source そのままの取得
 * Mechanize の debug 用のファイル、取得した raw data の clean up

=end

module PukiAssist
  class PukiWiki
    class ConfigForPukiwikiNotExist < StandardError; end
    class URINotEnough < StandardError; end
    class PageRawdataCannotFetch < StandardError; end
    class PukiWikiCommandNotValid < StandardError; end

    def initialize( name, opt = {} )
      @name = name
      @conf = {
        'date'            => Date.today,
        'uri_host'        => nil,
        'uri_base'        => '/',
        'pagename_prefix' => nil,
        'charset'         => 'euc',
        'filename_suffix' => '-raw.txt',
        'debug'           => nil,
      }
      if ( opt.is_a?( Hash ) )
        @conf.merge!( opt )
      else
        raise ConfigForPukiwikiNotExist
      end

      @date = @conf['date'].to_s
      if ( @conf['uri_host'] and @conf['uri_base'] )
        @uri = URI( @conf['uri_host'] ) + @conf['uri_base']
        @uri_base = @uri.dup.to_s
      else
        raise URINotEnough
      end
    end
    attr_reader :name, :date

    def pagename_prefix
      return @conf['pagename_prefix']
    end

    def filename_suffix
      return @conf['filename_suffix']
    end

    #
    # 基本的には 単に cmd=edit で開いて [ 更新 ] するだけ
    #
    # template が用意されていればこれだけで新規ページが作成できる
    # ない場合は'created by pukiassist' の内容で作成
    #
    def create_page
      agent = EzDebug_Mechanize.new( :debug    => @conf['debug'],
                                     :page_dir => debug_dir )
      form = find_msg_form( agent.get( create_uri( 'edit' ) ) )
      msg  = form.field_with( :name => 'msg' )
      msg.value = 'created by pukiassist' if msg.value == ''

      form.submit( form.button_with( :value => 'ページの更新'.send( "to#{@conf['charset']}" ) ) )
    end

    def find_msg_form( page )
      forms = page.forms_with( :action => @conf['uri_base'] )
      if ( forms.size == 0 )
        forms = page.forms_with( :action => @uri_base )
      end

      return forms.find { |f|
        f.has_field?( 'msg' )
      }
    end

    def create_uri( cmd = 'raw' )
      case cmd
      when 'raw', 'edit'
        query = {
          'page' => pagename,
          'cmd'  => cmd
        }
      else
        raise PukiWikiCommandNotValid, cmd
      end

      @uri.query = query.map { |k, v|
        "#{k}=#{v}"
      }.join( '&' )

      return @uri
    end

    def uri_for_read
      @uri.query = pagename

      return @uri
    end

    def pagename
      return URI.encode( (@conf['pagename_prefix'] + @date).send( "to#{@conf['charset']}" ) )
    end

    #
    # ページの raw data を取得
    #
    # HTML としてパースできる場合はエラーが表示されているので例外
    #
    def fetch
      uri = create_uri
      s   = uri.read
      if ( html?( s ) )
        raise PageRawdataCannotFetch, "#{PageRawdataCannotFetch.to_s}: #{uri}"
      else
        return s
      end
    end

    #
    # HTML として解釈できるかどうか
    #
    def html?( str )
      d = Hpricot( str )
      return d.inspect.include?( 'elem' )
    end

    def store
      File.open( path, 'wb' ) { |f|
        f.puts( fetch )
      }
    end

    def path
      return File.join( work_dir, filename )
    end

    def filename
      date = date4path( @date )
      return  date + @conf['filename_suffix']
    end

    def date4path( str )
      return str.gsub( /-/, '' )
    end

    def work_dir
      dir = File.join( PATH[:work], @name )
      if ( !File.exist?( dir ) )
        Dir.mkdir( dir )
      end

      return dir
    end

    def debug_dir
      dir = File.join( PATH[:page], @name )
      if ( !File.exist?( dir ) )
        Dir.mkdir( dir )
      end

      return dir
    end

    def clean
      Dir.chdir( work_dir ) {
        Dir.glob( '*~\0*.bak' ).each { |e|
          File.unlink( e )
        }
      }
      Dir.chdir( debug_dir  ) {
        Dir.glob( '*' ).each { |e|
          File.unlink( e )
        }
      }
    end
  end
end
