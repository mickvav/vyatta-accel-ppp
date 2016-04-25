package Vyatta::AccelPPPConfig;

use strict;
use lib "/opt/vyatta/share/perl5";
use Vyatta::Config;
use Vyatta::Misc;
use NetAddr::IP;

my $cfg_delim_begin = '### Vyatta Accel PPPoE Begin ###';
my $cfg_delim_end = '### Vyatta Accel PPPoE End ###';

# GLOBAL
# PPPOE
# PPP OPTIONS
my $accelcmd="/usr/bin/accel_cmd";
my %fields = (
	_global_dns1			=> undef,
	_global_dns2			=> undef,
	_global_wins1			=> undef,
	_global_wins2			=> undef,
	_ip_pool			=> undef,
	_ip_pool_gw_ip_addr		=> undef,
	_ip_pool_gw			=> undef,
	_ip_pool_tunnel			=> undef,
	_log				=> undef,
	_log_file			=> undef,
	_log_emerg			=> undef,
	_log_fail			=> undef,
	_log_level			=> undef,
	_log_copy			=> undef,
	_log_per_sess_dir		=> undef,
	_log_per_user_dir		=> undef,
	_log_per_sess			=> undef,
	_pppoe				=> undef,
	_pppoe_ac			=> undef,
	_pppoe_called_sid               => undef,
	_pppoe_ifname_in_sid		=> undef,
	_pppoe_intfs			=> [],
	_pppoe_ip_pool			=> undef,
	_pppoe_mac_filter		=> undef,
	_pppoe_mppe			=> undef,
	_pppoe_pado_delay		=> undef,
	_pppoe_service			=> undef,
	_pppoe_tr101			=> undef,
	_pppoe_verbose			=> undef,
	_ppp_ccp			=> undef,
	_ppp_check_ip			=> undef,
	_ppp_ipv4			=> undef,
	_ppp_ipv6			=> undef,
	_ppp_ipv6_accept_peer_intf_id	=> undef,
	_ppp_ipv6_intf_id		=> undef,
	_ppp_ipv6_peer_intf_id		=> undef,
	_ppp_lcp_echo_failure		=> undef,
	_ppp_lcp_echo_interval		=> undef,
	_ppp_lcp_echo_timeout		=> undef,
	_ppp_min_mtu			=> undef,
	_ppp_ppp_mppe			=> undef,
	_ppp_mtu			=> undef,
	_ppp_sid_case			=> undef,
	_ppp_single_session		=> undef,
	_ppp_unit_cache			=> undef,
	_ppp_verbose			=> undef,
	_radius				=> undef,
	_radius_acct_delay_time		=> undef,
	_radius_acct_interim_interval	=> undef,
	_radius_acct_on			=> undef,
	_radius_acct_timeout		=> undef,
	_radius_dae_server		=> undef,
	_radius_default_realm		=> undef,
	_radius_dm_coa_secret		=> undef,
	_radius_gw_ip_address		=> undef,
	_radius_interim_verbose		=> undef,
	_radius_max_try			=> undef,
	_radius_nas_identifier		=> undef,
	_radius_nas_ip_address		=> undef,
	_radius_servers			=> [],
	_radius_timeout			=> undef,
	_radius_verbose			=> undef,
	_shaper				=> undef,
	_shaper_vendor			=> undef,
	_shaper_attr			=> undef,
	_shaper_enabled			=> undef,
	_shaper_attr_down		=> undef,
	_shaper_attr_up			=> undef,
	_shaper_burst_factor		=> undef,
	_shaper_down_burst_factor	=> undef,
	_shaper_up_burst_factor		=> undef,
	_shaper_latency			=> undef,
	_shaper_mpu			=> undef,
	_shaper_mtu			=> undef,
	_shaper_r2q			=> undef,
	_shaper_quantum			=> undef,
	_shaper_up_limiter		=> undef,
	_shaper_down_limiter		=> undef,
	_shaper_leaf_qdisc		=> undef,
	_shaper_rate_multiplier		=> undef,
	_shaper_time_range		=> undef,
	_shaper_verbose			=> undef,
	_is_empty			=> 1,
);

#my %ppp-options = (
#);

sub new {
    my $that = shift;
    my $class = ref ($that) || $that;
    my $self = {
        %fields,
    };
    
    bless $self, $class;
    return $self;
}

