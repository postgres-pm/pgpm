#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "active_support/core_ext/string/inflections"
require "pgpm"
require "csv"
require "open-uri"

Pgpm.load_packages

URI.open("https://raw.githubusercontent.com/pgsty/extension/refs/heads/main/data/pigsty.csv") do |f|
  i = 0
  CSV.foreach(f, headers: true) do |row|
    next unless row["url"] =~ /github/ || row["url"] =~ /gitlab/

    origin = row["url"]
    if row["url"] =~ /github/
      github = origin.match(%r{https://github\.com/([^/]+)/([^/]+)}).captures.join("/")
      origin = "github \"#{github}\""
    else
      origin = "git \"#{origin}\""
    end
    name = row["name"]

    next if Pgpm::Package.find do |pkg|
      origin =~ /github/ &&
      pkg.respond_to?(:github_config) && pkg.github_config&.name == github
    end

    next if File.exist?("packages/#{name}.rb")

    i += 1
    classname = name.camelize
    new_class = <<~CLASS
      class #{classname} < Pgpm::Package
          #{origin}
      end
    CLASS
    File.write("packages/#{name}.rb", new_class)
    puts name
  end
  puts "#{i} packages imported"
end
