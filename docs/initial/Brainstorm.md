# Brainstorm

This is the brainstorm for a desktop front-end for a project called "Alexandria".  

## Features

- The user can view, reproduce (audio and video), edit metadata and delete:
  - Music (audio files)
  - Movies and series (video files)
  - HTML pages
  - Markdown and text files
  - PDF and e-book formats
  - Images
  - Browser bookmarks

What the user can edit?

- Music metadata
- Video metadata
- Markdown and text files
- Every file name

So I don't want any complex operation, like audio or video editing. I just want a software that can be used to organize and show those files from disk.  

How the files can be organized?

- The user can create, update, delete and organize browser bookmarks in folders
- Can do the same for every other file type
- Can create watchlists for movies, series and track watched movies and series progress

## Technologies

- The back-end is being written in Rust, to ensure the best performance and safety. It's done in another project
- This front-end desktop must run on Windows and Linux (if we can't ensure that it will run in all distros, ensure at least Ubuntu)
- This front-end must consume the Rust API using FFI

## Goals

- Beside implementing all the features, I want the front to be as performatic and light as possible.
- The app must be responsible, addapting to different screens sizes and windows rezises, without disturbing usability.
- The interface must be clean, modern, intuitive and easy to use.

## Implementation

I want to use the best practices, SOLID principles, and the latest stable versions of all technologies involved.

## Screens, Features and components

- Login/Sign-in
- E-mail confirmation
- Password recovery
- Markdown/TXT editor
- Home screen (must be a dashboard)
- Left panel showing the types of files in the library (music, movies, series, books, comic books, notes, text files, HTML pages, PDFs, etc)
- File viewer, of different layouts (list, list with details and grid)
- File search
- Filters
- Modals and checkboxes when needed
- Loading when needed
- Video reproducer with basic functions (full screen, pause, forward, backward, subtitles, audio tracks)
- The same for music, but with an animation when an álbum or artist is played (a CD, Vinyl or Tape being introduced to the respective device they play, and a animation of a disc or vinyl spining on this player, or the tape being played, must be on the screen by the duration of the songs, and stop on pauses)
