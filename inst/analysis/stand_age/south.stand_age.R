#source(system.file("analysis/stand_age/south.stand_age.R", package="sibships"))

library(sibships)
library(raster)

load(system.file("analysis/data/south.RData", package="sibships"))

landscape_covariates <- raster::stack(list("stand_age"=scale(stand_age)))

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

parameter_grid <- as.matrix(expand.grid(
  "theta"=unique(c(
     seq(-4.0, -2.5, length.out=11), 
     seq(-2.5,  2.5, length.out=51),
     seq( 2.5,  4.0, length.out=11)
))))

#does it work? evaluate at first point in parameter grid
plot(resistance_model(landscape_covariates, parameter_grid[1,]))

fit <- sibship_foraging_model(
  colony_count_at_traps, 
  floral_cover_at_traps, 
  trap_coordinates,
  landscape_covariates,
  resistance_model,
  parameter_grid,
  verbose=TRUE
)
save(fit, file="south.stand_age.fitted.RData")

#simulate/refit at maximum likelihood estimates of the parameters
boot_at_mle <- parametric_bootstrap(fit, fit$mle, num_boot=100, verbose=TRUE, random_seed=1)

#simulate/refit at null model
null <- c("theta" = 0)
boot_at_null <- parametric_bootstrap(fit, null, num_boot=100, verbose=TRUE, random_seed=1)

save(boot_at_null, boot_at_mle, file="south.stand_age.simulations.RData")

#make some figures to visualize loglik surface, uncertainty in estimates
load("south.stand_age.fitted.RData")
load("south.stand_age.simulations.RData")

dir.create("fig")

plot_1d_likelihood_surface(
  fit, 
  simulations=boot_at_mle, 
  sim_color="dodgerblue"
  ) + 
  xlim(-0.5, 0.5) + 
  ggtitle("Bootstrap") 
ggplot2::ggsave("fig/south.sim_at_mle.png", height=4, width=7, units="in", dpi=300)

plot_1d_likelihood_surface(
  fit, 
  simulations=boot_at_null, 
  sim_color="firebrick"
  ) + 
  xlim(-0.5, 0.5) + 
  ggtitle("Null model") 
ggplot2::ggsave("fig/south.sim_at_null.png", height=4, width=7, units="in", dpi=300)

plot_1d_sampling_distributions(
  fit, 
  parametric_bootstraps=boot_at_mle, 
  null_simulations=boot_at_null, 
  null_color="firebrick", boot_color="dodgerblue"
  ) +
  xlim(-0.5, 0.5) + 
  ggtitle("Null/bootstrap distributions")
ggplot2::ggsave("fig/south.sampling_dist.png", height=4, width=7, units="in", dpi=300)
