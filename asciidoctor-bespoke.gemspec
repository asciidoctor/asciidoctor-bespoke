# -*- encoding: utf-8 -*-
require File.expand_path '../lib/asciidoctor-bespoke/version', __FILE__

Gem::Specification.new do |s|
  s.name = 'asciidoctor-bespoke'
  s.version = Asciidoctor::Bespoke::VERSION
  s.authors = ['Dan Allen']
  s.email = ['dan.j.allen@gmail.com']
  s.homepage = 'https://github.com/asciidoctor/asciidoctor-bespoke'
  s.summary = 'Converts AsciiDoc to HTML for a Bespoke.js presentation'
  s.description = 'An Asciidoctor converter that generates the HTML component of a Bespoke.js presentation from AsciiDoc.'
  s.license = 'MIT'
  s.required_ruby_version = '>= 1.9.3'

  begin
    s.files = `git ls-files -z -- {bin,lib,templates}/* {LICENSE,README}.adoc Rakefile`.split "\0"
  rescue
    s.files = Dir['**/*']
  end

  s.executables = ['asciidoctor-bespoke']
  s.extra_rdoc_files = Dir['README.adoc', 'LICENSE.adoc']
  s.require_paths = ['lib']

  # QUESTION should asciidoctor be a runtime dependency?
  s.add_runtime_dependency 'asciidoctor', '>= 1.5.0'
  s.add_runtime_dependency 'slim', '~> 3.0.6'
  s.add_runtime_dependency 'thread_safe', '~> 0.3.5'

  s.add_development_dependency 'rake', '~> 10.4.2'
end
