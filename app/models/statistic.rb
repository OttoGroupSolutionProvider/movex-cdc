class Statistic < ApplicationRecord
  belongs_to  :table

  def self.write_record(attribs)
    attribs[:events_success]          = 0 if attribs[:events_success].nil?
    attribs[:events_delayed_errors]   = 0 if attribs[:events_delayed_errors].nil?
    attribs[:events_final_errors]     = 0 if attribs[:events_final_errors].nil?
    attribs[:events_d_and_c_retries]  = 0 if attribs[:events_d_and_c_retries].nil?
    attribs[:events_delayed_retries]  = 0 if attribs[:events_delayed_retries].nil?

    stat = Statistic.new(attribs.merge({end_timestamp: Time.now}))
    stat.save!
  rescue Exception => e
    ExceptionHelper.log_exception(e, 'Statistic.write_record')                  # No further escalation if write failes
  end

  private

end
