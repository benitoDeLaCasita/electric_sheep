module ElectricSheep
  module Transports
    module Aws
      extend ActiveSupport::Concern

      DEFAULT_REGION='us-east-1'
      
      included do
        option :access_key_id, required: true
        option :secret_key, required: true, secret: true
        option :region

      end
    end

    module Helpers
      module Aws
        def multipart_chunk_size(file)
          if file.size > 10.megabytes
            # Try to use small chunks to reduce memory consumption
            chunk=[5, 10, 20, 30, 40, 50, 100, 200, 300, 500].find do |size|
              # S3 and Glacier hard-limit: 10000 chunks
              size.megabytes * 10000 >= file.size
            end
            chunk.megabytes
          end
        end
      end
    end
  end
end
