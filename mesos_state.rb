class MesosState
  def initialize(state:)
    @state = state
  end

  def framework_state(framework_id)
    frameworks_info = @state['frameworks'].select{|f| f['id'] == framework_id}
    puts "Found #{frameworks_info.size} framework state" if frameworks_info.size != 1
    frameworks_info.last
  end
end

