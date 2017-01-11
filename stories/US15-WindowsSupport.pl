# User story 15: Support Windows
# There is no real distinguising code for this story

# Implementation notes:
# The problem that is readily apparent is that the process invocation of p4d
#     in P4::Server fails. I expect to replace this with IPC::Run, which may
#     also address issues with capture of stderr.
# Other issues may crop up after that is cleared. Anticipated possibilities are
#     the use of back tick invocations of p4 in testing.
