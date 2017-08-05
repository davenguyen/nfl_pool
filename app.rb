require_relative 'models'

require 'roda'
require 'pry'

class NFLPool < Roda
  opts[:unsupported_block_result] = :raise
  opts[:unsupported_matcher] = :raise
  opts[:verbatim_string_matcher] = true

  plugin :default_headers,
    'Content-Type'=>'text/html',
    'Content-Security-Policy'=>"default-src 'self' https://oss.maxcdn.com/ https://maxcdn.bootstrapcdn.com https://ajax.googleapis.com",
    #'Strict-Transport-Security'=>'max-age=16070400;', # Uncomment if only allowing https:// access
    'X-Frame-Options'=>'deny',
    'X-Content-Type-Options'=>'nosniff',
    'X-XSS-Protection'=>'1; mode=block'

  use Rack::Session::Cookie,
    :key => '_NFLPool_session',
    #:secure=>!TEST_MODE, # Uncomment if only allowing https:// access
    :secret=>File.read('.session_secret')

  plugin :assets,
    css: %w[bootstrap.min.css font-awesome.min.css adminlte.min.css adminlte-red.min.css nfl_pool.sass],
    js: %w[jquery.min.js jquery-ui.min.js bootstrap.min.js adminlte.min.js]
  plugin :csrf
  plugin :render, engine: :haml
  plugin :multi_route
  plugin :static, %w[/fonts /images]

  compile_assets

  Unreloader.require('routes'){}

  route do |r|
    r.assets
    r.multi_route

    r.root do
      view 'index'
    end

    r.on 'picks', method: :get do
      default_week = Week.current.week
      current_week_path = "/picks/#{default_week}"

      r.is Integer do |week|
        @week = Week.first(season: 2017, week: week)
        @week ? view('picks') : r.redirect(current_week_path)
      end

      r.is '' do
        r.redirect current_week_path
      end

      r.is do
        r.redirect current_week_path
      end
    end
  end
end
