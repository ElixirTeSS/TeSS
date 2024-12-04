output = `curl --verbose --silent http://localhost:3000/ 2>&1`
if $?.success? && output.include?('Browse the catalogue')
  exit 0
else
  puts "::group::Docker logs"
  puts `docker compose --file docker-compose-prod.yml logs`
  puts "::endgroup::"
  puts "::group::curl output"
  puts output
  puts "::endgroup::"
  exit 1
end

