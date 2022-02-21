# zettel

> zero system-interference Markdown note-taking system

The problems and needs I'm trying to address here:

- I want to use Markdown for everything I write
- I want to refer easily from one note to the other
- I want to use my own text editor and my own web browser 
  for writing and viewing
- I want to use a standard Markdown syntax
- I don't want to have both HTML and Markdown lying around
- I don't want any configuration files on my system

The result is **zettel**, a local background server
which takes care of translating your Markdown to HTML, 
displaying it in your browser and automatically updating
the view when needed. The name comes from the 
[Zettelkasten](https://en.wikipedia.org/wiki/Zettelkasten) 
technique.

## Compile and installation

What you need:
- a Linux system (not tested on other platforms)
- git
- a web browser and a text editor
- [Digital Mars D compiler (DMD)](https://dlang.org/download.html) 
  and [DUB](https://dub.pm/getting_started), the D package manager

Clone the repo and simply run `dub build`.

## Quickstart (in fact, there is almost nothing more)

Start the server simply by executing `zettel server`.
Go somewhere in your filesystem, say `/foo/bar/`, and create a new Markdown file, say `test.md`.
Run `zettel test.md` and you will see the HTML page in your set browser. In the title bar 
you will find the button edit, which, upon pressed, will open your text editor. Edit the file and
save it to automatically update the browser view.

## Markdown syntax

GitHub-flavored Markdown with extension for using Latex's `$ ... $` and `$$ ... $$` is used as a base. 
The only functional addition is that links 
that refer to local Markdown files automatically send you to their `zettel` view.

## Configuration

There is no config file. All configuration is done by recompiling. This way you can easily change
the layout/appearance or the used port of the server (in case of interference with other programs).
