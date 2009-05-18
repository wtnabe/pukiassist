# -*- coding: utf-8 -*-

require 'rubygems'
require 'pathname'
require File.dirname( __FILE__ ) + '/ezdebug_mechanize'
require File.dirname( __FILE__ ) + '/setext'
require File.dirname( __FILE__ ) + '/pukiwiki'
require File.dirname( __FILE__ ) + '/mail'
require File.dirname( __FILE__ ) + '/copy'
require File.dirname( __FILE__ ) + '/recipe'

module PukiAssist
  def self.basepath
    return Pathname( File.dirname( __FILE__ ) ).parent;
  end

  def self.namespaces
    return Recipe.recipes
  end

  def self.conf( recipe )
    if ( !@conf or @recipe != recipe )
      @conf = Recipe.conf( recipe )
    end

    return @conf
  end

  def self.pukiwiki( recipe )
    if ( !@pukiwiki or @recipe != recipe )
      @pukiwiki = PukiWiki.new( recipe, conf( recipe )['pukiwiki'] )
    end

    return @pukiwiki
  end

  def self.setext( recipe )
    if ( !@setext or @recipe != recipe )
      @setext = Setext.new( self.pukiwiki( recipe ),
                            conf( recipe )['setext'] )
    end

    return @setext
  end

  def self.copy( recipe )
    if ( !@copy or @recipe != recipe )
      @copy = Copy.new( self.setext( recipe ),
                        conf( recipe )['copy'] )
    end

    return @copy
  end

  def self.mail( recipe )
    if ( !@mail or @recipe != recipe )
      @mail = Mail.new( recipe, conf( recipe )['mail'] )
    end

    return @mail
  end

  #
  # YYYY-MM-DD string
  #
  def self.w3c_date( date = nil )
    if ( !date )
      date = Date.today
    end

    return date.to_s
  end

  PATH = {
    :recipe => (self.basepath + 'recipes').expand_path,
    :work   => (self.basepath + 'work').expand_path,
    :page   => (self.basepath + 'page').expand_path,
  }
end
