How to run:
ruby tail.rb [-f] [-n #] [file ...]

Requirements: >= ruby 1.9.3p194

Assumptions taken:
  As tail is mostly used for tailing log files, assuming that files are only appended.

How could we do this differently?
-f option:
In my current implementation, after initial tail, I print only the new data that gets appended at the end. Some tail implementations printed the whole file again, which seemed weird to me. I could have done differently by saving start byte offset of last buffer printed and see if there was any change. If there was a change I print the whole file again, else just the new lines.


