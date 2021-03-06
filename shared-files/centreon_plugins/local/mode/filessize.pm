################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package os::linux::local::mode::filessize;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "hostname:s"        => { name => 'hostname' },
                                  "remote"            => { name => 'remote' },
                                  "ssh-option:s@"     => { name => 'ssh_option' },
                                  "ssh-path:s"        => { name => 'ssh_path' },
                                  "ssh-command:s"     => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"         => { name => 'timeout', default => 30 },
                                  "sudo"              => { name => 'sudo' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "warning-one:s"     => { name => 'warning_one', },
                                  "critical-one:s"    => { name => 'critical_one', },
                                  "warning-total:s"   => { name => 'warning_total', },
                                  "critical-total:s"  => { name => 'critical_total', },
                                  "separate-dirs"     => { name => 'separate_dirs', },
                                  "max-depth:s"       => { name => 'max_depth', },
                                  "all-files"         => { name => 'all_files', },
                                  "exclude-du:s@"     => { name => 'exclude_du', },
                                  "filter-plugin:s"   => { name => 'filter_plugin', },
                                  "files:s"           => { name => 'files', },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning_one', value => $self->{option_results}->{warning_one})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-one threshold '" . $self->{warning_one} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical_one', value => $self->{option_results}->{critical_one})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-one threshold '" . $self->{critical_one} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning_total', value => $self->{option_results}->{warning_total})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-total threshold '" . $self->{warning_total} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical_total', value => $self->{option_results}->{critical_total})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-total threshold '" . $self->{critical_total} . "'.");
       $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{files}) || $self->{option_results}->{files} eq '') {
       $self->{output}->add_option_msg(short_msg => "Need to specify files option.");
       $self->{output}->option_exit();
    }
    
    #### Create command_options
    $self->{option_results}->{command} = 'du';
    $self->{option_results}->{command_options} = '-x -b';
    if (defined($self->{option_results}->{separate_dirs})) {
        $self->{option_results}->{command_options} .= ' --separate-dirs';
    }
    if (defined($self->{option_results}->{max_depth})) {
        $self->{option_results}->{command_options} .= ' --max-depth=' . $self->{option_results}->{max_depth};
    }
    if (defined($self->{option_results}->{all_files})) {
        $self->{option_results}->{command_options} .= ' --all';
    }
    foreach my $exclude (@{$self->{option_results}->{exclude_du}}) {
        $self->{option_results}->{command_options} .= " --exclude='" . $exclude . "'";
    }
    $self->{option_results}->{command_options} .= ' ' . $self->{option_results}->{files};
    $self->{option_results}->{command_options} .= ' 2>&1';
}

sub run {
    my ($self, %options) = @_;
    my $total_size = 0;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});
    
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "All file/directory sizes are ok.");
    foreach (split(/\n/, $stdout)) {
        next if (!/(\d+)\t+(.*)/);
        my ($size, $name) = ($1, centreon::plugins::misc::trim($2));
        
        next if (defined($self->{option_results}->{filter_plugin}) && $self->{option_results}->{filter_plugin} ne '' &&
                 $name !~ /$self->{option_results}->{filter_plugin}/);
        
        $total_size += $size;
        my $exit_code = $self->{perfdata}->threshold_check(value => $size, 
                                                           threshold => [ { label => 'critical_one', 'exit_litteral' => 'critical' }, { label => 'warning_one', exit_litteral => 'warning' } ]);
        my ($size_value, $size_unit) = $self->{perfdata}->change_bytes(value => $size);
        $self->{output}->output_add(long_msg => sprintf("%s: %s", $name, $size_value . ' ' . $size_unit));
        if (!$self->{output}->is_status(litteral => 1, value => $exit_code, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf("'%d' size is %s", $name, $size_value . ' ' . $size_unit));
        }
        $self->{output}->perfdata_add(label => $name, unit => 'B',
                                      value => $size,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_one'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_one'),
                                      min => 0);
    }
 
    # Total Size
    my $exit_code = $self->{perfdata}->threshold_check(value => $total_size, 
                                                       threshold => [ { label => 'critical_total', 'exit_litteral' => 'critical' }, { label => 'warning_total', exit_litteral => 'warning' } ]);
    my ($size_value, $size_unit) = $self->{perfdata}->change_bytes(value => $total_size);
    $self->{output}->output_add(long_msg => sprintf("Total: %s", $size_value . ' ' . $size_unit));
    if (!$self->{output}->is_status(litteral => 1, value => $exit_code, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit_code,
                                   short_msg => sprintf("Total size is %s", $size_value . ' ' . $size_unit));
    }
    $self->{output}->perfdata_add(label => 'total', unit => 'B',
                                  value => $total_size,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_total'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_total'),
                                  min => 0);
      
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check size of files/directories.

=over 8

=item B<--files>

Files/Directories to check. (Shell expansion is ok)

=item B<--warning-one>

Threshold warning in bytes for each files/directories.

=item B<--critical-one>

Threshold critical in bytes for each files/directories.

=item B<--warning-total>

Threshold warning in bytes for all files/directories.

=item B<--critical-total>

Threshold critical in bytes for all files/directories.

=item B<--separate-dirs>

Do not include size of subdirectories.

=item B<--max-depth>

Don't check fewer levels. (can be use --separate-dirs)

=item B<--all-files>

Add files when you check directories.

=item B<--exclude-du>

Exclude files/directories with 'du' command. Values from exclude files/directories are not counted in parent directories.
Shell pattern can be used.

=item B<--filter-plugin>

Filter files/directories in the plugin. Values from exclude files/directories are counted in parent directories!!!
Perl Regexp can be used.

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command-path>

Command path (Default: none).

=back

=cut
