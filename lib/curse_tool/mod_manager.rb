require_relative 'curse_api'

module CurseTool
  module ModManager
    extend self
    attr_reader :seen_mods
    @seen_mods = {}

    CACHE_LOCATION = './data/mod_cache.yaml'

    def pull_mods(version)
      results = Psych.load(File.open(CACHE_LOCATION)) if File.exist?(CACHE_LOCATION)
      results ||= CurseApi.search_mods(version)
      results.each do |result|
        @seen_mods[result[:slug].to_sym] = result
      end
    end

    def lookup_mod(slug)
      return @seen_mods[slug.to_sym] if @seen_mods[slug.to_sym]
      @seen_mods[slug.to_sym][:id] || warn("No mod found matching #{slug} on CurseForge.  Can try adding id: key to manifest to force find it.")
    end

    def lookup_deps(slug)
      result = @seen_mods[slug.to_sym]
      return false unless result
    end

    def lookup_file(mod_id, mod_version = nil, maturity = MATURITY[:release])
      CurseApi.file(mod_id, mod_version, maturity).find { |it|
        (mod_version.nil? || it['fileName'].include?(mod_version)) && it['releaseType'] == maturity
      }
    end

    def add_mod(mod_info)
      @seen_mods[mod_info[:slug]] = mod_info[:id]
    end

    def dump!
      File.open(CACHE_LOCATION, 'w') { |f| Psych.dump(@seen_mods, f) }
    end

    at_exit do
      dump!
    end

  end
end