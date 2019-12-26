module CurseTool
  module NixWriter
    class << self
      def dump(object)
        hash = object.dump
      end
    end
  end
end