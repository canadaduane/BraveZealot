# Indents all lines within +text+ by the amount of +whitespace+
def indent(text, whitespace)
  text.lines.map do |l|
    whitespace + l
  end.join
end

# Removes as much indentation from all lines of +text+ as is present in the first line
def unindent(text)
  lines = text.lines
  whitespace = lines.first.scan(/^\s*/).first
  lines.map do |l|
    l.gsub(/^#{whitespace}/, "")
  end.join
end