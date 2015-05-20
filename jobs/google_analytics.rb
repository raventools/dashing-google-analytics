require 'google/api_client'
require 'date'

# Update these to match your own apps credentials
service_account_email = ENV['GOOGLE_SERVICE_ACCOUNT_EMAIL']
google_private_key = ENV['GOOGLE_PRIVATE_KEY']
google_private_key_secret = ENV['GOOGLE_PRIVATE_KEY_SECRET']
view_id = ENV['GOOGLE_ANALYTICS_VIEW_ID']

# Get the Google API client
client = Google::APIClient.new(
  application_name: 'Dashing',
  application_version: '0.01'
)

# Load your credentials for the service account
begin
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
  key = OpenSSL::PKey::RSA.new google_private_key, google_private_key_secret
  client.authorization = Signet::OAuth2::Client.new(
    token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
    audience: 'https://accounts.google.com/o/oauth2/token',
    scope: 'https://www.googleapis.com/auth/analytics.readonly',
    issuer: service_account_email,
    signing_key: key
  )
rescue StandardError => e
  puts "\e[33mFor the Google Analytics widget to work, you must complete"\
       " the configuration steps (including a private key).\e[0m"
  puts e.inspect
end

# Start the scheduler
SCHEDULER.every '60m', first_in: 0 do

  # Request a token for our service account
  client.authorization.fetch_access_token!

  # Get the analytics API
  analytics = client.discovered_api('analytics', 'v3')

  # Start and end dates
  start_date = (DateTime.now - 31).strftime('%Y-%m-%d')
  start_date_display = DateTime.parse(start_date).strftime('%-m/%-d/%Y')
  end_date = (DateTime.now - 1).strftime('%Y-%m-%d')
  end_date_display = DateTime.parse(end_date).strftime('%-m/%-d/%Y')

  # Sessions
  sessions = client.execute(
    api_method: analytics.data.ga.get, parameters: {
      'ids' => 'ga:' + view_id,
      'start-date' => start_date,
      'end-date' => end_date,
      'metrics' => 'ga:sessions'
    }
  )
  send_event(
    'ga_sessions',
    current: sessions.data.rows.count > 0 ? sessions.data.rows[0][0] : 0
  )

  # New Sessions
  new_sessions = client.execute(
    api_method: analytics.data.ga.get, parameters: {
      'ids' => 'ga:' + view_id,
      'start-date' => start_date,
      'end-date' => end_date,
      'metrics' => 'ga:sessions',
      'filters' => 'ga:userType==New Visitor'
    }
  )
  send_event(
    'ga_new_sessions',
    current: new_sessions.data.rows.count > 0 ? new_sessions.data.rows[0][0] : 0
  )

  # Traffic Sources
  traffic_sources = client.execute(
    api_method: analytics.data.ga.get, parameters: {
      'ids' => 'ga:' + view_id,
      'start-date' => start_date,
      'end-date' => end_date,
      'metrics' => 'ga:sessions',
      'dimensions' => 'ga:medium',
      'sort' => '-ga:sessions'
    }
  )
  # Reformat for List: Traffic Sources
  traffic_sources_list = traffic_sources.data.rows.map do |row|
    row[0] = row[0][0...50] + ' ...' if row[0].length > 50
    {
      label: row[0],
      value: row[1]
    }
  end
  send_event(
    'ga_traffic_sources',
    items: traffic_sources.data.rows.count > 0 ? traffic_sources_list.take(10) : []
  )

  # Bounce Rate
  bounce_rate = client.execute(
    api_method: analytics.data.ga.get, parameters: {
      'ids' => 'ga:' + view_id,
      'start-date' => start_date,
      'end-date' => end_date,
      'metrics' => 'ga:bounceRate'
    }
  )
  send_event(
    'ga_bounce_rate',
    current: bounce_rate.data.rows.count > 0 ? bounce_rate.data.rows[0][0].to_f.round(2) : 0,
    suffix: '%'
  )

  # Goals
  (1..20).each do |goal_id|
    # Completions
    goal_completions = client.execute(
      api_method: analytics.data.ga.get, parameters: {
        'ids' => 'ga:' + view_id,
        'start-date' => start_date,
        'end-date' => end_date,
        'metrics' => "ga:goal#{goal_id}Completions"
      }
    )
    send_event(
      "ga_goal_#{goal_id}_completions",
      current: goal_completions.data.rows.count > 0 ? goal_completions.data.rows[0][0] : 0
    )

    # Conversion Rate
    goal_conversion_rate = client.execute(
      api_method: analytics.data.ga.get, parameters: {
        'ids' => 'ga:' + view_id,
        'start-date' => start_date,
        'end-date' => end_date,
        'metrics' => "ga:goal#{goal_id}ConversionRate"
      }
    )
    send_event(
      "ga_goal_#{goal_id}_conversion_rate",
      current: goal_conversion_rate.data.rows.count > 0 ? goal_conversion_rate.data.rows[0][0].to_f.round(2) : 0,
      suffix: '%'
    )

    # Completions by Date
    goal_completions_dates = client.execute(
      api_method: analytics.data.ga.get, parameters: {
        'ids' => 'ga:' + view_id,
        'start-date' => start_date,
        'end-date' => end_date,
        'metrics' => "ga:goal#{goal_id}Completions",
        'dimensions' => 'ga:date'
      }
    )
    goal_completions_plot = []
    index = 0
    goal_completions_dates.data.rows.each do |row|
      goal_completions_plot << { x: index, y: row[1].to_i }
      index += 1
    end
    send_event(
      "ga_goal_#{goal_id}_completions_chart",
      points: goal_completions_dates.data.rows.count > 0 ? goal_completions_plot : [],
      moreinfo: "Chart: #{start_date_display} - #{end_date_display}"
    )

  end

  # Sessions by Date
  sessions_dates = client.execute(
    api_method: analytics.data.ga.get, parameters: {
      'ids' => 'ga:' + view_id,
      'start-date' => start_date,
      'end-date' => end_date,
      'metrics' => 'ga:sessions',
      'dimensions' => 'ga:date'
    }
  )
  sessions_dates_plot = []
  index = 0
  sessions_dates.data.rows.each do |row|
    sessions_dates_plot << { x: index, y: row[1].to_i }
    index += 1
  end
  send_event(
    'ga_session_chart',
    points: sessions_dates.data.rows.count > 0 ? sessions_dates_plot : [],
    moreinfo: "Chart: #{start_date_display} - #{end_date_display}"
  )

end
