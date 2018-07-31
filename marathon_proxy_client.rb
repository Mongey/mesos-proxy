require 'httparty'

ApplicationNotFound = Class.new(StandardError)

class MarathonProxyClient
  attr_reader :proxy_addr

  def initialize(proxy_addr:)
    @proxy_addr = proxy_addr
  end

  def available_apps
    marathon_request('/v2/apps').parsed_response['apps'].map{|a| a['id'][1..-1]}
  end

  def framework_id
    marathon_request('/v2/info').parsed_response['frameworkId']
  end

  def hosts_task_is_running_on(task)
    application_information(task)['app']['tasks'].map{|t| t['host']}
  end

  def application_information(task)
    r = marathon_request("/v2/apps/#{task}")
    raise ApplicationNotFound.new(r) unless r.success?
    r.parsed_response
  end

  def marathon_request(path)
    HTTParty.get(@proxy_addr + path,
                 headers: marathon_headers)
  end

  def marathon_headers
    {
      'X-Agent' => 'marathon.service.consul',
      'X-Port' => '8080'
    }
  end
end

