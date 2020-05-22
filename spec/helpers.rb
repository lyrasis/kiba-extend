module Helpers
  def generate_csv(path, rows)
    CSV.open(path, 'w') do |csv|
      rows.each{ |row| csv << row }
    end
  end

  def execute_job(filename:, csvopt: {} , xform:, xformopt: {})
    output_rows = []
    settings = {filename: filename, csv_options: CSVOPT.merge(csvopt)}
    job = Kiba.parse do
      source Kiba::Common::Sources::CSV, settings
      transform{ |r| r.to_h }
      transform xform, xformopt
      transform { |row| output_rows << row }
    end

    Kiba.run(job)
    output_rows
  end

  def job_csv(filename:, incsvopt: {}, outcsvopt: {})
    insettings = {filename: filename, csv_options: CSVOPT.merge(incsvopt)}
    outsettings = {filename: filename, csv_options: CSVOPT.merge(outcsvopt)}
    job = Kiba.parse do
      source Kiba::Common::Sources::CSV, insettings
      transform{ |r| r.to_h }
      destination Kiba::Common::Destinations::CSV, outsettings
    end
    Kiba.run(job)

    output_rows = []
    job2 = Kiba.parse do
      source Kiba::Common::Sources::CSV, insettings
      transform{ |r| r.to_h }
      transform { |row| output_rows << row }
    end
    Kiba.run(job2)
    output_rows
  end

end
