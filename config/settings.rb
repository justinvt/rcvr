ALLOWED_DOMAINS = %w{youtube imgur wikipedia}
DOMAIN_URL_REGEX = Regexp.new "(#{ALLOWED_DOMAINS.join("|")})"