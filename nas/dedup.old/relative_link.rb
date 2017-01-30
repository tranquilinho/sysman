#!/usr/bin/env ruby

ARGF.each do |line|
  (d1,d2)=line.split
  dirs1=d1.split("/")
  dirs2=d2.split("/")
  s = ""
  index=0
  (0..(dirs2.size-1)).each do |i|
    if dirs1[i] != dirs2[i]
      index=i
      break
    end
  end
  (dirs2.size - index -1 ).times { s << "../"} 
  (index..dirs1.size-1).each { |i| s <<  dirs1[i] +"/" }
  puts s
end
