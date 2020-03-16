require 'http'

# require 'stash/zenodo_replicate'
# resource = StashEngine::Resource.find(785)
# z = Stash::ZenodoReplicate::ZenodoConnection.new(resource: resource, file_collection:)
# The zenodo newversion seems to be editing the same deposition id
# 503933

module Stash
  module ZenodoReplicate

    class ZenodoError < StandardError; end

    class ZenodoConnection

      attr_reader :resource, :file_collection, :deposit_id, :links, :files

      def initialize(resource:, file_collection:)
        @resource = resource
        @file_collection = file_collection

        @http = HTTP.timeout(connect: 30, read: 60).timeout(7200).follow(max_hops: 10)
      end

      # checks that can access API with token and return boolean
      def validate_access
        standard_request(:get, "#{base_url}/api/deposit/depositions")
        true
      rescue ZenodoError
        false
      end

      # this creates a new deposit and adds metadata at the same time and returns the json response if successful, errors if already exists
      def new_deposition
        mg = MetadataGenerator.new(resource: @resource)
        resp = standard_request(:post, "#{base_url}/api/deposit/depositions", json: { metadata: mg.metadata })

        @deposit_id = resp[:id]
        @links = resp[:links]

        # state is unsubmitted at this point
        resp
      end

      # deposition_id is an integer that zenodo gives us on the first deposit
      def new_version_deposition(deposit_id:)
        # POST /api/deposit/depositions/123/actions/newversion
        mg = MetadataGenerator.new(resource: @resource)
        resp = standard_request(:post, "#{base_url}/api/deposit/depositions/#{deposit_id}/actions/newversion")

        raise ZenodoError, "Zenodo response: #{r.status.code}\n#{resp}" unless r.status.success?

        @deposit_id = resp[:id]
        @links = resp[:links]
        @files = resp[:files]

        resp
      end

      def put_metadata
        mg = MetadataGenerator.new(resource: @resource)

        resp = standard_request(:put, @links[:latest_draft], json: { metadata: mg.metadata })

        # {"status"=>400, "message"=>"Validation error.", "errors"=>[{"field"=>"metadata.doi", "message"=>"DOI already exists in Zenodo."}]}

        @deposit_id = resp[:id]
        @links = resp[:links]

        resp
      end

      def get_by_deposition(deposit_id:)
        resp = standard_request(:get, "#{base_url}/api/deposit/depositions/#{deposit_id}")

        @deposit_id = resp[:id]
        @links = resp[:links]
        @files = resp[:files]

        resp
      end

      def delete_files
        resp = standard_request(:get, "#{base_url}/api/deposit/depositions/#{deposit_id}")

        resp[:files].map do |f|
          standard_request(:delete, f[:links][:download])
        end

        @files = [] # now it's empty

        standard_request(:get, "#{base_url}/api/deposit/depositions/#{deposit_id}")
      end

      def send_files
        path = @file_collection.path.to_s
        path << '/' unless path.end_with?('/')

        all_files = Dir["#{path}/**/*"]

        all_files.each do |f|
          short_fn = f[path.length..-1]
          resp = standard_request(:put, "#{links[:bucket]}/#{ERB::Util.url_encode(short_fn)}", body: File.open(f, 'rb'))

          # TODO: check the response digest against the known digest
        end
      end

      def get_files_info
        # right now this is mostly just used for internal testing
        standard_request(:get, links[:bucket])
      end

      def publish
        standard_request(:post, links[:publish])
      end

      private

      def standard_request(method, url, **args)
        my_params = { access_token: APP_CONFIG[:zenodo][:access_token] }.merge(args.fetch(:params, {}))
        my_headers = { 'Content-Type': 'application/json' }.merge(args.fetch(:headers, {}))
        my_args = args.merge(params: my_params, headers: my_headers)

        r = @http.send(method, url, my_args)

        resp = r.parse
        resp = resp.with_indifferent_access if resp.class == Hash

        unless r.status.success?
          raise ZenodoError, "Zenodo response: #{r.status.code}\n#{resp} for \nhttp.#{method} #{url}\n#{resp}"
        end
        resp
      end

      def param_merge(p = {})
        { access_token: APP_CONFIG[:zenodo][:access_token] }.merge(p)
      end

      def base_url
        APP_CONFIG[:zenodo][:base_url]
      end

    end
  end
end
