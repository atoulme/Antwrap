# jruby_modules.rb
#
# Copyright Caleb Powell 2007
#
# Licensed under the LGPL, see the file README.txt in the distribution

module AntWrap
  module ApacheAnt
    include_class "org.apache.tools.ant.DefaultLogger"
    include_class "org.apache.tools.ant.Main"
    include_class "org.apache.tools.ant.Project"
    include_class "org.apache.tools.ant.RuntimeConfigurable"
    include_class "org.apache.tools.ant.Target"
    include_class "org.apache.tools.ant.UnknownElement"
  end
  
  module JavaLang
    include_class "java.lang.System"
  end
  
  module XmlSax
    include_class "org.xml.sax.helpers.AttributeListImpl"
  end
end