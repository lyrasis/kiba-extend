# frozen_string_literal: true

require "spec_helper"
class DynoSrcJob
  include Kiba::Extend::Jobs::DynamicJobable

  def source = :dynamic_src

  def destination = :dynamic_dest

  def job_code
    CSV.open(
      destination_path, "w",
      headers: ["Name", "Value"],
      write_headers: true
    ) do |csv|
      csv << ["Foo", 0]
      csv << ["Bar", 1]
      csv << ["Baz", 2]
    end
  end

  def outrows
    table = CSV.parse(File.read(destination_path), headers: true)
    table.size
  end
end

class AttrJob
  include Kiba::Extend::Jobs::DynamicJobable

  attr_reader :source, :destination

  def initialize(src:, dest:)
    @source = src
    @destination = dest
  end

  def job_code
    File.open(destination_path, "w") do |f|
      f << File.read(source_path)
        .chomp
        .reverse
    end
  end

  def outrows
    table = CSV.parse(File.read(destination_path), headers: true)
    table.size
  end
end

RSpec.describe "Kiba::Extend::Jobs::DynamicJobable" do
  before(:all) do
    reg = Kiba::Extend::Registry::FileRegistry.new
    Kiba::Extend.config.registry = reg
    @dest_file = File.join(fixtures_dir, "dynamic_job_dest.csv")
    @attr_file = File.join(fixtures_dir, "attr_job_dest.csv")
    entries = {
      dynamic_src: {
        dynamic_source: true,
        desc: "None"
      },
      dynamic_dest: {
        path: @dest_file,
        creator: DynoSrcJob.method(:new)
      },
      attr_dest: {
        path: @attr_file,
        creator: {
          callee: AttrJob.method(:new),
          args: {src: :dynamic_dest, dest: :attr_dest}
        }
      }
    }
    populate_registry(more_entries: entries)
    transform_registry
  end
  after(:all) { Kiba::Extend.reset_config }

  before(:each) do
    FileUtils.rm(@dest_file) if File.exist?(@dest_file)
    FileUtils.rm(@attr_file) if File.exist?(@attr_file)
  end

  after(:each) do
    FileUtils.rm(@dest_file) if File.exist?(@dest_file)
    FileUtils.rm(@attr_file) if File.exist?(@attr_file)
  end

  it "runs with dynamic source and produces expected result" do
    creator = Kiba::Extend.registry.resolve(:dynamic_dest).creator
    creator.call
    result = CSV.parse(File.read(@dest_file), **Kiba::Extend.csvopts)
    expect(result.headers).to eq(%i[name value])
  end

  it "runs with static source and produces expected result" do
    creator = Kiba::Extend.registry.resolve(:attr_dest).creator
    creator.call
    result = CSV.parse(File.read(@dest_file), **Kiba::Extend.csvopts)
    expect(result[2].to_a.map { |arr| arr[1].reverse }.join(", ")).to eq(
      "zaB, 2"
    )
  end
end
