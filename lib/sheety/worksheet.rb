require_relative 'feed'
require_relative 'cell'
require_relative 'row'

class Sheety::Worksheet < Sheety::Feed
  LINK_ROWS = 'http://schemas.google.com/spreadsheets/2006#listfeed'
  LINK_CELLS = 'http://schemas.google.com/spreadsheets/2006#cellsfeed'
  LINK_VIZ = 'http://schemas.google.com/visualization/2008#visualizationApi'
  LINK_CSV = 'http://schemas.google.com/spreadsheets/2006#exportcsv'
  NATIVE_LINKS = [LINK_ROWS, LINK_CELLS, LINK_VIZ, LINK_CSV, LINK_SELF, LINK_EDIT]
  # TODO: Put these in a ListFeed Object, because that's where they come from
  LINK_POST = 'http://schemas.google.com/g/2005#post'
  LINK_FEED = 'http://schemas.google.com/g/2005#feed'

  attr_accessor :col_count, :row_count

  atom_children :rows, klass: Sheety::Row, link: LINK_ROWS, merge_links: true, accessor: :value
  atom_children :cells, klass: Sheety::Cell, link: LINK_CELLS

  def parse(entry)
    super(entry)

    @col_count = Sheety::Feed.deref(entry, 'gs:colCount', 0).to_i
    @row_count = Sheety::Feed.deref(entry, 'gs:rowCount', 0).to_i
  end

  def update_rows(data, key_key='key', value_key='value')
    logs = {}
    row_key_key = Sheety::Row.normalize_key(key_key)
    row_value_key = Sheety::Row.normalize_key(value_key)

    data.each do |kv|
      case kv
        when Array
          key = kv[0].to_s
          val = kv[1]
        when Hash
          key = kv[key_key].to_s
          val = kv
        else
          raise ArgumentError("Unknown argument type: #{kv.class}")
      end

      row = find_row(row_key_key => key)

      if row.nil?
        row = new_row
        row[row_key_key] = key
      end

      if Hash === val
        row.put val
      else
        row[row_value_key] = val
      end

      resp = row.save

      logs[key] = resp unless resp['id']
    end
    return logs
  end

  ## Serialization Methods

  def as_xml
    return [
        '<entry xmlns="http://www.w3.org/2005/Atom" xmlns:gs="http://schemas.google.com/spreadsheets/2006">',
        if @id then
          "<id>#{@id}</id>"
        else
          ''
        end,
        "<category scheme=\"http://schemas.google.com/spreadsheets/2006\" term=\"http://schemas.google.com/spreadsheets/2006#worksheet\"/>",
        "<title type=\"text\">#{title}</title>",
        if link(LINK_EDIT) then
          "<link rel=\"#{LINK_EDIT}\" type=\"application/atom+xml\" href=\"#{link(LINK_EDIT)}\"/>"
        else
          ''
        end,
        "<gs:rowCount>#{row_count}</gs:rowCount>",
        "<gs:colCount>#{col_count}</gs:colCount>",
        "</entry>",
    ].join(Sheety::NEWLINE)
  end

  def to_s
    "<Worksheet::#{object_id} '#{title}' (#{col_count} x #{row_count}) w/ #{Sheety.length_s(@rows)} Rows & #{Sheety.length_s(@cells)} Cells>"
  end

  def inspect
    to_s
  end
end