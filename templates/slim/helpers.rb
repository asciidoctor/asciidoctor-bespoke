# This module gets mixed in to every node (the context of the template) at the
# time the node is being converted. The properties and methods in this module
# effectively become direct members of the template.
module Slim::Helpers
  CDN_BASE = '//cdnjs.cloudflare.com/ajax/libs'
  EOL = %(\n)
  BUILD_ROLE_BY_TYPE = {
    'self' => 'build',
    'items' => 'build-items'
  }

  SvgStartTagRx = /\A<svg[^>]*>/
  ViewBoxAttributeRx = /\sview[bB]ox="[^"]+"/
  WidthAttributeRx = /\swidth="([^"]+)"/
  HeightAttributeRx = /\sheight="([^"]+)"/
  SliceHintRx = /  +/

  # Capture nested template content and register it with the specified key, to
  # be executed at a later time.
  #
  # This method must be invoked using the control code directive (i.e., -). By
  # using a control code directive, the block is set up to append the result
  # directly to the output buffer. (Integrations often hide the distinction
  # between a control code directive and an output directive in this context).
  #
  # key   - The Symbol under which to save the template block.
  # opts  - A Hash of options to control processing (default: {}):
  #         * :append  - A Boolean that indicates whether to append this block
  #                      to others registered with this key (default: false).
  #         * :content - String content to be used if template content is not
  #                      provided (optional).
  # block - The template content (in Slim template syntax).
  #
  # Examples
  #
  #   - content_for :body
  #     p content
  #   - content_for :body, append: true
  #     p more content
  #
  # Returns nothing.
  def content_for key, opts = {}, &block
    @content = {} unless defined? @content
    (opts[:append] ? (@content[key] ||= []) : (@content[key] = [])) << (block_given? ? block : lambda { opts[:content] })
    nil
  end

  # Checks whether deferred template content has been registered for the specified key.
  #
  # key - The Symbol under which to look for saved template blocks.
  #
  # Returns a Boolean indicating whether content has been registered for this key.
  def content_for? key
    (defined? @content) && (@content.key? key)
  end

  # Evaluates the deferred template content registered with the specified key.
  #
  # When the corresponding content_for method is invoked using a control code
  # directive, the block is set up to append the result to the output buffer
  # directly.
  #
  # key  - The Symbol under which to look for template blocks to yield.
  # opts - A Hash of options to control processing (default: {}):
  #        * :drain - A Boolean indicating whether to drain the key of blocks
  #                   after calling them (default: true).
  #
  # Examples
  #
  #   - yield_content :body
  #
  # Returns nothing (assuming the content has been captured in the context of control code).
  def yield_content key, opts = {}
    if (defined? @content) && (blks = (opts.fetch :drain, true) ? (@content.delete key) : @content[key])
      blks.map {|b| b.call }.join
    end
    nil
  end

  def asset_uri_scheme
    if instance_variable_defined? :@asset_uri_scheme
      @asset_uri_scheme
    else
      @asset_uri_scheme = (scheme = @document.attr 'asset-uri-scheme', 'https').nil_or_empty? ? nil : %(#{scheme}:)
    end
  end

  def cdn_uri name, version, path = nil
    [%(#{asset_uri_scheme}#{CDN_BASE}), name, version, path].compact * '/'
  end

  #--
  #TODO mix directly into AbstractNode
  def local_attr name, default_val = nil
    attr name, default_val, false
  end

  #--
  #TODO mix directly into AbstractNode
  def local_attr? name, default_val = nil
    attr? name, default_val, false
  end

  # Retrieve the converted content, wrap it in a `<p>` element if
  # the content_model equals :simple and return the result.
  #
  # Returns the block content as a String, wrapped inside a `<p>` element if
  # the content_model equals `:simple`.
  def resolve_content
    @content_model == :simple ? %(<p>#{content}</p>) : content
  end

  #--
  #TODO mix into AbstractBlock directly?
  def pluck selector = {}, &block
    quantity = (selector.delete :quantity).to_i
    if blocks?
      unless (result = find_by selector, &block).empty?
        result = result[0..(quantity - 1)] if quantity > 0
        result.each {|b| b.set_attr 'skip-option', '' }
      end
    else
      result = []
    end
    quantity == 1 ? result[0] : result
  end

  def pluck_first selector = {}, &block
    pluck selector.merge(quantity: 1), &block
  end

  def partition_title str
    ::Asciidoctor::Document::Title.new str, separator: (@document.attr 'title-separator')
  end

  # Retrieves the level-1 section node for the current slide.
  #
  # Returns the Asciidoctor::Section for the current slide.
  def slide
    node = self
    until node.context == :section && node.level == 1
      node = node.parent
    end
    node
  end

  # Resolves the list of build-related roles for this block.
  #
  # Consults the build attribute first, then the build option if the build
  # attribute is not set.
  #
  # Also sets the build-initiated attribute on the slide if not previously set.
  #
  # Returns an Array of build-related roles or an empty Array if builds are not
  # enabled on this node.
  def build_roles
    if local_attr? :build
      slide.set_attr 'build-initiated', ''
      (local_attr :build).split('+').map {|type| BUILD_ROLE_BY_TYPE[type] }
    elsif option? :build
      if (_slide = slide).local_attr? 'build-initiated'
        ['build-items']
      else
        _slide.set_attr 'build-initiated', ''
        ['build', 'build-items']
      end
    else
      []
    end
  end

  # QUESTION should we wrap in span.line if active but delimiter is not present?
  # TODO alternate terms for "slice" - part(ition), chunk, segment, split, break
  def slice_text str, active = nil
    if (active || (active.nil? && (option? :slice))) && (str.include? '  ')
      (str.split SliceHintRx).map {|line| %(<span class="line">#{line}</span>) }.join EOL
    else
      str
    end
  end

  # Retrieves the built-in html5 converter.
  # 
  # Returns the instance of the Asciidoctor::Converter::Html5Converter
  # associated with this node.
  def html5_converter
    converter.converters[-1]
  end

  def delegate
    html5_converter.convert self
  end

  def include_svg target
    if (svg = html5_converter.read_svg_contents self, target)
      # add viewBox attribute if missing
      unless ViewBoxAttributeRx =~ (start_tag = SvgStartTagRx.match(svg)[0])
        if (width = start_tag.match WidthAttributeRx) && (width = width[1].to_f) >= 0 &&
            (height = start_tag.match HeightAttributeRx) && (height = height[1].to_f) >= 0
          width = width.to_i if width == width.to_i
          height = height.to_i if height == height.to_i
          svg = %(<svg viewBox="0 0 #{width} #{height}"#{start_tag[4..-1]}#{svg[start_tag.length..-1]})
        end
      end
      svg
    else
      %(<span class="alt">#{local_attr :alt}</span>)
    end
  end

  def spacer
    ' '
  end

  def newline
    if defined? @pretty
      @pretty ? EOL : nil
    elsif (@pretty = ::Thread.current[:tilt_current_template].options[:pretty])
      EOL
    end
  end
end
