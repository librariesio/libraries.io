require 'rails_helper'

describe PackageManager::Go do
  let(:project) { create(:project, name: 'foo', platform: described_class.name) }

  it 'has formatted name of "Go"' do
    expect(described_class.formatted_name).to eq('Go')
  end

  describe '#package_link' do
    it 'returns a link to project website' do
      expect(described_class.package_link(project)).to eq("https://pkg.go.dev/foo")
    end

    it 'ignores version' do
      expect(described_class.package_link(project, '2.0.0')).to eq("https://pkg.go.dev/foo@2.0.0")
    end
  end

  describe '#documentation_url' do
    it 'returns a link to project website' do
      expect(described_class.documentation_url('foo', '2.0.0')).to eq("https://pkg.go.dev/foo@2.0.0?tab=doc")
    end
  end

  describe '#install_instructions' do
    it 'returns a command to install the project' do
      expect(described_class.install_instructions(project)).to eq("go get foo")
    end

    it 'ignores version' do
      expect(described_class.install_instructions(project, '2.0.0')).to eq("go get foo")
    end
  end

  describe '#get_repository_url' do
    it 'follows redirects to get correct url' do
      VCR.use_cassette('go_redirects') do
        expect(described_class.get_repository_url({'Package' => 'github.com/DarthSim/imgproxy'})).to eq("https://github.com/imgproxy/imgproxy")
      end
    end
  end

  describe ".project_find_names(name)" do
    context "for names from a a known host" do
      it "returns the name" do
        expect(described_class.project_find_names("github.com/user/project"))
          .to eq(["github.com/user/project"])
      end
    end

    context "for names with a known vcs" do
      it "returns the name" do
        expect(described_class.project_find_names("example.org/user/foo.hg"))
          .to eq(["example.org/user/foo.hg"])
      end
    end

    context "for other names" do
      context "with a redirect" do
        it "follows the redirect" do
          html = <<~EOHTML
            <!DOCTYPE html>
            <html>
                <head>
                    <meta name="go-import" content="go.uber.org/multierr git https://github.com/uber-go/multierr">
                    <meta name="go-source" content="go.uber.org/multierr https://github.com/uber-go/multierr https://github.com/uber-go/multierr/tree/master{/dir} https://github.com/uber-go/multierr/tree/master{/dir}/{file}#L{line}">
                    <meta http-equiv="refresh" content="0; url=https://godoc.org/go.uber.org/multierr">
                </head>
                <body>
                    Nothing to see here. Please <a href="https://godoc.org/go.uber.org/multierr">move along</a>.
                </body>
            </html>
          EOHTML

          allow(described_class)
            .to receive(:get_html)
            .with("https://go.uber.org/multierr?go-get=1")
            .and_return(Nokogiri::HTML(html))

          expect(described_class.project_find_names("go.uber.org/multierr"))
            .to eq(["github.com/uber-go/multierr"])
        end
      end

      context "with an unknown result" do
        it "returns the original name" do
          allow(described_class)
            .to receive(:get_html)
            .with("https://go.example.org/user/foo?go-get=1")
            .and_return(Nokogiri::HTML("<html><body>Hello, world!</body></html>"))

          expect(described_class.project_find_names("go.example.org/user/foo"))
            .to eq(["go.example.org/user/foo"])
        end
      end
    end
  end
end
