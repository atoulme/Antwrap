require 'rexml/document'

xml = REXML::Document.new(File.open('/Users/caleb/projects/antwrap/test/test-resources/build.xml'))

xml.elements.each("//target") do |target| 
  name = target.attributes['name']
  depends = target.attributes['depends']
  foo = "name[#{name}]"
  if depends
    foo = foo + " depends[#{depends}]"
  end
  puts '***************************'
  puts foo
  target.elements.each do |element|
    puts "child: #{element}"
  end
  puts '***************************'
  
  
end