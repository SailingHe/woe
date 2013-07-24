#' Calculate Information Value for defined columns in data frame
#'
#' Calculates information value for defined columns in given data frame. Columns can have numeric or character type (including factors).
#' @details Information Value (IV) is concept used in risk management to assess predictive power of variable.
#' IV is defined as:
#' WoE (Weight of Evidence) is defined as:
#' @param df data frame with at least two columns
#' @param y column (integer) with binary outcome
#' @param summary Only total information value for variable is returned when summary is TRUE. Output is sorted by
#' information value, starting with highest value.
#' @param vars List of variables. If not specified, all character variables will be used
#' @param verbose Prints additional details when TRUE. Useful mainly for debugging.
#' @export
#' @examples
#' iv.mult(german_data,"gb")
#' iv.mult(german_data,"gb",TRUE)
#' iv.mult(german_data,"gb",TRUE,c("ca_status","housing","job","duration")) # str(german_data)
#' iv.mult(german_data,"gb",vars=c("ca_status","housing","job","duration"))
#' iv.mult(german_data,"gb",summary=TRUE, verbose=TRUE)
#' iv.mult(german_data,"gb",vars=c("duration","age"),rcontrol=rpart.control(cp=.001,minbucket=10))
#' iv.mult(german_data,"gb",summary=TRUE,rcontrol=rpart.control(cp=.001,minbucket=50))
#' # Use varlist() function to get all numeric variables
#' iv.mult(german_data,y="gb",vars=varlist(german_data,"numeric"))

iv.mult <- function(df,y,summary=FALSE,vars=NULL,verbose=FALSE,rcontrol=NULL) {
  if(verbose) {
    cat(paste("Started processing of data frame:", deparse(substitute(df)),"\n"))
  }
  
  if(is.null(vars)) {
    vars <- names(df)[names(df) !=y]
  }
  
  ivlist <- lapply(vars, function (x) {
      if(is.numeric(df[,x])) {
        if (verbose) cat(paste("Calling iv.num for variable:", x, "\n"))
        iv.num(df,x,y,verbose=verbose,rcontrol=rcontrol)
      } else {
        if (verbose) cat(paste("Calling iv.str for variable:", x, "\n"))
        iv.str(df,x,y,verbose=verbose)  
      }
    }
                  )
  
  if (summary) {
    if (verbose) cat(paste("Preparing summary","\n"))
    ivlist <- rbind.fill(ivlist)
    ivlist <- sqldf("select 
                        variable as Variable,
                        sum(miv) as InformationValue, 
                        count(*) as Bins,
                        sum(case when outcome_0 = 0 or outcome_1 = 0 then 1 else 0 end) as ZeroBins
                     from ivlist 
                     group by variable 
                     order by InformationValue desc") 

    ivlist$Strength[ivlist$InformationValue >= 1] <- 1
    ivlist$Strength[ivlist$InformationValue >= .5 & ivlist$InformationValue < 1] <- 2
    ivlist$Strength[ivlist$InformationValue >= .2 & ivlist$InformationValue < .5] <- 3
    ivlist$Strength[ivlist$InformationValue >= .1 & ivlist$InformationValue < .2] <- 4
    ivlist$Strength[ivlist$InformationValue >= .02 & ivlist$InformationValue < .1] <- 5
    ivlist$Strength[ivlist$InformationValue < .02] <- 6
    ivlist$Strength <- factor(ivlist$Strength, levels=c(1,2,3,4,5,6), 
                              labels= c("Suspicious","Very strong","Strong","Average","Weak","Wery weak"))
  }
  ivlist
}

