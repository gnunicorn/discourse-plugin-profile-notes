import UserController from 'discourse/controllers/user';

var injector = {
  _loadNotes: function() {
    var notes = this.get('notes');
    if (notes) return;

    this.set('loading', true);

    Discourse.ajax("/profile_notes/load", {
      data: {target_id: this.get('model.id')}
    }).then(function(newJSON) {
      this.set('loading', false);
      this.set("notes", newJSON.notes);
    }.bind(this));
    this.set('is_staff', Discourse.User.current().staff);
  }.observes('model').on('loaded'),

  actions: {

    showAddNote: function() {
      this.set('showAddNote', true);
    },

    addNote: function() {
      var noteText = $.trim($("textarea").val());
      if (!noteText) return;

      this.set('loading', true);
      this.set('showAddNote', false);
      Discourse.ajax("/profile_notes/add", {
        type: "POST",
        data: {target_id: this.get('model.id'),
               text: noteText, for_staff: $(".share-with-staff:checked").length}
      }).then(function(newJSON) {
        this.set('loading', false);
        this.set("notes", newJSON.notes);
      }.bind(this));

    },
    cancelAddNote: function() {
      this.set('showAddNote', false);
    },
    showEditNote: function(note) {
      this.set('note', note);
      this.set('showEditNote', true);
    },
    editNote: function() {
      var noteText = $.trim($("textarea").val());

      this.set('loading', true);
      this.set('showEditNote', false);
      Discourse.ajax("/profile_notes/edit", {
        type: "POST",
        data: {note_index: this.get('note').note_index,
                target_id: this.get('model.id'),
                text: noteText }
      }).then(function(newJSON) {
        this.set('loading', false);
        this.set("notes", newJSON.notes);
      }.bind(this));
    },
    cancelEditNote: function() {
      this.set('showEditNote', false);
    },
    deleteNote: function(note) {
      Discourse.ajax("/profile_notes/delete", {
        type: "DELETE",
        data: {note_index: note.note_index,
                target_id: this.get('model.id')}
      }).then(function(newJSON) {
        this.set("notes", newJSON.notes);
      }.bind(this));
    }
  }
};


export default {
  name: "inject-profiles-notes",

  initialize: function(container, application) {
    if (Discourse.SiteSettings.show_profile_notes_on_profile){
      UserController.reopen(injector);
    }

  }
}
