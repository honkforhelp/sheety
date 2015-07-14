Gem::Specification.new do |s|
  s.name        = 'sheety'
  s.version     = '0.2.0'
  s.date        = '2015-06-03'
  s.summary     = "A Google Spreadsheets Gem"
  s.description = "An interface for manipulating Google Sheets in Ruby on Rails"
  s.authors     = ["Blake Israel"]
  s.email       = 'blake@honkforhelp.com'
  s.files       = ["lib/sheety.rb", "lib/sheety/api.rb", "lib/sheety/cell.rb", "lib/sheety/children.rb", "lib/sheety/feed.rb", "lib/sheety/row.rb", "lib/sheety/spreadsheet.rb", "lib/sheety/worksheet.rb"]
  s.homepage    = 'https://github.com/honkforhelp/sheety'
  s.license     = 'MIT'

  s.add_runtime_dependency 'xml-simple', "= 1.1.5-bisrael"
  s.add_runtime_dependency "google-api-client", "~> 0.8", ">= 0.8.6"
end