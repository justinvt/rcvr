
def collect_sample_data
  sample_directory = File.join(File.dirname(__FILE__), "..", "samples")
  file_prefix = ARGV[0]
  json_file = "#{file_prefix}.json"
  yaml_file = "#{file_prefix}.yml"
  parser = Yajl::Parser.new
  json_contents = File.read(File.join(sample_directory,json_file))
  post = parser.parse(json_contents)


  yaml_file = File.new(File.join(sample_directory,yaml_file),"w+")
  yaml_file.puts YAML::dump( post )
  yaml_file.close
end

