# -*- coding: utf-8 -*-

require 'net/pop'
require 'net/smtp'
require 'erb'
require 'nkf'
require 'iconv'

module PukiAssist
  class Mail
    def initialize( name, opt = {} )
      @name = name
      @conf = {
        'pop'      => nil,
        'smtp'     => nil,
        'auth'     => {
          'user' => nil,
          'pass' => nil,
          'type' => nil,
        },
        'from'     => nil,
        'to'       => [],
        'cc'       => [],
        'bcc'      => [],
        'subject'  => nil,
        'body'     => nil,
        'encoding' => 'UTF-7'
      }.merge( opt )
      arrayize_dests
      @conf['port']     = default_send_port if ( !@conf['port'] )
      @conf['encoding'] = @conf['encoding'].upcase
      @nkf_out          = nkf_out
    end
    attr_reader :name

    def destinations
      return %w( to cc bcc )
    end

    def arrayize_dests
      destinations.each { |e|
        @conf[e] = @conf[e].is_a?( String ) ? [@conf[e]] : @conf[e]
      }
    end

    def default_send_port
      # non-auth smtp
      port = 25

      if ( smtp_auth? )
          port = 587
      elsif ( pop_before_smtp? )
        port = 25
      end

      return port
    end

    def sendmail
      if ( pop_before_smtp? )
        apop = ( @conf['auth']['type'] == 'apop' )
        Net::POP3.APOP( apop ).auth_only( @conf['pop'],
                                          nil,
                                          @conf['auth']['user'],
                                          @conf['auth']['pass'] )
        @conf['auth']['user'] = nil
        @conf['auth']['pass'] = nil
        @conf['auth']['type'] = nil
        sleep 1
      end
      authtype = @conf['auth']['type'].is_a?( Symbol ) ? @conf['auth']['type'] : nil
      Net::SMTP.start( @conf['smtp'], @conf['port'],
                       'localhost.localdomain',
                       @conf['auth']['user'], @conf['auth']['pass'],
                       authtype ) { |s|
        message = header + body
        message = message.force_encoding('binary') if defined? ::Encoding
        s.sendmail( message, @conf['from'], cat_dests )
      }
    end

    def body
      body = ''

      case @conf['body']
      when String
        body = erb_apply( @conf['body'] )
      when Symbol
        body = erb_apply( open( File.join( PATH[:recipe], "#{@name}.erb" ) ).read )
      end

      if defined? ::Encoding
        body.encode( @conf['encoding'] )
      else
        Iconv.conv( @conf['encoding'], 'UTF-8', body )
      end
    end

    def subject
      return erb_apply( @conf['subject'] )
    end

    def header
      h = erb_apply( <<EOD )
From: <%= header_encode( @conf['from'] ) %>
Subject: <%= header_encode( subject ) %>
<%- %w( to cc ).each { |e| if ( @conf[e].size > 0 ) -%>
<%= spread_destination( e ) %>
<%- end } -%>
Mime-Version: 1.0
Content-Type: text/plain; charset=<%= @conf['encoding'] %>
Content-Transfer-Encoding: <%= transfer_encoding %>

EOD

      if defined? ::Encoding
        h.encode( @conf['encoding'] )
      else
        h
      end
    end

    def spread_destination( dest )
      return "#{dest.capitalize}: #{@conf[dest].join( ',' )}"
    end

    def cat_dests
      dests = []

      %w( to cc bcc ).each { |e|
        case @conf[e]
        when Array
          dests += @conf[e]
        when String
          dests << @conf[e]
        end
      }

      return dests
    end

    #
    # nkf output encoding option
    #
    def nkf_out
      case @conf['encoding']
      when /UTF/
        'w'
      else
        'j'
      end
    end

    def header_encode( content )
      return NKF.nkf( "-M#{@nkf_out}", content )
    end

    def erb_apply( str )
      return ERB.new( str, nil, '-' ).result( binding )
    end

    def pop_before_smtp?
      return ( @conf['pop'] and
               @conf['auth']['user'] and @conf['auth']['pass'] )
    end

    def smtp_auth?
      return ( !@conf['pop'] and
               @conf['auth']['user'] and @conf['auth']['pass'] )
    end

    def transfer_encoding
      return ( enc_8bit? ) ? '8bit' : '7bit'
    end

    def enc_8bit?
      return body.unpack( 'C*' ).any? { |c|
        c & 0x80 > 0
      }
    end
  end
end
