require "rails_helper"

describe PackageManager::Base::VersionUpdater do
  describe "#upsert_version_for_project!" do
    let(:db_project) { Project.create(platform: "Pypi", name: project_name) }
    let(:api_version_to_upsert) do
      PackageManager::Base::ApiVersionToUpsert.new(
        version_number: version_number,
        published_at: published_at,
        runtime_dependencies_count: nil,
        original_license: nil,
        repository_sources: nil,
        status: nil
      )
    end

    let(:project_name) { "name" }
    let(:version_number) { "1.0.0" }
    let(:published_at) { Time.zone.now.change(usec: 0, subsec: 0) }

    let(:version_updater) { described_class.new(project: db_project, api_version_to_upsert: api_version_to_upsert, new_repository_source: "b") }

    context "with real project version" do
      let!(:db_project_version) { db_project.versions.create(number: version_number, published_at: nil, repository_sources: ["a"]) }

      it "updates the version" do
        version_updater.upsert_version_for_project!

        db_project_version.reload

        # deal with microtimeT differences between Ruby and PostgreSQL
        expect(db_project_version.published_at).to be_within(1.second).of(published_at)
        expect(db_project_version.repository_sources).to eq(%w[a b])
      end
    end

    context "with stub project version" do
      let(:db_project_version_stub) do
        Version.new
      end

      let(:logger) { instance_double(ActiveSupport::Logger) }

      before do
        allow(db_project.versions).to receive(:find_or_initialize_by).with(number: version_number).and_return(db_project_version_stub)
        allow(db_project_version_stub).to receive(:save!).and_raise(error_class, exception_details)

        allow(Rails).to receive(:logger).and_return(logger)
        allow(logger).to receive(:info)
      end

      let(:error_class) { ActiveRecord::RecordNotUnique }
      let(:exception_details) { "PG::UniqueViolation" }

      context "with activerecord not unique error" do
        context "with postgresql violation" do
          it "logs a message" do
            version_updater.upsert_version_for_project!
            expect(logger).to have_received(:info).with(/DUPLICATE VERSION 1/)
          end
        end

        context "with other error" do
          let(:exception_details) { "whatever" }

          it "raises an error" do
            expect { version_updater.upsert_version_for_project! }.to raise_error(error_class, /#{exception_details}/)
          end
        end
      end

      context "with activerecord record invalid" do
        let(:error_class) { ActiveRecord::RecordInvalid }

        # ActiveRecord::RecordInvalid expects a model as the parameter
        let(:exception_details) { db_project_version_stub }
        # and that models needs an ActiveModel::Errors object
        let(:errors) do
          instance_double(
            ActiveModel::Errors,
            full_messages: [message_text]
          )
        end

        let(:message_text) { "Number has already been taken" }

        before do
          allow(db_project_version_stub).to receive(:errors).and_return(errors)
        end

        context "with already taken" do
          it "logs a message" do
            version_updater.upsert_version_for_project!
            expect(logger).to have_received(:info).with(/DUPLICATE VERSION 2/)
          end
        end

        context "with other error" do
          let(:message_text) { "whatever" }

          it "raises an error" do
            expect { version_updater.upsert_version_for_project! }.to raise_error(error_class, /#{message_text}/)
          end
        end
      end
    end
  end
end
