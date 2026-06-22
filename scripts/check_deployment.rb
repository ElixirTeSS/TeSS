require 'json'

output = `curl --verbose --silent http://localhost:3000/ 2>&1`

puts 0
if $?.success? && output.include?('Browse the catalogue')
  docker_ps = `docker compose ps -a --format json | jq -s`
  puts 1
  if $?.success?
    puts 2
    j = JSON.parse(docker_ps)
    unless j.any? { |c| c['ExitCode'] == 1 } || j.any? { |c| c['Health'] == 'unhealthy' }
      puts 'exit 0'
      exit 0
    end
  end
end
puts 3
puts "::group::Docker ps"
puts `docker compose ps -a`
puts "::endgroup::"
puts "::group::Docker logs"
puts `docker compose --file docker-compose-prod.yml logs`
puts "::endgroup::"
puts "::group::curl output"
puts output
puts "::endgroup::"

exit 1
