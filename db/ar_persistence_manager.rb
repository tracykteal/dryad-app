require 'active_record'
require 'stash/persistence_manager'
require_relative 'models'

module Stash
  # PersistenceManager using ActiveRecord
  class ARPersistenceManager < PersistenceManager
    include Harvester::Models

    def initialize(connection_pool)
      @pool = connection_pool
    end

    def db_status_for(index_status)
      case index_status
      when Indexer::IndexStatus::COMPLETED
        Status::COMPLETED
      when Indexer::IndexStatus::FAILED
        Status::FAILED
      else
        raise ArgumentError("Unknown index status: #{index_status}")
      end
    end

    def begin_harvest_job(from_time: nil, until_time: nil, query_url:)
      @pool.with_connection do
        return HarvestJob.create(
          from_time: from_time,
          until_time: until_time,
          query_url: query_url,
          start_time: Time.now,
          status: Status::IN_PROGRESS
        ).id
      end
    end

    def record_harvested_record(harvest_job_id:, identifier:, timestamp:, deleted: false)
      @pool.with_connection do
        HarvestedRecord.create(
          harvest_job_id: harvest_job_id,
          identifier: identifier,
          timestamp: timestamp,
          deleted: deleted
        )
      end
    end

    def end_harvest_job(harvest_job_id:, status:)
      @pool.with_connection do
        HarvestJob.find_by(id: harvest_job_id).update(
          end_time: Time.now,
          status: db_status_for(status)
        )
      end
    end

    def begin_index_job(harvest_job_id:, solr_url:)
      @pool.with_connection do
        return IndexJob.create(
          harvest_job_id: harvest_job_id,
          solr_url: solr_url,
          start_time: Time.now,
          status: Status::IN_PROGRESS
        ).id
      end
    end

    def record_indexed_record(index_job_id:, harvested_record_id:, status:)
      @pool.with_connection do
        IndexedRecord.create(
          index_job_id: index_job_id,
          harvested_record_id: harvested_record_id,
          submitted_time: Time.now, # TODO: is this right?
          status: db_status_for(:status)
        )
      end
    end

    def end_index_job(index_job_id:, status:)
      @pool.with_connection do
        IndexJob.find_by(id: index_job_id).update(
          end_time: Time.now,
          status: db_status_for(status)
        )
      end
    end
  end
end
