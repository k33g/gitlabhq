module API
  class Geo < Grape::API
    before { authenticated_as_admin! }

    resource :geo do
      # Enqueue a batch of IDs of modified projects to have their
      # repositories updated
      #
      # Example request:
      #   POST /geo/refresh_projects
      post 'refresh_projects' do
        required_attributes! [:projects]
        ::Geo::ScheduleRepoUpdateService.new(params[:projects]).execute
      end

      # Enqueue a batch of IDs of wiki's projects to have their
      # wiki repositories updated
      #
      # Example request:
      #   POST /geo/refresh_wikis
      post 'refresh_wikis' do
        required_attributes! [:projects]
        ::Geo::ScheduleWikiRepoUpdateService.new(params[:projects]).execute
      end

      # Receive event streams from primary and enqueue changes
      #
      # Example request:
      #   POST /geo/receive_events
      post 'receive_events' do
        required_attributes! %w(event_name)

        case params['event_name']
        when 'key_create', 'key_destroy'
          required_attributes! %w(key id)
          ::Geo::ScheduleKeyChangeService.new(params).execute
        end
      end
    end
  end
end
