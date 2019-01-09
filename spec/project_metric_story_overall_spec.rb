require "spec_helper"

RSpec.describe ProjectMetricStoryOverall do
  context 'meta data' do
    it "has a version number" do
      expect(ProjectMetricStoryOverall::VERSION).not_to be nil
    end
  end

  context 'image and score' do
    subject(:metric) do
      credentials = {tracker_project: '2154341', tracker_token: 'test token'}
      raw_data = JSON.parse(File.read('spec/data/stories_memberships.json'))
      described_class.new credentials, raw_data
    end

    it 'should restore raw data' do
      expect(metric.instance_variable_get(:@tracker_stories)).not_to be_nil
      expect(metric.instance_variable_get(:@tracker_memberships)).not_to be_nil
    end

    it 'should set score correctly' do
      expect(metric.score).not_to be_nil
    end

    it 'should set image correctly' do
      expect(metric.image).to be_a(Hash)
    end

    it 'should contain the right image content' do
      image = metric.image
      expect(image[:data][:story_issues]).not_to be_nil
      expect(image[:data][:overall_issues]).not_to be_nil
    end

  end


  context 'stories metric' do
    subject(:metric) do
      credentials = {tracker_project: '2154341', tracker_token: 'test token'}
      raw_data = JSON.parse(File.read('spec/data/stories_memberships.json'))
      described_class.new credentials, raw_data
    end

    it 'should calculate the right duplication metric' do
      bow_a = ['this', 'is', 'a', 'test']
      bow_b = ['this', 'is', 'another', 'test']
      bow_c = ['this', 'is', 'a', 'new', 'test']
      expect(metric.send(:similarity, bow_a, bow_b)).to eql(3.0 / 4.0)
      expect(metric.send(:similarity, bow_a, bow_c)).to eql(1.0)
    end


    it 'should return the right duplicate list' do
      s1 = double('s1')
      allow(s1).to receive(:[]).and_return('this is a test')
      s2 = double('s2')
      allow(s2).to receive(:[]).and_return('this is another test')
      s3 = double('s3')
      allow(s3).to receive(:[]).and_return('this is a new test')

      expect(metric.send(:duplicate_stories, [s1, s2, s3])).to eql([[s1, s3]])
    end

    it 'should capture skipped stories' do
      s1 = double('s1')
      allow(s1).to receive(:[]).and_return('started')
      s2 = double('s2')
      allow(s2).to receive(:[]).and_return('unstarted')
      s3 = double('s3')
      allow(s3).to receive(:[]).and_return('started')
      s4 = double('s4')
      allow(s4).to receive(:[]).and_return('unstarted')

      expect(metric.send(:skipped_stories, [s1, s2, s3, s4])).to eql([s2])
    end
  end

  context 'data generator' do
    it 'should generate fake data' do
      expect(described_class.fake_data.length).to eql(3)
      expect(described_class.fake_data.first).to have_key(:image)
      expect(described_class.fake_data.first).to have_key(:score)
    end

    it 'should set image data correctly' do
      image = described_class.fake_data.first[:image]
      expect(image[:data][:story_issues]).not_to be_nil
      expect(image[:data][:overall_issues]).not_to be_nil
    end
  end
end
