import ocean.util.app.DaemonApp;

class MyApp : DaemonApp
{
    import ocean.util.app.ext.VersionInfo;
    public this ()
    {
        auto empty_info = VersionInfo.init; // istring[istring]
        super("my_app_name", "My app short description", empty_info);
    }

    import ocean.text.Arguments;
    import ocean.util.config.ConfigParser;
    override int run ( Arguments args, ConfigParser config )
    {
        return 0;
    }

    import ocean.util.app.model.IApplication;;
    import ocean.text.Arguments;
    override void setupArgs ( IApplication app, Arguments args )
    {
        args("user").aliased('u').required.params(1)
            .help("the account user-name");
        args("github").params(0).conflicts("bitbucket").requires("user")
            .help("user is a github account");
        args("bitbucket").params(0).conflicts("github").requires("user")
            .help("user is a bitbucket account");
    }
}


import ocean.transition;
void main (istring[] args)
{
    (new MyApp).main(args);
}

