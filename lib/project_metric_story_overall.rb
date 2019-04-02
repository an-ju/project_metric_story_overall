require "project_metric_story_overall/version"
require 'project_metric_story_overall/data_generator'
require "faraday"
require "json"
require "time"
require 'project_metric_base'

class ProjectMetricStoryOverall
  include ProjectMetricBase
  add_credentials %I[tracker_project tracker_token]
  add_raw_data %w[tracker_stories tracker_memberships]

  def initialize(credentials, raw_data = nil)
    @project = credentials[:tracker_project]
    @conn = Faraday.new(url: 'https://www.pivotaltracker.com/services/v5')
    @conn.headers['Content-Type'] = 'application/json'
    @conn.headers['X-TrackerToken'] = credentials[:tracker_token]

    complete_with raw_data
    analyze_issues
  end

  def score
    @issues.inject(0) { |sum, s| sum + s[:m_severity] } + @overall_issues.inject(0) { |sum, s| sum + s[:severity] }
  end

  def image
    { chartType: 'story_overall',
      data: { story_issues: @issues,
              overall_issues: @overall_issues }}
  end

  def obj_id
    nil
  end

  private

  def tracker_stories
    @tracker_stories = JSON.parse(@conn.get("projects/#{@project}/stories").body)
  end

  def tracker_memberships
    @tracker_memberships = JSON.parse(@conn.get("projects/#{@project}/memberships").body)
  end

  def analyze_issues
    @issues = backlog_stories.map do |s|
      sissues = story_issues(s)
      s.update(m_issues: sissues,
               m_num_issues: sissues.length,
               m_severity: sissues.inject(0) { |sum, elem| sum + elem[:severity] })
    end
    @overall_issues = stories_issues(backlog_stories)
  end

  def backlog_stories
    @tracker_stories.select { |s| %w[unstarted planned started finished delivered].include? s['current_state'] }
  end

  def stories_issues(slist)
    issues = []
    duplicate_stories(slist).each do |s1, s2|
      issues.push(issue: "Possible duplicated stories: #{s1['id']}(#{s1['name']}) | #{s2['id']}(#{s2['name']})", severity: 2)
    end
    issues
  end

  def story_issues(s)
    issues = []
    issues.push(issue: 'Story does not have an estimate.', severity: 3) if not_assigned?(s)
    issues.push(issue: 'Story description is short.', severity: 1) if short_description(s)
    issues
  end

  def duplicate_stories(slist)
    duplicate_list = []
    bows = slist.map { |s| s['name'].split(' ') }
    bows.each_with_index do |bow_a, ind_a|
      bows[(ind_a+1)..-1].each.with_index(ind_a+1) do |bow_b, ind_b|
        duplicate_list.push([slist[ind_a], slist[ind_b]]) if similarity(bow_a, bow_b) > 0.8
      end
    end
    duplicate_list
  end

  def similarity(bow_a, bow_b)
    # An implementation in https://stackoverflow.com/questions/37800483/intersections-and-unions-in-ruby-for-sets-with-repeated-elements
    intersection = (bow_a | bow_b).flat_map { |wd| [wd] * [bow_a.count(wd), bow_b.count(wd)].min }
    [intersection.length / bow_b.length.to_f, intersection.length / bow_a.length.to_f].max
  end

  def not_pointed?(s)
    s['story_type'].eql? 'feature' && s['estimate'].nil?
  end

  def not_assigned?(s)
    s['owner_ids'].empty? && %w[started finished delivered].include?(s['current_state'])
  end

  def not_labelled(s)
    s['labels'].empty?
  end

  def short_description(s)
    s['description'].nil? || s['description'].length < 50
  end

end
