require 'rexml/document'
@outfile = File.new('/Users/caleb/projects/antwrap/test/output/Rakefile.rb', 'w+')
@properties = Hash.new
xml = REXML::Document.new(File.open('/Users/caleb/projects/antwrap/test/test-resources/build.xml'))
@outfile.print "require 'antwrap.rb'\n"
@outfile.print "@ant = Ant.new()\n"

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
def print_task(task, tab=@one_tab, prefix='')
  if task.name == 'java'
    task_name = 'jvm'
  else
    task_name = task.name
  end
  
  @outfile.print "#{tab}#{prefix}#{task_name}("
  
  isFirst = true;
  task.attributes.each do |key, value|
    if !isFirst 
      @outfile.print(",\n#{tab+@one_tab}")
    end
    value = @properties[value] unless @properties[value] == nil
    @outfile.print ":#{key} => \"#{value}\""
    isFirst = false;
  end
  @outfile.print ")"
  
  
  if task.elements.size > 0 
    @outfile.print "{"
    task.elements.each do |child|
      @outfile.print "\n"
      print_task(child, (tab+@one_tab), '')
    end
    @outfile.print "\n#{tab}}"
  end
end

xml.elements.each("/project/*") do |node|
  if node.name != 'target'
    print_task(node, '', '@ant.')
    @outfile.print "\n\n"
  end
end

xml.elements.each("/project/target") do |node|
  
    task = "\ntask " + create_symbol(node.attributes['name']) + 
         " => [" + create_symbol(node.attributes['depends']) + "] do\n"
    
    @outfile.print task
    
    node.elements.each do |child|
      print_task(child, @one_tab, '@ant.')
      @outfile.print "\n"
    end
    @outfile.print "end\n"
end

