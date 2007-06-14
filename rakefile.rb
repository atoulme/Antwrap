# antwrap
#
# Copyright Caleb Powell 2007
#
# Licensed under the LGPL, see the file COPYING in the distribution
#
require 'rubygems'
Gem::manage_gems
require 'rake/gempackagetask'

def create_spec(spec, platform)
  spec.name          = 'Antwrap'
  spec.version       = '0.5.3'
  spec.author        = 'Caleb Powell'
  spec.email         = 'caleb.powell@gmail.com'
  spec.homepage      = 'http://rubyforge.org/projects/antwrap/'
  spec.platform      = platform
  spec.summary       = "A Ruby module that wraps the Apache Ant build tool, enabling Ant Tasks to be invoked from a Ruby/JRuby scripts."
  candidates      = Dir.glob("{lib,test,docs}/**/*")
  spec.files         = candidates.delete_if do |item|
    item.include?(".svn") || item.include?("apache-ant-1.7.0")
  end
  spec.require_path  = 'lib'
  spec.autorequire   = 'antwrap'
  spec.test_file     = 'test/tc_antwrap.rb'
  spec.has_rdoc      = true
  spec.extra_rdoc_files  = ['README', 'COPYING']
end        

jruby_spec = Gem::Specification.new do |spec| 
  create_spec(spec, 'java')
end

ruby_spec = Gem::Specification.new do |spec| 
  create_spec(spec, Gem::Platform::RUBY) 
  spec.add_dependency("rjb", ">= 1.0.3")
end

Rake::GemPackageTask.new(ruby_spec) do |pkg|
  puts "Creating Ruby Gem"
end

Rake::GemPackageTask.new(jruby_spec) do |pkg|
  puts "Creating JRuby Gem"
end

task :gems => [:pkg => '/Antwrap-0.5.1.gem'] 

