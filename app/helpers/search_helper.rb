module SearchHelper
	def filter_link name, value
		new_parameter = {name => value}
		parameters = request.parameters.clone

		if parameters.include?(name) 
			if !parameters[name].include?(value)
		    	new_parameter = {name => [parameters.delete(name), value].flatten}
		    else new_parameter = {}
		    end
		end
		return link_to value, parameters.merge(new_parameter)
	end

	def remove_filter_link name, value
	  parameters = request.parameters.clone
	  
	  if parameters.include?(name) 
	  	if parameters[name].is_a?(Array)
	  		parameters[name].delete(value)
	  	else parameters.delete(name) 
	  	end
	  end
	  return link_to "x #{value}", parameters 
	end
end
