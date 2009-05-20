def bzrequire(relative_feature, error_msg = nil)
  require File.expand_path(File.join(File.dirname(__FILE__), relative_feature))
rescue Exception => e
  puts error_msg if error_msg
  raise e
end
