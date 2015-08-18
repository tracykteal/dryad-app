require 'active_record'
require_relative 'status'
require_relative 'harvest_job'

module Stash
  module Harvester
    module Models
      class HarvestedRecord < ActiveRecord::Base
        belongs_to :harvest_job
        has_many :indexed_records

        # TODO: test me
        def self.find_last_indexed
          require_relative 'indexed_record'

          HarvestedRecord.joins(IndexedRecord.where(status: :completed))
            .order(timestamp: :desc)
            .first

          # completed = IndexedRecord.completed
          # harvested = HarvestedRecord.order(timestamp: :desc)
          #
          # completed.joins(harvested).first

          # IndexedRecord.completed.
          #   joins(:harvested_records).
          #   order(harvested_records[:timestamp].
          #           desc)

          # IndexedRecord.find_by(status: :completed)
          # joins(:indexed_records).where(indexed_records: { status: :completed }).first

          # joins(:indexed_records).
          #   where(indexed_records: { status: :completed }).
          #   order(timestamp: :desc).
          #   first

          # joins(:indexed_records).
          #   where(:indexed_records[:status].
          #           eq(IndexedRecord.statuses[:completed])).
          #   order(timestamp: :desc).first
        end

        # TODO: test me
        def self.find_first_failed
          joins(:indexed_records).where(:indexed_records[:status].eq(IndexedRecord.statuses[:failed])).order(:timestamp).last
        end
      end
    end
  end
end
