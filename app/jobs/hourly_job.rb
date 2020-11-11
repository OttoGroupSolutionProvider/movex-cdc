# This Job runs repeats itself permanent and runs once each hour
class HourlyJob < ApplicationJob
  queue_as :default

  def perform(*args)
    HourlyJob.set(wait: 3600.seconds).perform_later unless Rails.env.test?  # Ensure next execution independent from following operations

    # do housekeeping activities
    begin
      Database.set_application_info('HourlyJob/HousekeepingFinalErrors.do_housekeeping')
      HousekeepingFinalErrors.get_instance.do_housekeeping
    rescue Exception => e
      ExceptionHelper.log_exception(e, "HourlyJob.perform: calling HousekeepingFinalErrors.do_housekeeping!")
    end
  end
end