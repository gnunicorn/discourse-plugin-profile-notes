# README

This simple plugin adds private profile notes functionality to the discourse forum system.

## Details

This neat little plugin adds the possibility for any user to leave private, personal notes on another persons profile allowing them to read them later. Only the user, who created the note can view them. 

On top, Staff can decide to share the note with the rest of staff. In which case other staff will see what that person noted on it. This works on a per-note-bases and doesn't inhibit any staff person to still have their own personal notes.

## Installation

Just two easy steps. From your main discourse do:

    cd plugins
    git clone https://github.com/ligthyear/discourse-plugin-profile-notes.git   # clone the repo here
    cd ..
    RAILS_ENV=production rake assets:precompile 

Then restart your discourse and enjoy the fun on ever /user/*/activity-page.

## Changelog:

 * 2014-02-18
   - way improved UI. If you had a version before this one run in development, make sure to clear your cache (rm -rf DISCOURSE/tmp/cache/*)
   - Bugfix: as staff all notes were shared with staff. Now only when actually selected.

 * 2014-02-17
   - initial version

## TODO:

(in order of importance)

 * Notes can't be deleted atm
 * Notes should support markdown, too

## Authors:
Benjamin Kampmann <me @ create-build-execute . com>

## License (BSD):
Copyright (c) 2014, Benjamin Kampmann
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.