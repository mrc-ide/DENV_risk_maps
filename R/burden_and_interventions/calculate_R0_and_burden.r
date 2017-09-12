calculate_R0_and_burden <- function(
  FOI, N, age_struct, 
  age_band_lower_bounds, age_band_upper_bounds, age_band_tags,
  vec_phis, scaling_factor,
  w_1, w_2, w_3, var_names){
  
  #browser()
  
  fun_ls <- list(
    "calculate_primary_infection_prob",
    "calculate_secondary_infection_prob",
    "calculate_tertiary_infection_prob",
    "calculate_quaternary_infection_prob")
  
  out <- rep(0, length(var_names))
  
  cat("FOI =", FOI, "\n")
  cat("phi 1 =", vec_phis[1], "\n")  
  cat("phi 2 =", vec_phis[2], "\n") 
  cat("phi 3 =", vec_phis[3], "\n") 
  cat("phi 4 =", vec_phis[4], "\n") 
  cat("scaling factor =", scaling_factor, "\n")
  
  if (FOI > 0) {
    
    # calculate n people in age group
    n_j <- age_struct * N  
    
    
    # ---------------------------------------- calculate incidence of infections
    
    
    inf_probs <- lapply(
      fun_ls, 
      do.call,
      list(FOI, age_band_lower_bounds, age_band_upper_bounds))
    
    inc_rates <- lapply(
      inf_probs,
      calc_average_prob_infect,
      age_band_upper_bounds, 
      age_band_lower_bounds) 
    
    infec_j <- lapply(inc_rates, calculate_case_number, n_j)
    
    total_infec <- vapply(infec_j, sum, numeric(1))
    
    
    # ---------------------------------------- calculate R0
    
    
    R0 <- calculate_R0(
      FOI = FOI,
      N = N,
      vec_infections = total_infec, 
      vec_phis = vec_phis)
    
    cat("R0 =", R0, "\n")
    
    
    # ---------------------------------------- create look up function to transform R0 back to FOI
    
    
    R0_to_FOI <- approximate(
      target = calculate_R0,
      a = 0,
      b = 2,
      N = N,
      vec_infections = total_infec,
      vec_phis = vec_phis,
      tol = 1e-5,
      target_vectorised = FALSE,
      inverse = TRUE)
    
    
    # ---------------------------------------- calculate reduced R0 and back transform R0
    
    
    red_R0 <- R0 * scaling_factor
    cat("reduced R0 =", red_R0, "\n")
    
    red_FOI <- R0_to_FOI(red_R0)
    cat("reduced FOI =", red_FOI, "\n")
    
    
    # ---------------------------------------- recalculate everything 
    
    
    inf_probs <- lapply(
      fun_ls, 
      do.call,
      list(red_FOI, age_band_lower_bounds, age_band_upper_bounds))
    
    inc_rates <- lapply(
      inf_probs,
      calc_average_prob_infect,
      age_band_upper_bounds, 
      age_band_lower_bounds) 
    
    infec_j <- lapply(inc_rates, calculate_case_number, n_j)
    
    total_infec <- vapply(infec_j, sum, numeric(1))
    
    
    # ---------------------------------------- calculate burden measures
    
    
    # total number of infections in the population N
    a <- sum(total_infec)
    
    # total incidence of cases per age group
    tot_incid_rate_j <- calculate_total_incidence_rate(
      inc_rates_list = inc_rates,
      rho = w_2,
      gamma_1 = w_1,
      gamma_3 = w_3)
    
    # total number of cases per age group
    case_number_j <- calculate_case_number(tot_incid_rate_j, n_j)
    
    # total number of cases in the population N
    b <- sum(case_number_j)
    
    c <- calculate_incidence_of_infections(a, N, 1000)
    
    d <- calculate_incidence_of_infections(b, N, 1000)
    
    
    # ----------------------------------------
    
    
    out <- c(red_R0, a, b, c, d)
    
  }
  
  out
}