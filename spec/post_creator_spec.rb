require 'spec_helper'
require 'post_creator'

describe PostCreator do
  let(:user) { Fabricate(:user) }

  context "poll topic" do
    it "cannot be created without a list of options" do
      post = PostCreator.create(user, {title: "Poll: This is a poll", raw: "body does not contain a list"})
      post.errors[:raw].should be_present
    end

    it "cannot be created with multiple lists" do
      # TODO
    end
  end
end
