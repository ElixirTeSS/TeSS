git pull origin master
rake db:migrate
rake assets:clean
rake assets:precompile
rake sunspot:solr:reindex

