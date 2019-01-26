# The Qubes OS Project, https://www.qubes-os.org/
#
# Copyright (C) 2018 Marek Marczykowski-Górecki <marmarek@invisiblethingslab.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

use base "installedtest";
use strict;
use testapi;
use networking;

sub run {
    my ($self) = @_;

    select_console('x11');
    assert_screen "desktop";
    x11_start_program('xterm');
    send_key('alt-f10');
    become_root;
    curl_via_netvm;
    # WTF part
    if (script_run('qvm-check --running sys-net') != 0) {
        assert_script_run('qvm-pci dt sys-net dom0:00_04.0');
        assert_script_run('qvm-pci at sys-net dom0:00_04.0 -p -o no-strict-reset=True');
    }

    # update extra files
    open EXTRA_TARBALL, "tar cz -C " . testapi::get_required_var('CASEDIR') . " extra-files|base64|" or die "failed to create tarball";
    my $tarball = do { local $/; <EXTRA_TARBALL> };
    close(EXTRA_TARBALL);
    save_tmp_file('extra-files.tar.gz.b64', $tarball);

    assert_script_run("curl " . autoinst_url('/files/extra-files.tar.gz.b64') . " | base64 -d | tar xz -C /root");
    type_string "cd /root/extra-files\n";
    type_string "python3 ./setup.py install\n";
    type_string "cd -\n";

    assert_script_run('cp -a /root/extra-files/update /srv/salt/');
    assert_script_run('qubesctl top.enable update');
    if (get_var('REPO_1')) {
        my $pillar_dir = "/srv/pillar/base/update";
        my $repo_url = data_url("REPO_1");
        assert_script_run("mkdir -p $pillar_dir");
        assert_script_run("printf 'update:\\n  repo: $repo_url\\n' > $pillar_dir/init.sls");
        $repo_url =~ s/\d+\.\d+\.\d+\.\d+/uedqavcpvbij4kyr.onion/;
        assert_script_run("printf '  repo_onion: $repo_url\\n' >> $pillar_dir/init.sls");
        assert_script_run("printf \"base:\\n  '*':\\n    - update\\n\" > $pillar_dir/init.top");
        assert_script_run('qubesctl top.enable update pillar=True');
    }
    if (get_var("SYSTEM_TESTS") or get_var("REPO_1")) {
        assert_script_run('cp -a /root/extra-files/system-tests /srv/salt/');
        assert_script_run('qubesctl top.enable system-tests');
    }

    assert_script_run('systemctl restart qubesd');
    assert_script_run('(set -o pipefail; qubesctl --max-concurrency=3 --templates --show-output state.highstate 2>&1 | tee qubesctl-upgrade.log)', timeout => 9000);
    upload_logs("qubesctl-upgrade.log");
    assert_script_run('tail -1 qubesctl-upgrade.log|grep -v failed');
    assert_script_run('! grep ERROR qubesctl-upgrade.log');
    assert_script_run('! grep "^  Failed: *[1-9]" qubesctl-upgrade.log');

    if (check_var('RESTART_AFTER_UPDATE', '1')) {
        type_string("reboot\n");
        assert_screen ["bootloader", "luks-prompt", "login-prompt-user-selected"], 300;
        $self->handle_system_startup;
    } else {
        # only restart key VMs
        script_run('qvm-shutdown --wait sys-firewall');
        script_run('qvm-kill sys-firewall');
        sleep(5);
        assert_script_run('qvm-start sys-firewall');
        type_string("exit\n");
        type_string("exit\n");
    }
}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return { fatal => 1, milestone => 1 };
}


sub post_fail_hook {
    my $self = shift;

    $self->SUPER::post_fail_hook();
    upload_logs('/tmp/qubesctl-upgrade.log', failok => 1);
    script_run('pidof -x qvm-start-gui || echo qvm-start-gui crashed');
};

1;

# vim: set sw=4 et:
