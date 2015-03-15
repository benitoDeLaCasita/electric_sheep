require 'fog'

module ElectricSheep
  module Transports
    class Glacier
      include Transport
      include Aws

      register as: "glacier"

      option :vault_id, required: true
      option :description

      def remote_interactor
        @remote_interactor ||= S3Interactor.new(
          option(:access_key_id),
          option(:secret_key),
          option(:vault_id),
          option(:description),
        )
      end

      def remote_resource
        Resources::AwsGlacierArchive.new({
          id: option(:to),
          description: option(description),
        }).tap do |resource|
          resource.timestamp!(input)
        end
      end

      def local_resource
        file_resource host('localhost')
      end

      protected

      class S3Interactor
        include Helpers::Aws

        def initialize(access_key_id, secret_key, vault_id, description)
          @access_key_id = access_key_id
          @secret_key = secret_key
          @vault_id = vault_id
          @description = description
        end

        def in_session(&block)
          # Glacier is stateless
          yield
        end

        # TODO
        # def download!(from, to, local)
        #   path = local.expand_path(to.path)
        #   # TODO Handle large files ?
        #   File.open(path, "w") do |f|
        #     file = remote_file(from) do |chunk, remaining, total|
        #       f.write(chunk)
        #     end
        #   end
        # end

        def upload!(from, to, local)
          options = upload_options(local_file).merge(
            body: local_file
          )
          vault.archives.create(options)
        end

        # TODO
        # def delete!(resource)
        #   remote_file(resource).destroy
        # end

        def stat(resource)
          # TODO find a way to get file stat interactivly
          local_file_size
        end

        private
        def connection
          @connection ||= Fog::AWS::Glacier.new conn_options
        end

        def conn_options
          {
            provider: 'AWS',
            aws_access_key_id: @access_key_id,
            aws_secret_access_key: @secret_key,
            region: @region,
          }
        end

        def local_file
          @local_file ||= File.new( local.expand_path(from.path) )
        end

        def local_file_size
          local_file.size
        end

        def vault
          @vault ||= connection.vaults.get(@vault_id) || create_vault
        end

        def create_vault
          connection.vaults.create(id: @vault_id)
        end

        def upload_options(file)
          {}.tap do |opts|
            chunk = multipart_chunk_size(file)
            opts[:multipart_chunk_size]=chunk if chunk
            opts[:description] = description if description
          end
        end

      end

    end
  end
end
