namespace :batch do
  desc "Write the current date"
  task write_datetime: :environment do
    pp "kgcash current time: " + DateTime.now.to_s
  end

end
