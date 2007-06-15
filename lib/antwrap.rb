# antwrap.rb
#
# Copyright Caleb Powell 2007
#
# Licensed under the LGPL, see the file COPYING in the distribution
#
require 'antwrap_utilities'

class AntTask
  attr_accessor :unknown_element, :project, :taskname, :logger, :executed
  
  public  
  def initialize(taskname, antProject, attributes, proc)
    taskname = taskname[1, taskname.length-1] if taskname[0,1] == "_"
    @logger = antProject.logger
    @taskname = taskname
    @project_wrapper = antProject
    @project = antProject.project()
    @logger.debug(antProject.to_s)
    @unknown_element = create_unknown_element(@project, taskname)
    @logger.debug(to_s)
    
    add_attributes(attributes)
  end
  
  def to_s
    return self.class.name + "[#{@taskname}]"
  end 
  
  def create_unknown_element(project, taskname)
    
    element = ApacheAnt::UnknownElement.new(taskname)
    element.setProject(project)
    element.setOwningTarget(ApacheAnt::Target.new())
    element.setTaskName(taskname)
    
    #DNR. This initializes the Task's Wrapper object and prevents NullPointerExeption upon execution of the task
    element.getRuntimeConfigurableWrapper()
    
    if(@project_wrapper.ant_version >= 1.6)
      element.setTaskType(taskname)
      element.setNamespace('')
      element.setQName(taskname)
    end
    
    return element
    
  end
  
  # Sets each attribute on the AntTask instance.
  # :attributes - is a Hash.
  def add_attributes(attributes)
    
    return if attributes == nil
    
    wrapper = ApacheAnt::RuntimeConfigurable.new(@unknown_element, @unknown_element.getTaskName());
    
    if(@project_wrapper.ant_version >= 1.6)
      attributes.each do |key, val| 
        apply_to_wrapper(wrapper, key.to_s, val){ |k,v| wrapper.setAttribute(k, v)}
      end
    else  
      @unknown_element.setRuntimeConfigurableWrapper(wrapper)
      attribute_list = XmlSax::AttributeListImpl.new()
      attributes.each do |key, val| 
        apply_to_wrapper(wrapper, key.to_s, val){ |k,v| attribute_list.addAttribute(k, 'CDATA', v)}
      end
      wrapper.setAttributes(attribute_list)
    end
    
  end
  
  def apply_to_wrapper(wrapper, key, value)
  
    raise ArgumentError, "ArgumentError: You cannot use an Array as an argument. Use the :join method instead; i.e ['file1', 'file2'].join(File::PATH_SEPARATOR)." if value.is_a?(Array)
        
    begin
      if(key == 'pcdata')
        wrapper.addText(value.to_s)
      else
        yield key, value.to_s
      end
    rescue StandardError
      raise ArgumentError, "ArgumentError: Unable to set :#{key} attribute with value => '#{value}'"
    end
  end
    
  #Add <em>child</em> as a child of this task. 
  def add(child)
    @unknown_element.addChild(child.unknown_element())
    @unknown_element.getRuntimeConfigurableWrapper().addChild(child.unknown_element().getRuntimeConfigurableWrapper())
  end

  #Invokes the AntTask. 
  def execute
    @unknown_element.maybeConfigure
    @unknown_element.execute
    @executed = true
  end
  
end

class AntProject 
  require 'logger'
  
  private
  @@classes_loaded = false
  
  def init_project(options)
    @project= ApacheAnt::Project.new
    @project.setName(options[:name] || '')
    @project.setDefault('')
    @project.setBasedir(options[:basedir] || FileUtils::pwd)
    @project.init
    self.declarative= options[:declarative] || true      
    default_logger = ApacheAnt::DefaultLogger.new
    default_logger.setMessageOutputLevel(2)
    default_logger.setOutputPrintStream(options[:outputstr] || JavaLang::System.out)
    default_logger.setErrorPrintStream(options[:errorstr] || JavaLang::System.err)
    default_logger.setEmacsMode(false)
    @project.addBuildListener(default_logger)
  end
  
  public
  attr :project, false
  attr :ant_version, false
  attr_accessor(:declarative, :logger)
  
  # Create an AntProject. Parameters are specified via a hash:
  # :ant_home=><em>Ant basedir</em>
  #   -A String indicating the location of the ANT_HOME directory. If provided, Antwrap will
  #   load the classes from the ANT_HOME/lib dir. If ant_home is not provided, the Ant jar files
  #   must be available in the CLASSPATH.   
  # :name=><em>project_name</em>
  #   -A String indicating the name of this project.
  # :basedir=><em>project_basedir</em>
  #   -A String indicating the basedir of this project. Corresponds to the 'basedir' attribute 
  #   on an Ant project.  
  # :declarative=><em>declarative_mode</em>
  #   -A boolean value indicating wether Ant tasks created by this project instance should 
  #   have their execute() method invoked during their creation. For example, with 
  #   the option :declarative=>true the following task would execute; 
  #   @antProject.echo(:message => "An Echo Task")
  #   However, with the option :declarative=>false, the programmer is required to execute the 
  #   task explicitly; 
  #   echoTask = @antProject.echo(:message => "An Echo Task")
  #   echoTask.execute()
  #   Default value is <em>true</em>.
  # :logger=><em>Logger</em>
  #   -A Logger instance. Defaults to Logger.new(STDOUT)
  # :loglevel=><em>The level to set the logger to</em>
  #   -Defaults to Logger::ERROR
  def initialize(options=Hash.new)
   
    @logger = options[:logger] || Logger.new(STDOUT)
    @logger.level = options[:loglevel] || Logger::ERROR

    if(!@@classes_loaded && options[:ant_home])
      @logger.debug("loading ant jar files. Ant_Home: #{options[:ant_home]}")
      AntwrapClassLoader.load_ant_libs(options[:ant_home])
      @@classes_loaded = true
    end

    @logger.debug(ApacheAnt::Main.getAntVersion())
    @ant_version = ApacheAnt::Main.getAntVersion()[/\d\.\d\.\d/].to_f
    init_project(options)
    
  end
  
  @@task_stack = Array.new
  def method_missing(sym, *args)
    begin
      
      @logger.debug("AntProject.method_missing sym[#{sym.to_s}]")
      task = AntTask.new(sym.to_s, self, args[0], block_given? ? Proc.new : nil)
      
      parent_task = @@task_stack.last
      @@task_stack << task
      
      yield self if block_given?
  
      @logger.debug("Adding child task #{task} ==> #{parent_task}") if parent_task
      parent_task.add(task) if parent_task
      
      if @@task_stack.size == 1 && declarative
          @logger.debug("Executing task #{task}")
          task.execute 
      elsif @@task_stack.size == 1 && !declarative
          return task
      end
    rescue
      @logger.error("Error instantiating '#{sym.to_s}' task; " + $!)
      raise
    ensure
      @@task_stack.pop
    end
    
  end
  
  #The Ant Project's name. Default is ''
  def name()
    return @project.getName
  end
  
  #The Ant Project's basedir. Default is '.'
  def basedir()
    return @project.getBaseDir().getAbsolutePath();
  end
  
  def to_s
    return self.class.name + "[#{@project.getName()}]"
  end 
  
end
