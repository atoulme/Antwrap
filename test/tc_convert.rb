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
end
