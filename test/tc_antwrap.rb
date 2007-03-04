# antwrap
#
# Copyright Caleb Powell 2007
#
# Licensed under the LGPL, see the file COPYING in the distribution
#
require 'test/unit'
require 'fileutils'
require '../lib/antwrap.rb'
require 'java'
class TestStream < java.io.PrintStream
    attr_reader :last_line
    
    def initialise(out)
      self.super(out)
    end
    
    def println(s)
      puts "s"
      @last_line = s
      self.super(s)
    end
    
    def print(s)
      puts "s"
      @last_line = s
      self.super(s)
    end
end

class TestAntwrap < Test::Unit::TestCase
  
  def setup
    #   ENV is broken as of JRuby 0.9.2 but patched in 0.9.3 (see: http://jira.codehaus.org/browse/JRUBY-349)
    #   @output_dir = ENV['PWD'] + '/output'
    #   @resource_dir = ENV['PWD'] + '/test-resources'
    #   The following is a workaround
    @current_dir = Java::java.lang.System.getProperty("user.dir")
    @ant_proj_props = {:name=>"testProject", :basedir=>@current_dir, :declarative=>true, 
                        :logger=>Logger.new(STDOUT), :loglevel=>Logger::DEBUG}
    @ant = AntProject.new(@ant_proj_props)
    assert(@ant_proj_props[:name] == @ant.name())
    assert(@ant_proj_props[:basedir] == @ant.basedir())
    assert(@ant_proj_props[:declarative] == @ant.declarative())
    
    @output_dir = @current_dir + '/test/output'
    @resource_dir = @current_dir + '/test/test-resources'
    
    if File.exists?(@output_dir)
      FileUtils.remove_dir(@output_dir)
    end
    FileUtils.mkdir(@output_dir, :mode => 0775)
  end
  
  def test_antproject_init
    @ant_proj_props = {:name=>"testProject", :declarative=>true, 
                        :logger=>Logger.new(STDOUT), :loglevel=>Logger::ERROR}
    ant_proj = AntProject.new(@ant_proj_props)
    assert(@ant_proj_props[:name] == ant_proj.name())
    assert(@current_dir == ant_proj.basedir())
    assert(@ant_proj_props[:declarative] == ant_proj.declarative())
    assert(@ant_proj_props[:logger] == ant_proj.logger())
  end
      
  def test_unzip_task
    assert_absent @output_dir + '/parent/FooBarParent.class'
    task = @ant.unzip(:src => @resource_dir + '/parent.jar',
    :dest => @output_dir)
    
    assert_exists @output_dir + '/parent/FooBarParent.class'
  end
  
  def test_copyanddelete_task
    file = @output_dir + '/foo.txt'
    assert_absent file
    @ant.copy(:file => @resource_dir + '/foo.txt', 
    :todir => @output_dir)
    assert_exists file
    
    @ant.delete(:file => file)
    assert_absent file
  end
  
  def test_javac_task
    FileUtils.mkdir(@output_dir + '/classes', :mode => 0775)
    
    assert_absent @output_dir + '/classes/foo/bar/FooBar.class'
    
    @ant.javac(:srcdir => @resource_dir + '/src', 
    :destdir => @output_dir + '/classes',
    :debug => 'on',
    :verbose => 'no',
    :fork => 'no',
    :failonerror => 'yes',
    :includes => 'foo/bar/**',
    :excludes => 'foo/bar/baz/**',
    :classpath => @resource_dir + '/parent.jar')
    
    assert_exists @output_dir + '/classes/foo/bar/FooBar.class'
    assert_absent @output_dir + '/classes/foo/bar/baz/FooBarBaz.class'
  end
  
  def test_javac_task_with_property
    FileUtils.mkdir(@output_dir + '/classes', :mode => 0775)
    
    assert_absent @output_dir + '/classes/foo/bar/FooBar.class'
    @ant.property(:name => 'pattern', :value => '**/*.jar') 
    @ant.property(:name => 'resource_dir', :value => @resource_dir)
    @ant.path(:id => 'common.class.path'){
      fileset(:dir => '${resource_dir}'){
        include(:name => '${pattern}')
      }
    }
    
    @ant.javac(:srcdir => @resource_dir + '/src', 
    :destdir => @output_dir + '/classes',
    :debug => 'on',
    :verbose => 'yes',
    :fork => 'no',
    :failonerror => 'yes',
    :includes => 'foo/bar/**',
    :excludes => 'foo/bar/baz/**',
    :classpathref => 'common.class.path')
    
    assert_exists @output_dir + '/classes/foo/bar/FooBar.class'
    assert_absent @output_dir + '/classes/foo/bar/baz/FooBarBaz.class'
  end
  
  def test_jar_task
    assert_absent @output_dir + '/Foo.jar'
    @ant.property(:name => 'outputdir', :value => @output_dir)
    @ant.property(:name => 'destfile', :value => '${outputdir}/Foo.jar') 
    @ant.jar( :destfile => "${destfile}", 
    :basedir => @resource_dir + '/src',
    :duplicate => 'preserve')
    
    assert_exists @output_dir + '/Foo.jar'
  end
  
  def test_java_task
  
    return if @ant.ant_version < 1.7
     
    FileUtils.mkdir(@output_dir + '/classes', :mode => 0775)
    @ant.javac(:srcdir => @resource_dir + '/src',  
    :destdir => @output_dir + '/classes',
    :debug => 'on',
    :verbose => 'no',
    :fork => 'no',
    :failonerror => 'yes',
    :includes => 'foo/bar/**',
    :excludes => 'foo/bar/baz/**',
    :classpath => @resource_dir + '/parent.jar')
    
    @ant.property(:name => 'output_dir', :value => @output_dir)
    @ant.property(:name => 'resource_dir', :value =>@resource_dir)
    @ant.java(:classname => 'foo.bar.FooBar', :fork => 'false') {
      arg(:value => 'argOne')
      classpath(){
        pathelement(:location => '${output_dir}/classes')
        pathelement(:location => '${resource_dir}/parent.jar')
      }
      arg(:value => 'argTwo')
      jvmarg(:value => 'client')
      sysproperty(:key=> 'antwrap', :value => 'coolio')
    }
  end
  
  def test_echo_task
