BUF_TO_READ = 1 << 12
def init_tail(f, n)
  line_array = []
  buf_size = BUF_TO_READ
  file_size = f.size
  buf_size = file_size if file_size < buf_size
  loop do
    f.seek(-buf_size, IO::SEEK_END)
    line_array = f.readlines
    if line_array.size < n
      buf_size << 1
    else
      break
    end
  end
  line_array[-n..-1].each { |l| print l }
end

def multiple_file_tail(files, n, wait_for_update)
  modified_times = Array.new(files.size)
  last_modified_file = nil
  files.each_with_index do |f, i|
    modified_times[i] = f.mtime
    print "\n==> #{f.path} <==\n"
    init_tail f, n
    last_modified_file = f
  end

  Signal.trap("SIGINT") { files.each { |f| f.close }; exit }

  if wait_for_update
    while(sleep 1)
      files.each_with_index do |f, i|
        new_modified_time = f.mtime
        if modified_times[i] != new_modified_time
          print "\n==> #{f.path} <==\n" if last_modified_file.nil? || last_modified_file!=f
          modified_times[i] = new_modified_time
          f.readlines.each { |l| print l }
          last_modified_file = f
        end
      end
    end
  end
end

def single_file_tail(f, n, wait_for_update)
  modified_time = f.mtime unless f==STDIN
  init_tail f, n
  Signal.trap("SIGINT") { f.close; exit }
  if wait_for_update
    while(sleep 0.5)
      new_modified_time = f.mtime
      if modified_time != new_modified_time
        modified_time = new_modified_time
        if !f.eof
          f.readlines.each { |l| print l }
        end
      end
    end
  end
end

def stdin_tail(n)
  arr = []
  temp_arr = []
  STDIN.each_line do |line|
    arr << line
    if arr.size == n
      temp_arr = arr
      arr = []
    end
  end
  t_size = n - arr.size
  print "\n"
  temp_arr[-t_size..-1].each { |l| print l} if t_size > 0
  arr.each { |l| print l }
end

num_of_lines = -1
files = []
wait_for_update = false
ARGV.each do |arg|
  if num_of_lines == 0
    begin
      num_of_lines = arg.to_i
    rescue
      abort "tail -n: #{arg} invalid number of lines"
    end
    next
  end
  if arg == "-f"
    wait_for_update = true
  elsif arg == "-n"
    num_of_lines = 0
  else
    files << arg
  end
end

abort "tail -n: 0 is invalid number of lines" if num_of_lines == 0
begin
  files.map! { |f| File.open(f, "r") }
rescue Errno::ENOENT => e
  abort e.message
end

if files.empty?
  stdin_tail num_of_lines
  exit
end

num_of_lines = 10 if num_of_lines == -1

if files.size == 1
  single_file_tail(files.first, num_of_lines, wait_for_update)
else
  multiple_file_tail(files, num_of_lines, wait_for_update)
end