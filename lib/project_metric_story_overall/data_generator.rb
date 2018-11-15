class ProjectMetricStoryOverall
  def self.fake_data
    [fake_metric(0, 5, 2), fake_metric(2, 3, 1), fake_metric(3, 0, 0)]
  end

  def self.fake_metric(good, bad, overall)
    { score: 7 * good + 2 * overall,
      image: {
          chartType: 'story_overall',
          data: {
              story_issues: Array(good) { s_good } + Array(bad) { s_bad },
              overall_issues: Array(overall) { overall_issue }
          }
      }.to_json }
  end

  def self.s_bad
    {
        "kind": "story",
        "id": 566,
        "created_at": 1542110400000,
        "updated_at": 1542110400000,
        "story_type": "feature",
        "name": "Repair CommLink",
        "description": "It's malfunctioning.",
        "current_state": "started",
        "requested_by_id": 104,
        "url": "http://localhost/story/show/566",
        "project_id": 99,
        "owner_ids":
            [
            ],
        "labels":
            [
                {
                    "id": 2011,
                    "project_id": 99,
                    "kind": "label",
                    "name": "mnt",
                    "created_at": 1542110400000,
                    "updated_at": 1542110400000
                }
            ],
        "m_issues":
            [
                {
                    "issue": "Story does not have an estimate.",
                    "severity": 3
                },
                {
                    "issue": "On-going story does not have an owner.",
                    "severity": 3
                },
                {
                    "issue": "Story description is short.",
                    "severity": 1
                }
            ],
        "m_severity": 7,
        "m_num_issues": 3
    }
  end

  def self.s_good
    {
        "kind": "story",
        "id": 555,
        "created_at": 1542110400000,
        "updated_at": 1542110400000,
        "estimate": 2,
        "story_type": "feature",
        "name": "Bring me the passengers",
        "description": "ignore the droids",
        "current_state": "unstarted",
        "requested_by_id": 101,
        "url": "http://localhost/story/show/555",
        "project_id": 99,
        "owner_ids":
            [
            ],
        "labels":
            [
            ],
        "m_issues": [],
        "m_severity": 0,
        "m_num_issues": 0
    }
  end

  def self.overall_issue
    {
        "issue": "Possible duplicated stories: 123456(this is a test) | 234567(this is another test)",
        "severity": 2
    }
  end

end