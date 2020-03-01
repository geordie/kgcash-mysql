# Use this file to easily define all of your cron jobs.

ENV.each { |k, v| env(k, v) }
set :output, "/kgcash/log/cron_log.log"
# set :job_template, "/bin/bash -c \':job\'"

every 1.minute do
	rake "batch:write_datetime"
end
