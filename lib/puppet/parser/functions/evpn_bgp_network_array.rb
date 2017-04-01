module Puppet::Parser::Functions
  newfunction(:evpn_bgp_network_array, :type => :rvalue) do | args |
    if args.size != 1
      raise Puppet::ParseError, 'evpn_bgp_network_array: only one array is accepted as an argument'
    elsif args[0].class != Array
      raise Puppet::ParseError, 'evpn_bgp_network_array: only an array is accepted as an argument'
    end

    formatted_array = Array.new

    args[0].each do | item |
      formatted_array << Array.new([item])
    end
    return formatted_array
  end
end
