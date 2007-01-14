require 'java'
require 'fileutils'
require 'logger'
include Java

class AntTask
  private
  attr_reader :unknown_element
  attr_reader :project
  protected :unknown_element
  
  public  
  def initialize(taskname, project, attributes, proc)
    @project = project
    @unknown_element = org.apache.tools.ant.UnknownElement.new(taskname)
    @unknown_element.setProject(project);
    @unknown_element.setNamespace('');
    @unknown_element.setQName(taskname);
    @unknown_element.setTaskType(taskname);
    @unknown_element.setTaskName(taskname);
    
    wrapper = org.apache.tools.ant.RuntimeConfigurable.new(@unknown_element, @unknown_element.getTaskName());
    attributes.each do |key, value| 
        wrapper.setAttribute(key.to_s, value)
    end
    if (proc != nil)
      proc.call self 
    end
  end
  
  def add(child)
    child_wrapper = child.unknown_element().getRuntimeConfigurableWrapper()
    @unknown_element.getRuntimeConfigurableWrapper().addChild(child_wrapper)
    @unknown_element.addChild(child.unknown_element)
  end
  
  def execute
    @unknown_element.maybeConfigure
    @unknown_element.execute
  end

  def method_missing(sym, *args)
    puts("AntTask.method_missing sym[#{sym.to_s}]")
    begin
      child = AntTask.new(sym.to_s, project, args[0], nil)
      add(child)
    rescue StandardError
      puts("AntTask.method_missing error:" + $!)
    end
  end  
end

class Ant
  private
  @@log = Logger.new(STDOUT)
  @@log.level = Logger::DEBUG
  public
  def get_project()
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
    return AntTask.new(taskname, get_project(), attributes, proc)
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