require 'scraperwiki'
require 'mechanize'

url = "https://imagine.vincent.wa.gov.au/planning-consultations"

agent = Mechanize.new
page_number = 0
loop do
  page_number += 1
  page_url = "#{url}?page=#{page_number}"
  page = agent.get(page_url)

  puts "Parsing the results on page #{page_number}: #{page_url}"
  application_count = 0
  page.search('li.shared-content-block').each do |li|
    application_count += 1
    info_url = li.at('a')['href']
    details_page = agent.get(info_url)
    # Extract all text after "Serial Number:" from the second paragraph under the div which has class "truncated-description".
    council_reference = details_page.search('div.truncated-description p')[1].inner_text.gsub(/[\r\n]/, "").sub(/.*Serial Number:/, '').squeeze(' ').strip
    puts "Parsing information for " + council_reference
    puts "    Raw date text: " + li.search('div.truncated-description b')[1].inner_text.gsub(/[\r\n]/, "").squeeze(' ').strip.gsub(/\.$/, '')
    record = {
      'council_reference' => council_reference,
      'address' => li.at('a').inner_text.gsub("\r\n", "").squeeze(' ').strip,
      # Extract all text after "Development Details:" under the div which has class "truncated-description".
      'description' => li.at('div.truncated-description').inner_text.gsub(/[\r\n]/, "").sub(/.*Development Details:/, '').squeeze(' ').strip,
      'info_url' => info_url,
      'comment_url' => 'mailto:mail@vincent.wa.gov.au',
      'date_scraped' => Date.today.to_s,
      # Extract all text from the second <b>...</b> element under the div which has class "truncated-description" (and trim the trailing ".").
      'on_notice_to' => Date.parse(li.search('div.truncated-description b')[1].inner_text.gsub(/[\r\n]/, "").squeeze(' ').strip.gsub(/\.$/, '')).to_s
    }
    puts "Saving page #{page_number} application record #{application_count}."
    puts "    council_reference: " + record['council_reference']
    puts "              address: " + record['address']
    puts "          description: " + record['description']
    puts "             info_url: " + record['info_url']
    puts "          comment_url: " + record['comment_url']
    puts "         date_scraped: " + record['date_scraped']
    puts "         on_notice_to: " + record['on_notice_to']
    ScraperWiki.save_sqlite(['council_reference'], record)
  end
  
  # Continue paging until a page is encountered with no applications (or, as a safety precaution, a large number of pages have been processed).
  puts "Found #{application_count} application(s) on page #{page_number}."
  break if application_count == 0 or page_number > 100
end
puts "Complete."
