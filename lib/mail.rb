# -*- coding: utf-8 -*-

require 'net/pop'
require 'net/smtp'
require 'erb'
require 'nkf'
require 'iconv'

module PukiAssist
  class Mail
    def initialize( opt = {} )
      @conf = {
        'pop'      => nil,
        'smtp'     => nil,
        'auth'     => {
          'user' => nil,
          'pass' => nil
        },
        'from'     => nil,
        'to'       => [],
        'subject'  => nil,
        'body'     => nil,
        'encoding' => 'UTF-7'
      }.merge( opt )
      @conf['port']     = default_send_port if ( !@conf['port'] )
      @conf['encoding'] = @conf['encoding'].upcase
      @nkf_out          = nkf_out
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
        Net::POP3.auth_only( @conf['pop'],
                             nil,
                             @conf['auth']['user'],
                             @conf['auth']['pass'] )
        @conf['auth']['user'] = nil
        @conf['auth']['pass'] = nil
      end
      Net::SMTP.start( @conf['smtp'], @conf['port'],
                       'localhost.localdomain',
                       @conf['auth']['user'], @conf['auth']['pass'] ) { |s|
        s.sendmail( header + body, @conf['from'], @conf['to'] )
      }
    end

    def body
      return Iconv.conv( @conf['encoding'], 'UTF-8', erbed( @conf['body'] ) )
    end

    def subject
      return erbed( @conf['subject'] )
    end

    def header
      return <<EOD
From: #{header_encode( @conf['from'] )}
Subject: #{header_encode( subject )}
Mime-Version: 1.0
Content-Type: text/plain; charset=#{@conf['encoding']}
Content-Transfer-Encoding: #{transfer_encoding}

EOD
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

    def erbed( str )
      return ERB.new( str ).result
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
