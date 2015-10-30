require 'rails_helper'

RSpec.describe TestTrackRails::ApplicationHelper do
  describe "#test_track_setup_tag" do
    let(:session) { instance_double(TestTrackRails::Session, cookie_domain: ".example.com") }
    let(:visitor) { instance_double(TestTrackRails::Visitor, split_registry: split_registry, assignment_registry: assignment_registry) }
    let(:split_registry) { { time: { hammertime: 0, millertime: 100 } } }
    let(:assignment_registry) { { time: "hammertime" } }

    before do
      # can't stub methods that don't exist, so define singleton methods emulating the TestTrackableController mixin
      session_var = session
      view.define_singleton_method(:test_track_session) do
        session_var
      end

      visitor_var = visitor
      view.define_singleton_method(:test_track_visitor) do
        visitor_var
      end
    end

    it "returns a reasonable-looking script tag" do
      result = with_env(TEST_TRACK_ENABLED: 1) { helper.test_track_setup_tag }

      expect(result).to include('<div class="_tt" style="visibility:hidden;width:0;height:0;">')
      expect(result).to include("<script>")

      base64_variable_match = result.match(/window.TT = '(.+)';/)

      expect(base64_variable_match).to be_present

      state_hash = JSON.load(Base64.strict_decode64(base64_variable_match[1]))

      expect(state_hash).to include('url' => 'http://testtrack.dev')
      expect(state_hash).to include('cookieDomain' => '.example.com')
      expect(state_hash).to include('registry' => { "time" => { "hammertime" => 0, "millertime" => 100 } })
      expect(state_hash).to include('assignments' => { "time" => "hammertime" })
    end
  end
end
