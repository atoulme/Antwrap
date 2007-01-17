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
def print_child(child, tab=@one_tab)
  @outfile.print "#{child.name}("
  isFirst = true;
  child.attributes.each do |key, value|
    if !isFirst 
      @outfile.print(",\n")
    end
    value = @properties[value] unless @properties[value] == nil
    @outfile.print "#{tab}:#{key} => \"#{value}\""
    isFirst = false;
  end
  @outfile.print ")"
  
  if(child.elements.size > 0) 
    @outfile.print tab + "{"
    child.elements.each do |grandchild|
      @outfile.print tab + "\n"
      
      print_child(grandchild, tab + tab)
    end
    @outfile.print "}"
  else
    @outfile.print "\n"
  end
end

def print_task(task, tab=@one_tab)
  if task.name == 'java'
    task_name = 'jvm'
  else
    task_name = task.name
  end
  
  @outfile.print "#{tab}#{task.name}_task = @ant.#{task_name}(\n"
  
  isFirst = true;
  task.attributes.each do |key, value|
    if !isFirst 
      @outfile.print(",\n")
    end
    value = @properties[value] unless @properties[value] == nil
    @outfile.print "#{tab}:#{key} => \"#{value}\""
    isFirst = false;
  end
  @outfile.print "#{tab})"
  
  
  if task.elements.size > 0 
    @outfile.print "{"
    task.elements.each do |child|
      @outfile.print "\n"
      print_child(child, ' ')
    end
    @outfile.print "}"
  end
end


xml = REXML::Document.new(File.open('/Users/caleb/projects/antwrap/test/test-resources/build.xml'))

@outfile.print "require 'antwrap.rb'\n"
@outfile.print "@ant = Ant.new()\n"

xml.elements.each("//property") do |property|
  @outfile.print("@ant.add_property(\"" + property.attributes['name'] + "\", \"" + property.attributes['value'] + "\")\n" )
end

xml.elements.each("//path") do |path|
  print_task(path, '')
  @outfile.print "\n"
end
xml.elements.each("//patternset") do |patternset|
  print_task(patternset, '')
  @outfile.print "\n"
end

xml.elements.each("//macrodef") do |macrodef| 
  print_task(macrodef, '')
  @outfile.print "\n"
end


xml.elements.each("//target") do |target| 
  
  task = "task " + create_symbol(target.attributes['name']) + 
         " => [" + create_symbol(target.attributes['depends']) + "] do\n"
  
  @outfile.print task
  
  target.elements.each do |element|
    @outfile.print "\n"
    print_task(element)
    @outfile.print "\n"
  end
  
  @outfile.print "end\n"
  @outfile.print "\n"
  
end
