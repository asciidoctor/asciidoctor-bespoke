# This module gets mixed in to every template. The properties and methods in
# this module become direct members of the template.
module Slim::Helpers
  EOL = %(\n)

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

  def spacer
    ' '
  end

  def newline
    EOL
  end
end
