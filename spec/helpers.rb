# frozen_string_literal: true

module Helpers
  def test_csv
    File.join(File.expand_path(__dir__), 'tmp', 'test.csv')
  end
  def lookup_csv
    File.join(File.expand_path(__dir__), 'tmp', 'lkup.csv')
  end

  

  def generate_csv(rows)
    CSV.open(test_csv, 'w') do |csv|
      rows.each { |row| csv << row }
    end
  end

  def generate_lookup_csv(rows)
    CSV.open(lookup_csv, 'w') do |csv|
      rows.each { |row| csv << row }
    end
  end

  def execute_job(filename:, xform:, csvopt: {}, xformopt: {})
    output_rows = []
    settings = { filename: filename, csv_options: CSVOPT.merge(csvopt) }
    job = Kiba.parse do
      source Kiba::Common::Sources::CSV, settings
      transform(&:to_h)
      transform xform, xformopt
      transform { |row| output_rows << row }
    end

    Kiba.run(job)
    output_rows
  end

  def job_csv(filename:, incsvopt: {}, outcsvopt: {})
    insettings = { filename: filename, csv_options: CSVOPT.merge(incsvopt) }
    outsettings = { filename: filename, csv_options: CSVOPT.merge(outcsvopt) }
    job = Kiba.parse do
      source Kiba::Common::Sources::CSV, insettings
      transform(&:to_h)
      destination Kiba::Common::Destinations::CSV, outsettings
    end
    Kiba.run(job)

    output_rows = []
    job2 = Kiba.parse do
      source Kiba::Common::Sources::CSV, insettings
      transform(&:to_h)
      transform { |row| output_rows << row }
    end
    Kiba.run(job2)
    output_rows
  end
end
