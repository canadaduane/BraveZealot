# Note: You should have a .caprc file in your home directory that sets your username:
#   set :user, 'your_username'

# gem install mattmatt-cap-ext-parallelize -s http://gems.github.com
# require 'cap_ext_parallelize'

set :team, "green"
set :players, "2"
set :machine, "fungi"
set :bzfs_port, "5154"
set :bzrc_port, "5000"

# desc "Go"
# task :go, :hosts => "#{machine}.cs.byu.edu" do
#   stop_tunnel
#   stop_robot
#   stop_server
#   
#   begin
#     parallelize do |session|
#       session.run { start_server }
#       session.run { start_robot  }
#       session.run { start_tunnel_delayed }
#     end
#   rescue SignalException => e
#     puts "bzrobots shutdown"
#     stop_server
#     stop_robot
#     stop_tunnel
#   end
# end


desc "Starts the bzfs server on the remote CS department host"
task :start_server, :hosts => "#{machine}.cs.byu.edu" do
  begin
    cmd = "~cs470s/bzflag/src/bzfs/bzfs -c -d " +
          "-set _inertiaLinear 1 " +
          "-set _inertiaAngular 1 " +
          "-set _tankAngVel 0.5 " +
          "-set _rejoinTime 0 " +
          "-set _grabOwnFlag 0"
    stream cmd, :pty => true
  rescue SignalException => e
    puts "shutdown bzflag server"
    stop_server
  end
end

desc "Stops the bzfs server"
task :stop_server, :hosts => "#{machine}.cs.byu.edu" do
  run "ps auxww|grep bzfs|grep -v grep|awk '{print $2}'|xargs kill; true"
end


desc "Initiates a local SSH tunnel with port-forwarding to the remote bzflag server"
task :start_tunnel, :hosts => "localhost" do
  stop_tunnel
  puts "Opening SSH tunnel on port #{bzrc_port}"
  system("ssh -f -N -L #{bzrc_port}:#{machine}:#{bzrc_port} #{user}@#{machine}.cs.byu.edu")
end

task :start_tunnel_delayed, :hosts => "localhost" do
  puts "In 10 seconds, opening SSH tunnel on port #{bzrc_port}"
  system("sleep 10; ssh -f -N -L #{bzrc_port}:#{machine}:#{bzrc_port} #{user}@#{machine}.cs.byu.edu")
end

desc "Closes SSH tunnel(s) to the remote bzflag server"
task :stop_tunnel, :hosts => "localhost" do
  system("ps auxww|grep ssh|grep #{bzrc_port}|awk '{print $2}'|xargs kill")
end


desc "Start the bzrobots server/client"
task :start_robot, :hosts => "#{machine}.cs.byu.edu" do
  puts "Starting bzrobots server/client"
  begin
    run "~cs470s/bzflag/src/bzrobots/bzrobots -team #{team} -solo #{players} -p #{bzrc_port}"
  rescue SignalException => e
    puts "shutdown bzrobots"
    stop_robot
  end
end

desc "Stop the bzrobots server/client"
task :stop_robot, :hosts => "#{machine}.cs.byu.edu" do
  puts "Stopping bzrobots server/client"
  run "ps auxww|grep bzrobots|grep -v grep|awk '{print $2}'|xargs kill; true"
end
