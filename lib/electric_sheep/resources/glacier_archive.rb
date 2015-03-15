module ElectricSheep
  module Resources
    class GlacierArchive < Resource
      include Extended

      option :id, required: true
      option :vault, required: true
      option :description

      def initialize(opts={})
        if path=opts.delete(:path)
          opts.merge!(normalize_path(path))
        end
        super
      end

      def local?
        false
      end

      def to_location
        Metadata::Pipe::Location.new(
          id, vault, :aws_archive
        )
      end

    end
  end
end
