require 'set'
require 'digest/sha2'
require 'open-uri'

module CurseTool
  MATURITY = [nil, :release, :beta, :alpha].freeze
  SIDE = [:server, :pool, :both]

  class NixPack
    attr_accessor :version, :imports, :mod_list
    def initialize(**hash)
      self.version = hash[:version]
      self.imports = hash[:imports]
      self.mod_list = NixPackModList.new(self, hash[:mods])
    end

    def mods
      @mod_list.mods
    end

    def dump
      {
          version: version,
          imports: imports,
          mod_list: mods.dump
      }
    end
  end

  class NixPackModList
    attr_accessor :mods
    def initialize(pack, array)
      self.mods = array.each_with_object(Hash.new){ |mod, hash|
        hash[mod[:name].to_sym] = NixPackMod.new(pack, mod)
      }
    end
  end

  class NixPackMod
    attr_accessor :title, :name, :id, :side, :required, :default, :deps, :filename, :encoded, :page, :src, :type, :sha256, :pack, :maturity, :md5
    def initialize(pack, **hash)
      self.pack = pack
      self.title = hash[:title]
      self.name = hash[:name]&.to_sym
      self.id = hash[:id]
      self.side = hash[:side]&.to_sym || SIDE[2]
      self.required = hash[:required] || true
      self.default = hash[:default] || true
      self.deps = hash[:deps] || []
      self.filename = hash[:filename]
      self.encoded = hash[:encoded]
      self.page = hash[:page]
      self.src = hash[:src]
      self.type = hash[:type] || 'remote'
      self.md5 = hash[:md5]
      self.sha256 = hash[:sha256]
      self.maturity = MATURITY.index(hash[:maturity]&.to_sym || :release)
    end

    def from_curse(hash)
      self.title = hash[:name]
      self.name = hash[:slug]
      self.id = hash[:id]
      self
    end

    def populate_file
      return if !id || (filename && src)
      files = CurseApi.files(id)
      filename ? by_filename(files) : by_maturity(files)
      # TODO Calculating sha hashes makes s3 angry since i have to download a bunch of files so i'll need some form of throttling.
      # Bigger issue here is that this will also apply to regular downloads on madoka...
      begin
        self.sha256 = Digest::SHA2.new(256).update(open(src, &:read)) unless md5 || src.nil?
      rescue OpenURI::HTTPError => e
        warn "Failed to caculate hash on #{self.name} due to s3 temp ban."
      end
      self
    end

    def by_maturity(files)
      file = files.reverse.find{|it| it[:releaseType] == maturity && it[:gameVersion].include?(pack.version) }
      file ||= files.reverse.find{|it| it[:releaseType] == maturity + 1 && it[:gameVersion].include?(pack.version) }
      file ||= files.reverse.find{|it| it[:releaseType] == maturity + 2 && it[:gameVersion].include?(pack.version) }
      return warn("no file found for #{name} in any maturity for #{pack.version}") unless file
      self.filename = file[:fileName]
      self.src = CGI.escape(file[:downloadUrl]).gsub('%3A', ':').gsub('%2F', '/')
    end

    def by_filename(files)
      file = files.find{|it| it[:fileName] == filename}
      self.src = CGI.escape(file[:downloadUrl]).gsub('%3A', ':').gsub('%2F', '/')
    end

    def dump
      hash = {
          title: title,
          name: name,
          id: id,
          side: side,
          required: required,
          default: default,
          deps: deps,
          filename: filename,
          encoded: encoded,
          page: page,
          src: src,
          type: type
      }
      hash[:md5] = md5 if md5
      hash[:sha256] = sha256 if sha256
      hash
    end
  end

end