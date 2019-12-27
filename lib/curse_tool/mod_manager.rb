require_relative 'curse_api'

module CurseTool
  module ModManager
    extend self
    attr_reader :seen_mods
    @seen_mods = {}
    @seen_files = []

    CACHE_LOCATION = './data/mod_cache.yaml'

    def pull_mods(version)
      @seen_mods = Psych.load(File.open(CACHE_LOCATION)) if File.exist?(CACHE_LOCATION)
      results = CurseApi.search_mods(version) if !@seen_mods || @seen_mods.empty?
      results ||= []
      results.each do |result|
        @seen_mods[result[:slug].to_sym] = result
      end
    end

    def expand_info(mod_info)
      mod_hash = lookup_mod(mod_info) unless full_mod_def?(mod_info)
      mod_info.from_curse(mod_hash) if mod_hash
      mod_info.populate_file
      @seen_files << {sha256: mod_info.sha256, file: mod_info.src}
    end

    def full_mod_def?(mod_info)
      mod_info.title && mod_info.id && mod_info.filename &&
        mod_info.src && (mod_info.md5 || mod_info.sha256)
    end

    def lookup_mod(mod_info)
      slug = mod_info.name
      return @seen_mods[slug.to_sym] if @seen_mods[slug.to_sym]
      return @seen_mods.values.find{|it| it[:id] == mod_info.id}
      warn("No mod found matching #{slug} on CurseForge.  Can try adding id: key to manifest to force find it.")
    end

    def lookup_deps(slug)
      result = @seen_mods[slug.to_sym]
      return false unless result
    end

    def lookup_file(mod_info, mod_version = nil, maturity = MATURITY[:release])
      if mod_version
        CurseApi.file(mod_id, mod_version, maturity).find { |it|
          (mod_version.nil? || it['fileName'].include?(mod_version)) && it['releaseType'] == maturity
        }
      else
        @seen_mods[mod_name]
      end
    end

    def add_mod(mod_info)
      @seen_mods[mod_info[:slug]] = mod_info
    end

    def dump!
      File.open(CACHE_LOCATION, 'w') { |f| Psych.dump(@seen_mods, f) }
    end

    at_exit do
      dump!
    end

  end
end