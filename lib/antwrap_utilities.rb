module Find
  require 'find'
  def match(*paths)
    matched=[]
    find(*paths){ |path| matched << path if yield path }
    return matched
  end
  module_function :match
end

class AntwrapClassLoader
  def load_ant_libs(ant_home)
    puts "loading ant jar files"
    jars = Find.match(ant_home + '/lib') {|p| ext = p[-4...p.size]; ext && ext.downcase == '.jar'} 
    if(RUBY_PLATFORM == 'java')
      require 'java'
      jars.each {|jar| addURL(jar) }
      require 'jruby_modules.rb'
    else
      require 'rubygems'
      require 'rjb'
      Rjb::load(jars.join(":"), [])
      require 'rjb_modules.rb'
    end
    
  end
  
  def addURL(url)
    begin
      sysloader = java.lang.ClassLoader.getSystemClassLoader();
      methods = java.lang.Class.forName("java.net.URLClassLoader").getDeclaredMethods()
      add_url_method = methods.select { |m| m.getName() == "addURL" }[0]
      add_url_method.setAccessible(true);
      list = java.util.ArrayList.new
      list.add(java.io.File.new(url).toURL())
      add_url_method.invoke(sysloader, list.toArray());
    rescue
      puts "AntwrapClassLoader: Error loading #{url} [#{$!}]"
    end
  end
end
