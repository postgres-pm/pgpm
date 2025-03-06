# frozen_string_literal: true

require "delegate"

module Pgpm
  class ScopedObject < SimpleDelegator
    def initialize(obj, *scopes)
      @scopes = scopes
      super(obj)
    end

    def method_missing(method, *args, &block)
      __scoped_execution(@scopes.clone, method, *args, &block)
    end

    def respond_to_missing?(m, include_private)
      __getobj__.respond_to_missing?(m, include_private)
    end

    private

    def __scoped_execution(scopes, method, *args, &block)
      if scopes.empty?
        __getobj__.send(method, *args, &block)
      else
        scope = scopes.pop
        scope.with_scope { __scoped_execution(scopes, method, *args, &block) }
      end
    end
  end
end
