#' @title Cell continuous ordering - post processing of cell time class ordering
#'
#' @param signal_intensity: The signal intensity for the cells across time classes (N x T) matrix,
#'                          where T represents the number of time classes (equal to celltime_levels)
#' @param num_genes The number of genes in the data.
#'
#' @description The function takes the output from the cell_phase_ordering function and provides a
#'              more continuous ordering of the cells based on the signal intensity of the cells in the
#'              different cell time classes as in the cell_phase_ordering function.
#'
#' @return  Returns the full cell relative ordering of the cells on the
#'          cell cycle.
#'
#' @author  Kushal K Dey
#' @export
#' @examples
#'
#' G <- 500;
#' num_cells <- 400;
#' amp_genes <- rep(10, G);
#' phi_genes <- runif(G, 0, 2*pi)
#' sigma_genes <- rchisq(G, 4);
#' cell_times_sim <- sample(seq(0,2*pi, 2*pi/(num_cells-1)), num_cells, replace=FALSE);
#' cycle_data <- sim_sinusoidal_cycle(G, amp_genes, phi_genes, sigma_genes, cell_times_sim);
#' celltime_levels <- 100;
#' out <- cell_reordering_phase(cycle_data, celltime_levels = 100, num_iter=100)
#' signal_intensity <- out$signal_intensity;
#' cell_ordering_full(signal_intensity, G);




cell_ordering_full <- function(signal_intensity, num_genes)
{
  celltime_levels <- dim(signal_intensity)[2];
  numcells <- dim(signal_intensity)[1];
  G <- num_genes;
  cell_times_class <- seq(0, 2*pi, 2*pi/(celltime_levels-1));
  sorted_cell_times_class <- sort(cell_times_class)
  order_class <- order(cell_times_class);

  signal_intensity <- signal_intensity[,order_class];

  cell_order_full <- array(0,numcells)

  for(cell in 1:numcells)
  {
    max_index <- which.max(signal_intensity[cell,]);
    if(max_index==1){
      denominator <- signal_intensity[cell,max_index] - signal_intensity[cell,(max_index+1)];
      numerator <- signal_intensity[cell,max_index] - signal_intensity[cell,celltime_levels];
      ratio <- numerator/(numerator+denominator);
      cell_order_full[cell] <- sorted_cell_times_class[celltime_levels] + ratio*4*pi/(celltime_levels-1);
    }else if(max_index==celltime_levels){
      denominator <- signal_intensity[cell,max_index] - signal_intensity[cell,1];
      numerator <- signal_intensity[cell,max_index] - signal_intensity[cell,(max_index-1)];
      ratio <- numerator/(numerator+denominator);
      cell_order_full[cell] <- sorted_cell_times_class[(max_index-1)] + ratio*4*pi/(celltime_levels-1);
    } else {
      denominator <- signal_intensity[cell,max_index] - signal_intensity[cell,(max_index+1)];
      numerator <- signal_intensity[cell,max_index] - signal_intensity[cell,(max_index-1)];
      ratio <- numerator/(numerator+denominator);
      cell_order_full[cell] <- sorted_cell_times_class[(max_index-1)] + ratio*4*pi/(celltime_levels-1);
    }
  }

  return(cell_order_full)
}