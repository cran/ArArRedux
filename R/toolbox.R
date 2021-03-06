theday <- function(thedate){
    dateinseconds <- as.POSIXlt(thedate,origin="1970-01-01 00:00:00")
    dateindays <- (1900+dateinseconds$year-1970)*365 + dateinseconds$yday
    dayinseconds <- dateindays*24*3600
    return(dayinseconds)
}

mergematrices <- function(xcovmat,ycovmat){
    if (is.null(xcovmat)) return(ycovmat)
    if (is.null(ycovmat)) return(xcovmat)
    nx <- max(1,nrow(xcovmat))
    ny <- max(1,nrow(ycovmat))
    covmat <- matrix(0,nrow=nx+ny,ncol=nx+ny)
    covmat[1:nx,1:nx] <- xcovmat
    covmat[(nx+1):(nx+ny),(nx+1):(nx+ny)] <- ycovmat
    return(covmat)
}

# returns the indices of timevec2 which are closest to timevec1
nearest <- function(timevec1,timevec2){
    ii <- NULL
    for (i in 1:length(timevec1)) {
        ii <- c(ii, which.min(abs(timevec2 - timevec1[i])))
    }
    return(ii)
}

nmasses <- function(x){
    return(length(x$masses))
}

nruns <- function(x,...){ UseMethod("nruns",x) }
nruns.default <- function(x,...){
    length(x$labels)
}
nruns.PHdata <- function(x,...){
    return(nruns(x$signals[[1]]))
}

ncycles <- function(x,...){ UseMethod("ncycles",x) }
ncycles.default <- function(x,...){stop()}
ncycles.timeresolved <- function(x,...){
    return(dim(x$thetime)[1])
}

getsignal <- function(X,prefix,num=NULL){
    i <- getindices(X,prefix,num)
    return(cbind(X$intercepts[i], sqrt(X$covmat[i,i])))
}

getindices <- function(...){ UseMethod("getindices") }
getindices.default <- function(nmasses,nruns=NULL,
                               imasses=NULL,iruns=NULL,...){
    if (is.null(nruns)) nruns <- max(iruns)
    if (is.null(imasses)) imasses <- 1:nmasses
    if (is.null(iruns)) iruns <- 1:nruns
    i <- NULL
    for (irun in iruns){
        i <- c(i,(irun-1)*nmasses + imasses)
    }
    return(i)
}
getindices.logratios <- function(x,iruns,...){
    cs <- c(0,cumsum(x$nlr))
    i <- NULL
    for (irun in iruns){
        i <- c(i,(cs[irun]+1):cs[irun+1])
    }
    return(i)
}
getindices.redux <- function(X,prefix=NULL,num=NULL,den=NULL,
                             pos=NULL,invert=FALSE,include.J=FALSE,...){
    i <- 1:length(X$intercepts)
    if (is.null(prefix)) {
        i1 <- i
    } else {
        j <- findrunindices(X,prefixes=prefix,invert=invert,include.J=include.J)
        i1 <- getindices.logratios(X,j)
    }
    if (is.null(num)) {
        i2 <- i
    } else {
        i2 <- findmatches(X$num,prefixes=num,invert=invert)
    }
    if (is.null(den)) {
        i3 <- i
    } else {
        i3 <- findmatches(X$den,prefixes=den,invert=invert)
    }
    if (is.null(pos)) {
        i4 <- i
    } else {
        matches <- X$pos %in% pos
        if (invert){
            i4 <- which(!matches)
        } else {
            i4 <- which(matches)
        }
    }
    return(which((i %in% i1) & (i %in% i2) &
                 (i %in% i3) & (i %in% i4)))
}

findrunindices <- function(X,prefixes,invert=FALSE,include.J=FALSE){
    i <- 1:nruns(X)
    i1 <- findmatches(X$labels,prefixes,invert)
    out <- (i %in% i1)
    if (include.J) {
        i2 <- findmatches(X$pos,prefixes=X$Jpos,invert)
        i3 <- findmatches(X$labels,prefixes=c("DCAL","K:","Ca:"),invert)
        out <- out | (i %in% i2) | (i %in% i3)
    }
    which(out)
}

findmatches <- function(labels,prefixes,invert=FALSE){
    ns <- length(labels)
    i <- c() # vector of intercepts
    for (prefix in prefixes){
        matches <- labels %in% prefix
        if (any(matches)) i <- c(i,which(matches))
        else i <- c(i,grep(prefix, labels))
    }
    j <- sort(i)
    if (invert){
        if (length(j)==0) return(1:ns)
        else return((1:ns)[-j])
    } else {
        return(j)
    }
}

getruns <- function(x,...){ UseMethod("getruns",x) }
getruns.default <- function(x,...){stop()}
getruns.timeresolved <- function(x,i,...){
    ii <- getindices(nmasses=nmasses(x),iruns=i)
    return(x$d[,ii])
}

