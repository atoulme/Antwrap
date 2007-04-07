module ApacheAnt
  require 'rubygems'
  require 'rjb'
  Rjb::load("/Users/caleb/tools/apache-ant-1.7.0//lib/ant.jar", [])
  DefaultLogger =  Rjb::import("org.apache.tools.ant.DefaultLogger")
  Main = Rjb::import("org.apache.tools.ant.Main")
  Project = Rjb::import("org.apache.tools.ant.Project")
  RuntimeConfigurable = Rjb::import("org.apache.tools.ant.RuntimeConfigurable")
  Target = Rjb::import("org.apache.tools.ant.Target")
  UnknownElement = Rjb::import("org.apache.tools.ant.UnknownElement")
end

module JavaLang
  require 'rubygems'
  require 'rjb'
  System = Rjb::import("java.lang.System")
end