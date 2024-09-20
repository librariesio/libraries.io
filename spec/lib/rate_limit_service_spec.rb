# frozen_string_literal: true

require "rails_helper"

describe RateLimitService do
  context "when frozen in time" do
    # Use random key so we don't have to track down and reset redis keys before each spec block runs
    let(:what_to_limit) { "bar#{rand(999_999)}" }
    let(:limit) { 3 }
    let(:period) { 60 }
    let(:rate_limiter) { described_class.new(what_to_limit: what_to_limit, limit: limit, period: period) }

    before { freeze_time }

    it "limits rate after specified count" do
      3.times do
        rate_limiter.rate_limited { true }
      end
      expect { rate_limiter.rate_limited { true } }.to raise_error do |e|
        expect(e.class).to eq(RateLimitService::OverLimitError)
        expect(e.exceeded_by).to eq(1)
      end
    end

    it "limits rate after specified count with a different RateLimitService instance each time" do
      3.times do
        rate_limiter.rate_limited { true }
      end
      expect { rate_limiter.rate_limited { true } }.to raise_error do |e|
        expect(e.class).to eq(RateLimitService::OverLimitError)
        expect(e.exceeded_by).to eq(1)
      end
    end

    it "uses a different key after time passes" do
      3.times do
        rate_limiter.rate_limited { true }
      end
      3.times do |i|
        expect { rate_limiter.rate_limited { true } }.to raise_error do |e|
          expect(e.class).to eq(RateLimitService::OverLimitError)
          expect(e.exceeded_by).to eq(i + 1)
        end
      end

      allow(Time).to receive(:current).and_return(period.seconds.from_now)

      3.times do
        rate_limiter.rate_limited { true }
      end
      3.times do |i|
        expect { rate_limiter.rate_limited { true } }.to raise_error do |e|
          expect(e.class).to eq(RateLimitService::OverLimitError)
          expect(e.exceeded_by).to eq(i + 1)
        end
      end
    end
  end
end
