class cisco_datacentre::evpn::spineglobal (
  Integer $bfd_tx_internal      = 150,
  Integer $bfd_minrx_internal   = 150,
  Integer $bfd_multiplier       = 3,
) {
  cisco_bfd_global { 'default' :
    ensure        => present,
    ipv4_interval => [ $bfd_tx_internal, $bfd_minrx_internal, $bfd_multiplier ],
    startup_timer => 0,
  }
}
