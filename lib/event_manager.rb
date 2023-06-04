require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

week_names = {0 => "Sunday", 1 => "Monday",2 => "Tuesday", 3 => "Wednesday",
              4 => "Thursday", 5=> "Friday", 6 =>"Saturday"}
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
  phone_number.gsub!(/\D/,'')
  if phone_number.length == 10
    phone_number
  elsif phone_number.length == 11 && phone_number[0] == "1"
    phone_number[1..10]
  else
    "Bad number"
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hourly_activity = Array.new(24, 0)
daily_activity = Array.new(7, 0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])

  phone_number = clean_phone_number(row[:homephone])

  time = DateTime.strptime(row[:regdate], "%m/%d/%y %H:%M")
  hourly_activity[time.hour] += 1
  daily_activity[time.wday] += 1

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

def get_index_with_largest_val(arr)
  res = 0
  arr.each_with_index do |curr, index|
    if arr[res] < curr
      res = index
    end
  end
  res
end

puts "Most active hour is #{get_index_with_largest_val(hourly_activity)}"
puts "Most active day of the week is #{week_names[get_index_with_largest_val(daily_activity)]}"
