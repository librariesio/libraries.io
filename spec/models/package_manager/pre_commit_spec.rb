require "rails_helper"

describe PackageManager::PreCommit do
    describe "#project_names" do
        it "resolves projects correctly" do
            VCR.use_cassette("all-hooks") do
                project_names = described_class.project_names

                expect(project_names).to eq ["check-added-large-files", "check-ast", "autopep8"]
            end
        end
    end

    describe "#mapping" do
        it "maps project data correctly" do
            VCR.use_cassette("all-hooks") do
                project = described_class.project("check-ast")
                mapping = described_class.mapping(project)

                expect(mapping[:name]).to eq "check-ast"
                expect(mapping[:description]).to eq "Simply check whether the files parse as valid python."
                expect(mapping[:repository_url]).to eq "https://github.com/pre-commit/pre-commit-hooks"
            end
        end

        it "uses correct description fallback" do
            VCR.use_cassette("all-hooks") do
                project = described_class.project("autopep8")
                mapping = described_class.mapping(project)

                expect(mapping[:name]).to eq "autopep8"
                expect(mapping[:description]).to eq ""
                expect(mapping[:repository_url]).to eq "https://github.com/pre-commit/mirrors-autopep8"
            end
        end
    end

    describe "#formatted_name" do
        it 'has a formatted name of "pre-commit"' do
            expect(described_class.formatted_name).to eq("pre-commit")
        end
    end
end
