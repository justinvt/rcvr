
PASSWORD = "whoresdude"
ALLOWED_DOMAINS = %w{youtube imgur wikipedia}
DOMAIN_URL_REGEX = Regexp.new "(#{ALLOWED_DOMAINS.join("|")})"

USER = "justinvt"



set :environment, ENVIRONMENT
enable :logging, :dump_errors#, :raise_errors
enable :sessions

LOG_PROPAGATION = (ENVIRONMENT == :development) ? "a" : "a"

File.delete APP_LOG if File.exist?(APP_LOG)

log = File.new(APP_LOG, LOG_PROPAGATION)
DataMapper::Logger.new(DM_LOG, LOG_LEVEL)

#STDOUT.reopen(log)
#STDERR.reopen(log)


DataMapper.setup(:default, 'mysql://root@localhost/youtube?socket=/tmp/mysql.sock')
#DataMapper::Model.raise_on_save_failure = true