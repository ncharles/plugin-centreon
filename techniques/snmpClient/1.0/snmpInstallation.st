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


bundle agent snmp_installation {

  vars:
      "snmp_package_name"   string => "net-snmp";
      "c_snmp_package_name" string => canonify("${snmp_package_name}");
      "snmp_conf_file"      string => "/etc/snmp/snmpd.conf";
      "c_snmp_conf_file"    string => canonify("${snmp_conf_file}");

      "allowed_host"        string => "&SNMP_ALLOWED_HOST&";

  methods:
    "any" usebundle => package_install("${snmp_package_name}");

    "any" usebundle => rudder_common_reports_generic("SNMP installation", "package_install_${c_snmp_package_name}", "&TRACKINGKEY&", "SNMP installation", "None", "Installation of the SNMP package");

    "any" usebundle => file_ensure_lines_present("${snmp_conf_file}", "view    systemview    included   .1");
    "any" usebundle => file_ensure_lines_present("${snmp_conf_file}", "includeAllDisk 10%");

    "any" usebundle => file_replace_lines("${snmp_conf_file}", "syscontact\s+(?!(&SNMP_EMAIL_CONTACT&)$).*", "syscontact &SNMP_EMAIL_CONTACT&");

    "any" usebundle => file_replace_lines("${snmp_conf_file}", "com2sec\s+notConfigUser\s+(?!(${allowed_host}\s+public)$)\S+.*", "com2sec notConfigUser  ${allowed_host} public");

    "any" usebundle => service_reload("snmpd"),
          ifvarclass => "file_replace_lines_${c_snmp_conf_file}_repaired|file_ensure_lines_present_${c_snmp_conf_file}_repaired";

    "any" usebundle => service_ensure_running("snmpd");

    "success" usebundle => rudder_common_report("SNMP installation", "result_success",  "&TRACKINGKEY&", "SNMP configuration", "None", "Configuration of SNMP client"),
             ifvarclass => "file_replace_lines_${c_snmp_conf_file}_kept.service_ensure_running_snmpd_kept.!(file_replace_lines_${c_snmp_conf_file}_repaired|service_ensure_running_snmpd_repaired)";


    "repair" usebundle => rudder_common_report("SNMP installation", "result_repaired",  "&TRACKINGKEY&", "SNMP configuration", "None", "Configuration of Centron client"),
              ifvarclass => "(file_replace_lines_${c_snmp_conf_file}_repaired|service_ensure_running_snmpd_repaired).!(file_replace_lines_${c_snmp_conf_file}_error|service_ensure_running_snmpd_error)";

    "error" usebundle => rudder_common_report("SNMP installation", "result_error",  "&TRACKINGKEY&", "SNMP configuration", "None", "Configuration of Centron client"),
              ifvarclass => "(file_replace_lines_${c_snmp_conf_file}_error|service_ensure_running_snmpd_error)";




}
