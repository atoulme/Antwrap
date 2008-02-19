puts "Loading DevCreek.rb"
require 'rubygems'
require 'devcreek'
require 'fileutils'

#Load the devcreek gem
DevCreek::Core.instance().load_from_yaml("#{ENV['HOME']}/.antwrap.devcreek.yml")
