

#' Prikking av foretak og avrunding eller prikking av personer
#' 
#' Prikking av foretak og avrunding eller prikking av personer.
#' Sett parameteren `allowTotal` til `TRUE` for at kategorier innen (`within`) foretak skal prikkes samtidig som totalverdier over disse grupperingene tillates publisert.
#' 
#' Default parameterverdier der funksjonen \code{\link{lower_match}} brukes betyr at default er første variabelnavn i `data` 
#' som matcher når det ikke tas hensyn til små eller store bokstaver. Dette betyr, for eksempel, at parameteren `frtk` 
#' ikke må bli spesifisert av brukeren hvis variabelnavnet i inputdata er `"frtk_id_ssb"` eller `"FRTK_ID_SSB"`. 
#' Det kan også være `"frtk_id_SSB"` om man vil.   
#'
#' @param data Datasett som data frame 
#' @param between  Variabler som grupperer foretak for prikking  
#' @param within Ytterligere variabler innen foretak som brukes til avrunding eller prikking av personer
#' @param by Tid eller andre variabler som deler datasettet. Metoden kjøres på hver del og resultatet settes sammen. 
#' @param roundBase Base for avrunding
#' @param maxN Max-verdi for primærprikking av personer.  Ikke-NULL verdi betyr prikking istedenfor avrunding. 
#' @param protectZeros Suppression parameter. Empty cells (count=0) are set as primary suppressed When TRUE.  
#' @param secondaryZeros Suppression parameter.
#' @param freqVar A single variable holding counts (name or number) or NULL in the case of micro data (then variable named `"freq"` will be generated )  
#' @param sector Sektor-variabel som inneholder Privat-koden (se parameter \code{"private"}). 
#' @param private Privat-koden
#' @param nace between-variabel med nace-kode eller koding (starter med) som leter etter slik variabel (`nace` kan settes til `NULL`) 
#' @param nace00 nace-koden som foretrekkes til sekundærprikking  (`nace00` kan settes til `NULL`)
#' @param nace00primary Ved FALSE utelates nace00-koden (se over) fra primærprikking  
#' @param frtk foretak variabel 
#' @param virk virksomhet variabel
#' @param unik unik variabel  
#' @param makeunik Unik variabel genereres ved TRUE ellers antas det at den finnes
#' @param removeZeros When TRUE, rows with zero count will be removed from the data within the algorithm. 
#'                    Default er at parameteren er motsatt av `protectZeros`. 
#'                    Altså 0-er i data fjernes når 0-er ikke skal prikkes. 
#'                    Parameteren har betydning for telling av antall foretak bak et tall. 
#' @param preAggregate Input til \code{\link{GaussSuppressionFromData}}. Parameteren er med her for testing og sammenlikning av resultater. 
#' @param output Ved avrunding kan ulike type output velges. Enten "rounded" (samme som NULL) eller "suppressed" (liste med begge hvis noe annet). 
#'               Her kan det bli endring. 
#' @param decimal **Ved TRUE** returneres indre celle-data med desimaltall. Dette kan fungere som input seinere (se nedenfor).  
#'                Når, i tillegg, `maxN` er `NULL` (default), er det mulig å spesifisere `between` som en formel (se eksempel).
#'   
#' **Ved `decimal` som en data-frame** antas at dette er indre celle-data med desimaltall. Prikking vil baseres på aggregering av disse.                                  
#' 
#' @param freqDec Navn på variabel(er) med desimaltall eller koding (starter med). Brukes når `decimal` er en data-frame. 
#' @param nRep Antall desimaltallsvariabler, \code{\link{GaussSuppressDec}} parameter.
#' @param digitsA  \code{\link{GaussSuppressDec}} parameter (9 er vanligvis ok)
#' @param digitsB  \code{\link{SuppressionFromDecimals}} parameter (5 er ok når nRep=3)
#' @param allowTotal Når TRUE, ingen prikking når alle within-variabler er `"Total"`. 
#' @param til0 Når TRUE: Når ikke-prikket tall som følge av `allowTotal=TRUE` er avrundet til 0 blir
#'             prikking av undergrupper av denne opphevet og erstattet med 0.  
#' @param iWait Minimum antall sekunder mellom hver gang det skrives ut ekstra informasjon fra prikkerutinen.    
#' 
#' @return data frame 
#' @export
#' @importFrom GaussSuppression GaussSuppressionFromData NcontributorsHolding Ncontributors GaussSuppressDec SuppressionFromDecimals
#' @importFrom SSBtools WildcardGlobbingVector SortRows RowGroups Match
#' @importFrom methods hasArg
#' @importFrom stats aggregate delete.response formula terms
#' @importFrom utils flush.console
#' @examples
#' 
#' prikkeVarA <- c("arb_fylke", "ARB_ARBKOMM", "nar8", "sektor")
#' prikkeVarB <- c("arb_fylke", "ARB_ARBKOMM", "nar17")
#' 
#' z <- SdcData("syssel27")
#' 
#' SdcForetakPerson(z, between = prikkeVarA)
#' SdcForetakPerson(z, between = prikkeVarA, output = "suppressed")
#' 
#' SdcForetakPerson(z, between = prikkeVarB, within = "PERS_KJOENN")
#' 
#' SdcForetakPerson(z, between = prikkeVarA, maxN = 2)
#' SdcForetakPerson(z, between = prikkeVarA, maxN = 2, decimal = TRUE)
#' SdcForetakPerson(z, between = prikkeVarB, within = "PERS_KJOENN", maxN = 2, decimal = TRUE)
#' 
#' z100 <- SdcData("syssel100")
#' out <- SdcForetakPerson(z100, between = prikkeVarB, within = c("PERS_KJOENN", "alder6"))
#' head(out)
#' tail(out)
#' 
#' # Setter  allowTotal = TRUE
#' outT <- SdcForetakPerson(z100, between = prikkeVarB, within = c("PERS_KJOENN", "alder6"), 
#'                          allowTotal = TRUE)
#' # Rader som har gitt ulik prikking
#' rader <- which(is.na(outT$roundedSuppressed) != is.na(out$roundedSuppressed))
#' out[rader, ]
#' outT[rader, ]
#' 
#' # Ser effekt av allowTotal ved bare prikking
#' outP <- SdcForetakPerson(z100, between = prikkeVarB, within = c("PERS_KJOENN", "alder6"), maxN = 1)
#' outTP <- SdcForetakPerson(z100, between = prikkeVarB, within = c("PERS_KJOENN", "alder6"), maxN = 1, 
#'                           allowTotal = TRUE)
#' # Rader som har gitt ulik primærprikking 
#' raderP <- which(outTP$primary != outP$primary)
#' outP[raderP, ]   # Her ble allikevel prikking til slutt lik (suppressed)
#' outTP[raderP, ]  # Dette pga. singleton-håndtering (1-ere som kan avsløres)
#' 
#' 
#' # Finner data desimaltall med mange variabler som tas hensyn til.  
#' # Dessverre en warning som kan sees bort fra 
#' # Kan unngaas med dataDec <- suppressWarnings(SdcForetakPerson(.....
#' prikkeVarC <- c("arb_fylke", "ARB_ARBKOMM", "nar8", "sektor", "nar17")
#' dataDec <- SdcForetakPerson(z100, between = prikkeVarC, nace = "nar8", decimal = TRUE)
#' 
#' # Bruker desimaltall som utgangspunkt for prikking
#' outA <- SdcForetakPerson(z100, between = prikkeVarA, decimal = dataDec)
#' outB <- SdcForetakPerson(z100, between = prikkeVarB, within = "PERS_KJOENN", decimal = dataDec)
#' 
#' # Desimaltall kan genereres med formel 
#' dataDec2 <- SdcForetakPerson(z100, between = 
#'                  ~(arb_fylke + ARB_ARBKOMM) * nar8 * sektor + (arb_fylke + ARB_ARBKOMM) * nar17, 
#'                  nace = "nar8", decimal = TRUE)
#' 
#' # Lager data med to stataar
#' z100$stataar <- "2019"
#' z$stataar <- "2020"
#' z127 <- rbind(z100, z)
#' out127 <- SdcForetakPerson(z127, between = prikkeVarB, by = "stataar")
#' head(out127)
#' tail(out127)
SdcForetakPerson = function(data, between  = NULL, within = NULL, by = NULL, 
                            roundBase = 3, maxN = NULL,
                            protectZeros = FALSE, 
                            secondaryZeros = FALSE,
                            freqVar = NULL,
                            sector = lower_match(data, "sektor"),
                            private = "Privat",
                            nace = c("nar*", "NACE*", "nace*"), nace00="00",
                            nace00primary = FALSE,
                            frtk = lower_match(data, "frtk_id_ssb"), 
                            virk = lower_match(data, "virk_id_ssb"), 
                            unik = lower_match(data, "unik_id"), 
                            makeunik = TRUE, removeZeros = !protectZeros, preAggregate = TRUE,
                            output = NULL,
                            decimal = FALSE, 
                            freqDec = "freqDec*",
                            nRep = 3,
                            digitsA = 9,
                            digitsB = 5,
                            allowTotal = FALSE,
                            til0 = TRUE,
                            iWait = Inf){
  
  argOutput <- get0("GaussSuppressionFromData_argOutput", ifnotfound = "publish") # special input for testing from global environment
  
  if (is.data.frame(decimal)){
    dataDec <- decimal
    decimal <- FALSE
    nace <- NULL
  } else {
    dataDec <- NULL
  }
  
  
  if (is.null(output)) 
    output = "rounded"
  
  if (hasArg("freqvar"))
    stop('Misspelled parameter "freqvar" found. Use "freqVar".')
  if (hasArg("roundbase"))
    stop('Misspelled parameter "roundbase" found. Use "roundBase".')
  if (hasArg("maxn"))
    stop('Misspelled parameter "maxn" found. Use "maxN".')
  
  #if(!is.null(maxN))
  #  stop("Bruk av maxN er ikke implementert")
  
  #if(sector != "sektor")
  #  stop("Bruk av sector er ikke implementert")
  
  if (length(class(data)) > 1 | class(data)[1] != "data.frame") 
    data <- as.data.frame(data)
  
  
  CheckInput(by,  type = "varNrName", data = data, okNULL = TRUE, okSeveral = TRUE)
  
  
  if(!is.null(by)){
    #if(!is.null(dataDec)){
    # stop("Desimal-input kombinert med by er ikke implementert")
    #}
    
    if(!(output %in% c("rounded", "suppressed")))
      stop('Output must be "rounded" or "suppressed" when non-NULL "by"')
    return(KostraApply( data=data, by=by, Fun=SdcForetakPerson, dataDec = dataDec, 
                        between  = between , within = within, roundBase = roundBase, maxN = maxN, 
                        protectZeros = protectZeros, secondaryZeros = secondaryZeros, freqVar = freqVar,  
                        sector=sector, private = private,
                        nace = nace, nace00=nace00, nace00primary = nace00primary, 
                        frtk=frtk, virk=virk, unik =unik, makeunik =makeunik, 
                        removeZeros = removeZeros, preAggregate = preAggregate, output = output, 
                        decimal = decimal, freqDec = freqDec, 
                        nRep = nRep, digitsA = digitsA, digitsB = digitsB,
                        allowTotal = allowTotal, til0 = til0, iWait = iWait)) 
  }
  
  if(class(between)[1] == "formula"){
    if(!decimal | !is.null(maxN)){
      stop("between som formel bare implementert for decimal=TRUE/maxN=NULL")
    }
    formula_decimal <- between
    dimVar_decimal <- NULL 
    between <- row.names(attr(delete.response(terms(formula_decimal)), "factors"))
  } else {
    formula_decimal <- NULL
    dimVar_decimal <- between
  }
  
  CheckInput(between, type = "varNrName", data = data, okNULL = TRUE, okSeveral = TRUE)
  CheckInput(within,  type = "varNrName", data = data, okNULL = TRUE, okSeveral = TRUE)
  CheckInput(roundBase,   type = "integer", min = 2, okNULL = TRUE)
  CheckInput(maxN,   type = "integer", okNULL = TRUE)
  CheckInput(freqVar,  type = "varNrName", data = data, okNULL = TRUE)
  
  if(!is.null(between)) between <- names(data[1, between, drop = FALSE])
  if(!is.null(within))  within  <- names(data[1, within, drop = FALSE])
  if(!is.null(freqVar)) freqVar <- names(data[1, freqVar, drop = FALSE])
  
  if (removeZeros & !is.null(freqVar)) 
    data <- data[data[[freqVar]] != 0, , drop = FALSE]
  
  # nace brukes bare sammen med nace00
  if (length(nace00) == 0) nace <- NULL
  
  
  if(is.null(freqVar)){
    # freqVar <- "sySseLsaTte" # Kun variabelnavn som brukes internt
    # data$sySseLsaTte <- 1L
    if ("freq" %in% names(data)) {
      warning("'freq' is set to 1's. 'freq' existing in data is not used")
    }
    freqVar <- "freq"
    data$freq <- 1L
  }
  
  
  alleVar <- c(between , within)
  
  supData <- NULL
  prikkData <- NULL
  
  if(length(between )>0){
    
    if(is.null(dataDec)){
      
      CheckInput(sector,  type = "varNrName", data = data, okNULL = TRUE)
      CheckInput(frtk,  type = "varNrName", data = data, okNULL = TRUE)
      CheckInput(virk,  type = "varNrName", data = data, okNULL = TRUE)
      if(!makeunik) CheckInput(unik,  type = "varNrName", data = data, okNULL = TRUE)
      
      
      data <- Make_FRTK_VIRK_UNIK_AggVar(data, frtk=frtk, virk=virk, unik =unik, varnames = c("FRTK_VIRK_UNIK", NA, NA, NA, NA, NA, NA))
      
      if (!is.null(nace)) {
        if(length(nace)){
          nace <- WildcardGlobbingVector(names(data[1, between, drop=FALSE]), nace)
          if(length(nace)==0){
            warning("Ingen nace-variabel funnet")
          }
          if(length(nace)>1){
            stop("nace-variabel ikke unikt spesifisert")
          }
        }
      }
      
      if(length(nace)==0){
        nace = NULL
      }
      
      Primary_FRTK_VIRK_UNIK_sektor_here <- Primary_FRTK_VIRK_UNIK_sektor
      
    }
    
    if(is.null(dataDec)){
      if (!is.null(nace)) {
        data$narWeight <- Make_NarWeight_00(data, nace, nace00)
        if(!nace00primary){
          Primary_FRTK_VIRK_UNIK_sektor_here <- c(Primary_FRTK_VIRK_UNIK_sektor, Primary_NA_when_weight_is_0)
        }
      } else {
        data$narWeight <- 1L
      }
    }
    
    if(is.null(maxN)){
      if(is.null(dataDec)){
        if(decimal){
          
          if(argOutput != "publish"){
            prikkData   <-    GaussSuppressionFromData(data, dimVar = dimVar_decimal, freqVar = freqVar, 
                                          formula = formula_decimal,
                                          charVar = c(sector, "FRTK_VIRK_UNIK"), 
                                          weightVar = "narWeight", protectZeros = protectZeros, maxN = -1, 
                                          secondaryZeros = secondaryZeros,
                                          primary = Primary_FRTK_VIRK_UNIK_sektor_here, 
                                          singleton = NULL, singletonMethod = "none", preAggregate = preAggregate,
                                          sector = sector, private = private, #output = "publish_inner",
                                          output = argOutput, 
                                          iWait = iWait)
            return(prikkData)
          }
          a <-         GaussSuppressDec(data, dimVar = dimVar_decimal, freqVar = freqVar, 
                                        formula = formula_decimal,
                                                charVar = c(sector, "FRTK_VIRK_UNIK"), 
                                                weightVar = "narWeight", protectZeros = protectZeros, maxN = -1, 
                                                secondaryZeros = secondaryZeros,
                                                primary = Primary_FRTK_VIRK_UNIK_sektor_here, 
                                                singleton = NULL, singletonMethod = "none", preAggregate = preAggregate,
                                                sector = sector, private = private, #output = "publish_inner",
                                        output = ifelse(is.null(formula_decimal), "publish_inner", "inner"),
                                                nRep = nRep, digits = digitsA,  mismatchWarning = digitsB, 
                                        iWait = iWait)
          
          if(!is.null(formula_decimal)){
            # names(a)[names(a) == freqVar] <- "freq"
            return(a[names(a) != "narWeight"])
          }
          
          dimVarOut <- between[between %in% names(a$publish)]
          ma <- Match(a$publish[dimVarOut], a$inner[dimVarOut])
          prikkData <- cbind(a$inner[ma[!is.na(ma)], between, drop = FALSE], 
                             a$publish[!is.na(ma), !(names(a$publish) %in% c(between, "narWeight", "primary")), drop = FALSE])
          names(prikkData)[names(prikkData) == "suppressed"] <- "prikk"
          prikkData$prikk <- as.integer(prikkData$prikk)
          rownames(prikkData) <- NULL
          return(prikkData)
        } else {
          prikkData <- GaussSuppressionFromData(data, dimVar = between , freqVar = freqVar, 
                                                charVar = c(sector, "FRTK_VIRK_UNIK"), 
                                                weightVar = "narWeight", protectZeros = protectZeros, maxN = -1, 
                                                secondaryZeros = secondaryZeros,
                                                primary = Primary_FRTK_VIRK_UNIK_sektor_here, 
                                                singleton = NULL, singletonMethod = "none", preAggregate = preAggregate,
                                                sector = sector, private = private, 
                                                output = argOutput, 
                                                iWait = iWait)
          if(argOutput != "publish"){
            return(prikkData)
          }
        }
        
        if(output == "suppressed"){
          prikkData$prikk <- as.integer(prikkData$suppressed)
          return(prikkData)
        }
        
        # Lager prikkede kombinasjoner
        supData <- GaussSuppressed(prikkData, between )
      } else {
        notInDataDec <- between[!(between %in% names(dataDec))]
        if(length(notInDataDec)){
          stop(paste("Mangler i decimal: ",paste(notInDataDec, collapse = ", ")))
        }
        
        if(length(freqVar)){
          uniqueBetween <-  RowGroups(data[data[[freqVar]]>0, between, drop=FALSE], TRUE)$groups 
        } else {
          uniqueBetween <-  RowGroups(data[between], TRUE)$groups 
        }
        ma<- Match(uniqueBetween, dataDec[between])
        if(anyNA(ma)){
          print(uniqueBetween[head(which(is.na(ma))), ,drop=FALSE])
          stop("Finner ikke matchende rader i decimal")
        }
        freqDecNames <- WildcardGlobbingVector(names(dataDec), freqDec)
        if(!length(freqDecNames)){
          stop("Ingen freqDec-variabelnavn funnet")
        }
        prikkData <- SuppressionFromDecimals(dataDec, dimVar = between , freqVar = freqVar, #freqVar = "freq", 
                                              decVar = freqDecNames, preAggregate = preAggregate, digits = digitsB)
        if(output == "suppressed"){
          prikkData$prikk <- as.integer(prikkData$suppressed)
          return(prikkData)
        }
        
        # Lager prikkede kombinasjoner
        supData <- GaussSuppressed(prikkData, between )
      }
    }  
  } # if(length(between )>0){
  
  if(output == "suppressed") return(prikkData)
  
  
  if(!is.null(maxN)){
    
    # Når nace00primary = FALSE kan noen enere være ikke-primærprikket
    singletonMethod = ifelse(secondaryZeros | !nace00primary, "anySumNOTprimary", "anySum")
    
    if(decimal){
      if(length(between )>0){
        a <- GaussSuppressDec(data, dimVar = alleVar, freqVar = freqVar, 
                                              charVar = c(sector, "FRTK_VIRK_UNIK"), 
                                              weightVar = "narWeight", protectZeros = protectZeros, maxN = maxN,
                                              secondaryZeros = secondaryZeros,
                                              primary = Primary_FRTK_VIRK_UNIK_sektor_here, # singleton = NULL, singletonMethod = "none", 
                                              preAggregate = preAggregate,
                                              sector = sector, private = private, between = between,
                                              nRep = nRep, digits = digitsA,  mismatchWarning = digitsB, 
                                              singletonMethod = singletonMethod, output = "publish_inner",
                                              allowTotal = allowTotal, 
                                              iWait = iWait)
      } else {
        a <- GaussSuppressDec(data, dimVar = alleVar, freqVar = freqVar, 
                                              protectZeros = protectZeros, maxN = maxN, 
                                              secondaryZeros = secondaryZeros,
                                              preAggregate = preAggregate,
                                              nRep = nRep, digits = digitsA,  mismatchWarning = digitsB,
                                              singletonMethod = singletonMethod, output = "publish_inner", 
                                              iWait = iWait)
      }
      
      between <- alleVar # endrer siden delvis gjenbruk av kode 
      
      dimVarOut <- between[between %in% names(a$publish)]
      ma <- Match(a$publish[dimVarOut], a$inner[dimVarOut])
      prikkData <- cbind(a$inner[ma[!is.na(ma)], between, drop = FALSE], 
                         a$publish[!is.na(ma), !(names(a$publish) %in% c(between, "narWeight", "primary")), drop = FALSE])
      names(prikkData)[names(prikkData) == "suppressed"] <- "prikk"
      prikkData$prikk <- as.integer(prikkData$prikk)
      rownames(prikkData) <- NULL
      return(prikkData)
      

    }  
    if(is.null(dataDec)){
      if(length(between )>0){
        prikkData <- GaussSuppressionFromData(data, dimVar = alleVar, freqVar = freqVar, 
                                              charVar = c(sector, "FRTK_VIRK_UNIK"), 
                                              weightVar = "narWeight", protectZeros = protectZeros, maxN = maxN,
                                              secondaryZeros = secondaryZeros,
                                              primary = Primary_FRTK_VIRK_UNIK_sektor_here, # singleton = NULL, singletonMethod = "none", 
                                              preAggregate = preAggregate,
                                              sector = sector, private = private, between = between,
                                              singletonMethod = singletonMethod,
                                              allowTotal = allowTotal, 
                                              iWait = iWait)
      } else {
        prikkData <- GaussSuppressionFromData(data, dimVar = alleVar, freqVar = freqVar, 
                                              protectZeros = protectZeros, maxN = maxN, 
                                              secondaryZeros = secondaryZeros,
                                              preAggregate = preAggregate,
                                              singletonMethod = singletonMethod,
                                              iWait = iWait)
      }
    } else {
      
      between <- alleVar # endrer siden delvis gjenbruk av kode 
      
      notInDataDec <- between[!(between %in% names(dataDec))]
      if(length(notInDataDec)){
        stop(paste("Mangler i decimal: ",paste(notInDataDec, collapse = ", ")))
      }
      
      if(length(freqVar)){
        uniqueBetween <-  RowGroups(data[data[[freqVar]]>0, between, drop=FALSE], TRUE)$groups 
      } else {
        uniqueBetween <-  RowGroups(data[between], TRUE)$groups 
      }
      ma<- Match(uniqueBetween, dataDec[between])
      if(anyNA(ma)){
        print(uniqueBetween[head(which(is.na(ma))), ,drop=FALSE])
        stop("Finner ikke matchende rader i decimal")
      }
      freqDecNames <- WildcardGlobbingVector(names(dataDec), freqDec)
      if(!length(freqDecNames)){
        stop("Ingen freqDec-variabelnavn funnet")
      }
      prikkData <- SuppressionFromDecimals(dataDec, dimVar = between, freqVar = freqVar, # freqVar = "freq", 
                                           decVar = freqDecNames, preAggregate = preAggregate, digits = digitsB)
      prikkData <- prikkData[!(names(prikkData) %in% c(freqDecNames, "primary"))] 
      
    }

    ############################################
    # Endring foreløpig output til å være lik tidligere ArbForhold/Lonnstaker 
    ############################################
    # Endrer fra TRUE/FALSE til 0/1
    
    if(!is.null(prikkData$primary))
      prikkData$primary <- as.integer(prikkData$primary)
    prikkData$suppressed <- as.integer(prikkData$suppressed)
    # Tar bort weight og inn med prikket på samme plass
    names(prikkData)[names(prikkData) == "narWeight"] <- "prikket"
    prikkData$prikket <- prikkData[[freqVar]]  # prikkData$freq
    prikkData$prikket[prikkData$suppressed==1] <- NA
    
    
    rownames(prikkData) <- NULL
    
    return(prikkData)
  }
  
  cat("[aggregate for PLSroundingSuppressed ", dim(data)[1], "*", dim(data)[2], "->", sep = "")
  flush.console()
  
  aggData <- aggregate(data[, freqVar, drop = FALSE], data[, alleVar], sum)
  
  cat(dim(aggData)[1], "*", dim(aggData)[2], "]\n", sep = "")
  flush.console()
  
  
  prsData <- PLSroundingSuppressed(aggData, freqVar, dataSuppressed = supData, roundBase = roundBase, allowTotal = allowTotal)
  
  prsData <- prsData[, !(names(prsData) %in% "nCells")]
  
  if (allowTotal & til0) {
    if (!is.null(supData)) {
      ma <- which(!is.na(Match(prsData[, names(supData), drop = FALSE], supData)))
      ma1 <- ma[!is.na(prsData$roundedSuppressed[ma])]
      ma1 <- ma1[prsData$roundedSuppressed[ma1] == 0L]
      ma2 <- !is.na(Match(prsData[ma, names(supData), drop = FALSE], prsData[ma1, names(supData), drop = FALSE]))
      prsData$roundedSuppressed[ma[ma2]] <- 0L
    }
  }
  
  if(output == "rounded")
    return(prsData)
  
  list( rounded = prsData, suppressed = prikkData)
}
  