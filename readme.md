# zettel

> no-config, no-interference Markdown note-taking system

(name coming from the [Zettelkasten concept]())

The problems and needs I'm trying to address here:

- I want to use Markdown for everything I write
- Markdown is a single-file description language and is not really meant for files that know each other
    - need a very simple local server running in the background
- I don't want to/cannot extend my (very niche) text editor with Markdown preview abilities
    - my (very niche) web browser can do that better anyway
    - said server can be made responsible for auto-updating the view
- I don't want to mess up my Markdown with weird syntax
- I don't want to have both HTML and Markdown lying around
- I don't want any more configuration files on my system

## Compile and installation

What you need:
- (as of right now) a Linux system
- a [D]() compiler which implements D's standard library
- any text editor, set as `EDITOR` environment variable
- any web browser, set as `BROWSER` environment variable

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