#    stream = TestStream.new(java.lang.System.out)
#    
#    @ant = AntProject.new({:name=>"testProject", :basedir=>@current_dir, :declarative=>true, 
#                        :logger=>Logger.new(STDOUT), :loglevel=>Logger::DEBUG, :outputstr => stream})                            
    msg = "Antwrap is running an Echo task"                    
    @ant.echo(:message => msg, :level => 'info')
#    assert(stream.last_line, stream.last_line == msg)
    
    @ant.echo(:pcdata => "<foo&bar>")
  end
  
  def test_mkdir_task
    dir = @output_dir + '/foo'
    
    assert_absent dir
    
    @ant.mkdir(:dir => dir)
    
    assert_exists dir
  end 
  
  def test_mkdir_task_with_property
    dir = @output_dir + '/foo'
    
    assert_absent dir
    
    @ant.property(:name => 'outputProperty', :value => dir)
    @ant.mkdir(:dir => "${outputProperty}")
    
    assert_exists dir
  end 
  
  def test_macrodef_task
    
    return if @ant.ant_version < 1.6
    
    dir = @output_dir + '/foo'
    
    assert_absent dir
    
    @ant.macrodef(:name => 'testmacrodef'){
      attribute(:name => 'destination')
      sequential(){
        echo(:message => "Creating @{destination}")
        _mkdir(:dir => "@{destination}")
      }
    }      
    @ant.testmacrodef(:destination => dir)
    assert_exists dir
  end
  
  def test_cdata
    @ant.echo(:pcdata => "Foobar &amp; <><><>")
  end
  
  def test_ant_contrib

    return if @ant.ant_version < 1.6

    @ant.taskdef(:resource => "net/sf/antcontrib/antlib.xml")

    @ant.property(:name => "bar", :value => "bar")
    @ant._if(){
      _equals(:arg1 => "${bar}", :arg2 => "bar")
      _then(){
        echo(:message => "if 1 is equal")
      }
      _else(){
        echo(:message => "if 1 is not equal")
      }
    }

    @ant.property(:name => "baz", :value => "foo")
    @ant._if(){
      _equals(:arg1 => "${baz}", :arg2 => "bar")
      _then(){
        echo(:message => "if 2 is equal")
      }
      _else(){
        echo(:message => "if 2 is not equal")
      }
    }

  end
  
  private 
  def assert_exists(file_path)
    assert(File.exists?(file_path), "Does not exist[#{file_path}]")
  end
  
  def assert_absent(file_path)
    assert(!File.exists?(file_path), "Should not exist[#{file_path}]")
  end
end
