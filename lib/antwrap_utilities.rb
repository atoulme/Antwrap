# antwrap_utilities.rb
#
# Copyright Caleb Powell 2007
#
# Licensed under the LGPL, see the file COPYING in the distribution
#

module AntwrapClassLoader
  
  require 'find'
  
  def match(*paths)
    
    matched = Array.new 
    Find.find(*paths){ |path| matched << path if yield path }
    return matched
    
  end
  
  def load_ant_libs(ant_home)
    
    jars = match(ant_home + File::SEPARATOR + 'lib') {|p| ext = p[-4...p.size]; ext && ext.downcase == '.jar'} 
    
    if(RUBY_PLATFORM == 'java')
      jars.each {|jar| require jar }
    else
      Rjb::load(jars.join(File::PATH_SEPARATOR), [])
    end
    
  end
  
  module_function :match, :load_ant_libs
  
end
