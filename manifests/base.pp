class cisco_datacentre::base (
  String $gempath                        = '/root',
  Variant[String,Boolean] $install_repo  = false,
  Variant[String,Boolean] $install_proxy = false,
) {
  # Root user password not initially set, which upsets PAM
  user { 'root' :
    ensure   => present,
    password => 'Password123!',
  }

  if $install_repo and $install_proxy {
    class ciscopuppet::install {
      repo  => $install_repo,
      proxy => $install_proxy,
    }
  }
  elsif $install_repo {
    class ciscopuppet::install {
      repo  => $install_repo,
    }
  }
  elsif $install_proxy {
    class ciscopuppet::install {
      proxy => $install_proxy,
    }
  }
  else {
    include ciscopuppet::install
  }

}
