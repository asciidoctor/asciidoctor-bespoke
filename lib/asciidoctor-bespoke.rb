if RUBY_ENGINE == 'opal'
  require 'asciidoctor-bespoke/converter'
  `require('asciidoctor-template.js')`
else
  require 'asciidoctor' unless defined? Asciidoctor::Converter
  require_relative 'asciidoctor-bespoke/converter'
end
