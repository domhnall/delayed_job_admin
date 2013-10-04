module DelayedJobAdmin
  class QueueChecker
    attr_reader :queue_thresholds

    def initialize(queue_thresholds)
      raise ArgumentError, instantiation_error_message unless (queue_thresholds && queue_thresholds.is_a?(Hash))
      @queue_thresholds = queue_thresholds
    end

    def check_queues
      queue_thresholds.each do |queue_name, threshold|
        alert = check_queue_against_threshold(queue_name, threshold)
        raise_queue_alert(alert) if alert
      end
    end

    def check_queue_against_threshold(queue_name, threshold)
      queue_depth = Delayed::Job.where(queue: queue_name).count
      (queue_depth > threshold) ? DelayedJobAdmin::QueueAlert.new(queue_name, queue_depth) : nil
    end

    def raise_queue_alert(alert)
      DelayedJobAdmin::alert_strategies.each do |clazz, options|
        clazz.new(alert, options).alert
      end
    end

    private

    def instantiation_error_message
      'QueueChecker must be instantiated with a Hash representing the configured alert thresholds for different queues'
    end
  end
end
