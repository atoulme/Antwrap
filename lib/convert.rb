# antwrap
#
# Copyright Caleb Powell 2007
#
# Licensed under the LGPL, see the file COPYING in the distribution
#
require 'rexml/document'

if ARGV.empty?
    puts "Usage: #{$0} [antfile] [rakefile]" 
    exit! 1
end

@antfile = File.open(ARGV[0])
@rakefile = File.new(ARGV[1], 'w+')
@@reserved_words = ['alias',  'and',  'BEGIN',  'begin',  'break',  'case',  'class',  
                    'def',  'defined',  'do',  'else',  'elsif',  'END',  'end',  'ensure',  
                    'false',  'for',  'if',  'in',  'module',  'next',  'nil',  'not',  'or',  
                    'redo',  'rescue',  'retry',  'return',  'self',  'super',  'then',  'true',  
                    'undef',  'unless',  'until',  'when',  'while',  'yield']

xml = REXML::Document.new(@antfile)

puts "Converting from Ant build script[#{@antfile.path}] == to ==> \n Rakefile[#{@rakefile.path}]"

def create_symbol(str)
    str = rubyize(str)    
    return str.gsub(/(\w*[^,\s])/, ':\1')
end

def rubyize(str)
  if (str == nil) 
    str = ''
  elsif (@@reserved_words.index(str) != nil)
    str = '_' + str
  else
    str = str.gsub(/(\w*)[\-|\.](\w*)/, '\1_\2')
  end
  return str
end


@rakefile.print "require_gem 'Antwrap'\n"
@rakefile.print "@ant = AntProject.new()\n"
@one_tab= '   '
def print_task(task, tab=@one_tab, prefix='')
  task_name = rubyize(task.name)
  @rakefile.print "#{tab}#{prefix}#{task_name}("
  
  if(task_name == 'macrodef')
    task.attributes['name'] = rubyize(task.attributes['name'])
  end
  isFirst = true;
  task.attributes.each do |key, value|
    if !isFirst 
      @rakefile.print(",\n#{tab+@one_tab}")
    end
    @rakefile.print ":#{key} => \"#{value}\""
    isFirst = false;
  end
  
  if task.has_text?
    pcdata = task.texts().join
    if(pcdata.strip() != '')
      @rakefile.print ":pcdata => \"#{pcdata}\""  
    end
  end
  @rakefile.print ")"
  
  
  if task.elements.size > 0 
    @rakefile.print "{"
    task.elements.each do |child|
      @rakefile.print "\n"
      print_task(child, (tab+@one_tab), '')
    end
    @rakefile.print "\n#{tab}}"
  end
end

xml.elements.each("/project/*") do |node|
  if node.name != 'target'
    print_task(node, '', '@ant.')
    @rakefile.print "\n\n"
  end
end

xml.elements.each("/project/target") do |node|
  
    task = "\ntask " + create_symbol(node.attributes['name']) + 
         " => [" + create_symbol(node.attributes['depends']) + "] do\n"
    
    @rakefile.print task
    
    node.elements.each do |child|
      print_task(child, @one_tab, '@ant.')
      @rakefile.print "\n"
    end
    @rakefile.print "end\n"
end