#' Select a subset of some data
#'
#' Extracts those intercepts, covariances etc. that match a given list
#' of indices or labels.
#' 
#' @param x an object of class \code{\link{timeresolved}},
#'     \code{\link{logratios}}, \code{\link{redux}} or
#'     \code{\link{results}}
#' @param i a vector with indices of the selected runs
#' @param labels a string or a vector of strings with sample names
#' @param invert boolean flag indicating whether the selection should
#'     be inverted, i.e. whether the selected indices or labels should
#'     be removed rather than retained
#' @param include.J if \code{TRUE}, automatically adds the irradiation
#'     monitors to the selection
#' @param ... other arguments
#' @return an object of the same class as \code{x}
#' @examples
#' data(Melbourne)
#' ages <- process(Melbourne$X,Melbourne$irr,Melbourne$fract)
#' MD <- subset(ages,labels=c("MD2-1","MD2-2","MD2-3","MD2-4","MD2-5"))
#' plotcorr(MD)
#' @rdname subset
#' @export
subset.timeresolved <- function(x,i=NULL,labels=NULL,invert=FALSE,include.J=FALSE,...){
    if (is.null(i)) i <- findrunindices(x,prefixes=labels,invert=invert,include.J=include.J)
    out <- x
    out$d <- getruns(x,i)
    out$thetime <- x$thetime[,i]
    out$thedate <- x$thedate[i]
    out$irr <- x$irr[i]
    out$pos <- x$pos[i]
    out$labels <- x$labels[i]
    if (methods::is(x,"blankcorrected"))
        out$blankindices <- x$blankindices[i]
    return(out)
}
#' @rdname subset
#' @export
subset.logratios <- function(x,i=NULL,labels=NULL,invert=FALSE,include.J=FALSE,...){
    if (is.null(i)) i <- findrunindices(x,prefixes=labels,invert=invert,include.J=include.J)
    out <- x
    out$irr <- x$irr[i]
    out$pos <- x$pos[i]
    out$labels <- x$labels[i]
    out$thedate <- x$thedate[i]
    out$nlr <- x$nlr[i]
    j <- getindices.logratios(x,i)
    out$num <- x$num[j]
    out$den <- x$den[j]
    out$intercepts <- x$intercepts[j]
    out$covmat <- x$covmat[j,j]
    return(out)
}
#' @rdname subset
#' @export
subset.redux <- function(x,i=NULL,labels=NULL,invert=FALSE,include.J=FALSE,...){
    subset.logratios(x,i,labels,invert,include.J,...)
}
#' @rdname subset
#' @export
subset.results <- function(x,i=NULL,labels=NULL,invert=FALSE,...){
    out <- x
    if (is.null(i)) i <- findrunindices(x,prefixes=labels,invert=invert)
    out$labels <- x$labels[i]
    out$thedate <- x$thedate[i]
    out$ages <- x$ages[i]
    out$covmat <- x$covmat[i,i]
    return(out)
}

#' Select a subset of isotopes from a dataset
#'
#' Extracts the intercepts, covariance matrix, etc. of a selection of
#' isotopes from a larger dataset
#' 
#' @param x an object of class \code{\link{logratios}},
#' \code{\link{timeresolved}}, \code{\link{PHdata}} or
#' \code{\link{redux}}.
#' @param ... other arguments
#' @return an object of the same class as x
#' @examples
#' kfile <- system.file("K-glass.csv",package="ArArRedux")
#' masses <- c("Ar37","Ar38","Ar39","Ar40","Ar36")
#' mk <- loaddata(kfile,masses)
#' lk <- fitlogratios(blankcorr(mk,"EXB#","K:"),"Ar40")
#' k <- getmasses(lk,"Ar39","Ar40") # subset of the relevant isotopes
#' plotcorr(k)
#' @export
getmasses <- function(x,...){ UseMethod("getmasses",x) }
#' @rdname getmasses
#' @export
getmasses.default <- function(x,...){ stop() }
#' @param mass a vector of strings denoting the masses of interest
#' @param invert boolean parameter indicating whether the selection
#' should be inverted (default = FALSE)
#' @rdname getmasses
#' @export
getmasses.timeresolved <- function(x,mass,invert=FALSE,...){
    out <- x
    if (invert){ imasses <- which(x$masses != mass) }
    else       { imasses <- which(x$masses == mass) }
    out$masses <- out$masses[imasses]
    ii <- getindices(nmasses(x),nruns(x),imasses)
    out$d <- x$d[,ii]
    return(out)
}
#' @param num vector of strings indicating the numerator isotopes
#' @param den vector of string indicating the denominator isotopes
#' @rdname getmasses
#' @export
getmasses.logratios <- function(x,num,den,invert=FALSE,...){
    out <- x
    if (invert){ i <- which(!((x$num %in% num) & (x$den %in% den))) }
    else { i <- which((x$num %in% num) & (x$den %in% den)) }
    out$num <- x$num[i]
    out$den <- x$den[i]
    out$intercepts <- x$intercepts[i]
    out$covmat <- x$covmat[i,i]
    out$nlr <- graphics::hist(i,breaks=c(0,cumsum(x$nlr)),
                    plot=FALSE)$counts
    return(out)
}
#' @rdname getmasses
#' @export
getmasses.redux <- function(x,num,den,invert=FALSE,...){
    out <- x
    if (invert){ hasmass <- !((x$num %in% num) & (x$den %in% den)) }
    else { hasmass <- (x$num %in% num) & (x$den %in% den) }
    i <- which(hasmass)
    bi <- cumsum(c(1,x$nlr))
    ei <- cumsum(x$nlr)
    nn <- length(x$labels)
    retain <- rep(FALSE,nn)
    for (j in 1:nn) {
        retain[j] <- any(hasmass[bi[j]:ei[j]])
    }
    out$irr <- x$irr[retain]
    out$pos <- x$pos[retain]
    out$labels <- x$labels[retain]
    out$thedate <- x$thedate[i]
    out$intercepts <- x$intercepts[i]
    out$covmat <- x$covmat[i,i]
    out$num <- x$num[i]
    out$den <- x$den[i]
    out$nlr <- graphics::hist(i,breaks=c(0,cumsum(x$nlr)),plot=FALSE)$counts[retain]
    return(out)
}

