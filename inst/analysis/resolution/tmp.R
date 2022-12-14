
region <- "south"
resolution <- "90m"
species <- "bomvos"
lower_bound <- -2.5
upper_bound <- 2.5
grid_size <- 51
bootstraps <- 10
prefix <- paste0(region, ".", species, ".", resolution)

#-----------------------------------#
library(sibships)
library(raster)

load(system.file(paste0("data/", prefix, ".RData"), package="sibships"))

landscape_covariates <- raster::stack(list("stand_age"=stand_age))

resistance_model <- function(raster_stack, parameters)
{
  # converts stack of rasters to a single output raster
  # representing a resistance surface
  stopifnot("stand_age" %in% names(raster_stack))
  stopifnot("theta" %in% names(parameters))
  stopifnot(length(parameters) == 1)
  resistance <- exp(raster_stack[["stand_age"]] * parameters["theta"])
  return(resistance)
}

scaling <- 1/sd(values(landscape_covariates[["stand_age"]]))
parameter_grid <- as.matrix(expand.grid(
  "theta"=scaling*seq(lower_bound, upper_bound, length.out=grid_size)
))

#does model work? evaluate at first point in parameter grid, check for NAs, etc
print(resistance_model(landscape_covariates, parameter_grid[1,]))

#debug(sibships::distance_to_focal_raw)
#fit <- sibship_foraging_model(
#  colony_count_at_traps, 
#  floral_cover_at_traps, 
#  trap_coordinates,
#  landscape_covariates,
#  resistance_model,
#  parameter_grid,
#  verbose=TRUE
#)
#save(fit, file="south_constrained.fitted.RData")

#if (bootstraps > 0)
#{
#  load("south_constrained.fitted.RData")
#  #debug(sibships::parametric_bootstrap)
#  #debug(sibships::simulate_3parameter_model)
#  #simulate/refit at maximum likelihood estimates of the parameters
#  boot_at_mle <- parametric_bootstrap(fit, fit$mle, num_boot=bootstraps, verbose=TRUE, random_seed=1,
#    visitation_always_decreases_with_distance=TRUE)
#  boot_at_mle <- NA
#  
#  #simulate/refit at null model
#  null <- c("theta" = 0)
#  boot_at_null <- parametric_bootstrap(fit, null, num_boot=bootstraps, verbose=TRUE, random_seed=1,
#    visitation_always_decreases_with_distance=TRUE)
#  
#  save(boot_at_null, boot_at_mle, file="south_constrained.bootstrap.RData")
#}

load("south_constrained.fitted.RData")
load("south_constrained.bootstrap.RData")

#make some figures to visualize loglik surface, uncertainty in estimates

dir.create("fig")

#debug(plot_1d_likelihood_surface)
#plot_1d_likelihood_surface(
#  fit, 
#  simulations=boot_at_mle, 
#  sim_color="dodgerblue"
#  ) + 
#  xlim(-0.5, 0.5) + 
#  ggtitle("Bootstrap") 
#ggplot2::ggsave("fig/south_constrained.sim_at_mle.png", height=4, width=7, units="in", dpi=300)

plot_1d_likelihood_surface(
  fit, 
  simulations=boot_at_null, 
  sim_color="firebrick"
  ) + 
  ggtitle("Null model") 
ggplot2::ggsave("fig/south_constrained.sim_at_null.loglik.png", height=4, width=7, units="in", dpi=300)

plot_1d_likelihood_surface(
  fit, 
  simulations=boot_at_null, 
  sim_color="firebrick",
  what="landscape_distance_on_capture_rate"
  ) + 
  ggtitle("Null model") 
ggplot2::ggsave("fig/south_constrained.sim_at_null.landscape_distance_on_capture_rate.png", height=4, width=7, units="in", dpi=300)

#plot_1d_sampling_distributions(
#  fit, 
#  parametric_bootstraps=boot_at_mle, 
#  null_simulations=boot_at_null, 
#  null_color="firebrick", boot_color="dodgerblue"
#  ) +
#  xlim(-0.5, 0.5) + 
#  ggtitle("Null/bootstrap distributions")
#ggplot2::ggsave("fig/midnorth.sampling_dist.png", height=4, width=7, units="in", dpi=300)