sub setup_base {
	my ($self, $listNodes_func, $val_func, $vals_func, $exists_func) = @_;

	my $config = new Vyatta::Config;
	$config->setLevel('service accel-ppp');
	my @nodes = $config->$listNodes_func();
	if (scalar(@nodes) <= 0) {
		$self->{_is_empty} = 1;
		return 0;
	} else {
		$self->{_is_empty} = 0;
	}

	# Global options
	$self->{_global_dns1} = $config->$val_func('dns-servers server-1');
	$self->{_global_dns2} = $config->$val_func('dns-servers server-2');

	$self->{_global_wins1} = $config->$val_func('wins-servers server-1');
	$self->{_global_wins2} = $config->$val_func('wins-servers server-2');

	# PPPoE server
	if (defined($config->$vals_func('pppoe'))) {
		$self->{_pppoe}			= 1;
		$self->{_pppoe_ac}		= $config->$val_func('pppoe access-concentrator');
		$self->{_pppoe_called_sid}   	= $config->$val_func('pppoe called-sid');
		$self->{_pppoe_ifname_in_sid}	= $config->$val_func('pppoe ifname-in-sid');
		$self->{_pppoe_ip_pool}		= $config->$val_func('pppoe ip-pool');
		$self->{_pppoe_mac_filter}	= $config->$val_func('pppoe mac-filter');
		$self->{_pppoe_mppe}		= $config->$val_func('pppoe mppe');
		$self->{_pppoe_pado_delay}	= $config->$val_func('pppoe pado-delay');
		$self->{_pppoe_service}		= $config->$val_func('pppoe service-name');
		$self->{_pppoe_tr101}		= $config->$val_func('pppoe tr101');
		$self->{_pppoe_verbose}		= $config->$val_func('pppoe verbose');

		my @intfs = $config->$listNodes_func('pppoe interface');
		foreach my $intf (@intfs) {
			$self->{_pppoe_intfs} = [ @{$self->{_pppoe_intfs}}, $intf];
		}
	}

	$self->{_ppp_ccp}			= $config->$val_func('ppp-options ccp');
	$self->{_ppp_check_ip}			= $config->$val_func('ppp-options check-ip');
	$self->{_ppp_ipv4}			= $config->$val_func('ppp-options ipv4');
	$self->{_ppp_ipv6}			= $config->$val_func('ppp-options ipv6');
	$self->{_ppp_ipv6_accept_peer_intf_id}	= $config->$val_func('ppp-options ipv6-accept-peer-intf-id');
	$self->{_ppp_ipv6_intf_id}		= $config->$val_func('ppp-options ipv6-intf-id');
	$self->{_ppp_ipv6_peer_intf_id}		= $config->$val_func('ppp-options ipv6-peer-intf-id');
	$self->{_ppp_lcp_echo_failure}		= $config->$val_func('ppp-options lcp-echo-failure');
	$self->{_ppp_lcp_echo_interval}		= $config->$val_func('ppp-options lcp-echo-interval');
	$self->{_ppp_lcp_echo_timeout}		= $config->$val_func('ppp-options lcp-echo-timeout');
	$self->{_ppp_min_mtu}			= $config->$val_func('ppp-options min-mtu');
	$self->{_ppp_ppp_mppe}			= $config->$val_func('ppp-options mppe');
	$self->{_ppp_mtu}			= $config->$val_func('ppp-options mtu');
	$self->{_ppp_sid_case}			= $config->$val_func('ppp-options sid-case');
	$self->{_ppp_single_session}		= $config->$val_func('ppp-options single-session');
	$self->{_ppp_unit_cache}		= $config->$val_func('ppp-options unit-cache');
	$self->{_ppp_verbose}			= $config->$val_func('ppp-options verbose');

	if (defined($config->$vals_func('radius server'))) {
		$self->{_radius}			= 1;
		$self->{_radius_acct_delay_time}	= $config->$val_func('radius acct-delay-time');
		$self->{_radius_acct_interim_interval}	= $config->$val_func('radius acct-interim-interval');
		$self->{_radius_acct_on}		= $config->$val_func('radius acct-on');
		$self->{_radius_acct_timeout}		= $config->$val_func('radius acct-timeout');
		$self->{_radius_dae_server}		= $config->$val_func('radius dae-server');
		$self->{_radius_default_realm}		= $config->$val_func('radius default-realm');
		$self->{_radius_dm_coa_secret}		= $config->$val_func('radius dm_coa_secret');
		$self->{_radius_gw_ip_address}		= $config->$val_func('radius gw-ip-address');
		$self->{_radius_interim_verbose}	= $config->$val_func('radius interim-verbose');
		$self->{_radius_max_try}		= $config->$val_func('radius max-try');
		$self->{_radius_nas_identifier}		= $config->$val_func('radius nas-identifier');
		$self->{_radius_nas_ip_address}		= $config->$val_func('radius nas-ip-address');
		$self->{_radius_timeout}		= $config->$val_func('radius timeout');
		$self->{_radius_verbose}		= $config->$val_func('radius verbose');

		my @rservers = $config->$vals_func('radius server');
		foreach my $rserver (@rservers) {
			$self->{_radius_servers} = [ @{$self->{_radius_servers}}, $rserver];
		}
	}

	if (defined($config->$vals_func('shaper'))) {
		$self->{_shaper}			= 1;
		$self->{_shaper_vendor}			= $config->$val_func('shaper vendor');
		$self->{_shaper_attr}			= $config->$val_func('shaper attr');
		$self->{_shaper_enabled}		= $config->$val_func('shaper enabled');
		$self->{_shaper_attr_down}		= $config->$val_func('shaper attr-down');
		$self->{_shaper_attr_up}		= $config->$val_func('shaper attr-up');
		$self->{_shaper_burst_factor}		= $config->$val_func('shaper burst-factor');
		$self->{_shaper_down_burst_factor}	= $config->$val_func('shaper down-burst-factor');
		$self->{_shaper_up_burst_factor}	= $config->$val_func('shaper up-burst-factor');
		$self->{_shaper_latency}		= $config->$val_func('shaper latency');
		$self->{_shaper_mpu}			= $config->$val_func('shaper mpu');
		$self->{_shaper_mtu}			= $config->$val_func('shaper mtu');
		$self->{_shaper_r2q}			= $config->$val_func('shaper r2q');
		$self->{_shaper_quantum}		= $config->$val_func('shaper quantum');
		$self->{_shaper_up_limiter}		= $config->$val_func('shaper up-limiter');
		$self->{_shaper_down_limiter}		= $config->$val_func('shaper down-limiter');
		$self->{_shaper_leaf_qdisc}		= $config->$val_func('shaper leaf-qdisc');
		$self->{_shaper_rate_multiplier}	= $config->$val_func('shaper rate-multiplier');
		$self->{_shaper_verbose}		= $config->$val_func('shaper verbose');
	}
	if (defined($config->$vals_func('ip_pool'))) {
		$self->{_ip_pool}			= 1;
		$self->{_ip_pool_gw_ip_addr}		= $config->$val_func('ip-pool gw-ip-address');
		$self->{_ip_pool_gw}			= $config->$val_func('ip-pool gw');
		$self->{_ip_pool_tunnel}		= $config->$val_func('ip-pool tunnel');
	}

	if (defined($config->$vals_func('log'))) {
		$self->{_log}				= 1;
		$self->{_log_file}			= $config->$val_func('log log-file');
		$self->{_log_emerg}			= $config->$val_func('log log-emerg');
		$self->{_log_fail}			= $config->$val_func('log log-fail-file');
		$self->{_log_level}			= $config->$val_func('log level');
		$self->{_log_copy}			= $config->$val_func('log copy');
		$self->{_log_per_sess_dir}		= $config->$val_func('log per-session-dir');
		$self->{_log_per_user_dir}		= $config->$val_func('log per-user-dir');
		$self->{_log_per_sess}			= $config->$val_func('log per-session');
	}

	return 0;
}

