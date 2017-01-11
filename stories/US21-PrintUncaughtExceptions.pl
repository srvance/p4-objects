# Example code implementing Story 21: Print uncaught exceptions
# Right now, uncaught exceptions just say "Died" making it harder to debug
# without instrumenting everything with try/catch. Exceptions should display
# nicely when they reach the top uncaught, regardless of whether best
# practices are followed in exception handling. The Error package has a
# qw( :warndie ) option that I've only had partial success with.
