# Note: You should have a .caprc file in your home directory that sets your username:
#   set :user, 'your_username'

set :machine, "fungi"
set :bzfs_port, "5154"


desc "Initiates a local SSH tunnel with port-forwarding to the remote bzflag server"
task :start_tunnel, :hosts => "localhost" do
  puts "Opening SSH tunnel on port #{bzfs_port}"
  system("ssh -f -N -L #{bzfs_port}:#{machine}:#{bzfs_port} #{user}@#{machine}.cs.byu.edu")
end


desc "Closes SSH tunnel(s) to the remote bzflag server"
task :stop_tunnel, :hosts => "localhost" do
  puts "Closing SSH tunnel(s) to port #{bzfs_port}"
  system("ps auxww|grep ssh|grep #{bzfs_port}|awk '{print $2}'|xargs kill")
end


desc "Starts the bzfs server on the remote CS department host"
task :bzfs, :hosts => "#{machine}.cs.byu.edu" do
  stop_tunnel
  Thread.new {
    sleep 5
    start_tunnel
  }
  begin
    cmd = "~cs470s/bzflag/src/bzfs/bzfs -c -d " +
          "-set _inertiaLinear 1 " +
          "-set _inertiaAngular 1 " +
          "-set _tankAngVel 0.5 " +
          "-set _rejoinTime 0 " +
          "-set _grabOwnFlag 0"
    stream cmd, :pty => true
  rescue SignalException => e
    puts "bzflag server shutdown"
    stop_tunnel
  end
end
