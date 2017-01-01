require 'rails_helper'

describe GithubStarWorker do
  it "should use the low priority queue" do
    is_expected.to be_processed_in :low
  end

  it "should update from star" do
    repo_full_name = 'rails/rails'
    expect(GithubRepository).to receive(:update_from_star).with(repo_full_name, nil)
    subject.perform(repo_full_name)
  end
end
