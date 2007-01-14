require 'java'
require 'fileutils'
require 'logger'
include Java

@@log = Logger.new(STDOUT)
@@log.level = Logger::DEBUG
class AntTask
  private
  attr_reader :unknown_element, :project, :taskname, :wrapper
  protected :unknown_element, :wrapper
  
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
    
    @wrapper = org.apache.tools.ant.RuntimeConfigurable.new(@unknown_element, @unknown_element.getTaskName());
    if attributes
      attributes.each do |key, value| 
        @wrapper.setAttribute(key.to_s, value)
      end
    end
    
    if proc
      "proc given for #{taskname}"
      this = self
      singleton_class = class << proc; self; end
      singleton_class.module_eval{
        @@this = this
        def method_missing m, *a, &proc
          @@this.send m, *a, &proc
        end
      }
      proc.instance_eval &proc
    end
  end
  
  def add(child)
    puts "adding child[#{child.unknown_element().getTaskName()}] to [#{@unknown_element.getTaskName()}]"
    #    @unknown_element.addChild(child.unknown_element())
    #    child_wrapper = child.wrapper
    ##    @unknown_element.getRuntimeConfigurableWrapper().addChild(child_wrapper)
    #    @wrapper.addChild(child_wrapper)
    @unknown_element.addChild(child.unknown_element())
    @unknown_element.getRuntimeConfigurableWrapper().addChild(child.unknown_element().getRuntimeConfigurableWrapper())
    #    puts "childwrapper : #{child_wrapper}"
    #    puts "wrapper : #{@wrapper}"
  end
  
  def execute
    begin
      @unknown_element.maybeConfigure
    rescue
      puts "failed maybeConfigure"
    end
    @unknown_element.execute
  end
  
  def method_missing(sym, *args)
    puts("AntTask.method_missing sym[#{sym.to_s}]")
    begin
      proc = block_given? ? Proc.new : nil 
      child = AntTask.new(sym.to_s, project, args[0], proc)
      add(child)
    rescue StandardError
      puts("AntTask.method_missing error:" + $!)
    end
  end  
  
end

class Ant
  private
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