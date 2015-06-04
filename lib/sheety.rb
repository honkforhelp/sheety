module Sheety
  NEWLINE = "\n"

  def self.length_s(val)
    if val.respond_to?(:length) then val.length.to_s else "??" end
  end

end

require_relative 'sheety/api'
require_relative 'sheety/cell'
require_relative 'sheety/row'
require_relative 'sheety/worksheet'
require_relative 'sheety/spreadsheet'

module Sheety
  ## Convenience Methods
  def self.auth
    return Api.inst.auth
  end

  def self.sheets(force_refetch=false)
    return Api.inst.sheets(force_refetch)
  end

  def self.sheets_where(constraints)
    return Api.inst.sheets_where(constraints)
    end

  def self.find_sheet(constraints)
    return Api.inst.find_sheet(constraints)
  end

  def self.sheets_except(constraints)
    return Api.inst.sheets_except(constraints)
  end

  def self.sheets_except_any(constraints)
    return Api.inst.sheets_except_any(constraints)
  end

  def self.list_sheets
    sheets.each_with_index do |sheet, index|
      puts "Sheet #{index} - #{sheet}"
    end

    return nil
  end
end
