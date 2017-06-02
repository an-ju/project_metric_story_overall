require "project_metric_story_overall/version"
require "faraday"
require "json"
require "time"

class ProjectMetricStoryOverall
  attr_reader :raw_data

  def initialize(credentials, raw_data = nil)
    @project = credentials[:tracker_project]
    @conn = Faraday.new(url: 'https://www.pivotaltracker.com/services/v5')
    @conn.headers['Content-Type'] = 'application/json'
    @conn.headers['X-TrackerToken'] = credentials[:tracker_token]

    @raw_data = raw_data
  end

  def refresh
    @image = @score = nil
    @raw_data ||= stories
  end

  def raw_data=(new)
    @raw_data = new
    @score = nil
    @image = nil
  end

  def score
    @raw_data ||= stories
    synthesize
    @score ||= @user_points.values.inject { |s, e| s + e } / @user_points.length.to_f
  end

  def image
    @raw_data ||= stories
    synthesize
    @image ||= { chartType: 'point_distribution',
                 titleText: 'Distribution of points among users',
                 data: { data: @user_points.values, series: @user_points.keys } }.to_json
  end

  def self.credentials
    %I[tracker_project tracker_token]
  end

  private

  def stories
    JSON.parse(@conn.get("projects/#{@project}/stories").body)
  end

  def synthesize
    @user_points = Hash.new(0)
    @raw_data ||= stories
    @raw_data.each do |story|
      story['owner_ids'].each do |owner|
        estimate = story['estimate'] ? story['estimate'] : 0
        @user_points[owner] += estimate
      end
    end
  end

end
