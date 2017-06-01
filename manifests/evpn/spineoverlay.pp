# Spine overlay routing. Only route reflecting is required (no VTEPs on spines)
class cisco_datacentre::evpn::spineoverlay (
  String $bgp_asn,
  String $loopback0_ip,
  Hash $leaf_bgp_peers,
  String $bgp_md5_password = '3GP@ssw0rd',
) {

  cisco_bgp { "${bgp_asn} default":
    ensure               => present,
    router_id            => $loopback0_ip,
    log_neighbor_changes => true,
  }
  $leaf_bgp_peers.each |String $bgp_peer_ip, String $bgp_peer_name| {
    cisco_bgp_neighbor { "${bgp_asn} default ${bgp_peer_ip}":
      ensure        => present,
      description   => $bgp_peer_name,
      bfd           => true,
      remote_as     => $bgp_asn,
      update_source => 'loopback0',
      password      => $bgp_md5_password,
      password_type => '3des',
    }
    cisco_bgp_neighbor_af { "${bgp_asn} default ${bgp_peer_ip} l2vpn evpn":
      ensure                  => present,
      send_community          => 'extended',
      route_reflector_client  => true,
      soft_reconfiguration_in => 'always',
    }
  }
}
