#!/usr/bin/env ruby

require 'mastodon'

client = Mastodon::REST::Client.new(base_url: 'https://starflower.space', bearer_token: '')

statuses = client.public_timeline

since_id = statuses.first.id

matchtags = ["transcrowdfund", "emergencycrowdfund", "disabilitycrowdfund", "showupforwishes"]
blocktags = ["nobot"]
matchregs = []
#matchregs = [/<a[^>]*href="https?:\/\/(www\.)?gofundme.com[^"]*"/]

while true do
	statuses.each do |status|

		# Check all the reasons we wouldn't want to boost the post
		
		# if we already boosted it
		if status.reblogged? then
			next
		end

		# if the poster is a bot
		if status.account.bot? then
			next
		end

		# if the poster's profile contains the string "nobot"
		if /nobot/ =~ status.account.note.downcase then
			next
		end

		# if any of the hashtags in the post are in the list of blocked hashtags
		status.tags.each do |tag|
			blocktags.each do |blocktag|
				next if tag.name.downcase == blocktag
			end
		end

		# Now check if the post is one we'd want to boost

		should_boost = false

		# if any of the url regexes match
		matchregs.each do |reg|
			if reg =~ status.content then
				should_boost = true
			end
		end

		# or if any of the hashtags match
		status.tags.each do |tag|
			matchtags.each do |matchtag|
				if tag.name.downcase == matchtag then
					should_boost = true
				end
			end
		end


		if should_boost then
			puts "==== boosting ===="
			puts status.content
			client.reblog status.id
		end
	end
	statuses = client.public_timeline(since_id: since_id)
	if statuses.size == 0 then
		puts "no new posts"
		sleep 10
	else
		since_id = statuses.first.id
	end
end
