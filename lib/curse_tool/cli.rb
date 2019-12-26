module CurseTool
  class CLI
    class << self
      def build(manifest_file)
        manifest = build_manifest(manifest_file)
        pack = NixPack.new(**manifest)
        ModManager.pull_mods(pack.version)
        pack.mods.keep_if{|key, _| ModManager.seen_mods.keys.include? key}
        pack.mods.each do |mod_name, mod_info|
          mod_info.deps = ModManager.lookup_deps(mod_name) if mod_info.deps.empty?
          mod_info.deps ||= []
        end
        deps = pack.mods.flat_map{|key, it| it.deps}.uniq
        deps.delete_if(&:nil?)
        deps = deps.each_with_object({}) do |dep, hash|
          hash[dep.to_sym] = NixPackMod.new({name: dep.to_sym})
        end
        pack.mod_list = deps.merge(pack.mods)
        pack.mod_list.each do |mod_name, mod_info|
          mod_info.id ||= ModManager.lookup_mod(mod_name)
          mod_info.src, mod_info.filename, mod_info.md5 = ModManager.lookup_files
        end

      end

      def build_manifest(manifest_file)
        manifest = ManifestParser.new.parse(manifest_file)
        root_dir = manifest_file.split('/')[0..-2].join('/')
        imports = handle_imports(manifest[:imports], root_dir)
        duplicate_mods = manifest[:mods].map{|it| it[:name]} & imports.map{|it| it[:name]}
        warn "duplicate mods found #{duplicate_mods.map{|it| it}}, the highest import entry will be used" if duplicate_mods.any?
        manifest_mods = manifest[:mods] | imports
        manifest[:mods] = manifest_mods.uniq{|entry| entry[:name]}
        manifest
      end

      def handle_imports(imports, root_dir)
        imports.flat_map do |file|
          inner_manifest = ManifestParser.new.parse("#{root_dir}/#{file}")
          inner_imports = inner_manifest[:imports]
          inner_mods = inner_manifest[:mods]
          inner_imports = inner_imports.flat_map { |inner_file| handle_imports(inner_file)}
          duplicate_mods = inner_mods.map{|it| it[:name]} & inner_imports.map{|it| it[:name]}
          warn "duplicate mods found #{duplicate_mods.map{|it| it[:name]}} the highest import entry will be used" if duplicate_mods.any?
          inner_mods | inner_imports
        end
      end

    end
  end
end