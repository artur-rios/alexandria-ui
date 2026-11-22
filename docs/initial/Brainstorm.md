# Brainstorm

This is the brainstorm for a desktop front-end for a project called "Alexandria".  

Alexandria is for things to read and watch, and it plays music files too. Managing music — playlists, play history, browsing by artist and album — lives in Orpheus, a separate project.

There is no login: it runs on the owner's own machine, over their own files. And the library is navigated by the folders the owner chose, not by file type.

## Features

- The user can view, reproduce (video), edit metadata and delete:
  - Movies and series (video files)
  - HTML pages
  - Markdown and text files
  - PDF and e-book formats
  - Images
  - Browser bookmarks

What the user can edit?

- Video metadata
- Markdown and text files
- Every file name

So I don't want any complex operation, like video editing. I just want a software that can be used to organize and show those files from disk.  

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

- Markdown/TXT editor
- Home screen (must be a dashboard): the favorite libraries, and how many files of each type there are
- Left panel showing the libraries, with the ones I pin at the top, and opening each one as its folders
- File viewer, of different layouts (list, list with details and grid)
- File search
- Filters
- Modals and checkboxes when needed
- Loading when needed
- Video reproducer with basic functions (full screen, pause, forward, backward, subtitles, audio tracks)
