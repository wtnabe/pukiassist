# -*- mode: ruby; coding: utf-8 -*-

require File.dirname( __FILE__ ) + '/lib/lib'
$KCODE = 'u' unless defined? ::Encoding

Dir.chdir( File.dirname( __FILE__ ) )

PukiAssist.namespaces.each { |n|
  namespace n do
    desc "create new page on #{PukiAssist.pukiwiki( n ).pagename_prefix}"
    task :create_page do
      PukiAssist.pukiwiki( n ).create_page
    end

    desc "fetch PukiWiki raw data to #{File.basename( PukiAssist.pukiwiki( n ).filename )}"
    task :fetch do
      PukiAssist.pukiwiki( n ).store
    end

    desc "covert PukiWiki to setext on #{PukiAssist.setext( n ).filename}"
    task :setextize => :fetch  do
      PukiAssist.setext( n ).write
    end

    if ( PukiAssist.conf( n ).has_key?( 'copy' ) )
      desc "copy setext file to #{PukiAssist.copy( n ).path}"
      task :copy do
        PukiAssist.copy( n ).put
      end
    end

    if ( PukiAssist.conf( n ).has_key?( 'mail' ) )
      desc "send template mail"
      task :mail do
        PukiAssist.mail( n ).sendmail
      end
    end

    desc "cleanup backup files and mechanize debugging pages"
    task :clean do
      PukiAssist.pukiwiki( n ).clean
    end
  end
}

desc "cleanup each namespace's backup and debugging pages"
task :clean do
  PukiAssist.namespaces.each { |n|
    PukiAssist.pukiwiki( n ).clean
  }
end

task :default do
  sh 'bundle exec rake -s -T', :verbose => false
end
