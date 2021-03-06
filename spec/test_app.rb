# frozen_string_literal: true

require 'minitest/autorun'
require 'functions_framework/testing'
require 'rr'

# This is a test
class AppTest < Minitest::Test
  include FunctionsFramework::Testing

  def setup
    @data = { 'type' => 'event_callback',
              'event_id' => 'Ev08MFMKH6',
              'event' => {
                'channel' => 'C0HT2PHEZ',
                'item' => {
                  'channel' => 'C0HT2PHEZ',
                  'ts' => '12345678',
                },
                'event_id' => 'Ev08MFMKH6',
                'ts' => '1234567',
                'user' => '' }}
  end

  # type = url_verification
  def test_get_message
    load_temporary 'app.rb' do
      @data['type'] = 'url_verification'
      @data['challenge'] = 'Challenge OK'

      request = make_post_request 'https://example.com/recieve_slack_event',
                                  JSON.dump(@data), ['Content-Type: application/json']

      response = call_http 'recieve_slack_event', request
      assert_equal 'Challenge OK', response.body.join
    end
  end

  # type = message, subtype = nil
  def test_get_message
    load_temporary 'app.rb' do
      @data['event']['type'] = 'message'
      mock(SlackWormhole::EventHandler).message(@data['event']) { 'OK' }

      request = make_post_request 'https://example.com/recieve_slack_event',
                                  JSON.dump(@data), ['Content-Type: application/json']

      response = call_http 'recieve_slack_event', request
      assert_equal 'OK', response.body.join
    end
  end

  # type = message, subtype = nil, data.files != nil
  def test_get_message_with_file
    load_temporary 'app.rb' do
      @data['event']['type'] = 'message'
      @data['event']['files'] = true
      mock(SlackWormhole::EventHandler).post_files(@data['event']) { 'OK' }

      request = make_post_request 'https://example.com/recieve_slack_event',
                                  JSON.dump(@data), ['Content-Type: application/json']

      response = call_http 'recieve_slack_event', request
      assert_equal 200, response.status
      assert_equal '{"type":"message","files":true}', response.body.join
    end
  end

  # type = message, subtype = nil, data.thread_ts != nil
  def test_get_message_with_thread_ts
    load_temporary 'app.rb' do
      @data['event']['type'] = 'message'
      @data['event']['thread_ts'] = '1234567'
      mock(SlackWormhole::EventHandler).post_reply(@data['event']) { 'OK' }

      request = make_post_request 'https://example.com/recieve_slack_event',
                                  JSON.dump(@data), ['Content-Type: application/json']

      response = call_http 'recieve_slack_event', request
      assert_equal 200, response.status
      assert_equal '{"type":"message","thread_ts":true}', response.body.join
    end
  end

  # type = message, subtype = message_changed
  def test_get_message_with_subtype_message_changed
    load_temporary 'app.rb' do
      @data['event']['type'] = 'message'
      @data['event']['subtype'] = 'message_changed'
      mock(SlackWormhole::EventHandler).message_changed(@data['event']) { 'OK' }

      request = make_post_request 'https://example.com/recieve_slack_event',
                                  JSON.dump(@data), ['Content-Type: application/json']

      response = call_http 'recieve_slack_event', request
      assert_equal 200, response.status
      assert_equal '{"type":"message","subtype":"message_changed"}', response.body.join
    end
  end

  # type = message, subtype = message_deleted
  def test_get_message_with_subtype_message_deleted
    load_temporary 'app.rb' do
      @data['event']['type'] = 'message'
      @data['event']['subtype'] = 'message_deleted'
      mock(SlackWormhole::EventHandler).message_deleted(@data['event']) { 'OK' }

      request = make_post_request 'https://example.com/recieve_slack_event',
                                  JSON.dump(@data), ['Content-Type: application/json']

      response = call_http 'recieve_slack_event', request
      assert_equal 200, response.status
      assert_equal '{"type":"message","subtype":"message_deleted"}', response.body.join
    end
  end

  # type = message, subtype = channel_join
  def test_get_message_with_subtype_channel_join
    load_temporary 'app.rb' do
      @data['event']['type'] = 'message'
      @data['event']['subtype'] = 'channel_join'
      mock(SlackWormhole::EventHandler).channel_join(@data['event']) { 'OK' }

      request = make_post_request 'https://example.com/recieve_slack_event',
                                  JSON.dump(@data), ['Content-Type: application/json']

      response = call_http 'recieve_slack_event', request
      assert_equal 200, response.status
      assert_equal '{"type":"message","subtype":"channel_join"}', response.body.join
    end
  end

  # type = message, subtype = channel_leave
  def test_get_message_with_subtype_channel_leave
    load_temporary 'app.rb' do
      @data['event']['type'] = 'message'
      @data['event']['subtype'] = 'channel_leave'
      mock(SlackWormhole::EventHandler).channel_leave(@data['event']) { 'OK' }

      request = make_post_request 'https://example.com/recieve_slack_event',
                                  JSON.dump(@data), ['Content-Type: application/json']

      response = call_http 'recieve_slack_event', request
      assert_equal 200, response.status
      assert_equal '{"type":"message","subtype":"channel_leave"}', response.body.join
    end
  end

  # type = message, subtype = thread_broadcast
  def test_get_message_with_subtype_thread_broadcast
    load_temporary 'app.rb' do
      @data['event']['type'] = 'message'
      @data['event']['subtype'] = 'thread_broadcast'
      mock(SlackWormhole::EventHandler).thread_broadcast(@data['event']) { 'OK' }

      request = make_post_request 'https://example.com/recieve_slack_event',
                                  JSON.dump(@data), ['Content-Type: application/json']

      response = call_http 'recieve_slack_event', request
      assert_equal 200, response.status
      assert_equal '{"type":"message","subtype":"thread_broadcast"}', response.body.join
    end
  end

  # type = message, subtype = bot_message
  def test_get_message_with_subtype_bot_message
    load_temporary 'app.rb' do
      @data['event']['type'] = 'message'
      @data['event']['subtype'] = 'bot_message'
      mock(SlackWormhole::EventHandler).bot_message(@data['event']) { 'SKIP' }

      request = make_post_request 'https://example.com/recieve_slack_event',
                                  JSON.dump(@data), ['Content-Type: application/json']

      response = call_http 'recieve_slack_event', request
      assert_equal 200, response.status
      assert_equal '{"type":"message","subtype":"bot_message"}', response.body.join
    end
  end

  # type = message, subtype = file_share
  def test_get_message_with_subtype_bot_message
    load_temporary 'app.rb' do
      @data['event']['type'] = 'message'
      @data['event']['subtype'] = 'file_share'
      mock(SlackWormhole::EventHandler).file_share(@data['event']) { 'SKIP' }

      request = make_post_request 'https://example.com/recieve_slack_event',
                                  JSON.dump(@data), ['Content-Type: application/json']

      response = call_http 'recieve_slack_event', request
      assert_equal 200, response.status
      assert_equal '{"type":"message","subtype":"file_share"}', response.body.join
    end
  end

  # type = reaction_added
  def test_reaction_added
    load_temporary 'app.rb' do
      @data['event']['type'] = 'reaction_added'
      mock(SlackWormhole::EventHandler).reaction_added(@data['event']) { 'OK' }

      request = make_post_request 'https://example.com/recieve_slack_event',
                                  JSON.dump(@data), ['Content-Type: application/json']

      response = call_http 'recieve_slack_event', request
      # assert_equal 200, response.status
      assert_equal 'OK', response.body.join
    end
  end

  # type = reaction_removed
  def test_reaction_removed
    load_temporary 'app.rb' do
      @data['event']['type'] = 'reaction_removed'
      mock(SlackWormhole::EventHandler).reaction_removed(@data['event']) { 'OK' }

      request = make_post_request 'https://example.com/recieve_slack_event',
                                  JSON.dump(@data), ['Content-Type: application/json']

      response = call_http 'recieve_slack_event', request
      # assert_equal 200, response.status
      assert_equal 'OK', response.body.join
    end
  end
end
