require "google/api_client"
require 'xmlsimple'

require_relative 'children'
require_relative 'spreadsheet'

module Sheety

  private

  class Api
    include Sheety::Children

    URI_LIST = 'https://spreadsheets.google.com/feeds/spreadsheets/private/full'
    URI_AUTH = 'https://www.googleapis.com/oauth2/v3/token'

    def link(key) # for compat with ChildBearing
      return key
    end

    atom_children :sheets, klass: Sheety::Spreadsheet, link: URI_LIST

    def self.inst
      if @@instance.nil?
        @@instance = Sheety::Api.new
      end
      return @@instance
    end

    def auth(force=false)
      if @access_token.blank? || force
        data = { :grant_type => 'urn:ietf:params:oauth:grant-type:jwt-bearer', :assertion => @auth.to_jwt.to_s }
        resp = HTTParty.post(URI_AUTH, { :body => data })
        if Net::HTTPOK === resp.response
          @access_token = resp['access_token']
        end
      end

      return (@access_token ? self : nil)
    end

    # block so you can have the max retries set only for a small amount of code
    def with_max_retries(num, &block)
      raise ArgumentError.new, "Must pass a block!" unless block_given?

      previous_max = @max_retries
      @max_retries = num.to_i
      yield
      @max_retries = previous_max
    end

    attr_accessor :max_read_retries

    def with_max_read_retries(num)
      if block_given?
        previous_max = @max_read_retries
        @max_read_retries = num.to_i
        yield
        @max_read_retries = previous_max
      else
        @max_read_retries = num.to_i
      end
    end
    alias_method :set_max_read_retries, :with_max_read_retries

    def get_feed(uri)
      tries = 0
      begin
        return parse_response(HTTParty.get(uri, headers: get_headers))
      rescue
        if tries < [@max_retries, @max_read_retries].max
          tries += 1
          retry
        end

        return nil
      end
    end

    def post_feed(uri, data)
      tries = 0
      begin
        return parse_response(HTTParty.post(uri, body: data, headers: post_headers))
      rescue
        if tries < @max_retries
          tries += 1
          retry
        end

        return nil
      end
    end

    def put_feed(uri, data)
      tries = 0
      begin
        return parse_response(HTTParty.put(uri, body: data, headers: put_headers))
      rescue
        if tries < @max_retries
          tries += 1
          retry
        end

        return nil
      end
    end

    def delete_feed(uri)
      tries = 0
      begin
        return parse_response(HTTParty.delete(uri, headers: delete_headers))
      rescue
        if tries < @max_retries
          tries += 1
          retry
        end

        return nil
      end
    end

    private

    def parse_response(resp)
      begin
        return XmlSimple.xml_in(resp.body, { 'KeyAttr' => 'name', 'keepnamespace' => true })
      rescue
        return resp
      end
    end

    def get_headers
      return auth_headers
    end

    def post_headers
      return put_headers
    end

    def put_headers
      return auth_headers.merge('Content-Type' => 'application/atom+xml')
    end

    def delete_headers
      return auth_headers
    end

    def auth_headers
      return { 'Authorization' => "Bearer #{@access_token}" }
    end

    @@instance = nil

    def initialize
      @client = Google::APIClient.new(:application_name => 'Sheety', :application_version => "0.1.0")
      @client.authorization= :google_app_default
      @auth = @client.authorization
      @auth.scope = 'https://spreadsheets.google.com/feeds'
      @max_retries = 0
      @max_read_retries = 0

      return self
    end
  end
end
