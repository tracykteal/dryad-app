# This migration comes from stash_datacite (originally 20150918183953)
class CreateDcsRelationTypes < ActiveRecord::Migration
  def change
    create_table :dcs_relation_types do |t|
      t.string :relation_type
      t.string :related_metadata_scheme
      t.text   :scheme_URI
      t.string :scheme_type

      t.timestamps null: false
    end
  end
end