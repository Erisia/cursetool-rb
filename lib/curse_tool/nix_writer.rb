module CurseTool
  module NixWriter
    class << self
      def dump(object, file_name)
        file = File.open(file_name, 'w')
        object.dump(file)
      end
    end
  end
end