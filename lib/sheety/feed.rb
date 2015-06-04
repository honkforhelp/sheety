require_relative 'children'

class Sheety::Feed
  include Sheety::Children

  LINK_SELF = 'self'
  LINK_EDIT = 'edit'
  LINK_ALT = 'alternate'

  attr_reader :id, :content, :updated, :parent

  attr_accessor :title

  def initialize(parent, entry=nil)
    @parent = parent
    @links = {}
    unless entry.nil?
      parse(entry)
    end
  end

  def parse(entry)
    return if entry.blank? || entry.length == 0
    @title = Sheety::Feed.deref(entry, 'title', 0, 'content')
    @id = Sheety::Feed.deref(entry, 'id', 0)
    @content = Sheety::Feed.deref(entry, 'content', 'content')
    @updated = Sheety::Feed.deref(entry, 'updated', 0)
    @updated = DateTime.iso8601(@updated) if !@updated.blank?
    add_links(Sheety::Feed.deref(entry ,'link'))
  end

  def link(key)
    @links[key]
  end

  def as_xml
    return "<entry></entry>"
  end

  protected

  def add_links(links)
    return if links.blank?
    # Conflict prevention is here to preserve original values parsed from the entities.
    # This mainly comes into play with the List Feed (a.k.a.: Rows) because we need the
    #   ability to add new ones.
    links.each { |link_obj| @links[link_obj['rel']] = link_obj['href'] }
  end

  def link_edit
    link(LINK_EDIT)
  end

  def link_add
    parent.link(parent.class::LINK_ADD)
  end

  def save
    result = if link_edit
               Sheety::Api.inst.put_feed(link_edit, as_xml)
             else
               Sheety::Api.inst.post_feed(link_add, as_xml)
             end
    parse(result)
    return result
  end

  def to_s
    "<#{self.class}::#{object_id}>"
  end

  def inspect
    to_s
  end

  private

  def self.deref(data, *keys)
    found = data
    keys.each do |k|
      next if found.blank?
      found = found[k]
    end
    return found
  end
end