sub setup {
    my ($self) = @_;
    
    $self->setup_base('listNodes', 'returnValue', 'returnValues', 'exists');
    return 0;
}

sub setupOrig {
    my ($self) = @_;
    
    $self->setup_base('listOrigNodes', 'returnOrigValue', 'returnOrigValue', 
                      'existsOrig');
    return 0;
}

sub listsDiff {
    my @a = @{$_[0]};
    my @b = @{$_[1]};
    return 1 if scalar @a != scalar @b;
    
    while (my $a = shift @a) {
        my $b = shift @b;
        return 1 if ($a ne $b);
    }
    return 0;
}

sub isDifferentFrom {
	my ($this, $that) = @_;

	return 1 if ($this->{_is_empty} ne $that->{_is_empty});

	return 1 if ($this->{_global_dns1} ne $that->{_global_dns1});
	return 1 if ($this->{_global_dns2} ne $that->{_global_dns2});
	return 1 if ($this->{_global_wins1} ne $that->{_global_wins1});
	return 1 if ($this->{_global_wins2} ne $that->{_global_wins2});

	return 1 if ($this->{_pppoe_ac} ne $that->{_pppoe_ac});
	return 1 if ($this->{_pppoe_service} ne $that->{_pppoe_service});
	return 1 if ($this->{_pppoe_mtu} ne $that->{_pppoe_mtu});

	return 1 if ($this->{_radius_nas_ip_address} ne $that->{_radius_nas_ip_address});

	return 1 if (listsDiff($this->{_pppoe_intfs}, $that->{_pppoe_intfs}));
	return 1 if (listsDiff($this->{_radius_servers}, $that->{_radius_servers}));

	return 0;
}

