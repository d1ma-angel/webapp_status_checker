require 'daemons'
require './production'

Daemons.run('./checker.rb')