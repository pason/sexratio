# config.ru
$: << File.expand_path(File.dirname(__FILE__))

require 'gender'
run Sinatra::Application