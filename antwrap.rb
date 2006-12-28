require 'java'
require 'fileutils'
include Java

module ANT
  include_package 'org.apache.tools.ant'
end

module ANTTYPES
  include_package 'org.apache.tools.ant.types'
end

module JAVAIO
  include_package 'java.io'
end

module JAVALANG
  include_package 'java.lang'
end

class AntProject
  private_class_method :new
  @@project = nil
  def AntProject.create
    if @@project == nil
      @@project= ANT::Project.new
      @@project.init
    end
    return @@project
  end
end

module Antwrap
  public
  def copy(attributes)
    ant_task("org.apache.tools.ant.taskdefs.Copy", attributes)
  end
  
  def jar(attributes)
    attributes[:destFile]  =  JAVAIO::File.new(attributes[:destfile])
    attributes.delete_if{|key, value| key.to_s().eql?("destfile")}
    ant_task("org.apache.tools.ant.taskdefs.Jar", attributes)
  end  

  def javac(attributes)
    attributes[:srcdir]  = ANTTYPES::Path.new(AntProject.create, attributes[:srcdir])
    attributes[:classpath]  = ANTTYPES::Path.new(AntProject.create, attributes[:classpath])
    ant_task("org.apache.tools.ant.taskdefs.Javac", attributes)
  end  
  
  def ant_task(taskname, attributes)
    taskdef = make_instance(taskname)
    taskdef.send('setProject', AntProject.create)
    attributes.each do |key, value| 
      m = make_set_method key
      begin
        taskdef.send(m, introspect(value)) 
      rescue  StandardError => error
        puts "The following error occured attempting to invoke method: '#{m}' with value #{value}"
        puts "Error: #{error}"
        puts "Attempting to set property without introspection"
        taskdef.send(m, value) 
      end
    end
    taskdef.execute()
  end
  
  def make_set_method(name)
    str = name.to_s
    return 'set' + str[0,1].capitalize + str[1, str.length - 1]
  end
  
  def introspect(value)
    result = value
    case
      when value.instance_of?(TrueClass) || value.instance_of?(FalseClass)
        result = java_to_primitive value
      when value.instance_of?(String) && File.exists?(value)
        result = JAVAIO::File.new(value)  
      when value.instance_of?(String) && (value.eql?('true') || value.eql?('on') || value.eql?('yes'))
        result = java_to_primitive true
      when value.instance_of?(String) && (value.eql?('false') || value.eql?('off') || value.eql?('no'))
        result = java_to_primitive false
    end
    result
  end

  private
  def make_class(clazz)
    JavaClass.for_name(clazz)
  end
  
  def make_instance(clazz)
    clazz = JAVALANG::Class.forName(clazz)
    return clazz.newInstance
  end
  
  
end