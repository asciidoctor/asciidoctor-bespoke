# Add custom functions to this module that you want to use in your Slim templates.
# Within the template you can invoke them as top-level functions.
module Slim::Helpers
  def local_attr name, default_val = nil
    attr name, default_val, false
  end

  def local_attr? name, default_val = nil
    attr? name, default_val, false
  end

  def convert_content
    content_model == :simple ? %(<p>#{content}</p>) : content
  end

  def spacer
    ' '
  end
end
