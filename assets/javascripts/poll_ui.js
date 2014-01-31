(function() {

  var PollView = Ember.View.extend({
    templateName: "poll",
    classNames: ['poll-ui'],
    options: [],
    showResults: false,
    post_id: null,

    updateOptionsFromJSON: function(json) {
      if (json["selected"]) { this.set('showResults', true); }

      array = [];
      Object.keys(json["options"]).forEach(function(option) {
        array.push(Ember.Object.create({
          option: option,
          votes: json["options"][option],
          checked: (option == json["selected"])
        }));
      });
      this.set('options', array);
    },

    replaceElement: function(target) {
      this._insertElementLater(function() {
        target.replaceWith(this.$());
      });
    },

    actions: {
      selectOption: function(option) {
        this.get('options').forEach(function(opt) {
          opt.set('checked', opt.get('option') == option);
        });
        this.rerender();

        this.set('loading', true);
        Discourse.ajax("/poll", {
          type: "PUT",
          data: {post_id: this.get('post_id'), option: option}
        }).then(function(newJSON) {
          this.set('showResults', true);
          this.set('loading', false);
          this.updateOptionsFromJSON(newJSON);
          this.rerender();
        }.bind(this));
      },

      toggleShowResults: function() {
        this.set('showResults', !this.get('showResults'));
      }
    }
  });

  Discourse.PostView.reopen({
    createPollUI: function($post) {
      var post = this.get('post');

      if (!post.get('topic.title').match(/^poll:/i) || post.get('post_number') > 1) {
        return;
      }

      var poll_details = post.get('poll_details');
      var view = this.createChildView(PollView, {
        post_id: post.get('id')
      });
      view.updateOptionsFromJSON(poll_details);
      view.replaceElement($post.find("ul:first"));
      this.set('pollView', view);

    }.on('postViewInserted'),

    clearPollView: function() {
      if (this.get('pollView')) {
        this.get('pollView').destroy();
      }
    }.on('willClearRender')
  });


})();
