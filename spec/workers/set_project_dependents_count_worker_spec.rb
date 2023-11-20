# frozen_string_literal: true

require "rails_helper"

describe SetProjectDependentsCountWorker do
  it "should use the snakk priority queue" do
    is_expected.to be_processed_in :small
  end

  it "should update dependents count for a project" do
    project = create(:project)
    expect_any_instance_of(Project).to receive(:set_dependents_count)
    subject.perform(project.id)
  end
end
