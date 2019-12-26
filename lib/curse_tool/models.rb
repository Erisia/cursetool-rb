require 'set'
module CurseTool
  MATURITY = {release: 1, beta: 2, alpha: 3}.freeze
  SIDE = [:server, :pool, :both]

  class NixPack
    attr_accessor :version, :imports, :mod_list
    def initialize(**hash)
      self.version = hash[:version]
      self.imports = hash[:imports]
      self.mod_list = NixPackModList.new(hash[:mods])
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
    def initialize(array)
      self.mods = array.each_with_object(Hash.new){ |mod, hash|
        hash[mod[:name].to_sym] = NixPackMod.new(mod)
      }
    end
  end

  class NixPackMod
    attr_accessor :title, :name, :id, :side, :required, :default, :deps, :filename, :encoded, :page, :src, :type, :md5
    def initialize(**hash)
      self.title = hash[:name]
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
    end

    def dump
      {
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
          type: type,
          md5: md5
      }
    end
  end

end