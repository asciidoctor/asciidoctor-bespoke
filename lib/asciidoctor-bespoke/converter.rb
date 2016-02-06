require 'asciidoctor/converter/html5'
require 'asciidoctor/converter/composite'
require 'asciidoctor/converter/template'

# Asciidoctor < 1.5.5 doesn't recognize svg tag name if followed immediately by newline
Asciidoctor::Converter::Html5Converter.tap do |klass|
  klass.send :remove_const, :SvgPreambleRx
  klass.const_set :SvgPreambleRx, /\A.*?(?=<svg\b)/m
end if Asciidoctor::VERSION == '1.5.3' || Asciidoctor::VERSION == '1.5.4'

module Asciidoctor
module Bespoke
  class Converter < ::Asciidoctor::Converter::CompositeConverter
    ProvidedTemplatesDir = ::File.expand_path '../../../templates', __FILE__
    SlimPrettyOpts = { pretty: true, indent: false }.freeze
    register_for 'bespoke'

    def initialize backend, opts = {}
      template_dirs = [ProvidedTemplatesDir] # last dir wins
      if (custom_template_dirs = opts[:template_dirs])
        template_dirs += custom_template_dirs.map {|d| ::File.expand_path d }
      end
      include_dirs = template_dirs.reverse.tap {|c| c << (::File.join c.pop, 'slim') } # first dir wins
      engine_opts = (opts[:template_engine_options] || {}).dup
      extra_slim_opts = { include_dirs: include_dirs }
      extra_slim_opts.update SlimPrettyOpts if Set.new(%w(1 true)).include?(ENV['SLIM_PRETTY'].to_s)
      engine_opts[:slim] = (engine_opts.key? :slim) ? (extra_slim_opts.merge engine_opts[:slim]) : extra_slim_opts
      template_opts = opts.merge htmlsyntax: 'html', template_engine: 'slim', template_engine_options: engine_opts
      template_converter = ::Asciidoctor::Converter::TemplateConverter.new backend, template_dirs, template_opts
      html5_converter = ::Asciidoctor::Converter::Html5Converter.new backend, opts
      super backend, template_converter, html5_converter
      basebackend 'html'
      htmlsyntax 'html'
    end

    def convert node, transform = nil, opts = {}
      if node.attributes.delete 'skip-option'
        ''
      # FIXME mixin slide? method to AbstractBlock (or AbstractNode)
      elsif node.block? && (node.attr? 'transform') && node.context == :section && node.level == 1
        super node, %(slide_#{node.attr 'transform'}), opts
      else
        super
      end
    end
  end
end
end
