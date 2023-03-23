require "yaml"

module VagrantPlugins
  module HyperVNet
    module Cap
      module Linux
        class NicMacAddresses

            POSSIBLE_ETHERNET_PREFIXES = ["eth".freeze, "en".freeze].freeze

            @@logger = Log4r::Logger.new("vagrant::hypervnet::guest::linux::nic_mac_addresses")    

          def self.nic_mac_addresses(machine)
            s = ""
            machine.communicate.execute("ip -o link | grep -v LOOPBACK | awk '{print $2 \"|\" $17}' | sed 's/://'") do |type, data|
              s << data if type == :stdout
            end

            ifaces = s.split("\n").map { |line|
                parts = line.split("|")
                iface = {}
                iface[:name] = parts[0]                
                iface[:mac_address] = parts[1]
                iface[:parts] = iface[:name].scan(/(.+?)(\d+)?/).flatten.map do |name_part|
                    if name_part.to_i.to_s == name_part
                        name_part.to_i
                    else
                        name_part
                    end
                end 
                iface 
            }

            @@logger.debug("Unsorted list: #{ifaces.inspect}")

            ifaces = ifaces.uniq.sort do |lhs, rhs|
                result = 0
                slice_length = [rhs[:parts].size, lhs[:parts].size].min
                slice_length.times do |idx|
                if(lhs[:parts][idx].is_a?(rhs[:parts][idx].class))
                    result = lhs[:parts][idx] <=> rhs[:parts][idx]
                elsif(lhs[:parts][idx].is_a?(String))
                    result = 1
                else
                    result = -1
                end
                break if result != 0
                end
                result
            end
            @@logger.debug("Sorted list: #{ifaces.inspect}")

            ifaces.each do |iface|
                iface.delete(:parts)
            end

            resorted_ifaces = []
            resorted_ifaces += ifaces.find_all do |iface|
                POSSIBLE_ETHERNET_PREFIXES.any?{|prefix| iface[:name].start_with?(prefix)} &&
                iface[:name].match(/^[a-zA-Z0-9]+$/)
            end
            resorted_ifaces += ifaces - resorted_ifaces
            ifaces = resorted_ifaces
            @@logger.debug("Ethernet preferred sorted list: #{ifaces.inspect}")
            ifaces
          end
        end
      end
    end
  end
end
