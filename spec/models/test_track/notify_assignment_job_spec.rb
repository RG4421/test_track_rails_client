require 'rails_helper'

RSpec.describe TestTrack::NotifyAssignmentJob do
  let(:assignment) { instance_double(TestTrack::Assignment, split_name: "phaser", variant: "stun", context: "the_context") }
  let(:params) do
    {
      visitor_id: "fake_visitor_id",
      assignment: assignment
    }
  end

  subject { described_class.new(params) }

  it "blows up with empty visitor id" do
    expect { described_class.new(params.merge(visitor_id: nil)) }
      .to raise_error(/visitor_id/)
  end

  it "blows up with empty assignment" do
    expect { described_class.new(params.merge(assignment: nil)) }
      .to raise_error(/assignment/)
  end

  it "blows up with unknown opts" do
    expect { described_class.new(params.merge(extra_stuff: true)) }
      .to raise_error(/unknown opts/)
  end

  describe "#perform" do
    let(:remote_assignment) { instance_double(TestTrack::Remote::Assignment) }
    before do
      allow(TestTrack::Remote::Assignment).to receive(:create!).and_return(remote_assignment)
      allow(TestTrack.analytics).to receive(:track).and_return(true)
    end

    it "does not send analytics events when test track is not enabled" do
      subject.perform
      expect(TestTrack.analytics).to_not have_received(:track)
    end

    it "sends analytics event" do
      with_test_track_enabled { subject.perform }

      expect(TestTrack.analytics).to have_received(:track).with(
        "fake_visitor_id",
        "SplitAssigned",
        "SplitName" => 'phaser',
        "SplitVariant" => 'stun',
        "SplitContext" => 'the_context',
        "TTVisitorID" => 'fake_visitor_id'
      )
    end

    context "mixpanel_distinct_id supplied" do
      let(:subject) { described_class.new(params.merge(mixpanel_distinct_id: "fake_mixpanel_id")) }

      it "uses mixpanel_distinct_id" do
        with_test_track_enabled { subject.perform }

        expect(TestTrack.analytics).to have_received(:track).with(
          "fake_mixpanel_id",
          "SplitAssigned",
          "SplitName" => 'phaser',
          "SplitVariant" => 'stun',
          "SplitContext" => 'the_context',
          "TTVisitorID" => 'fake_visitor_id'
        )
      end
    end

    it "sends test_track assignment" do
      with_test_track_enabled { subject.perform }

      expect(TestTrack::Remote::Assignment).to have_received(:create!).with(
        visitor_id: 'fake_visitor_id',
        split_name: 'phaser',
        variant: 'stun',
        context: 'the_context',
        mixpanel_result: 'success'
      )
    end

    context "analytics client fails" do
      before do
        allow(TestTrack.analytics).to receive(:track).and_return(false)
      end

      it "sends test_track assignment with mixpanel_result set to failure" do
        with_test_track_enabled { subject.perform }

        expect(TestTrack::Remote::Assignment).to have_received(:create!).with(
          visitor_id: 'fake_visitor_id',
          split_name: 'phaser',
          variant: 'stun',
          context: 'the_context',
          mixpanel_result: 'failure'
        )
      end
    end
  end
end
