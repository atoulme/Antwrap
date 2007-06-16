# antwrap.rb
#
# Copyright Caleb Powell 2007
#
# Licensed under the LGPL, see the file COPYING in the distribution
#

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

require 'antwrap_utilities'
require 'ant_project'
require 'ant_task'