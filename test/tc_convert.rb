# antwrap
#
# Copyright Caleb Powell 2007
#
# Licensed under the LGPL, see the file COPYING in the distribution
#
require 'test/unit'
require 'fileutils'
require 'java'
require '../lib/convert.rb'

class TestConvert < Test::Unit::TestCase
  
  def test_create_symbol
    assert_equal(':upload_jar_OHQ', create_symbol('upload-jar-OHQ'))
    assert_equal(':upload_jar_OHQ', create_symbol('upload.jar.OHQ'))
    assert_equal(':upload_jar_OHQ, :aprop_bar', create_symbol('upload.jar.OHQ, aprop-bar'))
  end
  
    
  def test_replace_properties
    result = replace_properties("${aprop}", {'aprop' => 'bar'})
    assert_equal('bar', result)
    result = replace_properties("${aprop}/adir", {'aprop' => 'bar'})
    assert_equal('bar/adir', result)
    result = replace_properties("${aprop}/${aprop}", {'aprop' => 'bar'})
    assert_equal('bar/bar', result)
    result = replace_properties("${unrelated}", {'aprop' => 'bar'})
    assert_equal('${unrelated}', result)
    result = replace_properties("${common.dir}/classes", {'common.dir' => 'bar'})
    assert_equal('bar/classes', result)
  end
  
end
