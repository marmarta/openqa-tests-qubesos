
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
    x11_start_program('qubes-vm-create');

    # input name
    type_string('testqube');

    # choose a label
    assert_and_click('qubes-vm-create-label-open', timeout => 10);
    assert_and_click('qubes-vm-create-label-choose-blue', timeout => 10);

    # choose type
    assert_and_click('qubes-vm-create-type-open', timeout => 10);
    assert_and_click('qubes-vm-create-type-appvm', timeout => 10);

    # open template
    assert_and_click('qubes-vm-create-template-open', timeout => 10);
    assert_screen('qubes-vm-create-templates-opened', 10);
    send_key('esc');

    # open networking
    assert_and_click('qubes-vm-create-networking-open', timeout => 10);
    assert_screen('qubes-vm-create-networking-opened', 10);
    send_key('esc');

    # launch settings
    assert_and_click('qubes-vm-create-launch-settings', timeout => 10);

    # click ok
    assert_and_click('qubes-vm-create-ok', timeout => 10);

    # see if settings launched
    assert_screen('qubes-vm-create-settings-launched', 60);
    send_key('esc');

    # see if screen empty
    assert_screen('desktop');

    # launch again
    x11_start_program('qubes-vm-create');

    # click cancel
    assert_and_click('qubes-vm-create-cancel', timeout => 10);

    # see if screen empty
    assert_screen('desktop');

    # launch again
    x11_start_program('qubes-vm-create');

    # click exit button
    assert_and_click('qubes-vm-create-exit', timeout => 10);
}

sub post_fail_hook {
    my ($self) = @_;
    select_console('x11');
    send_key('esc');
    send_key('esc');
    save_screenshot;
    $self->SUPER::post_fail_hook;
};

1;

# vim: set sw=4 et:

