# rjb_modules.rb
#
# Copyright Caleb Powell 2007
#
# Licensed under the LGPL, see the file COPYING in the distribution
#

module ApacheAnt
  DefaultLogger =  Rjb::import("org.apache.tools.ant.DefaultLogger")
  Main = Rjb::import("org.apache.tools.ant.Main")
  Project = Rjb::import("org.apache.tools.ant.Project")
  RuntimeConfigurable = Rjb::import("org.apache.tools.ant.RuntimeConfigurable")
  Target = Rjb::import("org.apache.tools.ant.Target")
  UnknownElement = Rjb::import("org.apache.tools.ant.UnknownElement")
end

module JavaLang
  System = Rjb::import("java.lang.System")
end

module XmlSax
  AttributeListImpl = Rjb::import("org.xml.sax.helpers.AttributeListImpl")
end