require 'rexml/document'

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
@two_tab= '   '
def print_child(parent_task, child)
  puts "#{@one_tab}#{parent_task}.add(#{child.name}("
  child.attributes.each do |key, value|
    puts "#{@one_tab}:#{key} => \"#{value}\","
  end
  puts "#{@one_tab})\n"
  
end
def print_task(task)
  puts "#{@one_tab}#{task.name}_task = #{task.name}("
  
  task.attributes.each do |key, value|
    puts "#{@one_tab}:#{key} => \"#{value}\",\n"
  end
  puts "#{@one_tab})"
  
  task.elements.each do |child|
    print_child("#{task.name}_task", child)
  end
  
  puts "#{@one_tab}#{task.name}_task.execute() \n"
  
end

xml = REXML::Document.new(File.open('/Users/caleb/projects/antwrap/test/test-resources/build.xml'))
xml.elements.each("//target") do |target| 
  
  task = "task " + create_symbol(target.attributes['name']) + 
         " => [" + create_symbol(target.attributes['depends']) + "] do"
  
  puts task
  
  target.elements.each do |element|
    print_task(element)
  end
  
  puts 'end'
  puts ''
  
end