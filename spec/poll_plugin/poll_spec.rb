require 'spec_helper'

describe PollPlugin::Poll do
  let(:topic) { create_topic(title: "Poll: Chitoge vs Onodera") }
  let(:post) { create_post(topic: topic, raw: "Pick one.\n\n* Chitoge\n\n* Onodera") }
  let(:poll) { PollPlugin::Poll.new(post) }
  let(:user) { Fabricate(:user) }

  it "should detect poll post correctly" do
    expect(poll.is_poll?).to be_true
    post2 = create_post(topic: topic, raw: "This is a generic reply.")
    expect(PollPlugin::Poll.new(post2).is_poll?).to be_false
    post.topic.title = "Not a poll"
    expect(poll.is_poll?).to be_false
  end

  it "should get options correctly" do
    expect(poll.options).to eq(["<p>Chitoge</p>", "<p>Onodera</p>"])
  end

  it "should get details correctly" do
    expect(poll.details).to eq({"<p>Chitoge</p>" => 0, "<p>Onodera</p>" => 0})
  end

  it "should set details correctly" do
    poll.set_details!({})
    poll.details.should eq({})
    PollPlugin::Poll.new(post).details.should eq({})
  end

  it "should get and set votes correctly" do
    poll.get_vote(user).should eq(nil)
    poll.set_vote!(user, "<p>Onodera</p>")
    poll.get_vote(user).should eq("<p>Onodera</p>")
    poll.details["<p>Onodera</p>"].should eq(1)
  end

  it "should serialize correctly" do
    poll.serialize(user).should eq({options: poll.details, selected: nil})
    poll.set_vote!(user, "<p>Onodera</p>")
    poll.serialize(user).should eq({options: poll.details, selected: "<p>Onodera</p>"})
  end
end
