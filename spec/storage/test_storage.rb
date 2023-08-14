# frozen_string_literal: true

require 'minitest/autorun'
require 'rr'
require './lib/storage/storage'

class TestStorage < Minitest::Test
  def setup
    file = {
      id: '1',
      name: 'test',
      url_private_download: 'https://test.com',
    }
    @storage = SlackWormhole::Storage::Storage.new(file)
  end

  def test_initialize
    assert_kind_of SlackWormhole::Storage::Storage, @storage
  end
end
