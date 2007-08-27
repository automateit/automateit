require 'logger'

class QueuedLogger < Logger
  def initialize(*args)
    super(*args)
    @queue = []
    @emitted = false
  end

  def process_queue
    if queued?
      while true
        entry = @queue.shift or break
        severity, message = entry
        raw_method = "#{severity}_without_queue"
        severity_i = self.class.send(:const_get, severity.to_s.upcase)
        send(raw_method, message)
      end
    end
  end

  def enqueue(level, message)
    @queue << [level, message]
    @emitted = false
  end

  def dequeue(level=nil, message=nil)
    if queued?
      @queue.clear
    elsif level and message
      send("%s_without_queue"%level, message) if @emitted
    end
    @emitted = false
  end

  def queued?
    ! @queue.empty?
  end

  for level in %w(debug info warn error fatal) do
    class_eval <<-EOB
      def #{level}_with_queue(*args)
        severity = self.class.send(:const_get, "#{level.upcase}")
        process_queue if severity >= self.level
        @emitted = true
        #{level}_without_queue(*args)
      end
      alias_method_chain :#{level}, :queue
    EOB
  end

end

if __FILE__ == $0
  # FIXME write spec

  q = QueuedLogger.new($stdout)
  q.level = Logger::INFO
  q.info("first message")
  q.enqueue(:info, "queued message that'll be pushed")
  q.info("second message, which pushed out queued message")
  q.enqueue(:error, "ERROR: queued message that'll be discarded")
  q.debug("ERROR: message that'll be discarded and won't push queue")
  q.dequeue(:error, "ERROR: dequeue message that'll be discarded")
  q.enqueue(:info, "queued message that'll be pushed")
  q.info("message that'll push out the queue and dequeue messages")
  q.dequeue(:info, "dequeue message that'll be pushed")
end
