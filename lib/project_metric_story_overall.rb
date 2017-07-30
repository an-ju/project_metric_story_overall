require "project_metric_story_overall/version"
require "faraday"
require "json"
require "time"

class ProjectMetricStoryOverall
  attr_reader :raw_data

  STORY_STATES = %I[unscheduled unstarted started finished delivered rejected accepted]
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
    @score ||= undelivered_stories > 0 ? ongoing_stories.to_f / undelivered_stories.to_f : 0
  end

  def image
    @raw_data ||= stories
    synthesize
    @image ||= { chartType: 'story_overall_v2',
                 titleText: 'Status of Stories',
                 data: {
                   data: STORY_STATES.map { |state| @story_status[state] },
                   series: STORY_STATES
                 } }.to_json
  end

  def self.credentials
    %I[tracker_project tracker_token]
  end

  private

  def stories
    JSON.parse(@conn.get("projects/#{@project}/stories").body)
  end

  def synthesize
    @raw_data ||= stories
    @story_status = @raw_data.inject(Hash.new(0)) do |sum, story|
      sum[story['current_state'].to_sym] += 1
      sum
    end
  end

  def ongoing_stories
    %I[started delivered].inject(0) { |sum, state| sum + @story_status[state] }
  end

  def undelivered_stories
    %I[unscheduled unstarted started delivered].inject(0) { |sum, state| sum + @story_status[state] }
  end

end
