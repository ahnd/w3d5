require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @cols if @cols
    @columns = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        "#{table_name}"
      SQL

    @cols = @columns.first.map {|column| column.to_sym}
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) do
        self.attributes[column]
      end
      define_method(column.to_s + "=") do |value|
        self.attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    # ...
    data = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL

    parse_all(data)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result)}
  end

  def self.find(id)
    data = DBConnection.execute(<<-SQL, id)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        #{table_name}.id = ?
    SQL

    return nil if data.empty?
    parse_all(data).first

  end

  def initialize(params = {})
    params.each do |k, v|
      raise "unknown attribute '#{k}'" unless self.class.columns.include?("#{k}".to_sym)
      self.send("#{k}" + "=", v)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    res = []
    attributes.each do |k, v|
      res << v
    end
    res
  end

  def insert
    col_names = self.class.columns.drop(1).join(", ")
    question_marks = (["?"] * self.class.columns.drop(1).length).join(", ")

    data = DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    cols = self.class.columns.map do |column|
        "#{column} = ?"
      end.join(", ")
    data = DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{cols}
      WHERE
        #{self.class.table_name}.id = ?
      SQL
  end

  def save
    id.nil? ? insert : update
  end
end
