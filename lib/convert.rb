require 'rexml/document'
@outfile = File.new('/Users/caleb/projects/antwrap/test/output/Rakefile.rb', 'w+')
xml = REXML::Document.new(File.open('/Users/caleb/projects/antwrap/test/test-resources/build.xml'))


def create_symbol(str)
    str = rubyize(str)    
    return str.gsub(/(\w*[^,\s])/, ':\1')
end
def rubyize(str)
  if (str == nil) 
    str = ''
  else
    str = str.gsub(/(\w*)[\-|\.](\w*)/, '\1_\2')
  end
  return str
end


@outfile.print "require_gem 'Antwrap'\n"
@outfile.print "@ant = AntProject.new()\n"
@one_tab= '   '
def print_task(task, tab=@one_tab, prefix='')
  task_name = rubyize(task.name)
  @outfile.print "#{tab}#{prefix}#{task_name}("
  
  if(task_name == 'macrodef')
    task.attributes['name'] = rubyize(task.attributes['name'])
  end
  isFirst = true;
  task.attributes.each do |key, value|
    if !isFirst 
      @outfile.print(",\n#{tab+@one_tab}")
    end
    @outfile.print ":#{key} => \"#{value}\""
    isFirst = false;
  end
  
  if task.has_text?
    pcdata = task.texts().join
    if(pcdata.strip() != '')
      @outfile.print ":pcdata => \"#{pcdata}\""  
    end
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