setmasses <- function(x,mass,value){ UseMethod("setmasses",x) }
setmasses.default <- function(x,mass,value){stop()}
setmasses.timeresolved <- function(x,mass,value){
    imasses <- which(x$masses == mass)
    ii <- getindices(nmasses(x),nruns(x),imasses)
    x$d[,ii] <- value
    return(x)
}
setmasses.fit <- function(x,mass,value){
    imasses <- which(x$masses == mass)
    ii <- getindices(nmasses(x),nruns(x),imasses)
    x$intercepts[ii] <- value$intercepts
    for (i in 1:length(ii)){
        x$covmat[ii[i],ii] <- value$covmat[i,]
    }
    return(x)
}

replacenegatives <- function(x){
    out <- x
    nmasses <- nmasses(x)
    nruns <- nruns(x)
    isnegative <- apply(x$d<0,2,"sum")>0
    ntoreplace <- sum(isnegative)
    out$d[,isnegative] <- # effectively set to zero
    seq(from=1e-18,to=1e-20,length.out=ncycles(x)*ntoreplace)
    return(out)
}

#' Merge a list of logratio data
#'
#' Recursively concatenates a list of logratio data into one big dataset
#' 
#' @param lrlist a list containing items of class
#' \code{\link{logratios}} or \code{\link{redux}}
#' @return an object of the same class as \code{x} containing the
#' merged dataset
#' @examples
#' samplefile <-  system.file("Samples.csv",package="ArArRedux")
#' kfile <- system.file("K-glass.csv",package="ArArRedux")
#' cafile <- system.file("Ca-salt.csv",package="ArArRedux")
#' dfile <- system.file("Calibration.csv",package="ArArRedux")
#' masses <- c("Ar37","Ar38","Ar39","Ar40","Ar36")
#' blanklabel <- "EXB#"
#' Jpos <- c(3,15)
#' dlabels <- c("H1","AX","L1","L2")
#'  
#' m <- loaddata(samplefile,masses) # samples and J-standards
#' mk <- loaddata(kfile,masses) # K-interference data
#' mca <- loaddata(cafile,masses) # Ca interference data
#' md <- loaddata(dfile,dlabels,PH=TRUE) # detector intercalibrations
#'  
#' # form and fit logratios
#' l <- fitlogratios(blankcorr(m,blanklabel),"Ar40")
#' lk <- fitlogratios(blankcorr(mk,blanklabel,"K:"),"Ar40")
#' k <- getmasses(lk,"Ar39","Ar40") # subset on the relevant isotopes
#' lca <- fitlogratios(blankcorr(mca,blanklabel,"Ca:"),"Ar37")
#' ca <- getmasses(lca,c("Ar36","Ar39"),c("Ar37","Ar37")) # subset
#' ld <- fitlogratios(blankcorr(md))
#' d <- averagebyday(ld,"DCAL")
#' 
#' # merge all data (except air shots) into one big logratio structure
#' X <- newredux(concat(list(l,k,ca,d)),Jpos)
#' data(Melbourne)
#' if (isTRUE(all.equal(Melbourne$X,X))) {
#'    print("We just reconstructed the built-in dataset Melbourne$X")}
#' @export
concat <- function(lrlist){
    if (length(lrlist)==2) {
        x <- lrlist[[1]]
        y <- lrlist[[2]]
        out <- x
        out$irr <- c(x$irr,y$irr)
        out$pos <- c(x$pos,y$pos)
        out$labels <- c(x$labels,y$labels)
        out$thedate <- c(x$thedate,y$thedate)
        out$num <- c(x$num,y$num)
        out$den <- c(x$den,y$den)
        out$nlr <- c(x$nlr,y$nlr)
        out$intercepts <- c(x$intercepts,y$intercepts)
        out$covmat <- mergematrices(x$covmat,y$covmat)
    } else {
        x <- lrlist[[1]]
        rest <- lrlist[2:length(lrlist)]
        y <- concat(rest)
        out <- concat(list(x,y))
    }
    return(out)
}
