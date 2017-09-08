# frozen_string_literal: true

# == Schema Info
#
# betting_ends_at    datetime  indexed      not null
# betting_starts_at  datetime  indexed      not null
# betting_tier       integer
# id                 integer   primary_key  not null, nextval()
# season             integer   indexed      not null
# week               integer   indexed      not null
#

class Week < Sequel::Model
  class << self
    def current
      now = Time.now
      ds = Week.where(season: now.year).order(:betting_starts_at)

      ds.where{betting_starts_at <= now}.last ||
        ds.first
    end
  end

  dataset_module do
    def for(season = 2017)
      where(season: season).order(:week)
    end
  end

  many_through_many :picks, [
    [:games, :week_id, :id],
    [:odds, :game_id, :id]
  ],
    right_primary_key: :odd_id

  many_to_many :odds, join_table: :games, right_key: :id, right_primary_key: :game_id
  many_to_many :winners, class: :User, join_table: :users_weeks, right_key: :user_id

  one_through_one :winner, class: :User, join_table: :users_weeks, right_key: :user_id

  one_to_many :games, order: :starts_at

  def betting_period?
    Time.now >= betting_starts_at &&
      !betting_ended?
  end

  def betting_ended?
    Time.now > betting_ends_at
  end

  def correct_picks(odd_type = nil)
    return @_correct_picks if defined?(@_correct_picks)
    ds = picks_dataset
    ds = ds.send(odd_type) if odd_type
    ds = ds
      .won
      .select_group(:user_id)
      .select_append{count(:user_id).as(count)}

    @_correct_picks ||= ds.all.each_with_object({}) do |c, h|
      h[c[:count]] ||= []
      h[c[:count]] << c[:user_id]
    end
  end

  def games_finished?
    games_dataset.followed.unfinished.empty?
  end

  def last_week
    Week[id - 1]
  end

  def next_week
    Week[id + 1]
  end

  def picks_for(user)
    picks_dataset.where(user: user).all.each_with_object({}) do |pick, h|
      h[pick.odd_id] = pick.team
    end
  end

  def pot
    return @_pot if defined?(@_pot)
    return unless betting_tier

    buy_in = User.dataset.count * betting_tier
    previous_pot = betting_tier > 1 ? previous_week.pot : 0
    @_pot = buy_in + previous_pot
  end

  def winner!
    Game.update_scores!(id)
    return unless games_finished?

    correct_picks[correct_picks.keys.max].each do |user_id|
      add_winner User[user_id]
    end

    # TODO: Find single winner if winners_dataset.count > 1 and betting_tier == 4

    next_week.update(betting_tier: winner? ? 1 : betting_tier + 1)
  end

  def winner?
    winners_dataset.count == 1
  end
end
