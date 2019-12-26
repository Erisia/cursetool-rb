require 'net/http'
require 'connection_pool'
require 'json'

module CurseTool
  class CurseApi
    @pool = ConnectionPool.new(size: 20) { Net::HTTP }
    @base_uri = 'https://addons-ecs.forgesvc.net/api/v2'
    @seen_mods = {}

    class << self
      def search_mods(version)
        uri = URI(@base_uri + '/addon/search')
        params = {
          gameId: 432, # minecraft
          gameVersion: version,
          sort: 3, # Relevance
          sectionId: 6, # minecraft mods
          pageSize: 10000
        }
        uri.query = URI.encode_www_form(params)
        JSON.parse(with_pool { |client| client.get_response(uri) }.body, symbolize_names: true)
      end

      def get_mods(id_array)

      end

      def file(mod_id)
        uri = URI(@base_uri + "/addon/#{mod_id}/files")
        response = with_pool { |client| client.get_response(uri) }
        JSON.parse(response.body, symbolize_names: true)
      end

      def with_pool
        result = nil
        @pool.with { |client| result = yield(client) }
        result
      end
    end
  end
end

# CurseTool::CurseApi.search_mods('applied-energistics-2')
