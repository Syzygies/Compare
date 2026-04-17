# Common functionality for bin/ directory tools
# See bin/doc/common/common.md for documentation

module Common
  # Extension detection functionality
  # To be migrated from analyze-extensions
  module Extensions
    class << self
      def detect(filename)
        basename = File.basename(filename)
        
        # First pass: find the extension territory
        if basename =~ /\.([a-zA-Z.]+[^a-zA-Z.]?)/
          ext_territory = $1
          
          # Second pass: get final extension
          if ext_territory.include?('.')
            # For compound extensions like 'min.js', take after last period
            ext = ext_territory[ext_territory.rindex('.') + 1..]
          else
            # Simple extension or one with terminator like 'html?'
            ext = ext_territory
          end
        else
          ext = ''
        end
        
        ext
      end

      def matches_pattern?(filename, pattern)
        detect(filename) == pattern
      end

      def matches_any?(filename, patterns)
        patterns.any? { |pattern| matches_pattern?(filename, pattern) }
      end
    end
  end

  module TableFormatter
    def self.format_table(title, headers, rows, totals, numeric_cols = [1, 2, 3, 4])
      puts "\n#{title}\n\n"
      
      # Get field widths from headers for numeric columns
      field_widths = headers.map(&:length)
      
      # Format numeric fields with right justification based on header widths
      formatted_rows = rows.map do |row|
        row.map.with_index do |val, i|
          if numeric_cols.include?(i)
            "%#{field_widths[i]}s" % val
          else
            val
          end
        end
      end
      
      # Format totals row similarly
      formatted_totals = totals.map.with_index do |val, i|
        if numeric_cols.include?(i)
          "%#{field_widths[i]}s" % val
        else
          val
        end
      end
      
      # Format through column command
      formatted = IO.popen(['column', '-t', '-s', '|'], 'w+') do |io|
        table_rows = [
          headers.join(' | '),
          *formatted_rows.map { |row| row.join(' | ') },
          formatted_totals.join(' | ')
        ]
        io.puts table_rows.map(&:strip).join("\n")
        io.close_write
        io.read
      end

      # Add spacing around header and footer
      lines = formatted.lines.map(&:rstrip)
      puts [
        lines[0],         # header
        "",              # blank after header
        lines[1..-2],    # body rows
        "",              # blank before footer
        lines[-1]        # footer
      ].flatten.join("\n")
    end

    def self.human_size_mb(bytes, decimal_places = 1)
      "%.#{decimal_places}f" % (bytes.to_f / 1024 / 1024)
    end
  end
end 