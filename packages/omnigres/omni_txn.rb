# frozen_string_literal: true

require "minitar"
require "find"
require "zlib"
require "progress"

module Omnigres
  class OmniTxn < Pgpm::Package
    include Package

    def summary
      "Advanced transaction management"
    end
  end
end
