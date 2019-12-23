#!/usr/bin/env ruby

require 'mastodon'

client = Mastodon::REST::Client.new(base_url: 'https://starflower.space', bearer_token: '')

statuses = client.public_timeline

since_id = statuses.first.id

matchtags = ["transcrowdfund", "emergencycrowdfund", "disabilitycrowdfund", "showupforwishes"]
maybetags = ["mutualaid"]
blocktags = ["nobot"]
matchregs = [
	/<a[^>]*href="https?:\/\/(www\.)?gofundme.com[^"]*"/,
	/<a[^>]*href="https?:\/\/(www\.)?cash.me[^"]*"/,
	/<a[^>]*href="https?:\/\/(www\.)?paypal.me[^"]*"/,
	/<a[^>]*href="https?:\/\/(www\.)?paypal.com[^"]*"/,
	/<a[^>]*href="https?:\/\/(www\.)?ko-fi.com[^"]*"/,
	/<a[^>]*href="https?:\/\/(www\.)?patreon.com[^"]*"/,
	/<a[^>]*href="https?:\/\/(www\.)?venmo.com[^"]*"/,
	/<a[^>]*href="https?:\/\/(www\.)?liberapay.com[^"]*"/,
	/<a[^>]*href="https?:\/\/(www\.)?facebook.com\/donate[^"]*"/,
]

recent_boosts = {}

while true do

	delete_list = []
	recent_boosts.delete_if do |account, last_boosted|
		puts "Account #{account} left the 24 hour window so we can reboost them now."
		last_boosted < (Time.now.to_i - 86400)
	end

	statuses.each do |status|

		# Check all the reasons we wouldn't want to boost the post
		
		# if we already boosted it
		next if status.reblogged?
		# if the poster is a bot
		next if status.account.bot?
		# if the poster's profile contains the string "nobot"
		next if /nobot/ =~ status.account.note.downcase
		# skip if we recently boosted a post from this account
		next if recent_boosts[status.account.id]
		# if any of the hashtags in the post are in the list of blocked hashtags
		status.tags.each do |tag|
			blocktags.each do |blocktag|
				next if tag.name.downcase == blocktag
			end
		end

		# Now check if the post is one we'd want to boost

		should_boost = false

		# if any of the url regexes match
		#matchregs.each do |reg|
		#	if reg =~ status.content.downcase then
		#		should_boost = true
		#	end
		#end

		# or if any of the hashtags match
		status.tags.each do |tag|
			# match tags always match
			matchtags.each do |matchtag|
				if tag.name.downcase == matchtag then
					should_boost = true
				end
			end
			# maybe tags only match if the content also matches one of the regexes
			maybetags.each do |maybetag|
				if tag.name.downcase == maybetag then
					matchregs.each do |reg|
						if reg =~ status.content.downcase then
							should_boost = true
						end
					end
				end
			end
		end


		if should_boost then
			puts "==== boosting ===="
			puts status.content
			recent_boosts[status.account.id] = Time.now.to_i
			client.reblog status.id
		end
	end

	statuses = client.public_timeline(since_id: since_id)

	if statuses.size == 0 then
		sleep 3600
	else
		since_id = statuses.first.id
	end
end
