require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    # ...
    cols = params.keys.map {|key| "#{key} = ?"}.join(" AND ")
    p cols
    values = params.values
    p values
    data = DBConnection.execute(<<-SQL, *values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{cols}
    SQL
    parse_all(data)
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
