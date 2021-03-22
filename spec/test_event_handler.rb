# frozen_string_literal: true

require 'minitest/autorun'
require 'rr'
require './lib/event_handler'

class TestEventHandler < MiniTest::Unit::TestCase
  def setup
    @data = { 'channel' => 'C0HT2PHEZ',
              'item' => {
                  'channel' => 'C0HT2PHEZ',
                  'ts' => '12345678',
              },
              'message' => {
                'ts' => '23456789',
                'text' => 'test'
              },
              'ts' => '1234567',
              'user' => '' }
  end

  def test_message_changed
  end
end
