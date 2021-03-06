#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Read Active Transport File
###
### This function reads in a csv file with mean values for walking and
### cycling times, stratified by age and sex.  The format of this file
### is described at \url{https://ithim.ghi.wisc.edu/}.
###
### @param filename A character string with the name of the active
###     transport csv file.  There is no default value.  The order of
###     the rows matters.  ageClass must be given in increasing order.
### @note This function is called from createITHIM and is not needed
###     directly by the user.
###
### @return A list of two matrices; mean walking time and mean cycling
###     time in minutes per week.
###
###
readActiveTransportTime <- function(filename){
    activeTravel <- read.csv(file = filename, header = TRUE, stringsAsFactors = FALSE)

    activeTravelList <- split(activeTravel, activeTravel$mode)

    nAgeClass <- unique(unlist(lapply(activeTravelList, function(x) length(x$ageClass))))/2

    if (length(nAgeClass)>1){
        stop("Problem with Active Transport File age classes")
        }

    activeTravelList <- lapply(activeTravelList, function(x) {
        activeTravelMatrix <- cbind(x[x[,"sex"]=="M","value"],x[x[,"sex"]=="F","value"])
        dimnames(activeTravelMatrix) <- list(paste0("ageClass",1:nAgeClass), c("M","F"))
        activeTravelMatrix
    })

    return(activeTravelList)
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Compute Matrices of Active Transport Means
###
### This function computes mean walking/cycling time/speed, as well as
### active transport METs mean and standard deviation
###
### @param parList The list of parameters generated by
###     \code{\link{createParameterList}}
###
### @return A list with matrices of means
###
### \item{meanWalkTime}{A numerical matrix of mean weekly time (hours?) for walking as transport}
### \item{meanCycleTime}{A numerical matrix of mean weekly time for cycling as transport}
### \item{meanWalkMET}{A numerical matrix of mean weekly METs for walking as transport}
### \item{meanCycleMET}{A numerical matrix of mean weekly METs for cycling as transport}
### \item{meanActiveTransportTime}{A numerical matrix containing mean weekly active transport time}
### \item{sdActiveTransportTime}{A numerical matrix containing standard deviation of weekly active transport time}
### \item{propTimeCycling}{The proportion of time walking out of walking or cycling as active transport}
###
### @note Currently all age by sex classes are assigned 6 for weekly
###     cycling for transport METs.  This means we assume that, unlike
###     walking, cycling energy is not a function of speed.
###
### @note meanCycleMET is constant.  So, it's really a parameter and not a function of parameters.
### @note cycling speed has been removed
### @note We use a constant coefficient of variation across strata to compute standard deviations
### @seealso \code{\link{createITHIM}}
###
###
computeMeanMatrices <- function(parList){

    with(parList, {
        if( meanType == "overall" ){
            alphawt <- sum(F*Rwt)
            alphact <- sum(F*Rct)
            alphant <- sum(F*muNonTravelMatrix)
            meanWalkTime <- muwt/alphawt*Rwt
            meanCycleTime <- muct/alphact*Rct
            meanNonTravel <- muNonTravel/alphant*muNonTravelMatrix
        }else if( meanType == "referent" ){
            meanWalkTime <- muwt*Rwt
            meanCycleTime <- muct*Rct
            meanNonTravel <- muNonTravel*muNonTravelMatrix
        }else{
            message("Wrong mean type.")
        }
        propTimeCycling <-  meanCycleTime/(meanCycleTime+meanWalkTime)
        meanActiveTransportTime <- meanWalkTime + meanCycleTime
        sdActiveTransportTime <- meanActiveTransportTime*cv
        pWalk <- 1 - propTimeCycling #meanWalkTime/(meanWalkTime + meanCycleTime)

        return(list(meanWalkTime = meanWalkTime, meanCycleTime = meanCycleTime, meanActiveTransportTime = meanActiveTransportTime, sdActiveTransportTime = sdActiveTransportTime, propTimeCycling = propTimeCycling, pWalk = pWalk, meanNonTravel = meanNonTravel)) # meanWalkMET = meanWalkMET, meanCycleMET = meanCycleMET,
        })
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Performs the comparitive risk assesment for the physical activity
### component
###
### This function performs the CRA and returns the change in disease burden.  The user may specify among four burden types and disease (or total).
###
### @param ITHIM.baseline An ITHIM object
### @param ITHIM.scenario An ITHIM object
### @param bur A chatacter string indicating the type of burden.
###     Acceptable values are daly.delta, yll.delta, yld.delta,
###     deaths.delta (projected deaths).
### @param dis A character string indicating which disease is of interest.  Acceptable values are BreastCancer, ColonCancer, CVD, Dementia, Depression, Diabetes, Stroke, HHD or total.  The default value is tot
###
### @return A numerical value for the chnage in disease burden between
###     baseline and scenario.  Physical activity component only.
###
###
deltaBurdenFunction <- function(ITHIM.baseline, ITHIM.scenario, bur = "daly", dis = "all"){

    diseases <- names(getGBD(ITHIM.baseline, format = "list"))
    diseases <- diseases[diseases != "RTIs"]

    if(!(dis %in% c(diseases,"all"))){
        stop("Value for 'dis' not contained in disease burden file.")
    }

    ITHIM.baseline <- as(ITHIM.baseline, "list")
    ITHIM.scenario <- as(ITHIM.scenario, "list")

    CRA <- compareModels(ITHIM.baseline,ITHIM.scenario)

    if(bur == "daly"){
        burOld <- "daly.delta"
    }else if( bur == "yll"){
        burOld <- "yll.delta"
    }else if( bur == "yld"){
        burOld <- "yld.delta"
    }else if( bur == "deaths"){
        burOld <- "deaths.delta"
    }else{
        stop("Value for bur is unrecognized.")
    }

    index <- which(burOld == names(CRA))
    CRA <- CRA[[index]]

    if( dis == "all" ){
        burdenValue <- sum(unlist(CRA), na.rm = TRUE)
    }else{
        index <- which(dis == names(CRA))
        burdenValue <- sum(unlist(CRA[[index]]), na.rm = TRUE)
    }

  return(burdenValue) # AgeClass 1 is NOT removed from totals
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Compute Quintiles of Active Transport Time
###
### Compute Quintiles of Active Transport Time
###
### @param means A list of means generated by the \code{\link{computeMeanMatrices}}
### @param parameters A list of parameters as created with \code{\link{createParameterList}}
###
### @return A list of lists containing quintiles of active transport
###     time and METs, by sex and age class.
###
### \item{ActiveTransportTime}{Foo}
### \item{WalkingTime}{Foo}
### \item{CyclingTime}{Foo}
###
### @seealso \code{\link{computeQuintiles}}
###
###
getQuintiles <- function(means, parameters){

  ActiveTransportTime <- computeQuintiles(means$meanActiveTransportTime, means$sdActiveTransportTime, parameters$quantiles)
  WalkingTime <- list(M = ActiveTransportTime[["M"]] * (1-means$propTimeCycling[,"M"]), F = ActiveTransportTime[["F"]] * (1-means$propTimeCycling[,"F"]))
  CyclingTime <- list(M = ActiveTransportTime[["M"]] * (means$propTimeCycling[,"M"]), F = ActiveTransportTime[["F"]] * (means$propTimeCycling[,"F"]))

  TotalMETSample <- mapply(getTotalDistribution,
                                 muTravel = means$meanActiveTransportTime,
                                 cvTravel = parameters$cv,
                                 muNonTravel = means$meanNonTravel,
                                 cvNonTravel = parameters$cvNonTravel,
                                 pWalk = means$pWalk, # parameters$pWalk
                                 size = 1e5, SIMPLIFY = FALSE)
  TotalMETQuintiles <- lapply(TotalMETSample,function(x) quantile(x, parameters$quantiles, na.rm = TRUE))

  TotalMET <- list( M = matrix(unlist(TotalMETQuintiles[1:8]),ncol = length(parameters$quantiles), byrow = TRUE), F = matrix(unlist(TotalMETQuintiles[9:16]),ncol = length(parameters$quantiles), byrow = TRUE ) )

  TotalMET <- mapply(function(x,y) ifelse(x < 0.1, 0.1, x), TotalMET, SIMPLIFY=FALSE)

 return(list(ActiveTransportTime=ActiveTransportTime, WalkingTime=WalkingTime, CyclingTime=CyclingTime, TotalMET = TotalMET)) # WalkingMET=WalkingMET, CyclingMET = CyclingMET, TravelMET = TravelMET,
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Compute Quintiles of the Lognormal Distribution
###
### Compute quintiles of the lognormal distribution given matrices for
### mean and standard deviation of active transport time.  This
### function is used by the function \code{\link{getQuintiles}}
###
### @param mean A numerical matrix of means for active transport time
### @param sd A numerical matrix of standard deviations for active
###     transport time
###
### @return A vector of quintiles
###
### @note This function needs to be cleaned up so it is more user
###     friendly
### @note Quintiles are defined as 10, 30, 50, 70, 90 percentiles
###
### @seealso \code{\link{getQuintiles}}
###
###
computeQuintiles <- function( mean, sd, quantiles ){

    nAgeClass <- nrow(mean)
    ncol <- length(quantiles)

    logMean <- log(mean)-1/2*log(1+(sd/mean)^2)
    logSD <- sqrt(log(1+(sd/mean)^2))

    quintVec <- c()

    for( quant in quantiles ){

        quintVec <- c(quintVec, mapply(qlnorm, logMean, logSD, p = quant))

    }

    quintMat <- matrix(quintVec, nrow = 2*nAgeClass, ncol = ncol, dimnames = list(paste0("ageClass", rep(1:nAgeClass,2)),paste0("q",1:ncol)))

    quintList = list(M = quintMat[1:nAgeClass,], F = quintMat[nAgeClass+1:8,])

    return(quintList)
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Set Risk Ratios for Avctive Transport
###
### Set risk ratios for a list of diseases given MET exposure.  These
### values are used to compute change in disease burden due to active
### transport increase.
###
### @return A numerical vector of risk ratios given MET exposure
###
### @note To see the default values and how they are computed run
###     \code{createActiveTransportRRs} with no parentheses
###
### @seealso \code{\link{compareModels}}
###
###
createActiveTransportRRs <- function(nQuantiles = 5){

    diseaseNames <- c("BreastCancer","ColonCancer","CVD","Dementia","Depression","Diabetes")
    nAgeClass <- 8

    RR.lit <- exposure <- rep(list((matrix(NA,nrow=nAgeClass,ncol=2,dimnames=list(paste0("agClass",1:nAgeClass),c("F","M"))))), length(diseaseNames))

    names(RR.lit) <- names(exposure) <- diseaseNames

    exposure[["BreastCancer"]][1:nAgeClass,"F"] <- 4.5
    RR.lit[["BreastCancer"]][1:nAgeClass,"F"] <- 0.944

    exposure[["BreastCancer"]][1:nAgeClass,"M"] <- 1
    RR.lit[["BreastCancer"]][1:nAgeClass,"M"] <- 1

    exposure[["ColonCancer"]][1:nAgeClass,"M"] <- 30.9
    RR.lit[["ColonCancer"]][1:nAgeClass,"M"] <- 0.8

    exposure[["ColonCancer"]][1:nAgeClass,"F"] <- 30.1
    RR.lit[["ColonCancer"]][1:nAgeClass,"F"] <- 0.86

    exposure[["CVD"]][1:nAgeClass,1:2] <- 7.5
    RR.lit[["CVD"]][1:nAgeClass,1:2] <- 0.84

    exposure[["Dementia"]][1:nAgeClass,1:2] <- 31.5
    RR.lit[["Dementia"]][1:nAgeClass,1:2] <- 0.72

    exposure[["Diabetes"]][1:nAgeClass,1:2] <- 10
    RR.lit[["Diabetes"]][1:nAgeClass,1:2] <- 0.83

    exposure[["Depression"]][1:3,1:2] <- 11.25
    RR.lit[["Depression"]][1:3,1:2] <- 0.927945490148335

    exposure[["Depression"]][4:nAgeClass,1:2] <- 11.25
    RR.lit[["Depression"]][4:nAgeClass,1:2] <- 0.859615572255727

    ## exposure[["Stroke"]] <- exposure[["CVD"]]
    ## RR.lit[["Stroke"]] <- RR.lit[["CVD"]]

    ## exposure[["HHD"]] <- exposure[["CVD"]]
    ## RR.lit[["HHD"]] <- RR.lit[["CVD"]]

    k <- 0.5
    RR <- mapply(function(x,y,k) x^(1/y)^k, RR.lit, exposure, k, SIMPLIFY=FALSE)
    RR <- lapply(RR, reshapeRR, nQuantiles = nQuantiles)

    return(RR)

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Estimates change in disease burden
###
### Performs the ITHIM model analysis using two ITHIM objects; baseline
### and scenario.  These objects were created with
### \code{\link{createITHIM}} and updated with
### \code{\link{updateITHIM}}.
###
###
### @param baseline An ITHIM object created with
###     code{\link{createITHIM}} representing the baseline
###
### @param scenario An ITHIM object representing the scenario
###
### @return A list of estimates from the ITHIM model
###
### \item{RR.baseline}{Baseline relative risk compared with no exposure}
### \item{RR.scenario}{Scenario relative risk compared with no exposure}
### \item{RRnormalizedToBaseline}{}
### \item{AF}{Attributable fraction.  Computed with \code{\link{AFForList2}}}
### \item{normalizedDiseaseBurden}{}
### \item{deaths.delta}{Change in number of deaths. (the variable name deaths comes from Geoff's projected data)}
### \item{yll.delta}{Change in YLL}
### \item{yld.delta}{Change in YLD}
### \item{daly.delta}{Change in DALY}
###
### @seealso \code{\link{createITHIM}}, \code{\link{AFForList2}}
###
###
compareModels <- function(baseline, scenario){

    baseline <- as(baseline, "list")
    scenario <- as(scenario, "list")
    baseline$parameters <- as(baseline$parameters, "list")
    scenario$parameters <- as(scenario$parameters, "list")

    # diseases <- c("BreastCancer","ColonCancer","Depression","Dementia","Diabetes", "CVD")
    diseases <- names(baseline$parameters$GBD)
    diseases <- diseases[diseases != "RTIs"]

    GBD <- baseline$parameters$GBD[diseases]

    RR <- createActiveTransportRRs(nQuantiles = length(baseline$parameters$quantiles))
    RR.baseline <- lapply(RR, MET2RR, baseline$quintiles$TotalMET)
    RR.scenario <- lapply(RR, MET2RR, scenario$quintiles$TotalMET)

    RRnormalizedToBaseline.scenario <- mapply(ratioForList,RR.baseline, RR.scenario, SIMPLIFY = FALSE) # ratioForList simply computes the ratio
    RRnormalizedToBaseline.baseline <- mapply(ratioForList,RR.baseline, RR.baseline, SIMPLIFY = FALSE) # What!  Always 1!

#   AF <- mapply(AFForList, RRnormalizedToBaseline.scenario,RRnormalizedToBaseline.baseline, SIMPLIFY = FALSE) # Neil and Geoff compute AF diifferently.  This is Neil's way
    AF <- mapply(AFForList2, RR.scenario,RR.baseline, SIMPLIFY = FALSE) # Neil and Geoff compute AF diifferently.  This is Geoff's way.

    normalizedDiseaseBurden <- lapply(RR.scenario, normalizeDiseaseBurden)
    normalizedDiseaseBurden.baseline <- lapply(RR.baseline, normalizeDiseaseBurden)

    NewBurden <- lapply(AF,function(x) 1-x)
    NewBurdenList <- lapply(NewBurden,function(x) list(M = x[,"M"], F = x[,"F"]))


    denom <- lapply(normalizedDiseaseBurden, function(x) lapply(x, rowSums))
    denom.baseline <- lapply(normalizedDiseaseBurden.baseline, function(x) lapply(x, rowSums))

    GBD <- GBD[diseases]
    NewBurdenList <- NewBurdenList[diseases]
    denom <- denom[diseases]
    denom.baseline <- denom.baseline[diseases]
    normalizedDiseaseBurden <- normalizedDiseaseBurden[diseases]
    normalizedDiseaseBurden.baseline <- normalizedDiseaseBurden.baseline[diseases]

    deaths <- mapply(FUN = burdenFunction, GBD, NewBurdenList, denom, MoreArgs = list(burden = "deaths"), SIMPLIFY = FALSE)
    deaths.baseline <- mapply(FUN = burdenFunction, GBD, NewBurdenList, denom.baseline, MoreArgs = list(burden = "deaths", baseline = TRUE), SIMPLIFY = FALSE)
    deathsBurden <- calculateBurden(deaths, normalizedDiseaseBurden)
    deathsBurden.baseline <- calculateBurden(deaths.baseline, normalizedDiseaseBurden.baseline)
    deaths.delta <- mapply(function(x,y){
        mapply("-",x,y, SIMPLIFY = FALSE)
        },deathsBurden,deathsBurden.baseline, SIMPLIFY = FALSE)

    yll <- mapply(FUN = burdenFunction, GBD, NewBurdenList, denom, MoreArgs = list(burden = "yll"), SIMPLIFY = FALSE)
    yll.baseline <- mapply(FUN = burdenFunction, GBD, NewBurdenList, denom.baseline, MoreArgs = list(burden = "yll", baseline = TRUE), SIMPLIFY = FALSE)
    yllBurden <- calculateBurden(yll, normalizedDiseaseBurden)
    yllBurden.baseline <- calculateBurden(yll.baseline, normalizedDiseaseBurden.baseline)
    yll.delta <- mapply(function(x,y){
        mapply("-",x,y, SIMPLIFY = FALSE)
        },yllBurden,yllBurden.baseline, SIMPLIFY = FALSE)

    yld <- mapply(FUN = burdenFunction, GBD, NewBurdenList, denom, MoreArgs = list(burden = "yld"), SIMPLIFY = FALSE)
    yld.baseline <- mapply(FUN = burdenFunction, GBD, NewBurdenList, denom.baseline, MoreArgs = list(burden = "yld", baseline = TRUE), SIMPLIFY = FALSE)
    yldBurden <- calculateBurden(yld, normalizedDiseaseBurden)
    yldBurden.baseline <- calculateBurden(yld.baseline, normalizedDiseaseBurden.baseline)
    yld.delta <- mapply(function(x,y){
        mapply("-",x,y, SIMPLIFY = FALSE)
        },yldBurden,yldBurden.baseline, SIMPLIFY = FALSE)

    daly <- mapply(FUN = burdenFunction, GBD, NewBurdenList, denom, MoreArgs = list(burden = "daly"), SIMPLIFY = FALSE)
    daly.baseline <- mapply(FUN = burdenFunction, GBD, NewBurdenList, denom.baseline, MoreArgs = list(burden = "daly", baseline = TRUE), SIMPLIFY = FALSE)
    dalyBurden <- calculateBurden(daly, normalizedDiseaseBurden)
    dalyBurden.baseline <- calculateBurden(daly.baseline, normalizedDiseaseBurden.baseline)
    daly.delta <- mapply(function(x,y){
        mapply("-",x,y, SIMPLIFY = FALSE)
        },dalyBurden,dalyBurden.baseline, SIMPLIFY = FALSE)

    return(list(RR.baseline = RR.baseline,
                RR.scenario = RR.scenario,
                RRnormalizedToBaseline = RRnormalizedToBaseline.scenario,
                AF = AF,
                normalizedDiseaseBurden = normalizedDiseaseBurden,
                deaths.delta = deaths.delta,
                yll.delta = yll.delta,
                yld.delta = yld.delta,
                daly.delta = daly.delta
                ))

    }
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Computes simulated distribution of nonTravel METs
###
### Computes simulated distribution of nonTravel METs
###
### @return A random sample from the distribution.
###
###
getNonTravelDistribution <- function(mu, cv, size = 1e4){
    mu <- ifelse(mu == 0, 0.01, mu)
    sd <- mu*cv
    simLogNorm <- rlnorm(size, log(mu/sqrt(1+sd^2/mu^2)), sqrt(log(1+sd^2/mu^2)))
    simData <- simLogNorm
    return(simData)
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Computes simulated distribution of Travel METs
###
### Computes simulated distribution of Travel METs
###
### @return A random sample from the distribution.
###
###
getTravelDistribution <- function(mu, cv, pWalk, size = 1e4){
    mu <- ifelse(mu == 0, 0.01, mu)
    sd <- mu*cv
    activeTransportTime <- rlnorm(size, log(mu/sqrt(1+sd^2/mu^2)), sqrt(log(1+sd^2/mu^2)))

    walkingTime <- activeTransportTime*pWalk
    cyclingTime <- activeTransportTime*(1-pWalk)

    walkingMETs <- computeWalkingMETs()*walkingTime/60
    cyclingMETs <- computeCyclingMETs()*cyclingTime/60

    travelMETs <- walkingMETs + cyclingMETs

    return(travelMETs)
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Compute METs given walking speed
###
### Compute METs given walking speed
###
### @return An estimate for MET expenditure
###
###
computeWalkingMETs <- function(){

    #METs <- 1.2216*v + 0.0838
    #return(ifelse( METs < 2.5, 2.5, METs ))
    return(4.5)

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Compute cycling METs
###
### Compute METs
###
### @return An estimate for MET expenditure
###
###
computeCyclingMETs <- function(){

    return(6)

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Compute distribution of Total METs
###
### Compute distribution of Total METs
###
### @return An estimate for total MET distribution
###
###
getTotalDistribution <- function( muTravel, cvTravel, muNonTravel, cvNonTravel, pWalk, size ){

    return(getTravelDistribution( mu = muTravel, cv=cvTravel, pWalk = pWalk, size = size) + getNonTravelDistribution(mu = muNonTravel, cv = cvNonTravel, size = size))

}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Computes the RR for an exposure of x MET
###
### We use the transformation RR_x = RR_1^(x^k), where RR_1 is the
### relative risk for one MET.
###
### @return A list of matrices of quintiles of RR_x stratified by age
###     class and sex
###
### @note k is fixed at 0.5 for now
###
MET2RR <- function(RR,MET){
    mapply(FUN = function(x, y) x^(y^0.5), RR, MET, SIMPLIFY = FALSE)
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Computes AF given baseline and scenario
###
### Computes AF given baseline and scenario RRs relative to baseline.
###
### @return A list of AFs stratified by age and sex
###
AFForList <- function(scenario,baseline){
    mapply(function(scenario,baseline) (rowSums(scenario)-rowSums(baseline))/rowSums(scenario), scenario, baseline)
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Computes AF given baseline and scenario
###
### Computes AF given baseline and scenario RRs relative to baseline.
###
### @param scenario RR compared with no exposure
###
### @param baseline RR compared with no exposure
###
### @return A list of AFs stratified by age and sex
###
AFForList2 <- function(scenario,baseline){
    mapply(function(scenario,baseline) 1 - rowSums(scenario)/rowSums(baseline), scenario, baseline)
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Foo
###
### Foo
###
### @return Foo
###
normalizeDiseaseBurden <- function(diseaseBurden){
    lapply(diseaseBurden, function(x) x/x[,1])
    }
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### ??
###
### ??
###
### @return ??
###
###
burdenFunction <- function(x2,y2,z2,burden,baseline=FALSE){
    if(!baseline){
        mapply(function(x,y,z){x[x$burdenType==burden,"value"] * y / z}, x2, y2, z2, SIMPLIFY = FALSE)
    }else{
        mapply(function(x,y,z){x[x$burdenType==burden,"value"] / z}, x2, y2, z2, SIMPLIFY = FALSE)
    }
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Internal function.
###
### ??
###
### @return ??
###
###
calculateBurden <- function(burden, normalizedDiseaseBurden){

    foo <- function(x,y){
        matrix(x, nrow = length(x), ncol = ncol(y)) * y
        }

    foo2 <- function(x,y){
        mapply(foo, x, y, SIMPLIFY = FALSE)
        }

    List <- mapply(foo2, burden, normalizedDiseaseBurden, SIMPLIFY = FALSE)

    Burden <- lapply(List, function(x){
        lapply(x,rowSums)
        })

        return(Burden)

        }
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Transforms the RR object
###
### Transforms the RR object into something more convenient.
###
### @return A list of two matrices of RRs stratified by age class and
###     sex
###
reshapeRR <- function(RR, nQuantiles = 5){
    nAgeClass <- 8
    list( M = matrix(RR[,"M"], nrow = nAgeClass, ncol = nQuantiles, dimnames = list(paste0("ageClass",1:nAgeClass), paste0("quint",1:nQuantiles))),F = matrix(RR[,"F"], nrow = nAgeClass, ncol = nQuantiles, dimnames = list(paste0("ageClass",1:nAgeClass), paste0("quint",1:nQuantiles))))
    }
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Computes a ratio of elements in two lists
###
### Computes a ratio of elements in two lists.
###
### @return A list of ratios
###
ratioForList <- function(baseline,scenario){
mapply(FUN = "/", baseline, scenario, SIMPLIFY = FALSE)
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Retrieve a density vector for a logNormal distribution
###
### Retrieve a density vector for a logNormal distribution
###
### @param mu The mean (on log scale or not?  Figure this out.
### @param sd The standard deviation (on log scale or not?  Figure this out.
###
### @return A vector of length 2000 with density values over the
###     interval 0 to 2000
###
getLogNormal <- function(mu,sd){
    dlnorm(seq(0,2000,length.out=1e3), log(mu/sqrt(1+sd^2/mu^2)), sqrt(log(1+sd^2/mu^2)))
}
