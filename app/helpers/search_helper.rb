module SearchHelper
	def filter_link name, value
		if request.parameters.include?(name) 
			if !request.parameters[name].include?(value)
		    	new_parameter = {name => [request.parameters.delete(name), value].flatten}
		    else new_parameter = {}
		    end
		else new_parameter = {name => value}
		end

		return link_to value, request.parameters.merge(new_parameter)
	end
end
