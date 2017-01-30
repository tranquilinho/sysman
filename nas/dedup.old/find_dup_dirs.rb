#!/usr/bin/env ruby
require 'pp'

DUPINDEX="dupindex.ms"

file_index={}

if File.exists?(DUPINDEX)
  puts "Loading MD5 index from #{DUPINDEX}"
  File.open(DUPINDEX,"rb") {|f| file_index = Marshal.load(f)}
else
  ARGF.each do |line|
    (hash,filename) = line.split
    dup_list =  file_index[hash]
    dup_list=[] if dup_list.nil? 
    dup_list << filename
    file_index[hash]=dup_list
  end
  file_index.reject! { |k,e| e.size == 1 }
  File.open(DUPINDEX,"wb") do |file|
     Marshal.dump(file_index,file)
  end
end
puts "Index size: #{file_index.size}"

# For each directory, a table with the other directories with dup files in common (including itself)
dup_index={}
file_index.each do |index_key,dups|
  (key,rest) = dups
  basedir=File.dirname(key)
  filename=File.basename(key)

  current_dup_index = dup_index[basedir]
  current_dup_index={} if current_dup_index.nil? 
  self_dups_files = current_dup_index[basedir]
  self_dups_files=[] if self_dups_files.nil? 
  self_dups_files << filename
  current_dup_index[basedir]=self_dups_files

  rest.each do |d|
    dupbasedir=File.dirname(d)
    # puts "#{basedir} => #{dupbasedir} - #{dupfilename}"
    other_dups_files = current_dup_index[dupbasedir]
    other_dups_files= [] if other_dups_files.nil? 
    other_dups_files << filename
    current_dup_index[dupbasedir]=other_dups_files
  end
  dup_index[basedir]=current_dup_index
end

# Find directories with all files duplicated (that is, they have the same files as the directory itself)
dup_list=[]
dup_index.each do |key,current_dup_index|
  # current_dup_index.keys.group_by { |k| current_dup_index[k]}
  all_files = current_dup_index[key]
  current_dup_index.each do |k,files|
    # files were inserted into both "files" and "all_files" in same order, so no former additional sorting should be needed
    if k != key and all_files == files
      puts "#{key} #{k}"
    end
  end 
end
