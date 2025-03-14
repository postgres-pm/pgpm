# frozen_string_literal: true

module Omnigres
  class OmniLedger < Pgpm::Package
    include Package

    def summary
      "Financial ledgering and accounting"
    end

    def depends_on_omni?
      true
    end
  end
end
