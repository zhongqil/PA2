#coder: Zhongqi Li

require_relative './movie_test'

class MovieData #a class to deal with movie data based on file.
	def initialize(foldername, testname="") #initialize the class with loaded data
		if testname != ""
			training_path = "#{foldername}/#{testname}.base"
			test_path = "#{foldername}/#{testname}.test"
			@training_movie_data, @training_user_data, @training_original_data = load_data(training_path, 80000)
			@test_movie_data, @test_user_data, @test_original_data = load_data(test_path, 20000)
		else
			training_path = "#{foldername}/u.data"
			@training_movie_data, @training_user_data, @training_original_data = load_data(training_path)
		end
	end

	def load_data(file_path, num_lines=-1)	#load user data from file
		data = open(file_path)
		movie_data = Hash.new {|h, k| h[k] = Array.new}
		user_data = Hash.new {|h, k| h[k] = Array.new}
		original_data = []
		line_count = 0
		txt = data.read
		data.close
		txt.gsub!(/\r\n?/, "\n")
		if num_lines == -1
			num_lines = txt.size
		end
		txt.each_line do |line| #read line by line
			break if line_count == num_lines
			curline = line.split(' ')
			movie_data[curline[1]].push(getHash(:user_id, curline))
			user_data[curline[0]].push(getHash(:movie_id, curline))
			original_data.push(getHash(:other, curline))
			line_count += 1
		end
		return movie_data, user_data, original_data
	end

	def getHash(id_name, line) # interpret the raw data to readable hash
		the_hash = {rating: line[2].to_f, time_stamp: line[3]}
		if id_name == :user_id
			id_value = line[0].to_i
			the_hash[id_name] = id_value
		elsif id_name == :movie_id
			id_value == line[1].to_i
			the_hash[id_name] = id_value
		else
			the_hash[:user_id] = line[0].to_i
			the_hash[:movie_id] = line[1].to_i
		end
		return the_hash
	end

	def popularity(movie_id) #calculate popularity based on how many times the movie being mentioned, return frequency
		return @training_movie_data[movie_id.to_s].size
	end

	def popularity_list() #calculate popularity of each movie then show a descendant movie_id list
		pop_list = []
		sorted = @training_movie_data.sort_by { |_key, value| value.size }
		sorted = sorted.each {|movie_id, user_list| pop_list.push(movie_id)}
		pop_list = pop_list.reverse
		return pop_list
	end

	def similarity(user1, user2) #calculate similarity based on the movie in common between 2 users
		sum = 0						#and how close they rate those movies.
		user1_dic = getUserHash(user1)
		user2_dic = getUserHash(user1)
		com_movies = user1_dic.keys & user2_dic.keys
		com_movies.each {|movie| sum += (user1_dic[movie] - user2_dic[movie]).abs} #accumulative absolute value for common movies, which can be regarded as difference
		return calculate_similarity_score(sum, com_movies.size)
	end

	def calculate_similarity_score(sum_rating, num_com_movies) #a self developed function, the average difference closer to 0, the result closer to 10
		if sum_rating == 0 #average difference
			avg = 0
		else
			avg = sum_rating.to_f / com_movies.size
		end
		score = (1 - (avg.to_f + 1) / (avg.to_f + 2)) * 20
		score = score.round(4) #the closer the rating, the higher the score, range 0-10
		return score
	end

	def getUserHash(user, dataset=@training_user_data) # get a new hash including movie_id and rating for the given user
		user_dic = {}
		dataset[user.to_s].each {|info| user_dic[info[:movie_id]] = info[:rating]}
		return user_dic
	end

	def most_similar(u) #calculate the similarity score for every user, return a descendant user list based on similarity score.
		score_list = []
		baseline = 8 # only use the similar user that has the similar score above 8
		sorted = @training_user_data.each do |user_id, info|  # take all the similar user above baseline, use the average rating for the movie as prediction
			next if similarity(user_id, u) < baseline
				score_list.push(user_id)
		end
		return score_list.reverse		
	end

	def rating(user_id, movie_id, users=@training_user_data, movies=@training_movie_data) #returns the rating user gave to the movie in the training set
		users[user_id.to_s].each do |movie|
			if movie[:movie_id] == movie_id
				return movie[:rating].to_i
			end
		end
		return 0
	end

	def predict(u, movie_id, movie_data=@training_movie_data) #returns the predicted rating for the movie, the user would give.
		similar_sum = 0
		all_sum = 0
		user_list = most_similar(u)
		if movie_data[movie_id.to_s] 
			movie_data[movie_id.to_s].each do |info|
				if user_list.include? info[:user_id]
					similar_sum += info[:rating]
				end
				all_sum += info[:rating]
			end
		end
		if similar_sum != 0 # if there are no similar user score that higher than baseline, use the average rating from all user as prediction
			avg = similar_sum.to_f/user_list.size
		elsif movie_data[movie_id.to_s].size != 0
			avg = all_sum.to_f/movie_data[movie_id.to_s].size
		else
			avg = 3.5 #if no movie found, give 3.5 score for prediction
		end
		return avg.round(4)
	end

	def movies(user_id, users=@training_user_data) # returns the array of movies that the user has watched
		return getList(user_id, :movie_id, users)
	end

	def viewers(movie_id, movies=@training_movie_data) # returns the array of users that have seen the movie
		return getList(movie_id, :user_id, movies)
	end

	def getList(id_name, id_symbol, dataset) # returns the array of required object
		the_list = []
		dataset[id_name.to_s].each {|info| the_list.push(info[id_symbol])}
		return the_list
	end

	def run_test(k=-1, original_data=@test_original_data) # returns the first k lines of movie test object with predictions in it.
		if k == -1
			k = original_data.size + 1
		end
		lines_count = 0
		target_list = []
		original_data.each do |info|
			break if lines_count == k
			result = predict(info[:user_id], info[:movie_id])
			curline = [info[:user_id], info[:movie_id], info[:rating], result]
			target_list.push(curline)
			lines_count += 1
		end
		return target_list
	end
end

foldername = 'ml-100k'
z = MovieData.new(foldername, :u1)
#puts z.popularity(50)
#puts z.popularity_list()
#puts z.similarity(1, 113)
#put z.most_similar(1)
#puts z.rating(251, 100)
#z.movies(196)
#puts z.viewers(589)
before = Time.now
#puts z.predict(251, 100)
t_list = z.run_test(10000)
#puts t_list
after = Time.now
puts after - before
t = MovieTest.new(t_list)
puts t.mean
puts t.stddev
puts t.rms
#puts t.to_a