require 'spec_helper'

describe Poll do
  let(:topic) { create_topic(title: "Poll: Chitoge vs Onodera") }
  let(:post) { create_post(topic: topic, raw: "Pick one.\n\n* Chitoge\n\n* Onodera") }

  it "should detect poll post correctly" do
    expect(Poll.is_poll_post?(post)).to be_true
    post2 = create_post(topic: topic, raw: "This is a generic reply.")
    expect(Poll.is_poll_post?(post2)).to be_false
    post.topic.title = "Not a poll"
    expect(Poll.is_poll_post?(post)).to be_false
  end

  it "should get poll options correctly" do
    expect(Poll.get_poll_options(post)).to eq(["<p>Chitoge</p>", "<p>Onodera</p>"])
  end
end
