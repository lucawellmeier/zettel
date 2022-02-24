# zettel

> zero system-interference Markdown note-taking system

-------------------------------------------------

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

Clone the repo, go to `source/app.d` and set your preferred web browser
and text editor by editing the following lines at the beginning of the
file:
```D
enum string BROWSER = "surf %s";
enum string EDITOR  = "st -e nvim %s";
```
Then compile using `dub build`. Note that you can take the resulting
executable wherever you want since it is completely stand-alone. 
In particular, the `template.html` file is inserted into the code 
at compile-time.

## Quickstart (in fact, there is almost nothing more)

Start the server simply by executing `zettel server`.
Go somewhere in your filesystem, say `/foo/bar/`, and 
run `zettel test.md`. This will create the file it if does not yet
exists and you will see the file opening as web page in your configured 
browser. In the title bar you will find the button edit, which, upon 
pressed, will open your text editor. Edit the file and
save it to automatically update the browser view.

### Used Markdown syntax

It uses [CommonMark](https://commonmark.org/) with the following 
two extensions (see [documentation of the `commonmarkd` package](http://commonmark-d.dpldocs.info/commonmarkd.MarkdownFlag.html)):
- `permissiveAutoLinks`
- `latexMathSpans`
- `tablesExtension`


## Configuration

There is no config file. All configuration is done by recompiling. This way 
you can easily change the layout/appearance by editing the HTML template
(which is then inserted into the code at compile-time) or the used port of the 
server (in case of interference with other programs).
