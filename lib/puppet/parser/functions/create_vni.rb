module Puppet::Parser::Functions
  newfunction(:create_vni, :type => :rvalue) do | args |
    if args.size != 2
      raise Puppet::ParseError, 'create_vni: Only two arguments are accepted'
    elsif args[0].class != Fixnum or args[1].class != Fixnum
      raise Puppet::ParseError, "create_vni: Only integers are accepted - Prefix: #{args[0].class}, Suffix: #{args[1].class}"
    end
    # args[0] = VNI prefix
    # args[1] = VLAN ID
    # return a 7-character integer, with VLAN ID prepended as necessary
    # 1-4096
    max_suffix_count = 4
    prefix = args[0].to_s
    suffix = args[1].to_s

    if suffix.size < max_suffix_count
      char_add = max_suffix_count - suffix.size
      zero_str = ''
      zero_str = zero_str.ljust(char_add, '0')
      return (prefix + zero_str + suffix).to_i
    else
      return (prefix + suffix).to_i
    end
  end
end
