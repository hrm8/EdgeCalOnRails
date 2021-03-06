class RepetitionScheme < ActiveRecord::Base
  
	enum recurrence: [:no_recurrence, :daily, :every_other_day, :weekly, :monthly, :yearly]
	enum status: [:regular, :preference_based, :resolved]
  
	validate :max_min_duration
	before_create :equalize_slot_duration

	has_many :events, :dependent => :destroy
	has_and_belongs_to_many :allowed_users, :class_name => 'User'
	has_many :to_dos, :dependent => :destroy
	belongs_to :creator, :class_name => 'User'

	### <<<< LEAVE COMMENTED OUTPUTS TO CONSOLE ALONE >>>>

	def self.recurrence_to_date_time(period)
		return 1.day if period == ToDo.recurrences[:daily] || period == "daily"
		return 2.days if period == ToDo.recurrences[:every_other_day] || period == "every_other_day"
		return 1.week if period == ToDo.recurrences[:weekly] || period == "weekly"
		return 1.month if period == ToDo.recurrences[:monthly] || period == "monthly"
		return 1.year if period == ToDo.recurrences[:yearly] || period == "yearly"
		return 0.seconds
	end

	def create_events_with_recurrence(original_event, until_time, recurrence)
		if original_event.end_time >= until_time
			return
		end

		date = original_event.end_time
		period = RepetitionScheme.recurrence_to_date_time(recurrence)
		date += period

		#puts "WILL START RECURRENCE CREATION START: #{date}, PERIOD: #{period}, DURATION: #{original_event.duration}"

		while date < until_time do
			#puts "CREATING EVENT AT DATE #{date}"
			event = Event.create(:creator_id => original_event.creator_id, :title => original_event.title,
													 :description => original_event.description, :start_time => date,
													 :end_time => date + original_event.duration, :event_type => Event.event_types[:recurrent])
			Subscription.create(subscribed_event_id: event.id,subscriber_id: original_event.creator_id)
			self.events << event
			date += period
		end

		self.events << original_event
	end

	def update_events_based_on_event(event)
		events.each do |e|
			#puts "WILL UPDATE EVENT ID #{e} TITLE #{e.title} DESCRIPTION #{e.description} TO TITLE #{event.title} AND DESC #{event.description}"
			e.title = event.title
			e.description = event.description
			e.save
		end
	end

	def time_slot_start_time_allowed_for_event(event, start_time)
		#puts "** REP TIME ALLOWED **"
		#puts "** seconds of min #{min_time_slot_duration}"
		start_allowed = event.start_time

		if start_time < event.start_time || start_time > event.end_time
			return false
		end
		while start_allowed < event.end_time
			if start_time.hour == start_allowed.hour && start_time.min == start_allowed.min
				return true
			end
			start_allowed += min_time_slot_duration
		end
		return false
	end

	def time_slot_duration_allowed(duration)
		#puts "** REP DURATION ALLOWED **"
		duration <= max_time_slot_duration
	end

	def set_title(title)
		events.each do |e|
			e.title = title
			e.save
		end
	end

	def generate_to_dos_with_position(position)
		unless is_preference_mode?
			return
		end

		title = events.first.title
		allowed_users.each do |u|
			todo = ToDo.create(:creator_id => u.id, :position => position, :title => "Signup for a slot with #{creator.name}",
			:description => title, :duration => 5*60)
			u.to_dos << todo
			self.to_dos << todo
		end
	end

	def get_all_users_preferences
		unless is_preference_mode?
			return
		end

		preferences = {}
		allowed_users.each do |u|
			preferences[u] = []
			events.map {|e| e.time_slots.where(:user_id => u.id).map {|s| preferences[u] << s}}
			preferences[u].sort_by {|t| t.preference}
		end
		preferences
	end

	def suggest_slot_assignment
		preferences = get_all_users_preferences
		puts "GOT PREFERENCES"
		preferences.reject!{|k,v| v.count == 0}
		puts "REJECTED"
		ordered_keys = preferences.keys.sort_by{|k| preferences[k].count}
		puts "ORDERED"
		suggestion = {}
		ordered_keys.each do |u|
			preferences[u].each do |t|
				unless overlaps?(suggestion, t)
					puts "GOT SUGGESTION #{t}\n"
					suggestion[u] = t
					break
				end
			end
		end
		suggestion
	end

	def resolve_preferences_for_slots(slot_ids)
		unless is_preference_mode?
			return
		end

		preferences = get_all_users_preferences
		to_delete = []
		preferences.keys.map {|u| preferences[u].map {|t| to_delete << t if !(slot_ids.include? t.id)}}
		to_delete.map {|t| t.destroy}

		to_dos.map {|t| t.done = true; t.save }
		self.status = RepetitionScheme.statuses[:resolved]
		save
	end

	def user_allowed?(user_id)
		allowed_users.ids.include?(user_id)
	end

	def is_preference_mode?
		RepetitionScheme.statuses[status] == RepetitionScheme.statuses[:preference_based]
	end

	private

	def overlaps?(suggestion, time_slot)
		suggestion.keys.each do |u|
			other = suggestion[u]
			if (other.start_time - (time_slot.start_time + time_slot.duration))*((other.start_time + other.duration) - time_slot.start_time) < 0
				return true
			end
		end
		false
	end

	def max_min_duration
		#puts "VALIDATION MIN #{min_time_slot_duration} MAX #{max_time_slot_duration}"
		if min_time_slot_duration.nil? && max_time_slot_duration.nil?
			return true
		end
		if min_time_slot_duration > 0 || max_time_slot_duration > 0
			if min_time_slot_duration > max_time_slot_duration || min_time_slot_duration % 5 != 0 || max_time_slot_duration % 5 != 0
				errors[:base] = "minimum and maximum durations are incompatible"
				return false
			end
		end
		true
	end

	def equalize_slot_duration
		if RepetitionScheme.statuses[status] == RepetitionScheme.statuses[:preference_based]
			self.max_time_slot_duration = min_time_slot_duration
		end
	end

end
