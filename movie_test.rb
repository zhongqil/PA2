class MovieTest
	def initialize(prediction) # initialize the class
		@prediction = prediction
		@error_list = error()
	end

	def error() # calculate the difference between predict rating and real rating for each line, then return the array
		diff = []
		@prediction.each { |tuple| diff.push((tuple[2] - tuple[3]).abs) }
		return diff
	end

	def mean() # calculate the average predication error
		sum = @error_list.inject(:+)
		return sum / @error_list.size
	end

	def stddev() # calculate the standard deviation of the error
		sum = @error_list.inject{|accum, diff| accum + (diff - mean) ** 2}
		variance = sum / @error_list.size
		return Math.sqrt(variance)
	end

	def rms() # calculate the root mean square error of the prediction
		sum = @error_list.inject{|accum, diff| accum + diff ** 2}
		return Math.sqrt(sum / @error_list.size)
	end

	def to_a() # returns an array of the predictions in the form [u, m, r, p]
		return @prediction
	end
end