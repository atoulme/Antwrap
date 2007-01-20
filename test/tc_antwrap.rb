require 'test/unit'
require 'fileutils'
require '../lib/antwrap.rb'

class TestAntwrap < Test::Unit::TestCase
  
  def setup
    @ant = Ant.new(true)
    #   ENV is broken as of JRuby 0.9.2 but patched in 0.9.3 (see: http://jira.codehaus.org/browse/JRUBY-349)
    #   @output_dir = ENV['PWD'] + '/output'
    #   @resource_dir = ENV['PWD'] + '/test-resources'
    #   The following is a workaround
    current_dir = Java::java.lang.System.getProperty("user.dir")
    @output_dir = current_dir + '/test/output'
    @resource_dir = current_dir + '/test/test-resources'
    
    if File.exists?(@output_dir)
      FileUtils.remove_dir(@output_dir)
    end
    FileUtils.mkdir(@output_dir, :mode => 0775)
  end
  
  def teardown
    
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
  
  #  <javac srcdir='${src}'
  #         destdir='${build}'
  #         classpath='xyz.jar'
  #         debug='on'
  #         source='1.4'/>
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
    #    <path id="common.class.path">
    #        <fileset dir="${common.dir}/lib">
    #            <include name="**/*.jar"/>
    #        </fileset>
    #        <pathelement location="${common.classes}"/>
    #    </path>
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
    :verbose => 'no',
    :fork => 'no',
    :failonerror => 'yes',
    :includes => 'foo/bar/**',
    :excludes => 'foo/bar/baz/**',
    :classpathref => 'common.class.path')
    
    assert_exists @output_dir + '/classes/foo/bar/FooBar.class'
    assert_absent @output_dir + '/classes/foo/bar/baz/FooBarBaz.class'
  end
  
  #  <jar destfile='${dist}/lib/app.jar' basedir='${build}/classes'/>
  def test_jar_task
    assert_absent @output_dir + '/Foo.jar'
    @ant.property(:name => 'outputdir', :value => @output_dir)
    @ant.property(:name => 'destfile', :value => '${outputdir}/Foo.jar') 
    @ant.jar( :destfile => "${destfile}", 
    :basedir => @resource_dir + '/src',
    :level => '9',
    :duplicate => 'preserve')
    
    assert_exists @output_dir + '/Foo.jar'
  end
  
  # <java classname="test.Main">
  #    <arg value="-h"/>
  #    <classpath>
  #    <pathelement location="dist/test.jar"/>
  #    <pathelement path="${java.class.path}"/>
  #    </classpath>
  # </java>
  def test_java_task
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
    @ant.java(:classname => 'foo.bar.FooBar', :fork => 'no') {
      arg(:value => 'argOne')
      classpath(){
        pathelement(:location => '${output_dir}/classes')
        pathelement(:location => '${resource_dir}/parent.jar')
      }
      arg(:value => 'argTwo')
      jvmarg(:value => 'server')
      sysproperty(:key=> 'antwrap', :value => 'coolio')
    }
  end
  
  def test_echo_task
    @ant.echo(:message => "Antwrap is running an Echo task", :level => 'info')
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
    dir = @output_dir + '/foo'
    
    assert_absent dir
    
    @ant.macrodef(:name => 'testmacrodef'){
      attribute(:name => 'destination')
      sequential(){
        echo(:message => "Creating @{destination}")
        mkdir(:dir => "@{destination}")
      }
    }
    @ant.testmacrodef(:destination => dir)
    assert_exists dir
    
  end
  
  private 
  def assert_exists(file_path)
    assert(File.exists?(file_path), "Does not exist[#{file_path}]")
  end
  
  def assert_absent(file_path)
    assert(!File.exists?(file_path), "Should not exist[#{file_path}]")
  end
end
