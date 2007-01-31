# antwrap
#
# Copyright Caleb Powell 2007
#
# Licensed under the LGPL, see the file COPYING in the distribution
#
require 'fileutils'
require 'logger'
require 'java'

module ApacheAnt
 include_class "org.apache.tools.ant.UnknownElement"
 include_class "org.apache.tools.ant.RuntimeConfigurable"
 include_class "org.apache.tools.ant.Project"
 include_class "org.apache.tools.ant.DefaultLogger"
end

module JavaLang
 include_class "java.lang.System"
end

@@log = Logger.new(STDOUT)
@@log.level = Logger::ERROR

class AntTask
  private
  @@task_stack = Array.new
  attr_reader :unknown_element, :project, :taskname
  
  public  
  def initialize(taskname, project, attributes, proc)
    if(taskname[0,1] == "_")
      taskname = taskname[1, taskname.length-1]
    end
    @taskname = taskname
    @project = project
    @unknown_element = ApacheAnt::UnknownElement.new(taskname)
    @unknown_element.project= project
    @unknown_element.namespace= ''
    @unknown_element.QName= taskname
    @unknown_element.taskType= taskname
    @unknown_element.taskName= taskname
    
    wrapper = ApacheAnt::RuntimeConfigurable.new(@unknown_element, @unknown_element.getTaskName());
    attributes.each do |key, val| 
      if(key.to_s != 'pcdata')
        wrapper.setAttribute(key.to_s, val)
      else
        wrapper.addText(val)
      end
    end unless attributes == nil
    
    if proc
      @@log.debug("task_stack.push #{taskname} >> #{@@task_stack}") 
      @@task_stack.push self
      
      singleton_class = class << proc; self; end
      singleton_class.module_eval{
        def method_missing(m, *a, &proc)
          @@task_stack.last().send(m, *a, &proc)
        end
      }
      proc.instance_eval &proc
      @@task_stack.pop 
    end
  end
  
  def method_missing(sym, *args)
    @@log.debug("AntTask.method_missing sym[#{sym.to_s}]")
    begin
      proc = block_given? ? Proc.new : nil 
      self.add(AntTask.new(sym.to_s, project, args[0], proc))
    rescue StandardError
      @@log.error("AntTask.method_missing error:" + $!)
    end
  end  
  
  def add(child)
    @@log.debug("adding child[#{child.unknown_element().getTaskName()}] to [#{@unknown_element.getTaskName()}]")
    @unknown_element.addChild(child.unknown_element())
    @unknown_element.getRuntimeConfigurableWrapper().addChild(child.unknown_element().getRuntimeConfigurableWrapper())
  end
  
  def execute
    @unknown_element.maybeConfigure
    @unknown_element.execute
    @executed = true
  end
  
  def was_executed?
    @executed
  end
  
end

class AntProject
  
  attr :project, false
  attr :declarative, true
  
  def initialize(name='', default='', basedir='',declarative=true)
    @project= ApacheAnt::Project.new
    @project.name= name
    @project.default= default
    @project.basedir= basedir
    @project.init
    self.declarative= declarative      
    default_logger = ApacheAnt::DefaultLogger.new
    default_logger.messageOutputLevel= 2
    default_logger.outputPrintStream= JavaLang::System.out
    default_logger.errorPrintStream= JavaLang::System.err
    default_logger.emacsMode= false
    @project.addBuildListener default_logger
  end
  
  def create_task(taskname, attributes, proc)
    task = AntTask.new(taskname, project(), attributes, proc)
    task.execute if declarative
    if taskname == 'macrodef'
      @@log.debug("Pushing #{attributes[:name]} to tasks")
    end
    task
  end
  
  def method_missing(sym, *args)
      begin
        @@log.info("AntProject.method_missing sym[#{sym.to_s}]")
        proc = block_given? ? Proc.new : nil 
        return create_task(sym.to_s, args[0], proc)
      rescue
        @@log.error("Error instantiating task[#{sym.to_s}]" + $!)
      end
  end

  #overridden. 'mkdir' conflicts wth the rake library.
  def mkdir(attributes)
    create_task('mkdir', attributes, (block_given? ? Proc.new : nil))
  end  
  
  #overridden. 'copy' conflicts wth the rake library.
  def copy(attributes)
    create_task('copy', attributes, (block_given? ? Proc.new : nil))
  end  
  
  #overridden. 'java' conflicts wth the JRuby library.
  def jvm(attributes=Hash.new)
    create_task('java', attributes, (block_given? ? Proc.new : nil))
  end  
  
end