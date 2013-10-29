require 'rufus-scheduler'
require 'sem_ccb_job'

scheduler = Rufus::Scheduler.new

scheduler.in '3s' do
  puts 'HK... Rufus'
  SemCcbJob.new.perform
end

scheduler.join
