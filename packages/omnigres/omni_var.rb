# frozen_string_literal: true

require "minitar"
require "find"
require "zlib"
require "progress"

module Omnigres
  class OmniVar < Pgpm::Package
    include Package

    def summary
      "Variable management"
    end
  end
end
