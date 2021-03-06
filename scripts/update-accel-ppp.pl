#!/usr/bin/perl

use strict;
use lib "/opt/vyatta/share/perl5";
use Vyatta::AccelPPPConfig;

my $PPPOE_INIT        = '/etc/init.d/accel-ppp';
my $FILE_PPPOE_CFG    = '/etc/accel-ppp.conf';

my $config = new Vyatta::AccelPPPConfig;
my $oconfig = new Vyatta::AccelPPPConfig;
$config->setup();
$oconfig->setupOrig();

if (!($config->isDifferentFrom($oconfig))) {
    # config not changed. do nothing.
    exit 0;
}

if ($config->isEmpty()) {
    if (!$oconfig->isEmpty()) {
        system('/usr/sbin/invoke-rc.d accel-ppp stop');
        system("echo 'ACCEL_PPPD_OPTS=' > /etc/default/accel-ppp");
    }
    exit 0;
}

my ($pppoe_conf, $err) = (undef, undef);

#while (1) {
($pppoe_conf, $err) = $config->get_ppp_opts();
#    last if (defined($err));
#}

if (defined($err)) {
    print STDERR "accel-ppp server configuration error: $err.\n";
    exit 1;
}

exit 1 if (!$config->removeCfg($FILE_PPPOE_CFG));
exit 1 if (!$config->writeCfg($FILE_PPPOE_CFG, $pppoe_conf, 0, 0));

if ($config->needsReload($oconfig)) {
        $config->pushReload($oconfig);
	system('/usr/bin/accel-cmd reload');
	exit 0;
}
elsif ($config->needsRestart($oconfig)) {
	# restart accel-ppp
	# We can use accel-cmd reload|restart to not disconnect clients
	# So far its not working need to investigate
        my $init_mode='sysv';
        if(-d '/etc/systemd/system') {
           $init_mode='systemd';
        };
	system("echo 'ACCEL_PPPD_OPTS=\"-c /etc/accel-ppp.conf\"' > /etc/default/accel-ppp");
        my $rc;
        if ($init_mode eq 'sysv') {
# System V
         if ( ! -f '/etc/init.d/accel-ppp-init') {
           open(FD,'>/etc/init.d/accel-ppp-init') or exit 1;
           print FD '#!/bin/sh
# /etc/init.d/accel-pppd: set up the accel-ppp server
### BEGIN INIT INFO
# Provides:          accel-ppp
# Required-Start:    $remote_fs $syslog $network $time
# Required-Stop:     $remote_fs $syslog $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
### END INIT INFO

set -e

PATH=/bin:/usr/bin:/sbin:/usr/sbin

. /lib/lsb/init-functions

if test -f /etc/default/accel-ppp; then
    . /etc/default/accel-ppp
fi

if [ -z "$ACCEL_PPPD_OPTS" ]; then
  ACCEL_PPPD_OPTS="-c /etc/accel-ppp.conf"
fi

case "$1" in
  start)
	log_daemon_msg "Starting PPtP/L2TP/PPPoE server" "accel-pppd"
	if start-stop-daemon --start --quiet --oknodo --exec /usr/sbin/accel-pppd -- -d -p /var/run/accel-pppd.pid $ACCEL_PPPD_OPTS; then
	    log_end_msg 0
	else
	    log_end_msg 1
	fi
  ;;
  restart)
	log_daemon_msg "Restarting PPtP/L2TP/PPPoE server" "accel-pppd"
	start-stop-daemon --stop --quiet --oknodo --retry 180 --pidfile /var/run/accel-pppd.pid
	if start-stop-daemon --start --quiet --oknodo --exec /usr/sbin/accel-pppd -- -d -p /var/run/accel-pppd.pid $ACCEL_PPPD_OPTS; then
	    log_end_msg 0
	else
	    log_end_msg 1
	fi
  ;;

  stop)
	log_daemon_msg "Stopping PPtP/L2TP/PPPoE server" "accel-pppd"
	start-stop-daemon --stop --quiet --oknodo --retry 180 --pidfile /var/run/accel-pppd.pid
	log_end_msg 0
  ;;

  status)
	status_of_proc /usr/sbin/accel-pppd "accel-pppd"
  ;;
  *)
    log_success_msg "Usage: /etc/init.d/accel-ppp {start|stop|status|restart}"
    exit 1
    ;;
esac

exit 0';
         close(FD);
         chmod(0755,'/etc/init.d/accel-ppp-init');
         };
	 system('/usr/sbin/invoke-rc.d accel-ppp stop');
	 $rc = system('/usr/sbin/invoke-rc.d accel-ppp start');
        } else {
### Systemd
         if ( ! -f '/etc/systemd/system/accel-ppp-init.service') {
            open(FD, '>/etc/systemd/system/accel-ppp-init.service') or exit(1);
            print FD '[Unit]
Description=Accel-pppd accelerated ppp server
After=network.target
ConditionPathExists=/etc/accel-ppp.conf

[Service]
EnvironmentFile=-/etc/default/accel-ppp
ExecStart=/usr/sbin/accel-pppd -c /etc/accel-ppp.conf -d
ExecReload=/usr/bin/accel-cmd reload
ExecStop=/usr/bin/killall -9 accel-pppd
KillMode=process
Restart=on-failure
Type=forking

[Install]
WantedBy=multi-user.target
Alias=accel-ppp.service ';
            close(FD);
            chmod(0755,'/etc/systemd/system/accel-ppp-init.service');
            $rc = system('/bin/systemctl enable accel-ppp-init');
            
            };
          
        };
	exit $rc;
}
exit 0;
