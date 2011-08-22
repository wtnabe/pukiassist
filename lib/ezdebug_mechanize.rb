# -*- coding: utf-8 -*-

=begin

agent = EzDebug_Mechanize.new( :debug    => true,
                               :page_dir => /path/to/dir ) { |a|
  a.log       = Logger( '/path/to/logfile' )
  a.log.level = Logger::DEBUG
}

LICENCE : two-clause BSD

=end

gem 'mechanize', '< 2'
require 'mechanize'

class EzDebug_Mechanize < Mechanize
  def initialize( params = {} )
    super()

    @debug    = nil
    @page_dir = nil

    opt = {
      :debug    => false,
      :page_dir => nil
    }.merge( params )

    if ( opt[:debug] )
      @debug    = true
      @page_dir = opt[:page_dir] if ( opt[:page_dir] )
    end
  end

  def fetch_page( params )
    page = super

    if ( @debug and page.is_a?( Mechanize::File ) and @page_dir )
      pagepath = Object::File.join( @page_dir,
                                    sprintf( "%03i_%s",
                                             @history.size, page.filename ) )
      page.save_as( pagepath )
      Object::File.open( pagepath + '.mech', 'wb' ) { |f|
        f.write( page.inspect )
      }
    end

    return page
  end
end
