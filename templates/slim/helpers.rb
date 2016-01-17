# This module gets mixed in to every template. The properties and methods in
# this module become direct members of the template.
module Slim::Helpers
  EOL = %(\n)
  SvgStartTagRx = /\A<svg[^>]*>/
  ViewBoxAttributeRx = /\sviewBox="[^"]+"/
  WidthAttributeRx = /\swidth="([^"]+)"/
  HeightAttributeRx = /\sheight="([^"]+)"/

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
