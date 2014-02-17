var ProfileNotesView = Ember.View.extend({
  templateName: "profile_notes",
  classNames: ['profile-notes-ui'],
  options: [],
  showResults: false,

  insertElement: function() {
    this._insertElementLater(function() {
      var target = this._parentView.$("section.about");
      this.$().insertAfter(target);
    });
  },

  actions: {
    showAddNote: function() {
      this.set('showAddNote', true);
    },
    cancelAddNote: function() {
      this.set('showAddNote', false);
    }
  }
});

Discourse.UserView.reopen({
  renderProfileNotes: function() {
    if (this.get('profileNotesView')) return;

    var view = this.createChildView(ProfileNotesView, {
      controller: this.get('controller'),
    });
    view.insertElement();
    this.set('profileNotesView', view);
  }.observes('user.loaded', 'user.username'),

  clearProfileNotesView: function() {
    if (this.get('profileNotesView')) {
      this.get('profileNotesView').destroy();
    }
  }.on('willClearRender')
});
