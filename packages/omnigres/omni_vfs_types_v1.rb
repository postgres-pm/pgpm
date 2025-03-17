# frozen_string_literal: true

module Omnigres
  class OmniVfsTypesV1 < Pgpm::Package
    include Package

    def summary
      "Virtual File System API"
    end

    def requires
      # FIXME: this handles the special case of this extension being in
      # the same folder as omni_vfs.
      # In order to configure it, all dependencies of omni_vfs, save for omni_vfs_types_v1,
      # must be included.
      Pgpm::Package["omnigres/omni_vfs"][:latest].requires.reject { |p| p.name == name }
    end

    def native?
      # This extension shares the directory with `omni_vfs` which has .c files,
      # but it is not a native-code extension itself.
      false
    end
  end
end
