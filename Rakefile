$dir = "/Users/duane/Projects/Others/bzflag"
team = "green"
players = 2
bzfs_port = 5154
bzrobots_port = 6000
callsign = "duane"

def waitport(port)
  begin
    result = `netstat -an|grep \.#{port}\s`
  end while result.empty?
end

def shell(cmd)
  cmd = "cd #{$dir}; #{cmd}"
  puts cmd
  system cmd
end

desc "Start a local bzflag client"
task :client do
  shell "src/bzflag/bzflag -window 1024x768 -directory ./data obs@localhost:#{bzfs_port}"
end

namespace :local do
  desc "Start a local bzfs server"
  task :bzfs do
    shell "src/bzfs/bzfs -c -d -set _inertiaLinear 1 -set _inertiaAngular 1 -set _tankAngVel 0.5 -set _rejoinTime 0 -set _grabOwnFlag 0 &"
  end
    
  desc "Start local bzrobots client/server"
  task :robot do
    puts "Waiting for bzfs server on port #{bzfs_port}"
    waitport(bzfs_port)
    shell "src/bzrobots/bzrobots -team #{team} -solo #{players} -p #{bzrobots_port} #{callsign}@localhost"
  end
  
  desc "Start bzfs server and bzrobots"
  task :start => [:bzfs, :robot] do
    `ps auxww|grep bzfs|grep -v grep|awk '{print $2}'|xargs kill`
    puts "Server shutdown."
  end
end
