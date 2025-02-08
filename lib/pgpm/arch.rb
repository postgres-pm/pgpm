# frozen_string_literal: true

require "rbconfig"
require "lspace"

module Pgpm
  class Arch
    def self.host
      new(RbConfig::CONFIG["host_cpu"])
    end

    def self.in_scope
      LSpace[:pgpm_target_arch]
    end

    def initialize(name)
      @name = name == "arm64" ? "aarch64" : name
    end

    attr_reader :name

    def with_scope(&block)
      LSpace.with(pgpm_target_arch: self) do
        block.yield
      end
    end
  end
end
