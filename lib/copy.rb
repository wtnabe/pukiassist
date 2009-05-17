require 'erb'
require 'fileutils'

module PukiAssist
  class SetextFileNotExist < StandardError; end

  class Copy
    def initialize( setext, opt = {} )
      @setext = setext
      @conf = {
        'path' => nil
      }.merge( opt )
    end

    def put
      if ( setext_path_available? )
        FileUtils.cp( setext_path, @conf['path'] )
      end
    end

    def path
      if ( !@path )
        @path = ERB.new( @conf['path'] ).result
      end

      return @path
    end

    def setext_path
      if ( !@setext_path )
        @setext_path = @setext.path
      end

      return @setext_path
    end
        
    def setext_path_available?
      if ( File.exist?( setext_path ) and File.file?( setext_path ) and
           File.readable?( setext_path ) )
        return true
      else
        raise SetextFileNotExist, "#{SetextFileNotExist.to_s}: #{setext_path}"
      end
    end
  end
end
