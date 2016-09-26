require 'pry'
require 'date'

# multi-threaded load test: give a host some busywork
#
# Maciek Nowacki, University of Alberta, IST
# nowacki@ualberta.ca

if ARGV.empty?
	puts "usage: #{$PROGRAM_NAME} thread_count"
	exit
end

class Busywork

attr_accessor :loops_in_one_second

def eratosthenes n
	# inefficient implementation of Sieve of Eratosthenes
	ints = [ *2..n ]

	(n-1).times.each do |_p|
		p=_p+2
		(n - 2*p).times.each_slice p do |_mult_of_p,*_|
		#((2 * p .. n).step p).each do |mult_of_p|
			mult_of_p = 2 * p + _mult_of_p
			if mult_at_idx = (ints.find_index mult_of_p)
				ints.delete_at mult_at_idx
			end
		end
	end

	ints
end

def calibrate_loops_to_one_second n=121

	tried_loops = 0

	dt_start = Process.clock_gettime Process::CLOCK_MONOTONIC

	while (Process.clock_gettime Process::CLOCK_MONOTONIC) - dt_start < 1
		tried_loops += 1
		self.eratosthenes n
	end

	puts "calibrated to #{tried_loops} loops per second for #{n}"

	self.loops_in_one_second = [ n, tried_loops ]
end

def run_for_time s

	dt_start = Process.clock_gettime Process::CLOCK_MONOTONIC

	(self.loops_in_one_second.last * s).times do
		self.eratosthenes self.loops_in_one_second.first
	end

	dt_elapsed = (Process.clock_gettime Process::CLOCK_MONOTONIC) - dt_start

	if dt_elapsed > s * 1.5 || dt_elapsed * 1.5 < s 
		self.loops_in_one_second = [ self.loops_in_one_second.first, ((self.loops_in_one_second.last * s ) / dt_elapsed ).to_i ]
		puts "time required was wrong: needed #{dt_elapsed} seconds; new calibration: #{self.loops_in_one_second.last}"
	else
		print '.'
	end
end

end

t_list = ARGV.first.to_i.times.map do
	puts "starting thread..."
	t = Thread.new do
		my_sieve = Busywork.new

		my_sieve.calibrate_loops_to_one_second

		loop do
			my_sieve.run_for_time 1
		end
	end
	sleep 5
	t
end

puts "Threads running. Joining..."

t_list.each do |t|
	t.join
end

