#!/usr/bin/env ruby
require 'pp'

DUPINDEX="dupindex.ms"

file_index={}
savings=0

if File.exists?(DUPINDEX)
  puts "Loading MD5 index from #{DUPINDEX}"
  File.open(DUPINDEX,"rb") {|f| file_index = Marshal.load(f)}
else
  ARGF.each do |line|
    (hash,filename) = line.split
    dup_list =  file_index[hash]
    dup_list=[] if dup_list.nil? 
    if File.exists?(filename)
       dup_list << filename
       savings += File.size(filename)
    end
    file_index[hash]=dup_list
  end
  file_index.reject! { |k,e| e.size == 1 }
  File.open(DUPINDEX,"wb") do |file|
     Marshal.dump(file_index,file)
  end
end
puts "Index size: #{file_index.size}. File dedup saving: #{savings}"

