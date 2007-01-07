require 'rexml/document'
@outfile = File.new('/Users/caleb/projects/antwrap/test/output/Rakefile.rb', 'w+')
@properties = Hash.new

def replace_properties(str, props)
  if(str == nil)
    return ""
  end
  str = str.gsub(/\$\{([\w|\-|\.|\_]*)\}/) do |str| 
    puts "parsing #{str}"
    if(props[$1] != nil)
      props[$1]
    else
      str
    end      
  end
end


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
def print_child(parent_task, child, tab=@one_tab)
  @outfile.print "#{child.name}_child =  @ant.#{child.name}("
  isFirst = true;
  child.attributes.each do |key, value|
    if !isFirst 
      @outfile.print(",\n")
    end
    value = @properties[value] unless @properties[value] == nil
    @outfile.print "#{tab}:#{key} => \"#{value}\""
    isFirst = false;
  end
  @outfile.print ")\n"
   
  child.elements.each do |grandchild|
    print_child("#{child.name}_child", grandchild, tab)
  end
  @outfile.print "#{tab}#{parent_task}.add(#{child.name}_child)\n"
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
  @outfile.print "#{tab})\n"
  
  task.elements.each do |child|
    print_child("#{task.name}_task", child, tab)
  end
  
  @outfile.print "#{tab}#{task.name}_task.execute() \n"
  
end

xml = REXML::Document.new(File.open('/Users/caleb/projects/antwrap/test/test-resources/build.xml'))

@outfile.print "require 'antwrap.rb'\n"
@outfile.print "@ant = Ant.new()\n"

xml.elements.each("//property") do |property|
    @properties[property.attributes['name']] = replace_properties(property.attributes['value'], @properties)
end

xml.elements.each("//property") do |property|
    @outfile.print("@ant.get_project().setNewProperty(\"" + property.attributes['name'] + "\", \"" + @properties[property.attributes['name']] + "\")\n" )
end

@properties.each do |key, value|
  puts "key[#{key}] => \"#{value}\""
end

def fix_atts(element, props)
  puts "fix_atts"
  element.attributes.each do |key, value|
    element.attributes[key] = replace_properties(value, props)  
  end
  
  element.elements.each do |child|
    puts "calling child"
    fix_atts(child, props)
  end
end

xml.elements.each("//path") do |path|
    fix_atts(path, @properties)
    print_task(path, '')
    @outfile.print "\n"
end
xml.elements.each("//patternset") do |patternset|
    fix_atts(patternset, @properties)
    print_task(patternset, '')
    @outfile.print "\n"
end

xml.elements.each("//macrodef") do |macrodef| 
#  fix_atts(macrodef, @properties)
  print_task(macrodef, '')
  @outfile.print "\n"
end


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
