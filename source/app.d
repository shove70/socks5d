import std.stdio, std.getopt;
import socks5d.server, socks5d.config;
import std.experimental.logger;
import core.thread : Thread;

immutable string versionString = "0.0.2";
immutable string defaultAddress = "127.0.0.1";
immutable ushort defaultPort = 1080;

ushort port = defaultPort;
string address = defaultAddress;
string authString;
string configFile;
byte   verbosity; // log verbosity level
bool   ver;

int main(string[] args)
{
    if (processHelpInformation(args)) {
        return 0;
    }

    switch (verbosity) {
        case 0:
            sharedLog.logLevel = LogLevel.critical;
            break;
        case 1:
            sharedLog.logLevel = LogLevel.warning;
            break;
        case 2:
            sharedLog.logLevel = LogLevel.info;
            break;
        case 3:
            sharedLog.logLevel = LogLevel.trace;
            break;
        default:
            sharedLog.logLevel = LogLevel.critical;
            warningf("Unknown verbosity level: %d", verbosity);
    }

    auto configReader = new ConfigReader;
    configReader
        .setAddress(address)
        .setPort(port)
        .setAuthString(authString)
        .setConfigFile(configFile);

    auto server = configReader.buildServer();
    startServer(server);

    return 0;
}

void startServer(Server server)
{
    logf(LogLevel.critical, "Starting socks5d server v. %s", versionString);

    new Thread({
        server.run();
    }).start();
}


bool processHelpInformation(string[] args)
{
    import std.conv;
    const string helpString = "Socks5d SOCKS 5 proxy server version " ~ versionString ~ ".\n\n" ~
        "Usage: socks5d [OPTIONS]";

    auto helpInformation = getopt(args,
        std.getopt.config.caseSensitive,
        "address", "[IP address] Address to bind to (" ~ defaultAddress ~ " by default).",   &address,
        "port",    "[1..65535] Port number to listen to (" ~ to!string(defaultPort) ~ " by default).", &port,
        "auth",    "[login:password] Authentication string if required.",  &authString,
        "config",  "[path] Path to config file.", &configFile,
        "version|V",  "Print version and exit.",     &ver,
        "verbose|v",  "[0..3] Use verbose output level. Available levels: " ~
            "0(default, least verbose), 1, 2, 3(most verbose).",         &verbosity
    );

    if (ver) {
        writefln("Socks5d version %s", versionString);

        return true;
    }

    if (helpInformation.helpWanted) {
        defaultGetoptPrinter(helpString, helpInformation.options);
        return true;
    }

    return false;
}
