require 'asciidoctor'
require 'erb'
require 'date'

#set build date
builddate = Date::today

#Currently supported versions
versions = ["1.0", "2.0"]

readers = ["internal", "external"]

os = ["Linux", "Microsoft Windows Server", "macOS"]

guard 'shell' do
  watch(/^.*\.adoc$/) {|m|
	doc = Asciidoctor.load_file m[0]
	title = doc.attributes["doctitle"].gsub!(/\s/,'_')
	doctype = doc.attributes["doctype"]
	target = doc.attributes["target"]
	
	

	if doctype == "manual"

		#loop through the product version array and build each
		versions.each {
			| x |
			revnumber = x
			if revnumber >= "2.0" then
				stylesheet = "styles.css"
				coy = "My company"
			else
				stylesheet = "old_styles.css"
				coy = "old company"
			end
			Asciidoctor.render_file(m[0],
				:safe => 'unsafe',
			 	:attributes => {'revnumber'=>"#{revnumber}", 'revdate'=>"#{builddate}", 'stylesheet'=>"#{stylesheet}", 'coy' => "#{coy}"},
				:in_place => false,
				:to_file=>"#{title}_#{revnumber}.html")
		}

		#loop through the product version array and build a web publication version
		versions.each {
			| x |
			revnumber = x
			Asciidoctor.render_file(m[0],
				:safe => 'unsafe',
			 	:attributes => {'revnumber'=>"#{revnumber}", 'revdate'=>"#{builddate}", 'target'=>'web'},
				:in_place => false,
				:to_file=>"#{title}_#{revnumber}_web.html")
			
			`mv #{title}_#{revnumber}_web.html /home/christopher/projects/build/documents/web/#{revnumber}/#{title}_#{revnumber}.html`
			`rsync -r images/ /home/christopher/projects/build/documents/web/#{revnumber}/images/`
			`rsync -r stylesheets/ /home/christopher/projects/build/documents/web/#{revnumber}/stylesheets/`
		}

		#loop though the dp3 versions and build an epub version
		# NOTE THIS IS EXPERIMENTAL!
#		versions.each {
#		`asciidoctor-epub3 -D /home/christopher/Projects/build/documents/epub #{m[0]}`
#		}


	elsif doctype == "rnotes"
		#get version number
		revnumber = doc.attributes["revnumber"]

		#loop through readers array and build each
		readers.each {
			| x |
			reader = x
			Asciidoctor.render_file(m[0],
				:safe => 'unsafe',
			 	:attributes => {'audience'=>"#{reader}"},
				:in_place => false,
				:to_file=>"#{title}_#{reader}.html")

		}
	elsif doctype == "upgrade-guide"
		#get version number
		revnumber = doc.attributes["revnumber"]
		previous = doc.attributes["prevrelease"]
		client = doc.attributes["client"]

		#loop through readers array and build each
		os.each {
			| x |
			dp3platform = x
			if os == "Linux"
				platform = "Linux"
			else
				platform = "Windows"
			end
			Asciidoctor.render_file(m[0],
				:safe => 'unsafe',
			 	:attributes => {'platform'=>"#{dp3platform}"},
				:in_place => false,
				:to_file=>"#{title}_#{previous}_#{revnumber}_#{platform}_#{client}.html")
		}
	else
		revnumber = doc.attributes["revnumber"]
		Asciidoctor.render_file(m[0],
				:safe => 'unsafe',
			 	:attributes => {'revnumber'=>"#{revnumber}"},
				:in_place => false,
				:to_file=>"#{title}_#{revnumber}.html")
	end

  }
end


guard 'shell' do
  watch(/^.*\.html$/) {|m|
	parentdir = File.expand_path("..", File.dirname(m[0]))
	filename = File.basename(m[0])
	
		pdf = File.basename(m[0]).gsub!('html','pdf')
		#epub = File.basename(m[0]).gsub!('html','epub')
		#`prince --http-proxy=http://localhost:3128 --insecure --javascript --script=scripts/prince.js #{filename} -o #{pdf}`
		#`prince --insecure --javascript --script=scripts/prince.js #{filename} -o #{pdf}`
		#`pandoc -f html -t epub3 -o #{epub} #{filename}`
		#`mv #{filename} ../test/resources/`
		#`mv #{pdf} ../test/resources/`
		#`mv #{epub} ../test/resources/`
		if filename.include? "Release_Notes"
		`mv #{pdf} /home/christopher/projects/build/documents/release_notes/`
		`mv #{filename} /home/christopher/projects/build/documents/release_notes/html/`
		elsif filename.include? "Training"
		`mv #{pdf} /home/christopher/projects/build/documents/training/`
		`mv #{filename} /home/christopher/projects/build/documents/training/html/`
		else
		`mv #{filename} /home/christopher/projects/build/documents/html/`
		`mv #{pdf} /home/christopher/projects/build/documents/pdf/`
		#`mv #{epub} /home/christopher/Projects/DP3_Documentation/documents/`
		end
  }
end