sub needsReload {
	my ($this, $that) = @_;

	return 0 if ($this->{_is_empty} ne $that->{_is_empty});

	return 1 if ($this->{_pppoe_ac} ne $that->{_pppoe_ac});
	return 1 if ($this->{_pppoe_service} ne $that->{_pppoe_service});
	return 1 if ($this->{_global_dns1} ne $that->{_global_dns1});
	return 1 if ($this->{_global_dns2} ne $that->{_global_dns2});
	return 1 if ($this->{_global_wins1} ne $that->{_global_wins1});
	return 1 if ($this->{_global_wins2} ne $that->{_global_wins2});
	return 1 if (listsDiff($this->{_pppoe_intfs}, $that->{_pppoe_intfs}));

	return 0;
};

sub pushReload {
	my ($this, $that) = @_;
	if (listsDiff($this->{_pppoe_intfs}, $that->{_pppoe_intfs})) {
            my %thathash=();
            foreach my $if ( @{ $that->{_pppoe_intfs}} ) {
               $thathash{$if}=1;
            };
            my %thishash=();
            foreach my $if ( @{ $this->{_pppoe_intfs}} ) {
               $thishash{$if}=1;
               if(defined($thathash{$if})) {
                  $thishash{$if}=0;
                  $thathash{$if}=0;
               };
            };
            foreach my $if ( keys(%thathash) ) {
               if(defined($thishash{$if})) {
                  $thishash{$if}=0;
                  $thathash{$if}=0;
               };
            };

            foreach my $if ( keys(%thathash)) {
               if($thathash{$if}) { ### Needs to be removed
                   my $rc=system("$accelcmd pppoe interface del $if");
                   if($rc != 0) { return 0 ;};
               };
            };
            foreach my $if ( keys(%thishash)) {
               if($thishash{$if}) { ### Needs to be added
                   my $rc=system("$accelcmd pppoe interface add $if");
                   if($rc != 0) { return 0; };
               };
            };
        };
        my %pars = ( _pppoe_ac => 'AC-Name',
                     _pppoe_service => 'Service-Name',
                     _pppoe_verbose => 'verbose' );
        foreach my $key (keys(%pars)) {
	  if ($this->{$key} ne $that->{$key}) {
            my $rc=system("$accelcmd pppoe set ".$pars{$key}." ".$this->{$key});
            if($rc != 0) { print STDERR "Can't set ".$pars{$key}."\n";return 0; };
          };
        };

	return 1;
};

sub needsRestart {
	 my ($this, $that) = @_;

	return 1 if ($this->{_is_empty} ne $that->{_is_empty});

	return 1 if ($this->{_pppoe_mtu} ne $that->{_pppoe_mtu});

	return 1 if ($this->{_radius_nas_ip_address} ne $that->{_radius_nas_ip_address});

	return 1 if (listsDiff($this->{_radius_servers}, $that->{_radius_servers}));

	return 0;
}

sub isEmpty {
    my ($self) = @_;
    return $self->{_is_empty};
}

