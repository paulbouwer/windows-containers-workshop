using System.ServiceProcess;

namespace WorkshopService
{
    public partial class WorkshopService : ServiceBase
    {
        public WorkshopService()
        {
            InitializeComponent();
            var config = new NLog.Config.LoggingConfiguration();
            var logfile = new NLog.Targets.FileTarget() { FileName = System.Configuration.ConfigurationManager.AppSettings["LogLocation"] + "log.txt", Name = "logfile", Layout = "${longdate}|${level:uppercase=true}|${logger}|${message}" };
            config.LoggingRules.Add(new NLog.Config.LoggingRule("*", NLog.LogLevel.Debug, logfile));
            NLog.LogManager.Configuration = config;
        }

        protected override void OnStart(string[] args)
        {
            var logger = NLog.LogManager.GetCurrentClassLogger();

            logger.Info("OnStart: Hello from inside a container.");
            logger.Info("App Settings: Message: {0}", System.Configuration.ConfigurationManager.AppSettings["Message"]);
            logger.Info("Connection Strings: DBConnection: {0}", System.Configuration.ConfigurationManager.ConnectionStrings["DBConnection"]);

        }

        protected override void OnStop()
        {
            var logger = NLog.LogManager.GetCurrentClassLogger();

            logger.Info("OnStop: Goodbye from inside a container.");
        }
    }
}