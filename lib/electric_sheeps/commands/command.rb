module ElectricSheeps
  module Commands
    module Command
      extend ActiveSupport::Concern

      attr_reader :logger, :shell, :work_dir
      
      def initialize(project, logger, shell, work_dir, metadata)
        @project = project
        @logger = logger
        @shell = shell
        @work_dir = work_dir
        @metadata = metadata
      end
      
      def check_prerequisites
        self.class.prerequisites.each { |prerequisite|
          raise "Missing #{prerequisite} in #{self.class}" unless self.respond_to?(prerequisite)
          self.send prerequisite
        }
      end

      protected
      def done!(resource)
        @project.store_product!(resource)
      end

      def resource
        @project.last_product
      end

      def option(name)
        @metadata.send(name)
      end

      module ClassMethods
        def register(options={})
          ElectricSheeps::Commands::Register.register(self, options)
        end

        def prerequisite(*args)
          @prerequisites = args.dup
        end

        def prerequisites
          @prerequisites ||= []
        end
      end

    end
  end
end
