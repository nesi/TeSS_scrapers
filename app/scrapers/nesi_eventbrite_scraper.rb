class NesiEventbriteScraper < Tess::Scrapers::Scraper

  def self.config
    {
        name: 'NeSI Eventbrite scraper',
        search_endpoint: 'https://www.eventbriteapi.com/v3/events/search/',
        # Note the following endpoint is not documented anywhere, I found it here:
        # https://groups.google.com/forum/#!searchin/eventbrite-api/organization|sort:date/eventbrite-api/uubABbdYLOg/ySFGRNN_AgAJ
        # Also note that an `organizer` is not an `organization`
        organizers_events_endpoint: 'https://www.eventbriteapi.com/v3/organizers/%{organizer_id}/events/',
        venue_endpoint: 'https://www.eventbriteapi.com/v3/venues/',
        organizer: '7888366724',
    }
  end

  def scrape

    if !Tess::API.config['eventbrite_key'].nil?
      token = Tess::API.config['eventbrite_key']
      cp = add_content_provider(Tess::API::ContentProvider.new(
          { title: "New Zealand eScience Infrastructure", #name
            url: "https://www.nesi.org.nz/", #url
            image_url: "https://www.nesi.org.nz/sites/default/themes/nesi_bootstrap/img/logo.png", #logo
            description: "NeSI provides a national platform of shared high performance computing tools and eResearch services to New Zealanders", #description
            content_provider_type: :organisation
          }))

      # Get the events by the organizer
      organizer_events_url = (config[:organizers_events_endpoint] % { organizer_id: config[:organizer] }) + "?token=" + token
      event_data = JSON.parse(open_url(organizer_events_url).read)

      #Loop through each event, creating a new event and looking up the venue
      event_data['events'].each do |event_data|
        new_event = Tess::API::Event.new(
            content_provider: cp,
            title: event_data['name']['text'],
            url: event_data['url'],
            start: event_data['start']['local'],
            end: event_data['end']['local'],
            description: event_data['description']['text'],
            organizer: 'NeSI',
            event_types: [:workshops_and_courses]
        )

        if event_data['venue_id']
          venue_url = config[:venue_endpoint] + event_data['venue_id'] + "/?token=" + token
          venue_data = JSON.parse(open_url(venue_url).read)

          new_event.latitude = venue_data['address']['latitude']
          new_event.longitude = venue_data['address']['longitude']
          new_event.venue = /(.*)\sGPS/.match(venue_data['address']['address_1']).to_a.last
          new_event.postcode = venue_data['address']['postal_code']
          new_event.city = venue_data['address']['city']
          new_event.country = venue_data['address']['country']
        end

        add_event(new_event)
      end
    else
      puts 'Please enter an eventbrite_key into the uploader_config.txt'
    end
  end
end
