require_relative 'feed'

class Sheety::Row < Sheety::Feed
  def initialize(parent, entry=nil)
    @attrs = {}
    super(parent, entry)
  end

  def parse(entry)
    super(entry)
    entry.keys.each do |k|
      if /\Agsx:/i =~ k
        @attrs[k] = entry[k][0]
      end
    end
  end

  def value(key)
    return @attrs['gsx:' + key.to_s]
  end

  alias_method :[], :value

  def []=(key, val)
    @attrs['gsx:' + key.to_s]=val
  end

  def put(hash)
    hash.each { |kv| self[Sheety::Row.normalize_key(kv[0])] = kv[1] }
  end

  def as_xml
    return [
        '<entry xmlns="http://www.w3.org/2005/Atom" xmlns:gsx="http://schemas.google.com/spreadsheets/2006/extended">',
        if !@id then
          ''
        else
          "<id>#{@id}</id>"
        end,
        if !@id then
          ''
        else
          "<updated>#{DateTime.now}</updated>"
        end,
        if !@id then
          ''
        else
          '<category scheme="http://schemas.google.com/spreadsheets/2006" term="http://schemas.google.com/spreadsheets/2006#list"/>'
        end,
        if !@id then
          ''
        else
          "<link rel=\"edit\" type=\"application/atom+xml\" href=\"#{@links[LINK_EDIT]}\" />"
        end,
        *(@attrs.map { |pair| "<#{pair[0]}>#{pair[1]}</#{pair[0]}>" }),
        '</entry>',
    ].join(Sheety::NEWLINE)
  end

  def save
    uri = link(LINK_EDIT)
    if uri
      return Sheety::Api.inst.put_feed(uri, as_xml)
    else
      return Sheety::Api.inst.post_feed(@parent.link(Sheety::Worksheet::LINK_POST), as_xml)
    end
  end

  alias_method :update, :save

  # ProTip: Delete Rows in Reverse, otherwise the shift of deletion will cause unexpected behaviors
  def delete
    return Sheety::Api.inst.delete_feed(link(LINK_EDIT))
  end

  def to_s
    "<#{self.class}::#{object_id} #{(@attrs.map { |kv| "#{kv[0].gsub('gsx:', '')}:#{kv[1]}" }).join(', ')}>"
  end

  def inspect
    to_s
  end

  def self.normalize_key(key)
    key.to_s.gsub(/[^a-zA-Z0-9]/, '')
  end
end