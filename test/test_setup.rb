require 'pathname'
require 'minitest/autorun'

$LOAD_PATH.unshift Pathname(__FILE__).dirname.parent.join('lib').to_s
