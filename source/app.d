import std.stdio : writeln;
import std.format : format;
import std.array : replace, split;
import std.path : absolutePath;
import std.file : exists, readText, timeLastModified;
import std.process : spawnProcess, Config;
import std.algorithm : endsWith;
import std.conv : to;
import std.socket : Socket, SocketOptionLevel, SocketOption;
import commonmarkd : convertMarkdownToHTML;
import handy_httpd : HttpServer, HttpRequestHandler, HttpRequest, HttpResponse, notFound, okResponse; 


enum string IP              = "127.0.0.1";
enum string HOSTNAME        = "localhost";
enum ushort PORT            = 8888;
enum string ADDRESS         = "http://" ~ HOSTNAME ~ ":" ~ PORT.to!string;
enum string BROWSER         = "surf %s";
enum string EDITOR          = "st -e nvim %s";
enum string HTML_TEMPLATE   = import("template.html").replace("[[[ADDRESS]]]", ADDRESS);


void spawnDetachedProcess(string command, string file)
{
    spawnProcess(
        command.split(" ").replace("%s", file),
        null, // environment
        Config.detached,
        null // working dir
    );
}

class NoWaitHttpServer : HttpServer
{
    this(HttpRequestHandler handler, string hostname, ushort port)
    {
        super(handler, hostname, port);
    }

    override void configurePreBind(Socket socket)
    {
        socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, 1);
    }
}

struct CachedHtml
{
    ulong timestamp;
    string html;
}

class RequestHandler : HttpRequestHandler
{
    CachedHtml[string] cache;

    private string fetchHtmlIfChanged(string file, long lastClientUpdate)
    {
        auto lastEdit = file.timeLastModified.toUnixTime!long;
        if (file !in cache || (file in cache && cache[file].timestamp < lastEdit))
        {
            CachedHtml cacheEntry;
            cacheEntry.timestamp = lastEdit;
            cacheEntry.html = convertMarkdownToHTML(readText(file));
            cache[file] = cacheEntry;
            return cacheEntry.html;
        }

        if (lastClientUpdate < 0 || lastClientUpdate < cache[file].timestamp)
        {
            return cache[file].html;
        }
        else
        {
            return "";
        }
    }

    HttpResponse handle(HttpRequest request)
    {
        string url = request.url;
        if (url.endsWith(".md") && url.exists)
        {
            string page = HTML_TEMPLATE
                .replace("[[[PATH]]]", url)
                .replace("[[[CONTENT]]]", fetchHtmlIfChanged(url, -1));
            return okResponse()
                .addHeader("Content-type", "text/html")
                .setBody(page);
        }
        else if (url.endsWith(".md/check") && url[0 .. $-6].exists)
        {
            string file = url[0 .. $-6];
            auto lastClientUpdate = to!long(request.headers["Last-update"]);
            auto doc = fetchHtmlIfChanged(file, lastClientUpdate);
            return okResponse()
                .addHeader("Content-type", "text/plain")
                .setBody(doc);
        }
        else if (url.endsWith(".md/edit") && url[0 .. $-5].exists)
        {
            string file = url[0 .. $-5];
            spawnDetachedProcess(EDITOR, file);
            return okResponse().addHeader("Content-type", "text/plain").setBody("");
        }
        else return notFound();
    }
}

void startview(string file)
{
    auto abspath = absolutePath(file);
    auto url = "http://localhost:" ~ to!string(PORT) ~  abspath;
    spawnDetachedProcess(BROWSER, url);
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
        auto server = new NoWaitHttpServer(new RequestHandler, IP, PORT);
        server.start();
        scope(exit) server.stop();
    }
    else
    {
        startview(args[1]);
    }
}
