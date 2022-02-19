import std.stdio : writeln;
import std.path : absolutePath;
import std.file : exists, readText;
import std.process : spawnProcess, environment;
import std.algorithm : endsWith;
import std.conv : to;
import commonmarkd : convertMarkdownToHTML;
import handy_httpd : HttpServer, HttpRequestHandler, HttpRequest, HttpResponse, notFound, okResponse; 

struct Settings
{
    string root;
    ushort port;
    string browser;

    static Settings inst;
    static void init()
    {
        inst.root = "127.0.0.1";
        inst.port = 8080;
        inst.browser = environment.get("BROWSER");
    }
}

class RequestHandler : HttpRequestHandler
{
    HttpResponse handle(HttpRequest request)
    {
        string abspath = request.url;
        if (!abspath.endsWith(".md") || !exists(abspath))
        {
            return notFound();
        }
        else
        {
            string html = convertMarkdownToHTML(readText(abspath));
            return okResponse().setBody(html);
        }
    }
}

void startview(string file)
{
    auto abspath = absolutePath(file);
    auto url = "localhost:" ~ to!string(Settings.inst.port) ~ abspath;
    spawnProcess([Settings.inst.browser, url]);
}

void main(string[] args)
{
    Settings.init();

	if (args.length != 2)
    {
        writeln("zettel");
        writeln("using web browser: ", Settings.inst.browser);
        writeln("Usage:");
        writeln("  zettel server");
        writeln("    -> start background server on port ", Settings.inst.port);
        writeln("  zettel [path to markdown]");
        writeln("    -> view the specified file");
        return;
    }
    
    if (args[1] == "server") 
        new HttpServer(new RequestHandler, Settings.inst.root, Settings.inst.port).start();
    else 
        startview(args[1]);
}
