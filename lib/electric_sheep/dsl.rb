module ElectricSheep
  class Dsl

    module RaiseOnMethodMissing
      def method_missing(method, *args, &block)
        raise SheepException, "Unknown command '#{method}' in Sheepfile"
      end
    end

    include RaiseOnMethodMissing

    attr_reader :config

    def initialize(config)
      @config = config
    end

    def host(id, options={})
      @config.hosts.add id, options
    end

    def project(id, options={}, &block)
      @config.add ProjectDsl.new( @config, id, options, &block ).project
    end

    def working_directory(dir)
      @config.hosts.localhost.working_directory=dir
    end

    class AbstractDsl

      include RaiseOnMethodMissing

      class << self
        def returning(property)
          define_method property do
            @subject
          end
        end
      end

      def initialize(*args, &block)
        @config = args.first
        build *args
        instance_eval &block if block_given?
      end

      def encrypted(value)
        Metadata::Encrypted.new(value)
      end

    end

    class ProjectDsl < AbstractDsl

      returning :project

      def build(config, id, options, &block)
        @subject = Metadata::Project.new(options.merge(id: id))
      end

      def remotely(options, &block)
        @subject.add RemoteShellDsl.new( @config, options, &block).shell
      end

      def locally(&block)
        @subject.add ShellDsl.new(@config, &block).shell
      end

      def copy(options)
        transport(:copy, options)
      end

      def move(options)
        transport(:move, options)
      end

      def resource(type, options={})
        options[:host] = @config.hosts.get(options[:host])
        begin
          resource_klass = Resources.const_get(type.to_s.camelize)
        rescue
          raise SheepException, "Resource '#{type.to_s}' in Sheepfile is undefined"
        end
        @subject.start_with! resource_klass.new(options)
      end

      def private_key(path)
        @subject.use_private_key! File.expand_path(path)
      end

      private
      def transport(type, options)
        options[:transport]=options.delete(:using)
        options[:to] = options[:to]
        @subject.add Metadata::Transport.new(options.merge(type: type))
      end
    end

    class ShellDsl < AbstractDsl

      returning :shell

      def build(config, options={}, &block)
        @subject = new_shell(options)
      end

      def method_missing(method, *args, &block)
        if Agents::Register.command(method)
          opts = {type: method}.merge(args.first || {})
          @subject.add Metadata::Command.new(opts)
        else
          super
        end
      end

      protected
      def new_shell(options)
        Metadata::Shell.new
      end
    end

    class RemoteShellDsl < ShellDsl
      protected
      def new_shell(options)
        opts = {user: options[:as] }
        Metadata::RemoteShell.new(opts)
      end
    end

  end
end
