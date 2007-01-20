# antwrap
#
# Copyright Caleb Powell 2007
#
# Licensed under the LGPL, see the file COPYING in the distribution
#
require 'rubygems'

SPEC = Gem::Specification.new do |s|
  s.name          = 'Antwrap'
  s.version       = '0.1'
  s.author        = 'Caleb Powell'
  s.email         = 'caleb.powell@gmail.com'
  s.homepage      = 'http://rubyforge.org/projects/antwrap/'
  s.platform      = Gem::Platform::RUBY
  s.summary       = "A JRuby module that wraps the Apache Ant build tool"
  candidates      = Dir.glob("{lib,test}/**/*")
  s.files         = candidates.delete_if do |item|
                      item.include?(".svn")
                    end
  s.require_path  = 'lib'
  s.autorequire   = 'antwrap'
  s.test_file     = 'test/tc_antwrap.rb'
  s.has_rdoc      = false
  s.extra_rdoc_files  = ['README']
  
end