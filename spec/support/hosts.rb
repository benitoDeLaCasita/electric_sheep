module Support
    module Hosts
        
        def new_host
            @hosts ||= ElectricSheeps::Metadata::Hosts.new
            host_id = next_host
            @hosts.add(
                id: host_id,
                name: "#{host_id}.tld"
            )
        end

        private
        def next_host
            @host_counter = @host_counter ? @host_counter + 1 : 1
            "host-#{@host_counter}"
        end
    end
end