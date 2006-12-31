require 'antwrap.rb'
require 'test/unit'
require 'fileutils'
require 'java'
include Antwrap
class TestAntwrap < Test::Unit::TestCase


  def setup
#   ENV is broken as of JRuby 0.9.2 but patched in 0.9.3 (see: http://jira.codehaus.org/browse/JRUBY-349)
#   @output_dir = ENV['PWD'] + '/output'
#   @resource_dir = ENV['PWD'] + '/test-resources'
#   The following is a workaround
    current_dir = java.lang.System.getProperty("user.dir")
    @output_dir = current_dir + '/output'
    @resource_dir = current_dir + '/test-resources'
    
    if File.exists?(@output_dir)
      FileUtils.remove_dir(@output_dir)
    end
    FileUtils.mkdir(@output_dir, :mode => 0775)
  end
  
  def teardown
  end

#  def test_make_set_method
#    assert_equal('setFoo', make_set_method('foo'))
#    assert_equal('setFoo', make_set_method(:foo))
#    assert_equal('setFooBar', make_set_method(:fooBar))
#  end
#  
#  def test_introspect
#    result = introspect('foo')
#    assert_equal('String', result.class.name)
# 
#    result = introspect(true)
#    assert_equal('TrueClass', result.class.name)
# 
#    result = introspect('yes')
#    assert_equal('TrueClass', result.class.name)
#
#    result = introspect('on')
#    assert_equal('TrueClass', result.class.name)
#    
#    result = introspect('true')
#    assert_equal('TrueClass', result.class.name)
# 
#    result = introspect(false)
#    assert_equal('FalseClass', result.class.name)
# 
#    result = introspect('off')
#    assert_equal('FalseClass', result.class.name)
# 
#    result = introspect('no')
#    assert_equal('FalseClass', result.class.name)
# 
#    result = introspect('false')
#    assert_equal('FalseClass', result.class.name)
# 
#    result = introspect(@output_dir)
#    assert_equal('Antwrap::JFile', result.class.name)
#  end
  
  def test_unzip_task
      assert_absent @output_dir + '/parent/FooBarParent.class'
     
      task = unzip(:src => @resource_dir + '/parent.jar',
                   :dest => @output_dir).execute
        
      assert_exists @output_dir + '/parent/FooBarParent.class'
  end
  
  def test_copy_task
      assert_absent @output_dir + '/foo.txt'
      
      copy(:file => @resource_dir + '/foo.txt', 
           :todir => @output_dir).execute

      assert_exists @output_dir + '/foo.txt'
  end

  #  <javac srcdir='${src}'
  #         destdir='${build}'
  #         classpath='xyz.jar'
  #         debug='on'
  #         source='1.4'/>
  def test_javac_task
      FileUtils.mkdir(@output_dir + '/classes', :mode => 0775)
      
      assert_absent @output_dir + '/classes/foo/bar/FooBar.class'
      
      javac(:srcdir => @resource_dir + '/src', 
            :destdir => @output_dir + '/classes',
            :debug => 'on',
            :verbose => 'yes',
            :fork => 'no',
            :failonerror => 'yes',
            :includes => 'foo/bar/**',
            :excludes => 'foo/bar/baz/**',
            :classpath => @resource_dir + '/parent.jar').execute

      assert_exists @output_dir + '/classes/foo/bar/FooBar.class'
      assert_absent @output_dir + '/classes/foo/bar/baz/FooBarBaz.class'
  end

  #  <jar destfile='${dist}/lib/app.jar' basedir='${build}/classes'/>
  def test_jar_task
      assert_absent @output_dir + '/Foo.jar'
      
      jar(:destfile => @output_dir + '/Foo.jar', 
          :basedir => @resource_dir + '/src',
          :level => '9',
          :duplicate => 'preserve').execute

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
      javac(:srcdir => @resource_dir + '/src', 
        :destdir => @output_dir + '/classes',
        :debug => 'on',
        :verbose => 'yes',
        :fork => 'no',
        :failonerror => 'yes',
        :includes => 'foo/bar/**',
        :excludes => 'foo/bar/baz/**',
        :classpath => @resource_dir + '/parent.jar').execute
      
      classpath = @output_dir + '/classes:' + @resource_dir + '/parent.jar'
      java_task = jvm(:classname => 'foo.bar.FooBar',
        :classpath => classpath)
#      java_task.createArg().setValue('argOne')     
#      java_task.createArg().setValue('argTwo')     
#      sysProp = AntVariable.new()
#      sysProp.setKey('antwrap')
#      sysProp.setValue('cool')
#      java_task.addSysproperty(sysProp)     
      java_task.execute     
      assert(true)
    end
  
  private 
  def assert_exists(file_path)
      assert(File.exists?(file_path))
  end

  def assert_absent(file_path)
      assert(!File.exists?(file_path))
  end
end
