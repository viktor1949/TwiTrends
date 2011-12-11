# set path to app that will be used to configure unicorn, 
# note the trailing slash in this example
@dir = "/home/main/work/TwiTrends/app"

worker_processes 2
working_directory @dir

preload_app true

timeout 30

# Specify path to socket unicorn listens to, 
# we will use this in our nginx.conf later
listen "/home/main/TwiTrend/shared/sockets/unicorn.sock", :backlog => 64

# Set process id path
pid "/home/main/TwiTrend/shared/pids"

# Set log file paths
stderr_path "/home/main/TwiTrend/shared/log/unicorn.stderr.log"
stdout_path "/home/main/TwiTrend/shared/log/unicorn.stdout.log" 
