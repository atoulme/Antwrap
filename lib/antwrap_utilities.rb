if(RUBY_PLATFORM == 'java')
  require 'java'
  autoload :ApacheAnt, 'jruby_modules.rb'
  autoload :JavaLang, 'jruby_modules.rb'
  autoload :XmlOrg, 'jruby_modules.rb'
else
  require 'rubygems'
  require 'rjb'
  autoload :ApacheAnt, 'rjb_modules.rb'
  autoload :JavaLang, 'rjb_modules.rb'
  autoload :XmlOrg, 'rjb_modules.rb'
end

module AntwrapClassLoader
  require 'find'
  def match(*paths)
    matched=[]
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
