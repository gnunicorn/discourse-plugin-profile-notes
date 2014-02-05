require 'spec_helper'

describe PollPlugin::PollController, type: :controller do
  let(:topic) { create_topic(title: "Poll: Chitoge vs Onodera") }
  let(:post) { create_post(topic: topic, raw: "Pick one.\n\n* Chitoge\n\n* Onodera") }
  let(:user1) { Fabricate(:user) }
  let(:user2) { Fabricate(:user) }

  it "should return 403 if no user is logged in" do
    xhr :put, :vote, post_id: post.id, option: "<p>Chitoge</p>", use_route: :poll
    response.should be_forbidden
  end

  it "should return 400 if post_id or invalid option is not specified" do
    log_in_user user1
    xhr :put, :vote, use_route: :poll
    response.status.should eq(400)
    xhr :put, :vote, post_id: post.id, use_route: :poll
    response.status.should eq(400)
    xhr :put, :vote, option: "<p>Chitoge</p>", use_route: :poll
    response.status.should eq(400)
    xhr :put, :vote, post_id: post.id, option: "<p>Tsugumi</p>", use_route: :poll
    response.status.should eq(400)
  end

  it "should return 400 if post_id doesn't correspond to a poll post" do
    log_in_user user1
    post2 = create_post(topic: topic, raw: "Generic reply")
    xhr :put, :vote, post_id: post2.id, option: "<p>Chitoge</p>", use_route: :poll
    response.status.should eq(400)
  end

  it "should save votes correctly" do
    log_in_user user1
    xhr :put, :vote, post_id: post.id, option: "<p>Chitoge</p>", use_route: :poll
    PollPlugin::Poll.new(post).get_vote(user1).should eq("<p>Chitoge</p>")

    log_in_user user2
    xhr :put, :vote, post_id: post.id, option: "<p>Onodera</p>", use_route: :poll
    PollPlugin::Poll.new(post).get_vote(user2).should eq("<p>Onodera</p>")

    PollPlugin::Poll.new(post).details["<p>Chitoge</p>"].should eq(1)
    PollPlugin::Poll.new(post).details["<p>Onodera</p>"].should eq(1)

    xhr :put, :vote, post_id: post.id, option: "<p>Chitoge</p>", use_route: :poll
    PollPlugin::Poll.new(post).get_vote(user2).should eq("<p>Chitoge</p>")

    PollPlugin::Poll.new(post).details["<p>Chitoge</p>"].should eq(2)
    PollPlugin::Poll.new(post).details["<p>Onodera</p>"].should eq(0)
  end
end
