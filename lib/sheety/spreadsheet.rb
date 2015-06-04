require_relative 'feed'
require_relative 'cell'
require_relative 'row'
require_relative 'worksheet'

class Sheety::Spreadsheet < Sheety::Feed
  LINK_WORKSHEETS = 'http://schemas.google.com/spreadsheets/2006#worksheetsfeed'
  LINK_ADD = LINK_WORKSHEETS

  atom_children :worksheets, klass: Sheety::Worksheet, link: LINK_WORKSHEETS

  attr_reader :author_name, :author_email

  def parse(entry)
    super(entry)
    @author_name = entry['author'][0]['name'][0]
    @author_email = entry['author'][0]['email'][0]
  end

  def export_to_worksheet(data, options={})
    if data.respond_to?(:as_json)
      data = data.as_json
    end

    unless !data.blank? && Array === data
      raise ArgumentError.new("data must be a non-blank array (or convertible by :as_json), got #{data}")
    end

    options = {title: 'worksheet', timestamp: true}.merge(options)

    headers = data[0].keys

    worksheet = new_worksheet
    worksheet.col_count = headers.length
    worksheet.row_count = 1 # we only need to have access to the header row for cells, other rows are inserted
    worksheet.title = if options[:timestamp] then
                        "#{options[:title]}_#{Time.now.to_i.to_s}"
                      else
                        "#{options[:title]}"
                      end
    worksheet.save # save that to create the ws

    worksheet.cells # we need to fetch the link to save new cells to

    headers.each_with_index do |key, index|
      cell = worksheet.new_cell
      cell.row = 1
      cell.col = index + 1
      cell.value = key.to_s
      cell.save
    end

    worksheet.rows # Fetches the link we can save rows to

    # We have to normalize the keys we display to a version without underscores or spaces or other bollocks
    header_keys = Hash[headers.map { |k| [k, Sheety::Row.normalize_key(k)] }]

    # TODO: Finish this if I end up caring....
    # dupes = (header_keys.values - header_keys.values.uniq)
    #
    # if dupes.length
    #
    # end

    data.each do |datum|
      row = worksheet.new_row
      datum.each do |kv|
        key, val = kv
        header_key = header_keys[key]
        row[header_key] = REXML::Text.normalize(val.to_s) unless val.blank?
      end
      row.save
    end
  end

  ## Serialization Methods

  # TODO: as_xml

  def to_s
    "<Spreadsheet::#{object_id} '#{title}' by #{author_name} w/ #{Sheety.length_s(@worksheets)} Worksheets>"
  end

  def inspect
    to_s
  end
end