sub get_ppp_opts {
	my ($self) = @_;
	my $loadmodules;
	my $config;
	my $finalconfig;

	# Global and hardcoded parameters
	$loadmodules .= "[modules]\n";
	$loadmodules .= "log_file\n";
	$loadmodules .= "auth_chap_md5\n";

	$config .= "[core]\n";
	$config .= "log-error=/var/log/accel-ppp/core.log\n";
	$config .= "thread-count=2\n\n";

	$config .= "[cli]\n";
	$config .= "#telnet=127.0.0.1:2000\n";
	$config .= "tcp=127.0.0.1:2001\n\n";

	$config .= "[dns]\n";	
	if (defined($self->{_global_dns1})) {
		$config .= "dns1=$self->{_global_dns1}\n";
	}
	if (defined($self->{_global_dns2})) {
		$config .= "dns2=$self->{_global_dns2}\n";
	}
	$config .= "\n";
	$config .= "[wins]\n";	
	if (defined($self->{_global_wins1})) {
		$config .= "wins1=$self->{_global_wins1}\n";
	}
	if (defined($self->{_global_wins2})) {
		$config .= "wins2=$self->{_global_wins2}\n";
	}
	$config .= "\n";

        if (defined($self->{_ip_pool})) {

		$loadmodules .= "ippool\n";
		$config .="[ip-pool]\n";

		if (defined($self->{_ip_pool_gw_ip_addr})) {
			$config .= "gw-ip-address=$self->{_ip_pool_gw_ip_addr}\n";
		}
		if (defined($self->{_ip_pool_gw})) {
			$config .= "gw=$self->{_ip_pool_gw}\n";
		}
		if (defined($self->{_ip_pool_tunnel})) {
			$config .= "tunnel=$self->{_ip_pool_tunnel}\n";
		}
		$config .= "\n";
	}

	if (defined($self->{_log})) {

		$config .="[log]\n";

		if (defined($self->{_log_file})) {
			$config .= "log-file=$self->{_log_file}\n";
		} else {
                        $config .= "log-file=/var/log/accel-ppp/accel-ppp.log\n";
                };
		if (defined($self->{_log_emerg})) {
			$config .= "log-emerg=$self->{_log_emerg}\n";
		} else {
                        $config .= "log-emerg=/var/log/accel-ppp/emerg.log\n";
                };
		if (defined($self->{_log_fail})) {
			$config .= "log-fail-file=$self->{_log_fail}\n";
		} else {
                        $config .= "log-fail-file=/var/log/accel-ppp/auth-fail.log\n";
                };
		if (defined($self->{_log_level})) {
			$config .= "level=$self->{_log_level}\n";
		} else {
                        $config .= "level=3\n";
                };
		if (defined($self->{_log_copy})) {
			$config .= "copy=$self->{_log_copy}\n";
		} else {
                        $config .= "copy=1\n";
                };
		if (defined($self->{_log_per_sess_dir})) {
			$config .= "per-session-dir=$self->{_log_per_sess_dir}\n";
		}
		if (defined($self->{_log_per_user_dir})) {
			$config .= "per-user-dir=$self->{_log_per_user_dir}\n";
		}
		if (defined($self->{_log_per_sess})) {
			$config .= "per-session=$self->{_log_per_sess}\n";
		}
		$config .= "\n";
	}

	# Generate PPPoE config
	if (defined($self->{_pppoe})) {
		return (undef, "Must define at least 1 interface")
			if scalar(@{$self->{_pppoe_intfs}}) < 1;

		$loadmodules .= "pppoe\n";
		$config .= "[pppoe]\n";

		# TODO: Get interface pado limit
		while (scalar(@{$self->{_pppoe_intfs}}) > 0) {
			my $intf = shift @{$self->{_pppoe_intfs}};
			$config .= "interface=$intf\n";
		}
		if (defined($self->{_pppoe_ac})) {
			$config .= "ac-name=$self->{_pppoe_ac}\n";
		}
		if (defined($self->{_pppoe_service})) {
			$config .= "service-name=$self->{_pppoe_service}\n";
		} else {
			$config .= "service-name=*\n";
		}
		if (defined($self->{_pppoe_pado_delay})) {
			$config .= "pado-delay=$self->{_pppoe_pado_delay}\n";
		}
		if (defined($self->{_pppoe_mac_filter})) {
			$config .= "mac-filter=$self->{_pppoe_mac_filter}\n";
		}
		if (defined($self->{_pppoe_called_sid})) {
			$config .= "called-sid=$self->{_pppoe_called_sid}\n";
		}
		if (defined($self->{_pppoe_ifname_in_sid})) {
			$config .= "ifname-in-sid=$self->{_pppoe_ifname_in_sid}\n";
		}
		if (defined($self->{_pppoe_pado_delay})) {
			$config .= "pado-delay=$self->{_pppoe_pado_delay}\n";
		}
		if (defined($self->{_pppoe_verbose})) {
			$config .= "verbose=$self->{_pppoe_verbose}\n";
		} else {
			$config .= "verbose=1\n";
		}
		if (defined($self->{_pppoe_tr101})) {
			$config .= "tr101=$self->{_pppoe_tr101}\n";
		}
		if (defined($self->{_pppoe_padi_limit})) {
			$config .= "padi-limit=$self->{_pppoe_padi_limit}\n";
		}
		if (defined($self->{_pppoe_mppe})) {
			$config .= "mppe=$self->{_pppoe_mppe}\n";
		} else {
			$config .= "mppe=deny\n";
		}
		if (defined($self->{_ip_pool})) {
			$config .= "ip-pool=$self->{_pppoe_ip_pool}\n";
		}
		$config .= "\n";
	}


	# Generate PPP options
	$config .= "[ppp]\n";
	if (defined($self->{_ppp_ccp})) {
		$config .= "ccp=$self->{_ppp_ccp}\n";
	}
	if (defined($self->{_ppp_check_ip})) {
		$config .= "check-ip=$self->{_ppp_check_ip}\n";
	}
	if (defined($self->{_ppp_ipv4})) {
		$config .= "ipv4=$self->{_ppp_ipv4}\n";
	} else {
		$config .= "ipv4=require\n";
	}
	if (defined($self->{_ppp_ipv6})) {
		$config .= "ipv6=$self->{_ppp_ipv6}\n";
	} else {
		$config .= "ipv6=deny\n";
	}
	if (defined($self->{_ppp_ipv6_accept_peer_intf_id})) {
		$config .= "ipv6-accept-peer-intf-id=$self->{_ppp_ipv6_accept_peer_intf_id}\n";
	}
	if (defined($self->{_ppp_ipv6_intf_id})) {
		$config .= "ipv6-intf-id=$self->{_ppp_ipv6_intf_id}\n";
	}
	if (defined($self->{_ppp_ipv6_peer_intf_id})) {
		$config .= "ipv6-peer-intf-id=$self->{_ppp_ipv6_peer_intf_id}\n";
	}
	if (defined($self->{_ppp_lcp_echo_failure})) {
		$config .= "lcp-echo-failure=$self->{_ppp_lcp_echo_failure}\n";
	}
	if (defined($self->{_ppp_lcp_echo_interval})) {
		$config .= "lcp-echo-interval=$self->{_ppp_lcp_echo_interval}\n";
	} else {
		$config .= "lcp-echo-interval=30\n";
	}
	if (defined($self->{_ppp_lcp_echo_timeout})) {
		$config .= "lcp-echo-timeout=$self->{_ppp_lcp_echo_timeout}\n";
	} else {
		$config .= "lcp-echo-timeout=120\n";
	}
	if (defined($self->{_ppp_min_mtu})) {
		$config .= "min-mtu=$self->{_ppp_min_mtu}\n";
	} else {
		$config .= "min-mtu=1280\n";
	}
	if (defined($self->{_ppp_mppe})) {
		$config .= "mppe=$self->{_ppp_ppp_mppe}\n";
	} else {
		$config .= "mppe=deny\n";
	}
	if (defined($self->{_ppp_mtu})) {
		$config .= "mtu=$self->{_ppp_mtu}\n";
		$config .= "mru=$self->{_ppp_mtu}\n";
	} else {
		$config .= "mtu=1450\n";
		$config .= "mru=1450\n";
	}
	if (defined($self->{_ppp_sid_case})) {
		$config .= "sid-case=$self->{_ppp_sid_case}\n";
	}
	if (defined($self->{_ppp_single_session})) {
		$config .= "single-session=$self->{_ppp_single_session}\n";
	}
	if (defined($self->{_ppp_unit_cache})) {
		$config .= "unit-cache=$self->{_ppp_unit_cache}\n";
	}
	if (defined($self->{_ppp_verbose})) {
		$config .= "verbose=$self->{_ppp_verbose}\n";
	} else {
		$config .= "verbose=1\n";
	}
	$config .= "\n";

	if (defined($self->{_radius})) {
		return (undef, "Must define at least 1 radius server to enable radius")
			if scalar(@{$self->{_radius_servers}}) < 1;

		$loadmodules .= "radius\n";
		$config .= "[radius]\n";

		while (scalar(@{$self->{_radius_servers}}) > 0) {
			my $rserver = shift @{$self->{_radius_servers}};
			$config .= "server=$rserver\n";
		}
		if (defined($self->{_radius_acct_delay_time})) {
			$config .= "acct-delay-time=$self->{_radius_acct_delay_time}\n";
		}
		if (defined($self->{_radius_acct_interim_interval})) {
			$config .= "acct-interim-interval=$self->{_radius_acct_interim_interval}\n";
		}
		if (defined($self->{_radius_acct_on})) {
			$config .= "acct-on=$self->{_radius_acct_on}\n";
		}
		if (defined($self->{_radius_acct_timeout})) {
			$config .= "acct-timeout=$self->{_radius_acct_timeout}\n";
		}
		if (defined($self->{_radius_dae_server})) {
			$config .= "dae-server=$self->{_radius_dae_server}\n";
		}
		if (defined($self->{_radius_default_realm})) {
			$config .= "default-realm=$self->{_radius_default_realm}\n";
		}
		if (defined($self->{_radius_dm_coa_secret})) {
			$config .= "dm_coa_secret=$self->{_radius_dm_coa_secret}\n";
		}
		if (defined($self->{_radius_gw_ip_address})) {
			$config .= "gw-ip-address=$self->{_radius_gw_ip_address}\n";
		} else {
			$config .= "gw-ip-address=192.168.100.1\n";
		}
		if (defined($self->{_radius_interim_verbose})) {
			$config .= "interim-verbose=$self->{_radius_interim_verbose}\n";
		}
		if (defined($self->{_radius_max_try})) {
			$config .= "max-try=$self->{_radius_max_try}\n";
		}
		if (defined($self->{_radius_nas_identifier})) {
			$config .= "nas-identifier=$self->{_radius_nas_identifier}\n";
		} else {
			$config .= "nas-identifier=accel-ppp\n";
		}
		if (defined($self->{_radius_nas_ip_address})) {
			$config .= "nas-ip-address=$self->{_radius_nas_ip_address}\n";
		} else {
			$config .= "nas-ip-address=127.0.0.1\n";
		}
		if (defined($self->{_radius_timeout})) {
			$config .= "timeout=$self->{_radius_timeout}\n";
		}
		if (defined($self->{_radius_verbose})) {
			$config .= "verbose=$self->{_radius_verbose}\n";
		} else {
			$config .= "verbose=1\n";
		}
		$config .= "\n";
	}

	if (defined($self->{_shaper}) and ( not(defined($self->{_shaper_enabled}) or $self->{_shaper_enabled} eq 'true') )) {
		return (undef, "Must specify upstream rate limiting method.")
			if ! defined $self->{_shaper_up_limiter};

		return (undef, "Must specify downstream rate limiting method.")
			if ! defined $self->{_shaper_down_limiter};

		$loadmodules .= "shaper\n";
		$config .= "[shaper]\n";

		if (defined($self->{_shaper_vendor})) {
			$config .= "vendor=$self->{_shaper_vendor}\n";
		}

		if (defined($self->{_shaper_attr}) && !defined($self->{_shaper_attr_down}) && !defined($self->{_shaper_attr_up})) {
			$config .= "attr=$self->{_shaper_attr}\n";
		} else {
			return (undef, "Cannot use attr and attr-down or attr-up at the same time.");
		}

		if (defined($self->{_shaper_attr_down}) && !defined($self->{_shaper_attr})) {
			$config .= "attr-down=$self->{_shaper_attr_down}\n";
		} elsif(defined($self->{_shaper_attr_down}) && defined($self->{_shaper_attr})) {
			return (undef, "Cannot use attr and attr-down at the same time.");
		} elsif(!defined($self->{_shaper_attr_down}) && !defined($self->{_shaper_attr})) {
			$config .= "attr-down=WISPr-Bandwidth-Max-Down\n";
		}

		if (defined($self->{_shaper_attr_up}) && !defined($self->{_shaper_attr})) {
			$config .= "attr-up=$self->{_shaper_attr_up}\n";
		} elsif(defined($self->{_shaper_attr_up}) && defined($self->{_shaper_attr})) {
			 return (undef, "Cannot use attr and attr-up at the same time.");
		} elsif(!defined($self->{_shaper_attr_up}) && !defined($self->{_shaper_attr})) {
			$config .= "attr-up=WISPr-Bandwidth-Max-Up\n";
		}

		if (defined($self->{_shaper_burst_factor})) {
			$config .= "burst-factor=$self->{_shaper_burst_factor}\n";
		}

		if (defined($self->{_shaper_down_burst_factor})) {
			$config .= "down-burst-factor=$self->{_shaper_down_burst_factor}\n";
		}

		if (defined($self->{_shaper_up_burst_factor})) {
			$config .= "up-burst-factor=$self->{_shaper_up_burst_factor}\n";
		}

		if (defined($self->{_shaper_latency})) {
			$config .= "latency=$self->{_shaper_latency}\n";
		}

		if (defined($self->{_shaper_mpu})) {
			$config .= "mpu=$self->{_shaper_mpu}\n";
		}

		if (defined($self->{_shaper_mtu})) {
			$config .= "mtu=$self->{_shaper_mtu}\n";
		}

		if (defined($self->{_shaper_r2q})) {
			$config .= "r2q=$self->{_shaper_r2q}\n";
		}

		if (defined($self->{_shaper_quantum})) {
			$config .= "quantum=$self->{_shaper_quantum}\n";
		}

		if (defined($self->{_shaper_up_limiter})) {
			$config .= "up-limiter=$self->{_shaper_up_limiter}\n";
		}

		if (defined($self->{_shaper_down_limiter})) {
			$config .= "down-limiter=$self->{_shaper_down_limiter}\n";
		}

		if (defined($self->{_shaper_leaf_qdisc})) {
			$config .= "leaf-qdisc=$self->{_shaper_leaf_qdisc}\n";
		}

		if (defined($self->{_shaper_rate_multiplier})) {
			$config .= "rate-multiplier=$self->{_shaper_rate_multiplier}\n";
		}

		if (defined($self->{_shaper_verbose})) {
			$config .= "verbose=$self->{_shaper_verbose}\n";
		} else {
			$config .= "verbose=1\n";
		}
	}


	$finalconfig  = "$cfg_delim_begin\n";
	$finalconfig .= $loadmodules . "\n";
	$finalconfig .= $config;
	$finalconfig .= "\n$cfg_delim_end\n";

	#return (undef, $finalconfig)
	#	if 2 > 1;

	return ($finalconfig, undef);
}

