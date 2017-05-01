require "project_metric_story_overall/version"
require "faraday"
require "json"

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
    { chartType: 'd3',
      titleText: 'Story Lifecycle',
      data: @raw_data }.to_json
  end

  def refresh
    @raw_data = {transitions: [], stories: []}
    stories.each do |s|
      trans = transitions s['id']
      unless trans.empty?
        @raw_data[:transitions] << trans
        @raw_data[:stories] << s
      end
    end
    @raw_data[:transitions] = @raw_data[:transitions].flatten
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
