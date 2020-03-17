module ExceptionHelper
  def self.log_exception_backtrace(exception, line_number_limit=nil)
    curr_line_no=0
    output = ''
    exception.backtrace.each do |bt|
      output << "#{bt}\n" if line_number_limit.nil? || curr_line_no < line_number_limit # report First x lines of stacktrace in log
      curr_line_no += 1
    end

    Rails.logger.error "Stack-Trace for exception: #{exception.class} #{exception.message}\n#{output}"
  end

  def self.log_exception(exception, context)
    Rails.logger.error "#{self.class}: #{exception.class}: #{exception.message}"
    Rails.logger.error "Context: #{context}"
    log_exception_backtrace(exception)
  end

end

