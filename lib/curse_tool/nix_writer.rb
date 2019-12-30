module CurseTool
  module NixWriter
    class << self
      def dump(object)
        file = File.open('bloof.nix', 'w')
        object.dump(file)
      end
    end
  end
end