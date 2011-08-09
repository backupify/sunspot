namespace :schema do
  desc 'Generate schema from template'
  task :compile do
    require File.expand_path(join(File.dirname(__FILE__), '..', 'lib', 'sunspot', 'schema'))
    File.open(
        File.expand_path(
      File.join(
        File.dirname(__FILE__),
        '..',
        'solr',
        'solr',
        'conf',
        'schema.xml'
    )),
      'w'
    ) do |file|
      file << Sunspot::Schema.new.to_xml
    end
  end
end
