# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'
require_relative '../../models'
raise "test database doesn't end with test" unless
  DB.opts[:database].match?(/test\z/)

require_relative '../minitest_helper'
