
# The Qubes OS Project, https://www.qubes-os.org/
#
# Copyright (C) 2019 Marta Marczykowska-Górecka <marmarta@invisiblethingslab.com>
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


sub run {
    # open global-settings
    select_console('x11');
    assert_screen "desktop";
    x11_start_program('qubes-global-settings');

    # enable checking for updates for all qubes
    assert_and_click('global-settings-enable-all', timeout => 5);
    assert_and_click('global-settings-confirm', timeout => 10);
    # disable checking for updates for all qubes
    assert_and_click('global-settings-disable-all', timeout => 5);
    assert_and_click('global-settings-confirm', timeout => 10);

    # are kernels listing?
    assert_and_click('global-settings-kernel-listing', timeout => 10);
    assert_and_click('global-settings-kernels-listed', timeout => 10);

    # are default DispVMs being listed?
    assert_and_click('global-settings-default-dispvms-listing', timeout => 10);
    assert_and_click('global-settings-default-dispvms-listed', timeout => 10);

    # are clockVMs being listed?
    assert_and_click('global-settings-clockvms-listing', timeout => 5);
    assert_and_click('global-settings-clockvms-listed', timeout => 5);

    # change vm update default
    assert_and_click('global-settings-vm-update', timeout => 2);

    # is confirming settings working
    assert_and_click('global-settings-ok', timeout => 2);

    # is cancelling working
    x11_start_program('qubes-global-settings');
    assert_and_click('global-settings-cancel', timeout => 2);

    select_console('root-virtio-terminal');
    assert_script_run('qubes-prefs default-kernel $(ls -v /var/lib/qubes/vm-kernels|tail -1|tee /dev/stderr)', 20);
    select_console('x11');
}

sub post_fail_hook {
    my ($self) = @_;
    select_console('x11');
    send_key('esc');
    save_screenshot;
    $self->SUPER::post_fail_hook;

};

1;

# vim: set sw=4 et:

