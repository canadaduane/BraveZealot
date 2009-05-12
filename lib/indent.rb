def indent(text, whitespace)
  text.lines.map do |l|
    whitespace + l
  end.join
end

def unindent(text)
  lines = text.lines
  whitespace = lines.first.scan(/^\s*/).first
  lines.map do |l|
    l.gsub(/^#{whitespace}/, "")
  end.join
end