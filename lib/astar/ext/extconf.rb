# Loads mkmf which is used to make makefiles for Ruby extensions
require 'mkmf'

have_header('stdio.h') or exit
have_header('priorityqueue.h') or exit
have_header('astar.h') or exit

# Give it a name
extension_name = 'astar'

# The destination
dir_config(extension_name)

# Do the work
create_makefile(extension_name)
