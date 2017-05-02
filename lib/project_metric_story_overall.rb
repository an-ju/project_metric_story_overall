require "project_metric_story_overall/version"
require "faraday"
require "json"
require "time"

class ProjectMetricStoryOverall
  attr_reader :raw_data

  def initialize(credentials, raw_data = nil)
    @project = credentials[:project]
    @conn = Faraday.new(url: 'https://www.pivotaltracker.com/services/v5')
    @conn.headers['Content-Type'] = 'application/json'
    @conn.headers['X-TrackerToken'] = credentials[:token]

    @raw_data = raw_data
  end

  def image
    refresh unless @raw_data
    { chartType: 'gauge',
      titleText: 'Story Management GPA',
      data: @raw_data }.to_json
  end

  def refresh
    transition_times = []
    stories.each do |s|
      previous_time = nil
      transitions(s['id']).each do |trans|
        tmp_trans_time = Time.parse trans['occurred_at']
        transition_times.push(tmp_trans_time - previous_time) if previous_time
        previous_time = tmp_trans_time
      end
    end
    trans_time_valid = transition_times.select {|tt| tt > 24*3600 }
    @raw_data = { score: (trans_time_valid.length * 4.0 / transition_times.length).round(1) }
  end

  def raw_data=(new)
    @raw_data = new
    @score = nil
    @image = nil
  end

  def score
    refresh unless @raw_data
    @score = @raw_data.length
  end

  def self.credentials
    %I[project token]
  end

  private

  def project
    JSON.parse(
        @conn.get("projects/#{@project}").body
    )
  end

  def stories
    JSON.parse(
        @conn.get("projects/#{@project}/stories").body
    )
  end

  def transitions(story_id)
    JSON.parse(
        @conn.get("projects/#{@project}/stories/#{story_id}/transitions").body
    )
  end
end
