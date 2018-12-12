require_dependency 'stash_datacite/application_controller'
require 'httparty'

module StashDatacite
  class PublicationsController < ApplicationController
    include HTTParty

    # rubocop:disable Metrics/AbcSize
    def update
      @se_id = StashEngine::Identifier.find(params[:internal_datum][:identifier_id])
      @pub_issn = StashEngine::InternalDatum.find_by(stash_identifier: @se_id, data_type: 'publicationISSN')
      @pub_issn = StashEngine::InternalDatum.new(stash_identifier: @se_id, data_type: 'publicationISSN') if @pub_issn.nil?

      @msid = StashEngine::InternalDatum.find_by(stash_identifier: @se_id, data_type: 'manuscriptNumber')
      @msid = StashEngine::InternalDatum.new(stash_identifier: @se_id, data_type: 'manuscriptNumber') if @msid.nil?
      respond_to do |format|
        format.js { render template: 'stash_datacite/shared/update.js.erb' } if @pub_issn.update(value: params[:internal_datum][:publication_issn])
        format.js { render template: 'stash_datacite/shared/update.js.erb' } if @msid.update(value: params[:internal_datum][:msid])
      end
    end

    # rubocop:disable Metrics/MethodLength
    def autofill_data
      @id = params[:id]
      @se_id = StashEngine::Identifier.find(StashEngine::Resource.find(params[:id]).identifier_id)
      @pub_issn = StashEngine::InternalDatum.find_by(stash_identifier: @se_id, data_type: 'publicationISSN').value
      @msid = StashEngine::InternalDatum.find_by(stash_identifier: @se_id, data_type: 'manuscriptNumber').value
      body = { dryadDOI: 'doi:' + @se_id.identifier,
               dashUserID: current_user.id,
               manuscriptNumber: @msid }.to_json
      url = APP_CONFIG.old_dryad_url + '/api/v1/journals/' + @pub_issn + '/packages/'
      @results = HTTParty.put(url,
                              query: { access_token: APP_CONFIG.old_dryad_access_token },
                              body: body,
                              headers: { 'Content-Type' => 'application/json' })
      redirect_to :back
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

  end
end