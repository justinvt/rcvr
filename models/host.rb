class Host
  include DataMapper::Resource

  property :id, Serial
  property :ip, String
  property :domain, String

  validates_uniqueness_of :domain


end

