require 'java'
require 'fileutils'
require 'logger'
include Java

class AntTask < org.apache.tools.ant.UnknownElement
  
  def add(child)
    getRuntimeConfigurableWrapper().addChild(child.getRuntimeConfigurableWrapper())
    addChild(child)
  end
  
  def execute
    maybeConfigure
    super
  end
  
end

class Ant
  private
  @@log = Logger.new(STDOUT)
  @@log.level = Logger::DEBUG
  @project = nil
  
  public
  def get_project()
    if @project == nil
      @project= org.apache.tools.ant.Project.new
      @project.init
      default_logger = org.apache.tools.ant.DefaultLogger.new
      #      default_logger.setMessageOutputLevel(org.apache.tools.ant.Project.MSG_INFO);
      default_logger.setMessageOutputLevel(2);
      default_logger.setOutputPrintStream(java.lang.System.out);
      default_logger.setErrorPrintStream(java.lang.System.err);
      default_logger.setEmacsMode(false);
      @project.addBuildListener(default_logger)
    end
    return @project
  end
  
  def method_missing(sym, *args)
    begin
      if (args[1] == nil)
        create_task(sym.to_s, args[0])    
      elsif(args[1] != nil)
        create_task(sym.to_s, args[0], args[1])    
      end
    rescue
      @@log.error("Ant.method_missing sym[#{sym.to_s}]")
      super.method_missing(sym, args)
    end
  end
  
  def jvm(attributes, *children)
    create_task('java', attributes, *children)
  end  
  
  def mkdir(attributes, *children)
    create_task('mkdir', attributes, *children)
  end  
  
  def copy(attributes, *children)
    create_task('copy', attributes, *children)
  end  
  
  def create_task(taskname, attributes, *children)
    @@log.info("--task[#{taskname.to_s}]--")
    task = AntTask.new(taskname);
    task.setProject(get_project());
    task.setNamespace('');
    task.setQName(taskname);
    task.setTaskType(taskname);
    task.setTaskName(taskname);
    
    wrapper = org.apache.tools.ant.RuntimeConfigurable.new(task, task.getTaskName());
    if(attributes != nil)
      attributes.each do |key, value| 
        wrapper.setAttribute(key.to_s, value)
      end
    end

    children.map {|child| task.add(child)} unless children == nil 

    return task
  end
  
end