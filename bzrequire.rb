def bzrequire(relative_feature)
  require File.expand_path(File.join(File.dirname(__FILE__), relative_feature))
end
