def team_colors(color)
  case color
  when /red/i    then [Color::RGB::Red,    Color::RGB::Pink]
  when /green/i  then [Color::RGB::Green,  Color::RGB::LightGreen]
  when /blue/i   then [Color::RGB::Blue,   Color::RGB::LightBlue]
  when /purple/i then [Color::RGB::Purple, Color::RGB::Violet]
  else                [Color::RGB::Gray, Color::RGB::Black]
  end
end