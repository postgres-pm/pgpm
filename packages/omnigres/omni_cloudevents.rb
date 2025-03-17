# frozen_string_literal: true

module Omnigres
  class OmniCloudevents < Pgpm::Package
    include Package

    def summary
      "CloudEvents support"
    end
  end
end
