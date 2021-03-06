buildcmatrix <- function(formula, verbose=FALSE){
	#get terms involved in the model
	nobarsformula <- suball(formula);
	datavariables <- attr(terms(nobarsformula),"variables");
	datavariables <- as.character(datavariables)[-1];     
	
	#exclude the 'sender' and 'receiver' terms (as they are autogenerated)
	datavariables <- datavariables[datavariables!="sender"];
	datavariables <- datavariables[datavariables!="receiver"];
	
	#extract the network object name
	datacopy <- get(datavariables[1]); 
	
	#check if network is directed
	if((datacopy %n% "directed") == FALSE){
		stop("this function is for directed networks only.")
	}	
	
	#create a modified formula to trick ergm		
	extraterms <- "+ nodeicov(\"NODE_ID_TEMP\") + nodeocov(\"NODE_ID_TEMP\")";
	newformula <- paste("datacopy ~", paste(datavariables[-1], collapse="+"), extraterms);
	newformula <- as.formula(newformula);
	
	#insert sender ids
	nodelength <- nrow(as.matrix(datacopy));
	datacopy %v% "NODE_ID_TEMP" <- 1:nodelength;
	
	#build the covariates matrix
	nw <- ergm.getnetwork(newformula)
	model <- ergm.getmodel(newformula, nw, drop = FALSE, initialfit = TRUE)
	Clist <- ergm.Cprepare(nw, model)
	Clist.miss <- ergm.design(nw, model)
	MPLEsetup <- ergm.pl(Clist, Clist.miss, model, verbose=verbose);
	cmatrix <- cbind(y=MPLEsetup$zy, MPLEsetup$xmat);
	
	#check if nothing dropped
	if(nrow(cmatrix) != (nodelength * (nodelength-1))){
		stop("Something went wrong. Covariates matrix does not seem to have right number of rows.")
	}
	
	#rename the id columns
	colnames(cmatrix)[which(colnames(cmatrix)== "nodeicov.NODE_ID_TEMP")] <- "receiver";
	colnames(cmatrix)[which(colnames(cmatrix)== "nodeocov.NODE_ID_TEMP")] <- "sender";	
	
	#lme4 wants a dataframe:
	cmatrix <- as.data.frame(cmatrix);
	
	#return
	return(cmatrix);
}