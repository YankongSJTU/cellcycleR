np_cell_ordering_iter <- function(cycle_data, celltime_levels, cell_times_iter, method=c("LOESS", "B-spline", "Wavelet"))
{
  # cycle_data: a N \times G matrix, where N is number of cells, G number of genes
  # cell_times_iter:  the vector of cell times taken as input (a N \times 1)

  G <- dim(cycle_data)[2];
  numcells <- dim(cycle_data)[1];
  cell_times_class <- seq(0, 2*pi, 2*pi/(celltime_levels-1));

  npfit_list <- parallel::mclapply(1:G, function(g)
                                  {

                                      if(method=="LOESS"){
                                              ## take mean of the observations belonging to same time class
                                              ordered_vec <- as.numeric(tapply(cycle_data[order(cell_times_iter),g], factor(sort(cell_times_iter)), mean));
                                                ## interpolate the values at class times in which no cell has been placed
                                              ordered_vec_out <- approx(unique(sort(cell_times_iter)), ordered_vec, xout = cell_times_class, ties = "ordered")$y
                                              ## substitute the NAs at the ends by nearest observation
                                              ordered_vec_out <- zoo::na.fill(ordered_vec_out, "extend");
                                              ## duplicate the cell time classes 2 times to account for np smoothing with make ends meet
                                              cell_times_class_extend <- c(cell_times_class, cell_times_class+2*pi, cell_times_class+4*pi);
                                              ## replicate the observations for the duplicated time classes
                                              ordered_vec_out_extend <- rep(ordered_vec_out,3);
                                              ## Fit the LOESS smoother on the duplicated data against time
                                              fit_extend <- loess(ordered_vec_out_extend ~ cell_times_class_extend)$fitted;
                                              ## Filter out the smoothed fit from the middle stretch of duplicated data
                                              fit <- fit_extend[(celltime_levels+1):(2*celltime_levels)];
                                              ## The standard error of the data
                                              out_sigma <- sd(cycle_data[,g]);
                                      }
                                      if(method=="B-spline"){
                                              ## take mean of the observations belonging to same time class
                                              ordered_vec <- as.numeric(tapply(cycle_data[order(cell_times_iter),g], factor(sort(cell_times_iter)), mean));
                                              ## interpolate the values at class times in which no cell has been placed
                                              ordered_vec_out <- approx(unique(sort(cell_times_iter)), ordered_vec, xout = cell_times_class, ties = "ordered")$y
                                              ## substitute the NAs at the ends by nearest observation
                                              ordered_vec_out <- zoo::na.fill(ordered_vec_out, "extend");
                                              ## duplicate the cell time classes 2 times to account for np smoothing with make ends meet
                                              cell_times_class_extend <- c(cell_times_class, cell_times_class+2*pi, cell_times_class+4*pi);
                                              ## replicate the observations for the duplicated time classes
                                              ordered_vec_out_extend <- rep(ordered_vec_out,3);
                                              ## Fit the B-spline smoother on the duplicated data against time
                                              fit_extend <- smooth.spline(cell_times_class_extend, ordered_vec_out_extend)$y;
                                              ## Fit the B-spline smoother on the duplicated data against time
                                              fit <- fit_extend[(celltime_levels+1):(2*celltime_levels)];
                                              ## The standard error of the data
                                              out_sigma <- sd(cycle_data[,g]);
                                      }
                                      if(method=="Wavelet"){
                                              if(log(celltime_levels)%% log(2) !=0) stop("for wavelet smoother, number of time classes must be power of 2")
                                              if(log(celltime_levels)%% log(2) ==0){
                                              ordered_vec <- as.numeric(tapply(cycle_data[order(cell_times_iter),g], factor(sort(cell_times_iter)), mean));
                                              ordered_vec_out <- approx(unique(sort(cell_times_iter)), ordered_vec, xout = cell_times_class, ties = "ordered")$y
                                              ordered_vec_out <- zoo::na.fill(ordered_vec_out, "extend");
                                              fit <-  wr(threshold(wd(ordered_vec_out), type="soft"));
                                              out_sigma <- sd(cycle_data[,g]);
                                      }}
                                      out_list <- list("fit"=fit, "sigma"=out_sigma);
                                      return(out_list)
  }, mc.cores=1)

  np_signal <- do.call(cbind, lapply(1:G, function(g) return(npfit_list[[g]]$fit)));
  sigma <- as.numeric(unlist(lapply(1:G, function(g) return(npfit_list[[g]]$sigma))));

   options(digits=12)
  signal_intensity_per_class <- matrix(0, numcells, celltime_levels)

  signal_intensity_per_class <- do.call(rbind,parallel::mclapply(1:numcells, function(cell)
  {
    res_error <- sweep(np_signal,2,cycle_data[cell,]);
    res_error_adjusted <- -(res_error^2);
    res_error_adjusted <- sweep(res_error_adjusted, 2, 2*sigma^2, '/');
    out <- rowSums(sweep(res_error_adjusted,2,log(sigma)) - 0.5*log(2*pi));
    return(out)
  }, mc.cores=1));

  signal_intensity_class_exp <- do.call(rbind,lapply(1:dim(signal_intensity_per_class)[1], function(x)
  {
    out <- exp(signal_intensity_per_class[x,]- max(signal_intensity_per_class[x,]));
    return(out)
  }));

  cell_times <- cell_times_class[unlist(lapply(1:dim(signal_intensity_class_exp)[1], function(x)
  {
    temp <- signal_intensity_class_exp[x,];
    if(length(unique(signal_intensity_class_exp[x,]))==1)
      out <- sample(1:dim(signal_intensity_class_exp)[2],1)
    else
      out <- which(rmultinom(1,1,signal_intensity_class_exp[x,])==1);
    return(out)
  }))];

  out <- list("cell_times_iter"=cell_times, "signal_intensity_iter"=signal_intensity_per_class, "fitted_signal"=np_signal, "sigma_iter"=sigma);
  return(out)
}





