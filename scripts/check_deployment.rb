require 'json'

output = `curl --verbose --silent http://localhost:3000/ 2>&1`

if $?.success? && output.include?('Browse the catalogue')
  docker_ps = `docker compose ps -a --format json`
  if $?.success?
    begin
      j = JSON.parse(docker_ps)
    rescue => e
      puts "THE JSON:\n\n\n\n#{docker_ps}\n\n\n\n"
      raise e
    end
    unless j.any? { |c| c['ExitCode'] == 1 }
      exit 0
    end
  end
end

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
