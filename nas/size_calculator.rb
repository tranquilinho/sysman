#! /usr/bin/env ruby

# it would be more flexible if implemented as an DSL...
# right now, each token comes as a parameter of the command
# Minimum unit is KB (that is, a number with no unit is interpreted as KB)

FACTOR = { "K" => 1, "M" => 1024, "G" => 1048576, "T" => 1073741824 }

def convert(number,unit)
    (number / FACTOR[unit]).to_s + unit
end

expression=""

ARGV.each do |arg|
  e = arg
  if arg =~ /[kmgt]/i
    number= arg.to_i
    unit= arg[ /[0-9]*([kKmMgGtT]).*/,1 ].upcase
    e = number * FACTOR[unit]
  end
  expression << e.to_s
end
result_in_KB= eval(expression)
result = if result_in_KB > FACTOR["T"]
    convert(result_in_KB,"T")
  elsif result_in_KB > FACTOR["G"]
    convert(result_in_KB,"G")
  elsif result_in_KB > FACTOR["M"]
    convert(result_in_KB,"M")
  else 
    result_in_KB.to_s + "K"
end
puts result
