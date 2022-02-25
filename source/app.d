import std.stdio : writeln;
import std.format : format;
import std.array : replace, split, array;
import std.path : absolutePath, dirName, pathSplitter;
import std.file : exists, read, readText, timeLastModified, isDir, isFile, write, FileException, SpanMode, dirEntries;
import std.process : spawnProcess, Config;
import std.range : repeat;
import std.algorithm : endsWith;
import std.algorithm.sorting : sort;
import std.algorithm.comparison : min;
import std.conv : to;
import std.socket : Socket, SocketOptionLevel, SocketOption;
import commonmarkd : convertMarkdownToHTML, MarkdownFlag;
import handy_httpd : HttpServer, HttpRequestHandler, HttpRequest, HttpResponse, notFound, okResponse; 


enum string IP              = "127.0.0.1";
enum string HOSTNAME        = "localhost";
enum ushort PORT            = 8888;
enum string ADDRESS         = "http://" ~ HOSTNAME ~ ":" ~ PORT.to!string;
enum string BROWSER         = "firefox %s";
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
            cacheEntry.html = convertMarkdownToHTML(
                readText(file), 
                MarkdownFlag.dialectCommonMark 
                | MarkdownFlag.permissiveAutoLinks
                | MarkdownFlag.latexMathSpans 
                | MarkdownFlag.tablesExtension);
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
        if (url.endsWith(".png") && url.exists && url.isFile)
        {
            return okResponse()
                .addHeader("Content-type", "image/png")
                .setBody(to!string(cast(char[]) read(url)));
        }
        else if (url.endsWith(".png") && url.exists && url.isFile)
        {
            return okResponse()
                .addHeader("Content-type", "image/jpeg")
                .setBody(to!string(cast(char[]) read(url)));

        }
        else if (url.endsWith(".md") && url.exists && url.isFile)
        {
            string page = HTML_TEMPLATE
                .replace("[[[PATH]]]", url)
                .replace("[[[CONTENT]]]", fetchHtmlIfChanged(url, -1));
            return okResponse()
                .addHeader("Content-type", "text/html")
                .setBody(page);
        }
        else if (url.endsWith(".md/check") && url[0 .. $-6].exists && url[0 .. $-6].isFile)
        {
            string file = url[0 .. $-6];
            auto lastClientUpdate = to!long(request.headers["Last-update"]);
            auto doc = fetchHtmlIfChanged(file, lastClientUpdate);
            return okResponse()
                .addHeader("Content-type", "text/plain")
                .setBody(doc);
        }
        else if (url.endsWith(".md/edit") && url[0 .. $-5].exists && url[0 .. $-5].isFile)
        {
            string file = url[0 .. $-5];
            spawnDetachedProcess(EDITOR, file);
            return okResponse().addHeader("Content-type", "text/plain").setBody("");
        }
        else if (url.isDir)
        {
            string query = url.absolutePath ~ "/";
            string current = request.headers["Current-path"].dirName.absolutePath ~ "/";

            auto currentParts = array(pathSplitter(current));
            auto queryParts = array(pathSplitter(query));
            auto smallerCount = min(currentParts.length, queryParts.length);

            ulong common = 0;
            int i = 0;
            while (i < smallerCount && currentParts[i] == queryParts[i])
            {
                common += currentParts[i].length + 1;
                i += 1;
            }
            common -= 1; // correct 1 for the initial / which appears as a part

            string[] dirs;
            string[] docs;
            foreach (string file; dirEntries(query, SpanMode.shallow))
            {
                if (file.isDir) dirs ~= file[common..$];
                else if (file.isFile && file.endsWith(".md")) docs ~= file[common..$];
            }
            dirs = array(sort(dirs));
            docs = array(sort(docs));
            // sort

            string commonWhite = ' '.repeat(common).to!string;

            string response = "";
            response ~= current[0..common] ~ "\n";
            foreach (string doc; docs) response ~= commonWhite ~ doc ~ "\n";
            foreach (string dir; dirs) response ~= commonWhite ~ dir ~ "/\n";
            return okResponse().addHeader("Content-type", "text/plain").setBody(response);
        }
        else return notFound();
    }
}

void startview(string file)
{
    if (file.exists && file.isDir)
    {
        "Error: specified path is a directory".writeln;
    }
    else
    {
        try
        {
            if (!file.exists)
            {
                file.write("# New note");
            }

            auto abspath = absolutePath(file);
            auto url = ADDRESS ~ abspath;
            spawnDetachedProcess(BROWSER, url);
        }
        catch (FileException e)
        {
            "Error: file does not exist but could not be created either.".writeln;
        }
    }
}

void main(string[] args)
{
	if (args.length != 2)
    {
        writeln("zettel - zero system-interference Markdown note-taking system");
        writeln("    web browser command: ", BROWSER);
        writeln("    text editor command: ", EDITOR);
        writeln("Usage: zettel server                  -> start background server on port ", PORT);
        writeln("Usage: zettel [path to markdown file] -> (create and) view the specified file");
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
