require "rails_helper"

RSpec.describe Search::QueryBuilders::FeedContent, type: :service do
  describe "::intialize" do
    it "sets params" do
      filter_params = { foo: "bar" }
      filter = described_class.new(filter_params)
      expect(filter.params).to include(filter_params)
    end

    it "builds query body" do
      filter = described_class.new({})
      expect(filter.body).not_to be_nil
    end
  end

  describe "#as_hash" do
    it "applies QUERY_KEYS from params" do
      params = { search_fields: "test" }
      filter = described_class.new(params)
      exepcted_query = [{
        "simple_query_string" => {
          "query" => "test*", "fields" => [:search_fields], "lenient" => true, "analyze_wildcard" => true
        }
      }]
      expect(filter.as_hash.dig("query", "bool", "must")).to match_array(exepcted_query)
    end

    it "applies TERM_KEYS from params" do
      params = { approved: true, tag_names: "beginner", user_id: 777, class_name: "Article" }
      filter = described_class.new(params)
      exepcted_filters = [
        { "term" => { "approved" => true } },
        { "term" => { "tags.name" => "beginner" } },
        { "term" => { "user.id" => 777 } },
        { "term" => { "class_name" => "Article" } },
      ]
      expect(filter.as_hash.dig("query", "bool", "filter")).to match_array(exepcted_filters)
    end

    it "applies RANGE_KEYS from params" do
      Timecop.freeze(Time.current) do
        params = { published_at: { lte: Time.current } }
        filter = described_class.new(params)
        exepcted_filters = [
          { "range" => { "published_at" => { lte: Time.current } } },
        ]
        expect(filter.as_hash.dig("query", "bool", "filter")).to match_array(exepcted_filters)
      end
    end

    it "applies QUERY_KEYS, TERM_KEYS, and RANGE_KEYS from params" do
      Timecop.freeze(Time.current) do
        params = { search_fields: "ruby", published_at: { lte: Time.current }, tag_names: "cfp" }
        filter = described_class.new(params)
        exepcted_query = [{
          "simple_query_string" => { "query" => "ruby*", "fields" => [:search_fields], "lenient" => true, "analyze_wildcard" => true }
        }]
        exepcted_filters = [
          { "range" => { "published_at" => { lte: Time.current } } },
          { "term" => { "tags.name" => "cfp" } },
        ]
        expect(filter.as_hash.dig("query", "bool", "must")).to match_array(exepcted_query)
        expect(filter.as_hash.dig("query", "bool", "filter")).to match_array(exepcted_filters)
      end
    end

    it "ignores params we don't support" do
      params = { not_supported: "trash", search_fields: "cfp" }
      filter = described_class.new(params)
      exepcted_query = [{
        "simple_query_string" => {
          "query" => "cfp*", "fields" => [:search_fields], "lenient" => true, "analyze_wildcard" => true
        }
      }]
      expect(filter.as_hash.dig("query", "bool", "must")).to match_array(exepcted_query)
    end

    it "allows default params to be overriden" do
      params = { sort_by: "published_at", sort_direction: "asc", size: 20 }
      filter = described_class.new(params).as_hash
      expect(filter.dig("sort")).to eq("published_at" => "asc")
      expect(filter.dig("size")).to eq(20)
    end
  end
end
