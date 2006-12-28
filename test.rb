require 'antwrap.rb'
require 'test/unit'
require 'fileutils'
include Antwrap
class TestAntwrap < Test::Unit::TestCase


  def setup
    @output_dir = ENV['PWD'] + '/output'
    @resource_dir = ENV['PWD'] + '/test-resources'
    if File.exists? @output_dir
      FileUtils.remove_dir(@output_dir)
      FileUtils.mkdir(@output_dir, :mode => 755)
    end
  end
  
  def teardown
  end

  def test_make_set_method
    assert_equal('setFoo', make_set_method('foo'))
    assert_equal('setFoo', make_set_method(:foo))
    assert_equal('setFooBar', make_set_method(:fooBar))
  end
  
  def test_introspect
    result = introspect('foo')
    assert_equal('String', result.class.name)
 
    result = introspect(true)
    assert_equal('TrueClass', result.class.name)
 
    result = introspect('yes')
    assert_equal('TrueClass', result.class.name)

    result = introspect('on')
    assert_equal('TrueClass', result.class.name)
    
    result = introspect('true')
    assert_equal('TrueClass', result.class.name)
 
    result = introspect(false)
    assert_equal('FalseClass', result.class.name)
 
    result = introspect('off')
    assert_equal('FalseClass', result.class.name)
 
    result = introspect('no')
    assert_equal('FalseClass', result.class.name)
 
    result = introspect('false')
    assert_equal('FalseClass', result.class.name)
 
    result = introspect(@output_dir)
    assert_equal('File', result.class.name)
  end
  
  def test_unzip_task
      assert_absent @output_dir + '/foo.zip'
     
      task = unzip(:src => @resource_dir + '/foo.zip',
                   :dest => @output_dir).execute
        
      assert_exists @output_dir + '/jirabrowser'
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
      FileUtils.mkdir(@output_dir + '/classes', :mode => 755)
      
      assert_absent @output_dir + '/classes/foo/bar/FooBar.class'
      
      javac(:srcdir => @resource_dir + '/src', 
            :destdir => @output_dir + '/classes',
            :debug => 'on',
            :verbose => 'yes',
            :fork => 'no',
            :failonerror => 'yes',
            :includes => 'foo/bar/**',
            :excludes => 'foo/bar/baz/**').execute

      assert_exists @output_dir + '/classes/foo/bar/FooBar.class'
      assert_absent @output_dir + '/classes/foo/bar/baz/FooBarBaz.class'
  end

  #  <jar destfile='${dist}/lib/app.jar' basedir='${build}/classes'/>
  def test_jar_task
      assert_absent @output_dir + '/Foo.jar'
      
      jar(:destfile => @output_dir + '/Foo.jar', 
          :basedir => @resource_dir + '/src',
          :level => 9,
          :duplicate => 'preserve').execute

      assert_exists @output_dir + '/Foo.jar'
  end

  private 
  def assert_exists(file_path)
      assert(File.exists?(file_path))
  end

  def assert_absent(file_path)
      assert(!File.exists?(file_path))
  end
end