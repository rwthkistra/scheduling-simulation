# Simulation for testing different integration strategies

## Running the simulation

- First check the install.jl to make sure your environment is set up correctly.
- Run a single simulation by

## Folder organization

- `data` contains data that is used to identify model parameters
- `old_version` contains the old simulation based on LMU Data
- `R` contains supplementary R code to help identify distribution parameters
- `src` contains Julia code that is used to organize the simulation (i.e. queueing and scheduling, confusion matrix plot)
- `tests` contain unit test cases for the `src` folder

## File Organization

- src/utils.jl utility functions for plotting confusion matrices
- src/scheduling_strategies.jl contains the scheduling functions to be used in the simulation
- model.jl contains the definition of a single simulation model
- settings.jl creates distributions and figures (png) of the settings used for the simulation
- runsim.jl contains the simulation runner method that also does bookkeeping and image generation (output)
- test.jl contains three test cases for the model simulation
- batch_run.jl contains a batch setup for multiple simulations from runsim.jl

#### Old Version still exists

Two versions of simulations exist
`old_version` is the simulation focused on using LMU input
root-folder version on comparing different strategies combination.
