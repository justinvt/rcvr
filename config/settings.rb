
PASSWORD = "whoresdude"
ALLOWED_DOMAINS = %w{youtube imgur wikipedia}
DOMAIN_URL_REGEX = Regexp.new "(#{ALLOWED_DOMAINS.join("|")})"

USER = "justinvt"



set :environment, ENVIRONMENT
enable :logging, :dump_errors#, :raise_errors

LOG_PROPAGATION = (ENVIRONMENT == :development) ? "w+" : "a"

log = File.new(APP_LOG, "a")
DataMapper::Logger.new(DM_LOG, LOG_LEVEL)

STDOUT.reopen(log)
STDERR.reopen(log)


DataMapper.setup(:default, 'mysql://root@localhost/youtube?socket=/tmp/mysql.sock')
#DataMapper::Model.raise_on_save_failure = true