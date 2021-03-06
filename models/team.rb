# frozen_string_literal: true

# == Schema Info
#
# abbreviation  string   indexed      not null
# id            integer  primary_key  not null, nextval()
# name          string   indexed      not null
#

class Team < Sequel::Model
  class << self
    %w(push over under).each do |field|
      define_method(field) { Team.first(name: field.capitalize) }
    end

    def by_id
      all.each_with_object({}) { |t, h| h[t.id] = t }
    end
  end

  def abb
    abbreviation
  end

  def icon_name
    case name
    when 'Over'
      'arrow-circle-up'
    when 'Under'
      'arrow-circle-down'
    when 'Push'
      'arrows-h'
    end
  end

  def logo_url
    "/images/team_logos/#{abb}.png"
  end
end
