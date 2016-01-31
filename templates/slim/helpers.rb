# This module gets mixed in to every template. The properties and methods in
# this module become direct members of the template.
module Slim::Helpers
  CDN_BASE = '//cdnjs.cloudflare.com/ajax/libs'
  EOL = %(\n)
  BUILD_ROLE_BY_TYPE = {
    'self' => 'build',
    'items' => 'build-items'
  }

  SvgStartTagRx = /\A<svg[^>]*>/
  ViewBoxAttributeRx = /\sviewBox="[^"]+"/
  WidthAttributeRx = /\swidth="([^"]+)"/
  HeightAttributeRx = /\sheight="([^"]+)"/
  SliceHintRx = /  +/

  def cdn_uri name, version, path = nil
    unless instance_variable_defined? :@asset_uri_scheme
      @asset_uri_scheme = (scheme = attr 'asset-uri-scheme', 'https').nil_or_empty? ? nil : %(#{scheme}:)
    end

    [%(#{@asset_uri_scheme}#{CDN_BASE}), name, version, path].compact * '/'
  end

  def local_attr name, default_val = nil
    attr name, default_val, false
  end

  def local_attr? name, default_val = nil
    attr? name, default_val, false
  end

  # Retrieve the converted content, wrap it in a paragraph element if
  # the content_model is :simple and return the result.
  def prepare_content
    content_model == :simple ? %(<p>#{content}</p>) : content
  end

  def partition_title text
    ::Asciidoctor::Document::Title.new text, separator: (document.attr 'title-separator')
  end

  # Public: Retrieve the level-1 section node for the current slide.
  #
  # Returns the Asciidoctor::Section for the current slide.
  def slide
    node = self
    until node.context == :section && node.level == 1
      node = node.parent
    end
    node
  end

  # Resolve the list of build-related roles for this block.
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
  def slice_text text, active = nil
    if (active || (active.nil? && (option? :slice))) && (text.include? '  ')
      (text.split SliceHintRx).map {|line| %(<span class="line">#{line}</span>) }.join EOL
    else
      text
    end
  end

  def include_svg target
    if (svg = converter.converters[-1].read_svg_contents self, target)
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
      %(<span class="alt">#{local_attr 'alt'}</span>)
    end
  end

  def spacer
    ' '
  end

  # FIXME this should return nil if pretty mode is not active
  def newline;
    EOL
  end
end
