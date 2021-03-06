# frozen_string_literal: true

require_relative 'presenter'

module StashApi
  class Dataset
    include StashApi::Presenter

    def initialize(identifier:, user: nil)
      id_type, iden = identifier.split(':', 2)
      @se_identifier = StashEngine::Identifier.where(identifier_type: id_type, identifier: iden).first
      @user = user
    end

    def last_se_resource
      @se_identifier.latest_viewable_resource(user: @user)
    end

    def last_version
      res = last_se_resource
      return nil unless res

      Version.new(resource_id: res.id)
    end

    def metadata
      # gets descriptive metadata together
      lv = last_version
      return simple_identifier if lv.nil?

      id_size_hsh = id_and_size_hash
      metadata = id_size_hsh.merge(lv.metadata)
      add_edit_link!(metadata, lv)

      # gives the links to nearby objects
      { '_links': links }.merge(metadata).recursive_compact
    end

    def versions_path
      # rails will not encode an id wish slashes automatically, and encoding it results in double-encoding
      path = api_url_helper.dataset_versions_path('foobar')
      path.gsub('foobar', CGI.escape(@se_identifier.to_s))
    end

    def version_path
      res = last_se_resource
      return nil unless res

      api_url_helper.version_path(res.id)
    end

    def self_path
      # rails will not encode an id wish slashes automatically, and encoding it results in double-encoding
      path = api_url_helper.dataset_path('foobar')
      path.gsub('foobar', CGI.escape(@se_identifier.to_s))
    end

    def download_uri
      # rails will not encode an id with slashes automatically, and encoding it results in double-encoding
      return nil unless @se_identifier.latest_viewable_resource(user: @user)

      path = api_url_helper.download_dataset_path('foobar')
      path.gsub('foobar', CGI.escape(@se_identifier.to_s))
    end

    def links
      {
        self: { href: self_path },
        'stash:versions': { href: versions_path },
        'stash:version': { href: version_path },
        'stash:download': { href: download_uri }
      }.merge(stash_curie)
    end

    private

    # a simple identifier without any versions, indicates that we created
    # an identifier that cannot be viewed
    def simple_identifier
      {
        identifier: @se_identifier.to_s,
        id: @se_identifier.id,
        message: 'identifier cannot be viewed, may be missing required elements'
      }
    end

    def id_and_size_hash
      {
        identifier: @se_identifier.to_s,
        id: @se_identifier.id,
        storage_size: @se_identifier.storage_size
      }
    end

    def add_edit_link!(hsh, version)
      hsh[:editLink] = "/stash/edit/#{CGI.escape(@se_identifier.to_s)}" if version.resource.permission_to_edit?(user: @user)
    end

  end
end
