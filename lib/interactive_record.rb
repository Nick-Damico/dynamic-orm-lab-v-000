require_relative "../config/environment.rb"
require 'active_support/inflector'
require "pry"
class InteractiveRecord

    def self.table_name
      self.to_s.downcase.pluralize
    end

    def table_name_for_insert
      self.class.table_name
    end

    def self.column_names
      DB[:conn].results_as_hash = true

      sql = "pragma table_info('#{table_name}')"
      table_info = DB[:conn].execute(sql)

      table_info.collect do |column|
        column["name"]
      end.compact

    end

    def col_names_for_insert
      self.class.column_names.delete_if { |col| col == "id" }.join(", ")
    end

    def values_for_insert
      values = []
      self.class.column_names.each do |name|
        values << "'#{send(name)}'" unless send(name).nil?
      end.join(", ")
      values.join(", ")
    end

    def initialize(options={})
      options.each do |property, value|
        self.send("#{property}=", value)
      end
    end

    def save
      sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"

      DB[:conn].execute(sql)
      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
      sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
      DB[:conn].execute(sql)
    end

    def self.find_by(hash_value)
      key = hash_value.keys[0].to_s.upcase
      value = "'#{hash_value.values[0]}'"
      sql = "SELECT * FROM #{table_name} WHERE #{key} = #{value}"
      DB[:conn].execute(sql)
    end

end
