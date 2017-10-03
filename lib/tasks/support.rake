namespace :support do 
	
	desc 'Add evidence of financial support to a user, org or repo'
	task add_evidence: :environment do
		r = Repository.first
		s = r.support || r.create_support
		s.support_evidences.create({

			currency: 'USD',
      amount: 5,
      description: 'Donation from Ashley Mannix on Open Collective',
      source_url: 'https://opencollective.com/octobox/transactions/23121228-cfde-41ac-bc40-c19ef89b1c8e/invoice.pdf',
      published_at: Date.parse('2 October 2017')

			})
	end

	desc 'Grab evidence of financial support from open collective'
	task open_collective: :environment do
		offset = 0		
		while true
			result = PackageManager::Base.get("https://opencollective.com/api/discover?sort=newest&offset=#{offset}") 
			break if result['collectives'] == []
			page_groups(result)
			offset += 12
		end
	end
end

def page_groups(result)
	result['collectives'].each do |collective|
		puts collective['slug']
		if collective['settings']['githubRepo']
			supportable = Repository.create_from_host('Github', collective['settings']['githubRepo'])
			page_tx(supportable, collective['slug'])
		elsif collective['settings']['githubOrg']
			o = AuthToken.client.user(collective['settings']['githubOrg'])
      if o.type == "Organization"
        supportable = RepositoryOrganisation.create_from_host('GitHub', o)
      else
        supportable = RepositoryUser.create_from_host('GitHub', o)
      end
			page_tx(supportable, collective['slug'])
		end 
	end
end

def page_tx(supportable, slug)
	page = 1 
	while true
		tx_list = PackageManager::Base.get( "https://opencollective.com/api/groups/#{slug}/transactions?page=#{page}")
		break if tx_list == []
		s = supportable.support || supportable.create_support
		tx_list.each do |tx|
			import_tx(s,tx)
		end
		page += 1
	end
end 

def import_tx(support, tx)
	return unless tx['type'] == 'DONATION'
	puts tx['description']
	support.support_evidences.find_or_create_by({
		currency: tx['txnCurrency'],
    amount: tx['amountInTxnCurrency'],
    description: "Donation from #{tx['UserId']} on Open Collective",
    source_url: "https://opencollective.com/octobox/transactions/#{tx['uuid']}/invoice.pdf",
    published_at: tx['createdAt']
	})
end