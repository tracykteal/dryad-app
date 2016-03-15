require 'stash/harvester'
require 'stash/indexer'

module Stash
  class HarvestAndIndexJob
    attr_reader :harvest_task
    attr_reader :indexer

    def initialize(source_config:, index_config:, metadata_mapper:, from_time: nil, until_time: nil)
      @harvest_task = source_config.create_harvest_task(from_time: from_time, until_time: until_time)
      @indexer = index_config.create_indexer(metadata_mapper)
    end

    def harvest_and_index
      harvested_records = harvest_task.harvest_records
      indexer.index(harvested_records) do |result|
        yield result if block_given?
      end
    end
  end
end
