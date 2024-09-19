# frozen_string_literal: true

require "rails_helper"

describe ExpiringSemaphore do
  let(:semaphore) { ExpiringSemaphore.new(name: "some-name", size: 10, ttl_seconds: 5) }

  before { REDIS.del(semaphore.key) }

  context "#initialize" do
    it "stores a namespaced key" do
      expect(semaphore.key).to eq("expiring_semaphore:some-name")
    end

    it "stores the max_value" do
      expect(semaphore.size).to eq(10)
    end
  end

  context "#acquire" do
    it "increments the counter and returns true" do
      expect do
        expect(semaphore.acquire).to be(true)
      end.to change { semaphore.current_value.to_i }.by(1)
    end

    it "returns false after it fills up" do
      semaphore.size.times do |_i|
        expect(semaphore.acquire).to be(true)
      end
      expect(semaphore.acquire).to be(false)
    end
  end

  context "#release" do
    before { semaphore.acquire }

    it "decrements the counter" do
      expect { semaphore.release }.to change { semaphore.current_value.to_i }.by(-1)
    end

    it "deletes the counter if it goes below zero" do
      expect(semaphore.current_value).to eq("1")

      semaphore.release
      expect(semaphore.current_value).to eq("0")

      semaphore.release
      expect(semaphore.current_value).to eq(nil)
    end
  end
end
