import std.stdio : writeln;
import std.array : replace;
import std.path : absolutePath;
import std.file : exists, readText;
import std.process : spawnProcess;
import std.algorithm : endsWith;
import std.conv : to;
import commonmarkd : convertMarkdownToHTML;
import handy_httpd : HttpServer, HttpRequestHandler, HttpRequest, HttpResponse, notFound, okResponse; 


string ROOT             = "127.0.0.1";
ushort PORT             = 8888;
string BROWSER          = "firefox";
string HTML_TEMPLATE    = import("template.html");


class RequestHandler : HttpRequestHandler
{
    HttpResponse handle(HttpRequest request)
    {
        string url = request.url;
        if (url.endsWith(".md") && url.exists)
        {
            string html = convertMarkdownToHTML(readText(url));
            string page = HTML_TEMPLATE.replace("[CONTENT]", html);
            page = page.replace("[URL]", url);
            return okResponse().setBody(page);
        }
        else if (url.endsWith(".md.check") && url[0 .. $-6].exists)
        {
            ulong lastClientUpdate = to!ulong(request.headers["Last-update"]);
            writeln(lastClientUpdate);
            auto response = okResponse();
            response.addHeader("Content-type", "text/html");
            response.setBody("");
            return response;
        }
        else return notFound();
    }
}

void startview(string file)
{
    auto abspath = absolutePath(file);
    auto url = "http://localhost:" ~ to!string(PORT) ~  abspath;
    spawnProcess([BROWSER, url]);
}

void main(string[] args)
{
	if (args.length != 2)
    {
        writeln("zettel");
        writeln("using web browser: ", BROWSER);
        writeln("Usage:");
        writeln("  zettel server");
        writeln("    -> start background server on port ", PORT);
        writeln("  zettel [path to markdown]");
        writeln("    -> view the specified file");
        return;
    }
    
    if (args[1] == "server")
    {
        auto server = new HttpServer(new RequestHandler, ROOT, PORT);
        server.start();
        scope(exit) server.stop();
    }
    else
    {
        startview(args[1]);
    }
}
