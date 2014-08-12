module ActiveRecord
  module LikeSearch
    def table
      self.arel_table
    end

    def starts_with(attribute, string)
      where(table[attribute].matches("#{string}%"))
    end

    def ends_with(attribute,string)
      where(table[attribute].matches("%#{string}"))
    end

    def contains(attribute,string)
      where(table[attribute].matches("%#{string}%"))
    end

  end

  Base.extend LikeSearch
end