require 'java'
require 'fileutils'
require 'logger'
include Java

@@log = Logger.new(STDOUT)
@@log.level = Logger::INFO
  
class AntTask
  private
  @@task_stack=Array.new
  attr_reader :unknown_element, :project, :taskname
  protected :unknown_element
  public  
  def initialize(taskname, project, attributes, proc)
    @taskname = taskname
    @project = project
    @unknown_element = org.apache.tools.ant.UnknownElement.new(taskname)
    @unknown_element.setProject(project);
    @unknown_element.setNamespace('');
    @unknown_element.setQName(taskname);
    @unknown_element.setTaskType(taskname);
    @unknown_element.setTaskName(taskname);
    
    wrapper = org.apache.tools.ant.RuntimeConfigurable.new(@unknown_element, @unknown_element.getTaskName());
    if attributes
      attributes.each do |key, value| 
        wrapper.setAttribute(key.to_s, value)
      end
    end
    
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
      self.add AntTask.new(sym.to_s, project, args[0], proc)
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
    begin
      @unknown_element.maybeConfigure
    rescue
      @@log.error("failed maybeConfigure")
    end
    @unknown_element.execute
  end
end

class Ant
  private
  public
  attr_reader :project
  
  def project()
    if @project == nil
      @project= org.apache.tools.ant.Project.new
      @project.init
      default_logger = org.apache.tools.ant.DefaultLogger.new
      default_logger.setMessageOutputLevel(2);
      default_logger.setOutputPrintStream(java.lang.System.out);
      default_logger.setErrorPrintStream(java.lang.System.err);
      default_logger.setEmacsMode(false);
      @project.addBuildListener(default_logger)
    end
    return @project
  end
  
  def create_task(taskname, attributes, proc)
    AntTask.new(taskname, project(), attributes, proc)
  end
  
  def method_missing(sym, *args)
    begin
      proc = block_given? ? Proc.new : nil 
      return create_task(sym.to_s, args[0], proc)
    rescue
      @@log.error("Ant.method_missing sym[#{sym.to_s}]")
    end
  end
  
  def jvm(attributes)
    proc = block_given? ? Proc.new : nil 
    create_task('java', attributes, proc)
  end  
  
  def mkdir(attributes)
    proc = block_given? ? Proc.new : nil 
    create_task('mkdir', attributes, proc)
  end  
  
  def copy(attributes)
    proc = block_given? ? Proc.new : nil 
    create_task('copy', attributes, proc)
  end  
  
  
end