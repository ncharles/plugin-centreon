#####################################################################################
# Copyright 2011-2013 Normation SAS
#####################################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, Version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#####################################################################################

#                                                                        #
# - RPM_PACKAGE_VERSION -->  The optionnal package version               #
#                                                                        #
##########################################################################

bundle agent centreon_installation {

  vars:
      "centreon_package_name" string => "centreon-nrpe-daemon";
      "centreon_plugin_base"  string => "centreon-plugins-base";

      "centreon_dest_key"     string => "/etc/pki/rpm-gpg/RPM-GPG-KEY-CES";


      "c_centreon_package_name" string => canonify("${centreon_package_name}");
      "c_centreon_plugin_base" string => canonify("${centreon_plugin_base}");

      "repo_file"            string => "/etc/yum.repos.d/plugin.repo";
      "centreon_conf_file"   string => "/etc/nrpe/centreon-nrpe.cfg";
      "c_centreon_conf_file"   string => canonify("${centreon_conf_file}");

      "plugin_folder"        string => "/var/rudder/configuration-repository/shared-files/centreon_plugins/local";
      "plugin_destination"   string => "/usr/lib/nagios/plugins/os/linux";
      "c_plugin_destination" string => canonify("${plugin_destination}");

      "centplugin_path"      string => "/var/lib/centreon/centplugins";
      "c_centplugin_path"    string => canonify("${centplugin_path}");

  classes:
      "user_centreon_engine_exists" expression => userexists("centreon-engine");

  commands:
    !user_centreon_engine_exists::
      "/usr/sbin/useradd centreon-engine"
        classes => classes_generic("create_user_centreon_engine");

  methods:
    "any" usebundle => file_copy_from_local_source("${sys.workdir}/inputs/centreonClient/1.0/RPM-GPG-KEY-CES", "${centreon_dest_key}");

    "any" usebundle => file_copy_from_local_source("${sys.workdir}/inputs/centreonClient/1.0/centreon_plugin.repo", "${repo_file}");


    "any" usebundle => package_install("${centreon_package_name}");

    "any" usebundle => package_install("${centreon_plugin_base}");

    "any" usebundle => file_copy_from_remote_source_recursion("${plugin_folder}", "${plugin_destination}", "inf"),
         ifvarclass => "package_install_${c_centreon_plugin_base}_ok";

    "any" usebundle => directory_create("${centplugin_path}");
    "any" usebundle => permissions_dirs("${centplugin_path}", "755", "centreon-engine", "centreon-engine"),
         ifvarclass => "directory_create_${c_centplugin_path}_ok";

    "any" usebundle => rudder_common_report("Centreon installation", "result_success", "&TRACKINGKEY&", "Centreon installation", "None", "Installation of the Centreon agent was correct"),
         ifvarclass => "package_install_${c_centreon_package_name}_kept.package_install_${c_centreon_plugin_base}_kept.file_copy_from_remote_source_${c_plugin_destination}_kept";

    "any" usebundle => rudder_common_report("Centreon installation", "result_repaired", "&TRACKINGKEY&", "Centreon installation", "None", "The Centreon agent has been correctly installed"),
         ifvarclass => "(package_install_${c_centreon_package_name}_repaired|package_install_${c_centreon_plugin_base}_repaired|file_copy_from_remote_source_${c_plugin_destination}_repaired).!(package_install_${c_centreon_package_name}_error|package_install_${c_centreon_plugin_base}_error|file_copy_from_remote_source_${c_plugin_destination}_error)";

    "any" usebundle => rudder_common_report("Centreon installation", "result_error", "&TRACKINGKEY&", "Centreon installation", "None", "Installation of the Centreon agent failed"),
         ifvarclass => "(package_install_${c_centreon_package_name}_error|package_install_${c_centreon_plugin_base}_error|file_copy_from_remote_source_${c_plugin_destination}_error)";


    "any" usebundle => file_copy_from_local_source("${sys.workdir}/inputs/centreonClient/1.0/centreon-nrpe", "${centreon_conf_file}"),
          ifvarclass => canonify("package_install_${c_centreon_package_name}_ok");



    "any" usebundle => service_reload("centreon-nrpe"),
          ifvarclass => canonify("file_copy_from_local_source_${c_centreon_conf_file}_repaired");

    "any" usebundle => service_ensure_running("centreon-nrpe");

    "success" usebundle => rudder_common_report("Centreon installation", "result_success",  "&TRACKINGKEY&", "Centreon configuration", "None", "Configuration of Centron client is correct"),
              ifvarclass => "file_copy_from_local_source_${c_centreon_conf_file}_kept.service_ensure_running_centreon_nrpe_kept.permissions_${c_centplugin_path}_kept.!(file_copy_from_local_source_${c_centreon_conf_file}_repaired|service_ensure_running_centreon_nrpe_repaired|create_user_centreon_engine_repaired|permissions_${c_centplugin_path}_repaired).user_centreon_engine_exists";


    "repair" usebundle => rudder_common_report("Centreon installation", "result_repaired",  "&TRACKINGKEY&", "Centreon configuration", "None", "Configuration of Centron client has been corrected"),
              ifvarclass => "(file_copy_from_local_source_${c_centreon_conf_file}_repaired|service_ensure_running_centreon_nrpe_repaired|create_user_centreon_engine_repaired|permissions_${c_centplugin_path}_repaired).!(file_copy_from_local_source_${c_centreon_conf_file}_error|service_ensure_running_centreon_nrpe_error|create_user_centreon_engine_error.!permissions_${c_centplugin_path}_error)";

    "error" usebundle => rudder_common_report("Centreon installation", "result_error",  "&TRACKINGKEY&", "Centreon configuration", "None", "Configuration of Centron client could not be corrected"),
              ifvarclass => "(file_copy_from_local_source_${c_centreon_conf_file}_error|service_ensure_running_centreon_nrpe_error|create_user_centreon_engine_error|permissions_${c_centplugin_path}_error)";




}
