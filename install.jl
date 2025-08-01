# this file helps you to install julia in the correct versions etc.

# first setup julia in version 1.9.2 using juliaup
# cmd> juliaup add 1.9.2
# cmd> juliaup default 1.9.2
# then set the julia executable in your IDE to the juliaup version
# typically /users/yourname/.juliaup/bin/julia

# then install the packages
using Pkg
Pkg.activate(".")
Pkg.instantiate()
