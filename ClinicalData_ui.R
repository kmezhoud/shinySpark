output$ClinicalDataTable <- DT::renderDataTable({
  
  ##  needed to make silence the error
  if (inherits(try( dat <- r_info$ClinicalData[input$Clinical_varsID], silent=TRUE),"try-error")){
    dat <- r_info$ClinicalData
  }else{
    dat <- r_info$ClinicalData[input$Clinical_varsID]
  }
  displayTable(dat)
})

##  Reactive checkBox to save GenProfData table to spark local server
output$PushClinicalData <- renderText({ 
  if(input$clinicalDataButtID && !is.null(r_info$sc)){
    ClinicalData_tbl <- dplyr::copy_to(r_info$sc, r_info$ClinicalData, name= "ClinicalData_tbl", overwrite = TRUE)
      #  input$CasesID
    r_info[['ClinicalData_tbl']] <- ClinicalData_tbl
  }
  ## print value of checkBox
  input$clinicalDataButtID
})



output$ui_Clinical_vars <- renderUI({
  shiny::withProgress(message = 'loading Clinical Data from cgdsr server...', value = 1, {
    ##### get Clinical Data for selected Case
    dat <- cgdsr::getClinicalData(cgds, input$CasesID)
    ## change rownames in the first column
    #dat <- dat %>% dplyr::add_rownames("Patients")
    dat <- dat %>% tibble::rownames_to_column("Patients")
    r_info[['ClinicalData']] <- dat
    
    Clinical_vars <- names(dat)
    #r_data[['Clinical_vars']] <- Clinical_vars
    
    selectInput("Clinical_varsID", "Select variables to show:", choices  = Clinical_vars,
                multiple = TRUE, selected = Clinical_vars,
                selectize = FALSE, size = min(8, length(Clinical_vars)))
  })
})


output$ui_ClinicalData <- renderUI({
  
  list(
    wellPanel(
      uiOutput("ui_Clinical_vars"),
      checkboxInput('clinicalDataButtID', label = "Push Clinical Data to spark"),
      verbatimTextOutput("PushClinicalData"),
      checkboxInput("SurvPlotID", "Survival plot model", value = FALSE)
    )
    
  )
  #    )
  
})


output$suvivalPlot <- renderPlot({
  
  #clinicalData <- read.csv("Clinical_tab.csv", na.strings=c("","NA"))
  
  clinicalData <- as.data.frame(r_info$ClinicalData)
  ## transform empty to NA for  all columns
  #clinicalData %>% mutate_each(funs(empty_as_na))
  clinicalData <- mutate_all(clinicalData,funs(empty_as_na))
  
  
  if(length(grep("^OS_STATUS$", names(clinicalData), ignore.case = TRUE))  == 1   &&   
     length(grep("^OS_MONTHS$", names(clinicalData), ignore.case = TRUE))  == 1   &&
     length(grep("^DFS_STATUS$", names(clinicalData), ignore.case = TRUE)) == 1
  ){
    
    
    clinicalData$OS_STATUS <- gsub("LIVING", "0", clinicalData$OS_STATUS, ignore.case = TRUE)
    clinicalData$OS_STATUS <- gsub("DECEASED", "1", clinicalData$OS_STATUS, ignore.case = TRUE)
    clinicalData$OS_STATUS <- as.numeric(clinicalData$OS_STATUS)
    
    fit <- survival::survfit(Surv(OS_MONTHS, OS_STATUS) ~ DFS_STATUS, data = clinicalData)
    
    survminer::ggsurvplot(fit, data = clinicalData,
                          type = "kaplan-meier",
                          #conf.type="log",
                          conf.int = TRUE,
                          pval = TRUE,
                          fun = "pct",
                          risk.table = TRUE,
                          size = 1,
                          linetype = "strata",
                          palette = c("#E7B800", "#2E9FDF"),
                          legend = "top",
                          lengend.title = "DFS_STATUS",
                          legend.labs = c("DiseaseFree", "Recurred")
    )
    
  }else{
    msgNoData <- "There is no \n OS_STATUT or OS_MONTHS or DFS_STATUS data"
    stop(msgNoData)
    #break(msgNoData)
  }
  
  
})


output$clinicalDataPlot <- renderPlot({
  start_time <- Sys.time()
   #clinicalData <- read.csv("ClinicalData.csv")
  r_info$ClinicalData %>% 
    mutate(OS_STATUS = gsub("LIVING", "0", OS_STATUS)) %>%
    mutate(OS_STATUS = gsub( "DECEASED", "1", OS_STATUS)) %>%
    mutate(DFS_STATUS = gsub( "^$|^ $", "DiseaseFree", DFS_STATUS)) %>%
    mutate(OS_STATUS = as.numeric(OS_STATUS)) %>%
    arrange(OS_MONTHS) %>%
    mutate( DiseaseFree = ifelse(DFS_STATUS == "DiseaseFree", 1, 0)) %>% 
    as.data.frame() %>%
    mutate(n_DiseaseFree = cumsum(DiseaseFree == 1)) %>%
    mutate(n_Recurred = cumsum(DiseaseFree == 0)) %>%
   ggplot(aes(x = OS_MONTHS, y = value, color = variable)) +
    geom_point(aes(y = n_DiseaseFree, col = "n_DiseaseFree")) +
    geom_point(aes(y = n_Recurred, col = "n_Recurred")) +
    labs(title = paste("Using R Session, Running time = ", Sys.time() - start_time))
  
})


spark_clinicalData_trans <- reactive({
  
  #clinicalData_tbl <- dplyr::copy_to(r_info$sc, r_info$ClinicalData, overwrite = TRUE)
  r_info[['start_time_spark']] <- Sys.time()
  
  ## works also
  #ClinicalData_tbl <- spark_read_table(r_info$sc, 'ClinicalData_tbl')
  
  r_info$ClinicalData_tbl %>%
    mutate(OS_STATUS = regexp_replace(OS_STATUS, "LIVING", "0")) %>%
    mutate(OS_STATUS = regexp_replace(OS_STATUS, "DECEASED", "1")) %>%
    mutate(DFS_STATUS = regexp_replace(DFS_STATUS, "^$|^ $", "DiseaseFree")) %>%
    filter(!is.na(OS_STATUS)) %>%
    mutate(OS_STATUS = as.numeric(OS_STATUS)) %>%
    arrange(is.na(OS_MONTHS), OS_MONTHS) %>%  ## OUFFF put Nan at the end of the column
    mutate(DiseaseFree = ifelse(DFS_STATUS == "DiseaseFree", 1, 0)) %>% 
    as.data.frame() %>%
    mutate( n_DiseaseFree = cumsum(as.numeric(DiseaseFree == 1 ))) %>%
    mutate( n_Recurred = cumsum(as.numeric(DiseaseFree == 0 ))) %>%
    collect()
  
})

output$clinicalDataPlot_spark <- renderPlot({
  ggplot(spark_clinicalData_trans(), 
         aes(x = OS_MONTHS, y = value, color = variable)) +
    geom_point(aes(y = n_DiseaseFree, col = "n_DiseaseFree")) +
    geom_point(aes(y = n_Recurred, col = "n_Recurred"))  +
    labs(title = paste("Running Time = ", Sys.time() - r_info$start_time_spark, " s"))
})

