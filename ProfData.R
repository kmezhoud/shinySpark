output$ProfDataTable <- DT::renderDataTable({

  GeneList <- t(as.data.frame(c("CHEK1", "CHEK2", "RAD51", "BRCA1", "BRCA2", "MLH1", "MSH2","ATM", "ATR", "MDC1", "PARP1", "FANCF")))

  if (ncol(GeneList)==0){
    dat <- as.data.frame("Gene List is empty. copy and paste genes from text file (Gene/line) or use gene list from examples.")
  }else{
       if (inherits(try( dat <- cgdsr::getProfileData(cgds,GeneList, input$GenProfID,input$CasesID),
                             silent=FALSE),"try-error")){
      dat <- as.data.frame("There are some Gene Symbols not supported by cbioportal.
                           Or gene list is empty.
                           Or bioCancer is not connected to cgdsr server (check connection).")
    }else{
      shiny::withProgress(message = 'loading ProfData from cgdsr server...', value = 1, {

      dat <- cgdsr::getProfileData(cgds,GeneList, input$GenProfID,input$CasesID)

      })
      if(dim(dat)[1]==0){
        ## avoide error when GeneList is empty
        ## Error..No.cancer.study..cancer_study_id...or.genetic.profile..genetic_profile_id..or.case.list.or..case_list..case.set..case_set_id..provid
        dat <- as.data.frame("Gene List is empty. copy and paste genes from text file (Gene/line) or use gene list from examples.")
      }else{
        #dat <- cgdsr::getProfileData(cgds,GeneList, input$GenProfID,input$CasesID)
        ## remove empty row
        dat <-  dat[which(apply(!(apply(dat,1,is.na) ),2,sum)!=0 ),]

        if(is.numeric(dat[2,2])){
          dat <- round(dat, digits = 3)
        }
        dat <- dat %>% tibble::rownames_to_column("Patients")
        r_info[['ProfData']] <- dat
      }
    }

    displayTable(dat)%>% DT::formatStyle(names(dat),
                        color = DT::styleEqual("Gene List is empty. copy and paste genes from text file (Gene/line) or use gene list from examples.",
                                                                'red'))#, backgroundColor = 'white', fontWeight = 'bold'

  }

  })


