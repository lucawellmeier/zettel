import std.stdio : writeln;
import std.path : absolutePath;
import std.file : exists, readText;
import std.process : spawnProcess, environment;
import std.algorithm : endsWith;
import std.conv : to;
import commonmarkd : convertMarkdownToHTML;
import handy_httpd : HttpServer, simpleHandler, notFound, okResponse; 

struct Settings
{
    ushort port;
    string browser;

    static Settings instance()
    {
        Settings settings;
        settings.port = 8080;
        settings.browser = environment.get("BROWSER");
        return settings;
    }
}

void startserver(Settings settings)
{
    auto s = new HttpServer(simpleHandler((request) {
        string abspath = request.url;
        if (!abspath.endsWith(".md") || !exists(abspath)) return notFound();
        string html = convertMarkdownToHTML(readText(abspath));
        return okResponse().setBody(html);
    }), "127.0.0.1", settings.port);
	s.start();
}

void startview(Settings settings, string file)
{
    auto abspath = absolutePath(file);
    auto url = "localhost:" ~ to!string(settings.port) ~ abspath;
    spawnProcess([settings.browser, url]);
}

void main(string[] args)
{
    const auto settings = Settings.instance();

	if (args.length != 2)
    {
        writeln("zettel");
        writeln("using web browser: ", settings.browser);
        writeln("Usage:");
        writeln("  zettel server");
        writeln("    -> start background server on port ", settings.port);
        writeln("  zettel [path to markdown]");
        writeln("    -> view the specified file");
        return;
    }
    
    if (args[1] == "server") startserver(settings);
    else startview(settings, args[1]);
}
