# -*- coding: utf-8 -*-

require 'yaml'
require File.dirname( __FILE__ ) + '/lib'

module PukiAssist
  class Recipe
    RECIPE_SUFFIX = "*.yaml\0*.yml"
    EXCLUDE       = ['format']

    def self.recipes
      Dir.chdir( PATH[:recipe] ) {
        return Dir.glob( RECIPE_SUFFIX ).map { |e|
          e.sub( /\.ya?ml/, '' )
        }.uniq - EXCLUDE
      }
    end

    def self.lookup_yamlfile( recipe )
      RECIPE_SUFFIX.split( /\0/ ).map { |e|
        e.gsub( /\*/, '' )
      }.each { |e|
        file = File.join( PATH[:recipe], recipe + e )
        if ( File.exist?( file ) )
          return file
        end
      }
    end

    def self.load_recipe( recipe )
      return YAML.load_file( self.lookup_yamlfile( recipe ) )
    end

    #
    # [Return] Hash
    #
    def self.conf( recipe )
      conf = self.load_recipe( recipe )
      
      return ( conf ) ? conf : {}
    end
  end
end
