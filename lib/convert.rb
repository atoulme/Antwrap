require 'rexml/document'
@outfile = File.new('/Users/caleb/projects/antwrap/test/output/Rakefile.rb', 'w+')
@properties = Hash.new

def create_symbol(str)
  if (str == nil) 
    str = ''
  else
    str = str.gsub(/(\w*)[\-|\.](\w*)/, '\1_\2')
    str = str.gsub(/(\w*[^,\s])/, ':\1')
  end
  return str
end


@one_tab= '   '
def print_child(parent_task, child)
  @outfile.print "#{@one_tab}#{parent_task}.add @ant.#{child.name}("
  isFirst = true;
  child.attributes.each do |key, value|
    if !isFirst 
      @outfile.print(",\n")
    end
    value = @properties[value] unless @properties[value] == nil
    @outfile.print "#{@one_tab}:#{key} => \"#{value}\""
    isFirst = false;
  end
  @outfile.print "#{@one_tab})\n"
  
end
def print_task(task)
  if task.name == 'java'
    task_name = 'jvm'
  else
    task_name = task.name
  end
  
  @outfile.print "#{@one_tab}#{task.name}_task = @ant.#{task_name}(\n"
  
  isFirst = true;
  task.attributes.each do |key, value|
    if !isFirst 
      @outfile.print(",\n")
    end
    value = @properties[value] unless @properties[value] == nil
    @outfile.print "#{@one_tab}:#{key} => \"#{value}\""
    isFirst = false;
  end
  @outfile.print "#{@one_tab})\n"
  
  task.elements.each do |child|
    print_child("#{task.name}_task", child)
  end
  
  @outfile.print "#{@one_tab}#{task.name}_task.execute() \n"
  
end

xml = REXML::Document.new(File.open('/Users/caleb/projects/antwrap/test/test-resources/build.xml'))

@outfile.print "require 'antwrap.rb'\n"
@outfile.print "@ant = Ant.new()\n"

xml.elements.each("//property") do |property|
    @properties[property.attributes['name']] = property.attributes['value']
    @outfile.print("@ant.get_project().setNewProperty(\"" + property.attributes['name'] + "\", \"" + property.attributes['value'] + "\")\n" )
end
puts @properties

xml.elements.each("//target") do |target| 
  
  task = "task " + create_symbol(target.attributes['name']) + 
         " => [" + create_symbol(target.attributes['depends']) + "] do\n"
  
  @outfile.print task
  
  target.elements.each do |element|
    print_task(element)
  end
  
  @outfile.print "end\n"
  @outfile.print "\n"
  
end