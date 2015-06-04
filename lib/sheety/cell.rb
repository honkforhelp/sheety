require_relative 'feed'

class Sheety::Cell < Sheety::Feed
  COL_LETTERS = [nil, *('A'..'Z')]

  attr_reader :row, :col, :input_value, :numeric_value, :display_value

  def parse(entry)
    super(entry)
    cell = entry['gs:cell'][0]

    @row = cell['row'].to_i
    @col = cell['col'].to_i
    @input_value = cell['inputValue']
    @numeric_value = cell['numericValue'].to_f
    @display_value = cell['content']
  end

  def value=(new_value)
    if new_value != @input_value
      @input_value = new_value
      @numeric_value = nil
      @display_value = nil
    end
  end

  def col=(c)
    if @col.nil?
      @col = c
    end
  end

  def row=(r)
    if @row.nil?
      @row = r
    end
  end

  def rc
    return "R#{row}C#{col}"
  end

  def as_xml
    return [
        "<entry xmlns=\"http://www.w3.org/2005/Atom\" xmlns:gs=\"http://schemas.google.com/spreadsheets/2006\">",
        "<id>#{
        if @id then
          @id
        else
          @parent.link(Sheety::Worksheet::LINK_CELLS) + "/#{rc}"
        end}</id>",
        "<link rel=\"#{Sheety::Feed::LINK_EDIT}\" type=\"application/atom+xml\" href=\"#{
        if link(LINK_EDIT) then
          link(LINK_EDIT)
        else
          @parent.link(Sheety::Worksheet::LINK_CELLS) + "/#{rc}"
        end}\"/>",
        "<gs:cell row=\"#{row}\" col=\"#{col}\" inputValue=\"#{input_value}\"/>",
        "</entry>",
    ].join(Sheety::NEWLINE)
  end

  def as_batch_xml
    return [
        "<entry>",
        "<batch:id>#{title}</batch:id>",
        "<batch:operation type=\"update\" />",
        "<id>#{id}</id>",
        "<link rel=\"#{LINK_EDIT}\" type=\"application/atom+xml\"",
        "href=\"#{link(LINK_EDIT)}\"/>",
        "<gs:cell row=\"#{@row}\" col=\"#{@col}\" inputValue=\"#{@input_value}\"/>",
        "</entry>",
    ].join(Sheety::NEWLINE)
  end

  def save
    uri = link(LINK_EDIT)
    if uri
      return Sheety::Api.inst.put_feed(uri, as_xml)
    else
      return Sheety::Api.inst.post_feed(@parent.link(Sheety::Worksheet::LINK_CELLS), as_xml)
    end
  end

  def to_s
    "<#{self.class}::#{object_id} #{rc} input='#{input_value}' numeric='#{numeric_value}' display='#{display_value}'>"
  end

  def inspect
    to_s
  end
end