sub removeCfg {
    my ($self, $file) = @_;
    if ( ! -f "$file" ) {
       print STDERR "accel-ppp configuration problem: file $file not found!\n";
       print STDERR "Trying to create new:\n";
       system("touch $file");
       if ( ! -f "$file" ) {
          print STDERR "Failed. I give up\n";
          return 0;
       };
       return 1;
    };
    system("sed -i '/$cfg_delim_begin/,/$cfg_delim_end/d' $file");
    if ($? >> 8) {
        print STDERR 
            "accel-ppp configuration error: Cannot remove old config from $file.\n";
        
        return 0;
    }
    return 1;
}

sub writeCfg {
    my ($self, $file, $cfg, $append, $delim) = @_;

    my $op = ($append) ? '>>' : '>';
    my $WR = undef;
    if (!open($WR, $op, "$file")) {
        print STDERR 
            "accel-ppp configuration error: Cannot write config to $file.\n";
        return 0;
    }
    if ($delim) {
        $cfg = "$cfg_delim_begin\n" . $cfg . "\n$cfg_delim_end\n";
    }
    print ${WR} "$cfg";
    close $WR;
    return 1;
}

sub print_str {
    my ($self) = @_;

    my $str = 'accel-ppp';
#    $str .= "\n  intfs " . (join ",", @{$self->{_intfs}});
#    $str .= "\n  cip_start " . $self->{_client_ip_start};
#    $str .= "\n  cip_stop " . $self->{_client_ip_stop};
#    $str .= "\n  auth_mode " . $self->{_auth_mode};
#    $str .= "\n  auth_local " . (join ",", @{$self->{_auth_local}});
#    $str .= "\n  auth_radius " . (join ",", @{$self->{_auth_radius}});
#    $str .= "\n  auth_radius_s " . (join ",", @{$self->{_auth_radius_keys}});
#    $str .= "\n  dns " . (join ",", @{$self->{_dns}});
#    $str .= "\n  wins " . (join ",", @{$self->{_wins}});
#    $str .= "\n  empty " . $self->{_is_empty};
#    $str .= "\n";

  return $str;
}

1;
