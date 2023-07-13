require "rails_helper"

describe PackageManager::Pypi::RawRelease do
  describe "#details?" do
    let(:raw_release) { described_class.new(number: "1.0.0", release: release) }

    context "with details" do
      let(:release) { [{}] }

      it "returns true" do
        expect(raw_release.details?).to eq(true)
      end
    end

    context "without details" do
      let(:release) { [] }

      it "returns false" do
        expect(raw_release.details?).to eq(false)
      end
    end
  end

  describe "#published_at" do
    let(:raw_release) { described_class.new(number: "1.0.0", release: release) }

    context "without details" do
      let(:release) { [] }

      it "returns nil" do
        expect(raw_release.published_at).to eq(nil)
      end
    end

    context "with no upload time" do
      let(:release) { [{}] }

      it "raises an error" do
        expect { raw_release.published_at }.to raise_error(ArgumentError, /does not contain upload_time/)
      end
    end

    context "with a bad upload time" do
      let(:release) do
        [{
          "upload_time" => "{]",
        }]
      end

      it "raises an error" do
        expect { raw_release.published_at }.to raise_error(ArgumentError, /no time information/)
      end
    end

    context "with a good upload time" do
      let(:release) do
        [{
          "upload_time" => "2020-01-01 10:00:00",
        }]
      end

      it "returns a time object" do
        expect(raw_release.published_at.year).to eq(2020)
      end
    end
  end
end
