# frozen_string_literal: true

require "English"
require "open3"
require "tty-command"

module Pgpm
  module Podman
    def self.run(command, unhandled_reboot_mitigation: true, print_stdout: true)
      result = TTY::Command.new(printer: :null).run("podman #{command}", pty: true) do |out, err|
        warn out if print_stdout
        warn err
      end

      result.out
    rescue TTY::Command::ExitError => e
      if unhandled_reboot_mitigation && e.message =~ /Please delete/
        FileUtils.rm_rf(["/run/containers/storage", "/run/libpod"])
        return run(command, print_stdout:, unhandled_reboot_mitigation: false)
      end

      raise
    end
  end
end
