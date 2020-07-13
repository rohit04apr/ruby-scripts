require 'aws-sdk'

def cloud_watch_metric(metric_name, value)
	cloud_watch = Aws::CloudWatch::Client.new
    	cloud_watch.get_metric_statistics(
      	namespace: 'AWS/RDS',
      	metric_name: metric_name,
      	dimensions: [
        {
          name: 'DBInstanceIdentifier',
          value: value
        }
      	],
      	start_time: Time.now - 60,
      	end_time: Time.now,
      	statistics: ['Average'],
      	period: 60,
      	unit: "Bytes",
    	)
end

def alertCondition(totalSpace)

	case
	when (0..20) === totalSpace 
   	 return 1
	when (21..50) === totalSpace
  	 return 10
	when (51..200) === totalSpace
   	 return 20
	when (201..500) === totalSpace
   	 return 50
	else
  	return 100
end

end

rds = Aws::RDS::Client.new
rds_list = rds.describe_db_instances({})
rds_list.db_instances.each do |db_instance| 
	if db_instance.engine != "aurora"
		puts "DB NAME :: #{db_instance.db_instance_identifier}"

		totalSpace=db_instance.allocated_storage
		puts "total space :: #{totalSpace} GB"

      		r = cloud_watch_metric 'FreeStorageSpace', db_instance.db_instance_identifier
      		average = r[:datapoints][0].average unless r[:datapoints][0].nil?
      		free_space =  (average.to_i / 1073741824)
      		puts "free space :: #{free_space} GB" 

		alertThreshold=alertCondition(totalSpace)
		puts "alert threshold :: #{alertThreshold} GB"

		if free_space >= alertThreshold
			puts "Storage is sufficient"
		else
			puts "Alert.. Storage is low"
		end
		puts ""
		puts ""
	end
	end