module Wordmove
  class SqlAdapter
    attr_reader :sql_path, :source_config, :dest_config

    def initialize(sql_path, source_config, dest_config)
      @sql_path = sql_path
      @source_config = source_config
      @dest_config = dest_config
    end

    def adapt!
      replace_vhost!
      replace_wordpress_path!
      replace_domain!
    end

    def replace_vhost!
      source_vhost = source_config[:vhost]
      dest_vhost = dest_config[:vhost]
      replace_field!(source_vhost, dest_vhost)
    end

    def replace_domain!
      source_domain = URI(source_config[:vhost]).host
      dest_domain = URI(dest_config[:vhost]).host
      replace_field!(source_domain, dest_domain)
    end

    def replace_wordpress_path!
      source_path = source_config[:wordpress_absolute_path] || source_config[:wordpress_path]
      dest_path = dest_config[:wordpress_absolute_path] || dest_config[:wordpress_path]
      replace_field!(source_path, dest_path)
    end

    def replace_field!(source_field, dest_field)
      if source_field && dest_field
        serialized_replace!(source_field, dest_field)
        simple_replace!(source_field, dest_field)
      end
    end

    def serialized_replace!(source_field, dest_field)
      length_delta = source_field.length - dest_field.length

      File.open("#{sql_path}.tmp", 'w') do |temp_output|
        File.open(sql_path, 'r') do |file_replace|
          while line = file_replace.gets
            line.gsub!(/s:(\d+):([\\]*['"])(.*?)\2;/) do |match|
              length = $1.to_i
              delimiter = $2
              string = $3

              string.gsub!(/#{Regexp.escape(source_field)}/) do |match|
                length -= length_delta
                dest_field
              end

              %(s:#{length}:#{delimiter}#{string}#{delimiter};)

            end # gsub

            temp_output.write(line)

          end # while
        end  # file read
      end # file write

      File.rename("#{sql_path}.tmp", sql_path)
    end

    def simple_replace!(source_field, dest_field)
      File.open("#{sql_path}.tmp", 'w') do |temp_output|
        File.open(sql_path, 'r') do |file_replace|
          while line = file_replace.gets
            line.gsub!(source_field, dest_field)
            temp_output.write(line)
          end # while
        end # file read
      end # file write

      File.rename("#{sql_path}.tmp", sql_path)
    end

  end
end
