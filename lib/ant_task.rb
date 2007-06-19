# ant_task.rb
#
# Copyright Caleb Powell 2007
#
# Licensed under the LGPL, see the file COPYING in the distribution
#

class AntTask
  attr_accessor :unknown_element, :project, :taskname, :logger, :executed
  
  public  
  # Creates an AntTask
  # taskname 
  #   -A String representing the name of an Ant Task. This name should correspond to 
  #   the element name of the Ant xml task (e.g. javac, jar, war, etc).
  # antProject
  #   -An instance of an AntProject
  # attributes
  #   -A Hash of task name/values to be applied to the task.
  #   
  # For example:
  #   antProject = AntProject.new()
  #   antTask = AntTask.new('javac', antProject, {:debug => 'on', :verbose => 'no', :fork => 'no'})     
  def initialize(taskname, antProject, attributes)
    
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
  
  # Displays the Class name followed by the Task name
  # -e.g.  AntTask[javac]
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
    
  # Add <em>child</em> as a child of this task. 
  def add(child)
    @unknown_element.addChild(child.unknown_element())
    @unknown_element.getRuntimeConfigurableWrapper().addChild(child.unknown_element().getRuntimeConfigurableWrapper())
  end

  # Invokes the AntTask. 
  def execute
    @unknown_element.maybeConfigure
    @unknown_element.execute
    @executed = true
    return nil
  end
  
end
