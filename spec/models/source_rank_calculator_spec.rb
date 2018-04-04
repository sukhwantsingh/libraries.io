require 'rails_helper'

describe SourceRankCalculator do
  let(:project) { build(:project) }
  let(:calculator) { SourceRankCalculator.new(project) }

  describe "#overall_score" do
    it "should be the average of all category scores" do
      allow(calculator).to receive(:popularity_score) { 10 }
      allow(calculator).to receive(:community_score) { 20 }
      allow(calculator).to receive(:quality_score) { 30 }
      allow(calculator).to receive(:dependencies_score) { 40 }

      expect(calculator.overall_score).to eq(25)
    end

    it "should be the rounded to an integer" do
      allow(calculator).to receive(:popularity_score) { 10 }
      allow(calculator).to receive(:community_score) { 20 }
      allow(calculator).to receive(:quality_score) { 30 }
      allow(calculator).to receive(:dependencies_score) { 41 }

      expect(calculator.overall_score).to eq(25)
    end
  end

  describe '#basic_info_score' do
    let(:repository) { create(:repository) }
    let!(:readme) { create(:readme, repository: repository) }

    context "if all basic info fields are present" do
      let!(:project) { build(:project, repository: repository,
                                       description: 'project description',
                                       homepage: 'http://homepage.com',
                                       repository_url: 'https://github.com/foo/bar',
                                       keywords_array: ['foo', 'bar', 'baz'],
                                       normalized_licenses: ['MIT']) }
      it "should be 100" do
        expect(calculator.basic_info_score).to eq(100)
      end
    end

    context "if none of the basic info fields are present" do
      let!(:project) { build(:project, description: '',
                                        homepage: '',
                                        repository_url: '',
                                        keywords_array: [],
                                        normalized_licenses: []) }
      it "should be 0" do
        expect(calculator.basic_info_score).to eq(0)
      end
    end
  end

  describe '#contribution_docs_score' do
    let!(:project) { build(:project, repository: repository) }

    context "if all contribution docs are present" do
      let(:repository) { create(:repository, has_coc: 'CODE_OF_CONDUCT',
                                             has_contributing: 'contributing.md',
                                             has_changelog: 'changelog.md') }
      it "should be 100" do
        expect(calculator.contribution_docs_score).to eq(100)
      end
    end

    context "if none of the contribution docs are present" do
      let(:repository) { create(:repository, has_coc: '',
                                             has_contributing: nil,
                                             has_changelog: '') }
      it "should be 0" do
        expect(calculator.contribution_docs_score).to eq(0)
      end
    end
  end

  describe '#dependencies_count_score' do
    context "if project doesn't have any versions" do
      it "should be 100" do
        allow(calculator).to receive(:has_versions?) { false }
        expect(calculator.dependencies_count_score).to eq(100)
      end
    end

    context "if project has over 100 dependencies" do
      it "should be 0" do
        allow(calculator).to receive(:has_versions?) { true }
        allow(calculator).to receive(:direct_dependencies) { (1..101).to_a }
        expect(calculator.dependencies_count_score).to eq(0)
      end
    end

    context "if project has less than 100 dependencies" do
      it "should be one lower for every dep" do
        allow(calculator).to receive(:has_versions?) { true }
        allow(calculator).to receive(:direct_dependencies) { (1..10).to_a }
        expect(calculator.dependencies_count_score).to eq(90)
      end
    end
  end

  describe '#dependent_projects_score' do
    context "passing max_dependent_projects on init" do
      it "should use passed in value" do
        calculator = SourceRankCalculator.new(project, max_dependent_projects: 1001)

        allow(project).to receive(:dependents_count) { 1001 }

        expect(calculator.dependent_projects_score).to eq(100)
      end
    end

    context "if it has the highest number of dependent projects in its ecosystem" do
      it "should be 100" do
        allow(project).to receive(:dependents_count) { 999 }
        allow(calculator).to receive(:max_dependent_projects) { 999 }

        expect(calculator.dependent_projects_score).to eq(100)
      end
    end

    context "if it doesn't have the highest number of dependent projects in its ecosystem" do
      it "should be a percentage of the highest" do
        allow(project).to receive(:dependents_count) { 50 }
        allow(calculator).to receive(:max_dependent_projects) { 100 }

        expect(calculator.dependent_projects_score).to eq(50)
      end
    end
  end

  describe '#dependent_repos_count' do
    context "passing max_dependent_repositories on init" do
      it "should use passed in value" do
        calculator = SourceRankCalculator.new(project, max_dependent_repositories: 1001)

        allow(project).to receive(:dependent_repos_count) { 1001 }

        expect(calculator.dependent_repositories_score).to eq(100)
      end
    end

    context "if it has the highest number of dependent projects in its ecosystem" do
      it "should be 100" do
        allow(project).to receive(:dependent_repos_count) { 999 }
        allow(calculator).to receive(:max_dependent_repositories) { 999 }

        expect(calculator.dependent_repositories_score).to eq(100)
      end
    end

    context "if it doesn't have the highest number of dependent projects in its ecosystem" do
      it "should be a percentage of the highest" do
        allow(project).to receive(:dependent_repos_count) { 50 }
        allow(calculator).to receive(:max_dependent_repositories) { 100 }

        expect(calculator.dependent_repositories_score).to eq(50)
      end
    end
  end

  describe '#stars_score' do
    context "passing max_stars on init" do
      it "should use passed in value" do
        calculator = SourceRankCalculator.new(project, max_stars: 1001)

        allow(project).to receive(:stars) { 1001 }

        expect(calculator.stars_score).to eq(100)
      end
    end

    context "if it has the highest number of stars in its ecosystem" do
      it "should be 100" do
        allow(project).to receive(:stars) { 19000 }
        allow(calculator).to receive(:max_stars) { 19000 }

        expect(calculator.stars_score).to eq(100)
      end
    end

    context "if it doesn't have the highest number of stars in its ecosystem" do
      it "should be a percentage of the highest" do
        allow(project).to receive(:stars) { 19 }
        allow(calculator).to receive(:max_stars) { 19000 }

        expect(calculator.stars_score).to eq(0.1)
      end
    end
  end

  describe '#forks_score' do
    context "passing max_forks on init" do
      it "should use passed in value" do
        calculator = SourceRankCalculator.new(project, max_forks: 1001)

        allow(project).to receive(:forks) { 1001 }

        expect(calculator.forks_score).to eq(100)
      end
    end

    context "if it has the highest number of forks in its ecosystem" do
      it "should be 100" do
        allow(project).to receive(:forks) { 56 }
        allow(calculator).to receive(:max_forks) { 56 }

        expect(calculator.forks_score).to eq(100)
      end
    end

    context "if it doesn't have the highest number of forks in its ecosystem" do
      it "should be a percentage of the highest" do
        allow(project).to receive(:forks) { 1 }
        allow(calculator).to receive(:max_forks) { 10 }

        expect(calculator.forks_score).to eq(10)
      end
    end
  end

  describe '#watchers_score' do
    context "passing max_watchers on init" do
      it "should use passed in value" do
        calculator = SourceRankCalculator.new(project, max_watchers: 1001)

        allow(project).to receive(:watchers) { 1001 }

        expect(calculator.watchers_score).to eq(100)
      end
    end

    context "if it has the highest number of watchers in its ecosystem" do
      it "should be 100" do
        allow(project).to receive(:watchers) { 56 }
        allow(calculator).to receive(:max_watchers) { 56 }

        expect(calculator.watchers_score).to eq(100)
      end
    end

    context "if it doesn't have the highest number of watchers in its ecosystem" do
      it "should be a percentage of the highest" do
        allow(project).to receive(:watchers) { 1 }
        allow(calculator).to receive(:max_watchers) { 10 }

        expect(calculator.watchers_score).to eq(10)
      end
    end
  end

  describe '#popularity_score' do
    it "should be the average of popularity category scores" do
      allow(calculator).to receive(:dependent_repositories_score) { 90 }
      allow(calculator).to receive(:dependent_projects_score) { 20 }
      allow(calculator).to receive(:stars_score) { 55 }
      allow(calculator).to receive(:forks_score) { 70 }
      allow(calculator).to receive(:watchers_score) { 10 }

      expect(calculator.popularity_score).to eq(49)
    end
  end

  describe '#quality_score' do
    it "should be the average of quality category scores" do
      allow(calculator).to receive(:basic_info_score) { 100 }
      allow(calculator).to receive(:status_score) { 0 }
      allow(calculator).to receive(:multiple_versions_score) { 50 }
      allow(calculator).to receive(:semver_score) { 100 }

      expect(calculator.quality_score).to eq(50)
    end
  end

  describe '#community_score' do
    it "should be the average of community category scores" do
      allow(calculator).to receive(:contribution_docs_score) { 100 }
      allow(calculator).to receive(:recent_releases_score) { 0 }
      allow(calculator).to receive(:brand_new_score) { 50 }
      allow(calculator).to receive(:contributors_score) { 100 }
      allow(calculator).to receive(:maintainers_score) { 0 }

      expect(calculator.community_score).to eq(50)
    end
  end

  describe '#breakdown' do
    it "should be the contain details of each score category" do
      expect(calculator.breakdown).to eq({
        :overall_score => 38,
        :popularity => {
          :score => 0,
          :dependent_projects => 0,
          :dependent_repositories => 0,
          :stars => 0,
          :forks => 0,
          :watchers => 0
        },
        :community => {
          :score => 0,
          :contribution_docs => {
            :code_of_conduct => false,
            :contributing => false,
            :changelog => false
          },
          :recent_releases => 0,
          :brand_new => 0,
          :contributors => 0,
          :maintainers => 0
        },
        :quality => {
          :score => 53.33333333333333,
          :basic_info => {
            :description => true,
            :homepage => true,
            :repository_url => true,
            :keywords => true,
            :readme => false,
            :license => false},
          :status => 100,
          :multiple_versions => 0,
          :semver => 100,
          :stable_release => 0
        },
        :dependencies => {
          :score => 100,
          :outdated_dependencies => 100,
          :dependencies_count => 100,
          :direct_dependencies => {}
        }
      })
    end
  end
end