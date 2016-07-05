#!/bin/bash --login

# The log file should show what's run, and the
# output file what happened on the last run.
LOG=/tmp/scrapers.log
OUTPUT=/tmp/scrapers.out
#PATH=/usr/local/bin:/home/tess/.rvm/gems/ruby-2.2.1/bin:/home/tess/.rvm/gems/ruby-2.2.1@global/bin:/home/tess/.rvm/rubies/ruby-2.2.1/bin:/home/tess/.rvm/bin:/usr/local/bin:/home/tess/bin:/usr/local/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games

rvm use ruby-2.2.1

if [ "$#" -eq 0 ];then
    echo "Usage: run_scrapers.sh <scraper_directory>"
	exit 0
else
    DIR=$1
    date >> $LOG
    cat /dev/null > $OUTPUT
fi

#rvm use 2.2-head@scraper
#legacy_software_carpentry_scraper # Probably doesn't need re-running


SCRAPERS=(biocomp_rdfa_scraper
          bitsvib_rdfa_scraper
          csc_events_scraper
          data_carpentry_scraper
          dtls_events
          ebi_scraper
          elixir_events_scraper
          futurelearn_rdfa_scraper
          genome3d_scraper
          goblet_rdfa_scraper
          khan_academy_api
          legacy_software_carpentry_scraper
          ngs_registry_scraper
          sib_scraper
          iann_events_uploader
          coursera_scraper
          erasys_rdfa_scraper
          birmingham_metabolomics_transfer
          france-bioinformatique_scraper
          )


for SCRAPER in "${SCRAPERS[@]}"
do
   :
   echo "Running $SCRAPER.rb" >> $LOG
   cd $DIR && ruby $SCRAPER.rb >> $OUTPUT 2> /dev/null
done

rake sunspot:solr:reindex

echo "Done!" >> $LOG
echo >> $LOG
