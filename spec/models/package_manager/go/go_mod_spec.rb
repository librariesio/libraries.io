# frozen_string_literal: true

require "rails_helper"

RSpec.describe PackageManager::Go::GoMod do
  subject(:go_mod) { described_class.new(mod_contents) }
  let(:mod_contents) { "" }

  describe "#retracted_version_ranges" do
    context "when empty" do
      it "has no retracted versions" do
        expect(go_mod.retracted_version_ranges).to be_empty
      end
    end

    context "when commented out" do
      let(:mod_contents) do
        <<~MODFILE
          // retract v0.9.4
        MODFILE
      end

      it "ignores commented out retract directives" do
        expect(go_mod.retracted_version_ranges).to be_empty
      end
    end

    context "when single version" do
      let(:mod_contents) do
        <<~MODFILE
          retract v1.0.0 // Oopsie
        MODFILE
      end

      it "detects retracted version" do
        expect(go_mod.retracted_version_ranges).to match_array(["v1.0.0"])
      end
    end

    context "when single range" do
      let(:mod_contents) do
        <<~MODFILE
          retract [v1.0.0, v1.0.5] // A set of oopsies
        MODFILE
      end

      it "detects retracted version range" do
        expect(go_mod.retracted_version_ranges).to match_array([["v1.0.0", "v1.0.5"]])
      end
    end

    context "when multiline" do
      let(:mod_contents) do
        <<~MODFILE
          // The following versions were removed for good reason
          retract (
            v1.0.2-dev0
            // Versions prior to 3.0.4 had a vulnerability in the dependency graph.  While we don't
            // directly use yaml, I'm not comfortable encouraging people to use versions with a
            // CVE - so prior versions are retracted.
            //
            // See CVE-2019-11254
            [v3.0.0, v3.0.3]
          )
        MODFILE
      end

      it "detects retracted versions and ranges" do
        expect(go_mod.retracted_version_ranges).to match_array(["v1.0.2-dev0", ["v3.0.0", "v3.0.3"]])
      end
    end

    context "when multiple" do
      let(:mod_contents) do
        <<~MODFILE
          retract v0.9.4 // foo
          // retract v0.9.5 // foo
          // foo
          retract [v1.0.0, v1.0.1]
        MODFILE
      end

      it "detects retracted version ranges" do
        expect(go_mod.retracted_version_ranges).to match_array(["v0.9.4", ["v1.0.0", "v1.0.1"]])
      end
    end

    context "when malformed" do
      let(:mod_contents) do
        <<~MODFILE
          retract // v0.9.4
          retrac v0.9.6
          retract v1.0.0
          retract asdfghjk
        MODFILE
      end

      it "ignores unparseable retract directives" do
        expect(go_mod.retracted_version_ranges).to match_array(["v1.0.0"])
      end
    end
  end

  describe "#canonical_module_name" do
    let(:mod_contents) do
      <<~MODFILE
        module my_cool_package
      MODFILE
    end

    it "reads module name from go.mod" do
      expect(go_mod.canonical_module_name).to eq("my_cool_package")
    end

    context "when malformed" do
      let(:mod_contents) do
        <<~MODFILE
          module // my_broke_package
          mod ule my_broke_package
        MODFILE
      end

      it "returns nil" do
        expect(go_mod.canonical_module_name).to be nil
      end
    end
  end
end
