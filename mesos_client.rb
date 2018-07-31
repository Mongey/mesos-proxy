require_relative 'mesos_state'

MesosStateNotFound = Class.new(StandardError)
MesosTaskHasNoHost = Class.new(StandardError)
UnableToGetFile = Class.new(StandardError)

# MesosMarathonClient does things
class MesosClient
  attr_reader :host, :marathon_port

  def initialize(host:, marathon_port: 8080)
    @host = host
    @marathon_port = marathon_port
  end

  def base_url
    "https://web-mesos-proxy.#{@host}"
  end

  def proxy_addr(path)
    "#{base_url}#{path}"
  end

  def mesos_state(agent_addr)
    r = mesos_request('/state.json', agent_addr)
    raise MesosStateNotFound.new(r) unless r.success?
    r.parsed_response
  end

  def mesos_request(path, agent_addr)
    HTTParty.get(proxy_addr(path), headers: { 'X-Agent' => agent_addr} )
  end

  def framework_state(mesos_state, framework_id)
    MesosState.new(state: mesos_state).framework_state(framework_id)
  end

  def directory_for(framework_info, app_name)
    dirs = framework_info['executors']
      .select{|e| e['id'].include?(app_name.split('/').first) && e['id'].include?(app_name.split('/').last)}
      .map{|e| e['directory']}

    puts "Found #{dirs.size} directories : #{dirs}" if dirs.size != 1

    dirs.first
  end

  def get_file(agent_addr, dir, file, offset=-1, length=-1)
    file_location = "/files/read.json?path=#{dir}/#{file}&offset=#{offset}&length=#{length}"
    r = mesos_request(file_location, agent_addr)
    raise UnableToGetFile.new(r) unless r.success?
    r.parsed_response
  end
end
