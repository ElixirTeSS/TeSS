#!/bin/bash --login

# The log file should show what's run, and the
# output file what happened on the last run.
LOG=/tmp/scrapers.log
OUTPUT=/tmp/scrapers.out

if [ "$#" -eq 0 ];then
    echo "Usage: run_scrapers.sh <scraper_directory>"
	exit 0
else
    DIR=$1
    date >> $LOG
    cat /dev/null > $OUTPUT
fi

#rvm use 2.2-head@scraper

SCRAPERS=(bitsvib_events_scraper
          bitsvib_scraper
          csc_events_scraper
          data_carpentry_scraper
          ebi_scraper
          elixir_events_scraper
          genome3d_scraper
          goblet_rdfa_scraper
          #legacy_software_carpentry_scraper # Probably doesn't need re-running
          ngs_registry_scraper
          sib_scraper
          )

for SCRAPER in "${SCRAPERS[@]}"
do
   :
   echo "Running $SCRAPER.rb" >> $LOG
   cd $DIR && ruby $SCRAPER.rb >> $OUTPUT 2> /dev/null
done

echo "Done!" >> $LOG
echo >> $LOG
