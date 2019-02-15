
Pod::Spec.new do |s|

  s.name         = "sqlite-helper"
  s.version      = `git describe --abbrev=0 --tags`
  s.summary      = "Sqlite helper for 'SQLite.swift'"
  s.description  = "Library for simlify using 'SQLite.swift' and 'apollo-mapper'"
  s.homepage     = "https://github.com/Lumyk/sqlite-helper"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Evgeny Kalashnikov" => "lumyk@me.com" }

  #  When using multiple platforms
  s.ios.deployment_target = "10.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/Lumyk/sqlite-helper.git", :tag => "#{s.version}" }

  s.source_files  = "Sources/**/*"

  s.dependency "SQLite.swift", "0.11.5"

end
