# frozen_string_literal: true

require "rbconfig"

module Pgpm
  module OS
    class RedHat < Pgpm::OS::Linux
      def self.auto_detect
        new # TODO: distinguish between flavors of RedHat
      end

      def self.name
        "redhat"
      end
    end

    class RockyEPEL9 < Pgpm::OS::RedHat
      def self.name
        "rocky+epel-9"
      end

      def self.builder
        Pgpm::RPM::Builder
      end

      def initialize(arch: nil)
        @arch = arch || RbConfig::CONFIG["host_cpu"]
        super()
      end

      def mock_config(_root = "rocky+epel-9-#{@arch}")
        <<~EOF
          include('rocky+epel-9-#{@arch}.cfg')
          config_opts['root'] = 'rocky+epel+pgdg-9-aarch64'

          config_opts['description'] = 'Rocky Linux EPEL 9'
          config_opts['dnf.conf'] += """

          #########################################################
          # PGDG Red Hat Enterprise Linux / Rocky repositories	#
          #########################################################

          # PGDG Red Hat Enterprise Linux / Rocky stable common repository for all PostgreSQL versions

          [pgdg-common]
          name=PostgreSQL common RPMs for RHEL / Rocky / AlmaLinux $releasever - $basearch
          baseurl=https://download.postgresql.org/pub/repos/yum/common/redhat/rhel-$releasever-$basearch
          enabled=1
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          # Red Hat recently breaks compatibility between 9.n and 9.n+1. PGDG repo is
          # affected with the LLVM repo. This is a band aid repo for the llvmjit users
          # whose installations cannot be updated.

          [pgdg-rocky9-sysupdates]
          name=PostgreSQL Supplementary ucommon RPMs for RHEL / Rocky / AlmaLinux $releasever - $basearch
          baseurl=https://download.postgresql.org/pub/repos/yum/common/pgdg-rocky9-sysupdates/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          # We provide extra package to support some RPMs in the PostgreSQL RPM repo, like
          # consul, haproxy, etc.

          [pgdg-rhel9-extras]
          name=Extra packages to support some RPMs in the PostgreSQL RPM repo for RHEL / Rocky / AlmaLinux $releasever - $basearch
          baseurl=https://download.postgresql.org/pub/repos/yum/common/pgdg-rhel$releasever-extras/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          # PGDG Red Hat Enterprise Linux / Rocky stable repositories:

          [pgdg17]
          name=PostgreSQL 17 for RHEL / Rocky / AlmaLinux $releasever - $basearch
          baseurl=https://download.postgresql.org/pub/repos/yum/17/redhat/rhel-$releasever-$basearch
          enabled=1
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg16]
          name=PostgreSQL 16 for RHEL / Rocky / AlmaLinux $releasever - $basearch
          baseurl=https://download.postgresql.org/pub/repos/yum/16/redhat/rhel-$releasever-$basearch
          enabled=1
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg15]
          name=PostgreSQL 15 for RHEL / Rocky / AlmaLinux $releasever - $basearch
          baseurl=https://download.postgresql.org/pub/repos/yum/15/redhat/rhel-$releasever-$basearch
          enabled=1
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg14]
          name=PostgreSQL 14 for RHEL / Rocky / AlmaLinux $releasever - $basearch
          baseurl=https://download.postgresql.org/pub/repos/yum/14/redhat/rhel-$releasever-$basearch
          enabled=1
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg13]
          name=PostgreSQL 13 for RHEL / Rocky / AlmaLinux $releasever - $basearch
          baseurl=https://download.postgresql.org/pub/repos/yum/13/redhat/rhel-$releasever-$basearch
          enabled=1
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg12]
          name=PostgreSQL 12 for RHEL / Rocky / AlmaLinux $releasever - $basearch
          baseurl=https://download.postgresql.org/pub/repos/yum/12/redhat/rhel-$releasever-$basearch
          enabled=1
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          # PGDG RHEL / Rocky / AlmaLinux Updates Testing common repositories.

          [pgdg-common-testing]
          name=PostgreSQL common testing RPMs for RHEL / Rocky / AlmaLinux $releasever - $basearch
          baseurl=https://download.postgresql.org/pub/repos/yum/testing/common/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          # PGDG RHEL / Rocky / AlmaLinux Updates Testing repositories. (These packages should not be used in production)
          # Available for 12 and above.

          [pgdg17-updates-testing]
          name=PostgreSQL 17 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Updates testing
          baseurl=https://download.postgresql.org/pub/repos/yum/testing/17/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=0
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg16-updates-testing]
          name=PostgreSQL 16 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Updates testing
          baseurl=https://download.postgresql.org/pub/repos/yum/testing/16/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg15-updates-testing]
          name=PostgreSQL 15 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Updates testing
          baseurl=https://download.postgresql.org/pub/repos/yum/testing/15/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg14-updates-testing]
          name=PostgreSQL 14 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Updates testing
          baseurl=https://download.postgresql.org/pub/repos/yum/testing/14/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg13-updates-testing]
          name=PostgreSQL 13 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Updates testing
          baseurl=https://download.postgresql.org/pub/repos/yum/testing/13/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg12-updates-testing]
          name=PostgreSQL 12 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Updates testing
          baseurl=https://download.postgresql.org/pub/repos/yum/testing/12/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          # PGDG Red Hat Enterprise Linux / Rocky SRPM testing common repository

          [pgdg-source-common]
          name=PostgreSQL 12 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Source
          baseurl=https://download.postgresql.org/pub/repos/yum/srpms/common/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          # PGDG RHEL / Rocky / AlmaLinux testing common SRPM repository for all PostgreSQL versions

          [pgdg-common-srpm-testing]
          name=PostgreSQL common testing SRPMs for RHEL / Rocky / AlmaLinux $releasever - $basearch
          baseurl=https://download.postgresql.org/pub/repos/yum/srpms/testing/common/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          # PGDG Source RPMs (SRPM), and their testing repositories:

          [pgdg17-source-updates-testing]
          name=PostgreSQL 17 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Source updates testing
          baseurl=https://download.postgresql.org/pub/repos/yum/srpms/testing/17/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=0
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg16-source]
          name=PostgreSQL 16 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Source
          baseurl=https://download.postgresql.org/pub/repos/yum/srpms/16/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg16-source-updates-testing]
          name=PostgreSQL 16 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Source updates testing
          baseurl=https://download.postgresql.org/pub/repos/yum/srpms/testing/16/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg15-source]
          name=PostgreSQL 15 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Source
          baseurl=https://download.postgresql.org/pub/repos/yum/srpms/15/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg15-source-updates-testing]
          name=PostgreSQL 15 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Source updates testing
          baseurl=https://download.postgresql.org/pub/repos/yum/srpms/testing/15/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg14-source]
          name=PostgreSQL 14 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Source
          baseurl=https://download.postgresql.org/pub/repos/yum/srpms/14/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg14-source-updates-testing]
          name=PostgreSQL 14 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Source updates testing
          baseurl=https://download.postgresql.org/pub/repos/yum/srpms/testing/14/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg13-source]
          name=PostgreSQL 13 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Source
          baseurl=https://download.postgresql.org/pub/repos/yum/srpms/13/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg13-source-updates-testing]
          name=PostgreSQL 13 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Source updates testing
          baseurl=https://download.postgresql.org/pub/repos/yum/srpms/testing/13/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg12-source]
          name=PostgreSQL 12 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Source
          baseurl=https://download.postgresql.org/pub/repos/yum/srpms/12/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg12-source-updates-testing]
          name=PostgreSQL 12 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Source update testing
          baseurl=https://download.postgresql.org/pub/repos/yum/srpms/testing/12/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          # Debuginfo/debugsource packages for stable repos

          [pgdg16-debuginfo]
          name=PostgreSQL 16 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Debuginfo
          baseurl=https://dnf-debuginfo.postgresql.org/debug/16/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg15-debuginfo]
          name=PostgreSQL 15 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Debuginfo
          baseurl=https://dnf-debuginfo.postgresql.org/debug/15/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg14-debuginfo]
          name=PostgreSQL 14 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Debuginfo
          baseurl=https://dnf-debuginfo.postgresql.org/debug/14/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg13-debuginfo]
          name=PostgreSQL 13 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Debuginfo
          baseurl=https://dnf-debuginfo.postgresql.org/debug/13/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg12-debuginfo]
          name=PostgreSQL 12 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Debuginfo
          baseurl=https://dnf-debuginfo.postgresql.org/debug/12/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          # Debuginfo/debugsource packages for testing repos
          # Available for 12 and above.

          [pgdg17-updates-testing-debuginfo]
          name=PostgreSQL 17 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Debuginfo
          baseurl=https://dnf-debuginfo.postgresql.org/testing/debug/17/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=0
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg16-updates-testing-debuginfo]
          name=PostgreSQL 16 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Debuginfo
          baseurl=https://dnf-debuginfo.postgresql.org/testing/debug/16/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=0
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg15-updates-testing-debuginfo]
          name=PostgreSQL 15 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Debuginfo
          baseurl=https://dnf-debuginfo.postgresql.org/testing/debug/15/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg14-updates-testing-debuginfo]
          name=PostgreSQL 14 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Debuginfo
          baseurl=https://dnf-debuginfo.postgresql.org/testing/debug/14/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg13-updates-testing-debuginfo]
          name=PostgreSQL 13 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Debuginfo
          baseurl=https://dnf-debuginfo.postgresql.org/testing/debug/13/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1

          [pgdg12-updates-testing-debuginfo]
          name=PostgreSQL 12 for RHEL / Rocky / AlmaLinux $releasever - $basearch - Debuginfo
          baseurl=https://dnf-debuginfo.postgresql.org/testing/debug/12/redhat/rhel-$releasever-$basearch
          enabled=0
          gpgcheck=1
          gpgkey=https://download.postgresql.org/pub/repos/yum/keys/PGDG-RPM-GPG-KEY-AARCH64-RHEL
          repo_gpgcheck = 1
          """

          #config_opts['dnf_install_command'] += ' https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm postgresql16 postgresql16-devel'
          config_opts['chroot_setup_cmd'] = 'install @development'
          # https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-aarch64/pgdg-redhat-repo-latest.noarch.rpm'

        EOF
      end
    end
  end
end
