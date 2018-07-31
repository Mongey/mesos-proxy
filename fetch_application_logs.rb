require_relative 'mesos_client'
require_relative 'marathon_proxy_client'

class FetchApplicationLogs
  def self.call(application_id:, host:, file:, data_length:)
    HTTParty::Basement.default_options.update(verify: false)

    mesos = MesosClient.new(host: host)
    marathon = MarathonProxyClient.new(proxy_addr: mesos.base_url)

    cmd = file

    begin
      raise ApplicationNotFound if application_id == '' || application_id == nil
      hosts = marathon.hosts_task_is_running_on(application_id)
    rescue ApplicationNotFound
      puts "Unable to find marathon task #{application_id}"
      puts 'Valid task names are:'
      puts marathon.available_apps
      exit 1
    end

    raise MesosTaskHasNoHost if hosts.empty?

    mstate = mesos.mesos_state(hosts.first)
    state = mesos.framework_state(mstate, marathon.framework_id)
    dir = mesos.directory_for(state, application_id)
    file_with_inital_offset = mesos.get_file(hosts.first, dir, cmd)

    initial_offset =  file_with_inital_offset['offset']
    offset = initial_offset - data_length
    offset = 0 if offset < 1

    while offset < initial_offset
      file = mesos.get_file(hosts.first,
                            dir,
                            cmd,
                            offset,
                            data_length)
      logs = file['data']
      offset = file['offset'] + logs.size
      line = 0

      logs.lines.each_with_index do |l, i|
        line = i if l.include?('Starting task')
      end

      logs.lines[line + 1, (logs.size - 1)].each { |l|
        puts l
      }
    end
  end
end
