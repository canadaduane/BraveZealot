require 'astar'

$size = 1_000_000
$length = Math.sqrt($size).to_i
arr = []
$size.times{ arr << ((rand*1000).to_i - 1) }
map = Astar.new(arr, $length)

for i in 0..1000
  u = (rand*100).to_i + 100
  u.times{ arr[(rand*$size).to_i] = ((rand*1000).to_i - 1) }
  puts "Updated #{u} cells"
  sx = (rand*$length).to_i
  sy = (rand*$length).to_i
  gx = (rand*$length).to_i
  gy = (rand*$length).to_i
  print "#{i}: #{sx}, #{sy} to #{gx}, #{gy}"
  path = map.search(sx, sy, gx, gy)
  puts " (#{path.size})"
end
