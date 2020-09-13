#! /usr/bin/env ruby

# CREDITS: https://sorashi.github.io/fix-facebook-json-archive-encoding/

path = '.'

Dir["#{path.sub('[\\/]$', '')}/**/message_" + ARGV[0] + ".json"].
each{|file|
    File.write(file,
        File.read(file)
        .gsub(/\\u00([a-f0-9]{2})/) {|m|
            $1.to_i(16).chr
        }
    )
    puts "Done #{file}"
}
