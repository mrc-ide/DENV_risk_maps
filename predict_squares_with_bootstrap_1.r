# Makes predictions for all the squares in the world, for each model fit. 

options(didehpc.cluster = "fi--didemrchnb")

CLUSTER <- TRUE

my_resources <- c(
  file.path("R", "random_forest", "fit_ranger_RF_and_make_predictions.R"),
  file.path("R", "utility_functions.R"))
  
my_pkgs <- "ranger"

context::context_log_start()
ctx <- context::context_save(path = "context",
                             packages = my_pkgs,
                             sources = my_resources)


# define parameters ----------------------------------------------------------- 


parameters <- list(
  dependent_variable = "FOI",
  grid_size = 5,
  no_samples = 200,
  no_predictors = 9)   

model_type_tag <- "_boot_model_23"


# define variables ------------------------------------------------------------


model_type <- paste0(parameters$dependent_variable, model_type_tag)

my_dir <- paste0("grid_size_", parameters$grid_size)


# are you using the cluster? --------------------------------------------------  


if (CLUSTER) {
  
  config <- didehpc::didehpc_config(template = "20Core")
  obj <- didehpc::queue_didehpc(ctx, config = config)
  
} else {
  
  context::context_load(ctx)
  
}

# obj$enqueue(install.packages(file.path("R_sources", "h2o_3.18.0.8.tar.gz"), repos=NULL, type="source"))$wait(Inf)


# load data ------------------------------------------------------------------- 


all_sqr_covariates <- readRDS(file.path("output", 
                                        "env_variables", 
                                        "all_squares_env_var_0_1667_deg.rds"))

RF_obj_path <- file.path("output",
                         "EM_algorithm",
                         "bootstrap_models",
                         my_dir,
                         model_type,
                         "optimized_model_objects")

predictor_rank <- read.csv(file.path("output", 
                                     "variable_selection",
                                     "stepwise",
                                     "predictor_rank.csv"), 
                           stringsAsFactors = FALSE)


# pre processing --------------------------------------------------------------


my_predictors <- predictor_rank$name[1:parameters$no_predictors]

no_samples <- parameters$no_samples


# submit one job -------------------------------------------------------------- 


# t <- obj$enqueue(
#   wrapper_to_make_ranger_preds(
#     seq_len(no_samples)[1],
#     model_in_path = RF_obj_path,
#     dataset = all_sqr_covariates,
#     predictors = my_predictors))


# submit all jobs ------------------------------------------------------------- 


if(CLUSTER){

  sqr_preds_boot <- queuer::qlapply(
    seq_len(no_samples),
    wrapper_to_make_ranger_preds,
    obj,
    model_in_path = RF_obj_path,
    dataset = all_sqr_covariates,
    predictors = my_predictors)

} else {

  sqr_preds_boot <- lapply(
    seq_len(no_samples),
    wrapper_to_make_ranger_preds,
    model_in_path = RF_obj_path,
    dataset = all_sqr_covariates,
    predictors = my_predictors)

}
