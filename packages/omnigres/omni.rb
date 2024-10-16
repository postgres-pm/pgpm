# frozen_string_literal: true

require "minitar"
require "find"
require "zlib"
require "progress"

module Omnigres
  class Omni < Pgpm::Package
    include Package

    def summary
      "Advanced adapter for Postgres extensions"
    end
  end
end
