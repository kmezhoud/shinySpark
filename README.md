
## try to run  `ml_linear_regression` function from spark and visualize plot by shiny

+ not working into shiny!

### reactive transformation function
```r
  spark_clinical_trans_for_regression <- reactive({
    print("0")
    # clinicalData <- read.csv("ClinicalData.csv") #, na.strings=c("","NA")
    # 
    # clinicalData <- clinicalData[c('OS_MONTHS',  'OS_STATUS', 'DFS_STATUS' )]
    # 
    # sc <- spark_connect(master = "local",
    #                      version = "2.4.0")
    # clinicalData_tbl <- dplyr::copy_to(sc, clinicalData, overwrite = TRUE)
    
    ClinicalData_tbl <- spark_read_table(sc, 'ClinicalData_tbl')
    
    #start_time_surv_reg <- Sys.time()
    clinicalData_trans_tbl <- ClinicalData_tbl %>%
      mutate(OS_STATUS = regexp_replace(OS_STATUS, "LIVING", 1)) %>%
      mutate(OS_STATUS = regexp_replace(OS_STATUS, "DECEASED", 0)) %>%
      mutate(DFS_STATUS = regexp_replace(DFS_STATUS, "^$|^ $", "DiseaseFree")) %>%
      mutate(DFS_STATUS = regexp_replace(DFS_STATUS, "DiseaseFree", 1)) %>%
      mutate(DFS_STATUS = regexp_replace(DFS_STATUS, "Recurred", 2)) %>%
      # mutate(xr = ifelse(TREATMENT_STATUS == "Untreated", 1 , 2)) %>%
      # mutate(xr = ifelse(TREATMENT_STATUS == "Treated", 2, 1)) %>%
      mutate(OS_STATUS = as.numeric(OS_STATUS)) %>%
      mutate(DFS_STATUS = as.numeric(DFS_STATUS)) %>%
      #arrange(is.na(OS_MONTHS), OS_MONTHS) %>% ## OUFFF put Nan at the end of the column
      filter(!is.na(OS_STATUS)) ## rm all NA in OS_STATUS column
    
    partitions_clinicalData <- clinicalData_trans_tbl %>%
      sdf_partition(training = 0.9, test = 0.1, seed = 1111)
    
    clinicalData_training <- partitions_clinicalData$training
    clinicalData_test <- partitions_clinicalData$test
    
    sur_reg_clinicalData <- clinicalData_training %>%
      ml_aft_survival_regression(OS_MONTHS ~ DFS_STATUS + OS_STATUS, censor_col = "OS_STATUS") 
    
    intercept_clinicalData <- sur_reg_clinicalData$coefficients[1]
    coefficients_clinicalData <- sur_reg_clinicalData$coefficients[c(2,3)]
    
    plotParams_clinicalData <- clinicalData_trans_tbl %>%
      select(c('DFS_STATUS', 'OS_STATUS'))
    
    scale_clinicalData <- as_tibble(exp(intercept_clinicalData + as_tibble(plotParams_clinicalData) * coefficients_clinicalData))
    
    tSeq_clinicalData <-  clinicalData_trans_tbl %>% select('OS_MONTHS')
    probs_clinicalData <- data.frame(t = tSeq_clinicalData)
    print("1")
    
    for (i in 1:8) { 
      probs_clinicalData[, paste("(DFS_STATUS, OS_STATUS) = (", toString(as_tibble(plotParams_clinicalData)[i, ]), ")", sep = "")] <- 
        pweibull(pull(tSeq_clinicalData), shape = 1, scale = pull(scale_clinicalData)[i], lower.tail = F)
    }
       print("2")
    melted_clinicalData <- melt(probs_clinicalData, id.vars="OS_MONTHS", variable.name="group", value.name="prob") %>%
      collect()
    
    
  })
  
  ```
  
  
  ### call reactive trasnformation and plot the result
  ```r
  output$survival_regression_plot <- renderPlot({
    
    start_time_surv_reg <- Sys.time()
    spark_clinical_trans_for_regression() %>%
    ggplot( aes(x= OS_MONTHS, y= prob, group= group, color= group)) + 
      geom_point() +
      #geom_smooth() +
      #geom_jitter() +
      labs(title = "plot the spark ml_aft_survival_regression modeling",
           x = "time", y = "Survival probability") +
      # annotation_custom(grob = textGrob("Read all about it"),  
      #       xmin = 120, xmax = 120, ymin = 0.3, ymax = 0.3) +
      theme(legend.position = c(0.8, 0.85),  legend.background = element_rect(color = "grey90", fill = "grey90")) +
      geom_text(aes(label = '1: DeseaseFree / Living', x = 95, y = 0.7), color="grey60", size=3.5) +
      geom_text(aes(label = '2: Recurred, 0: Diceased', x = 95, y = 0.65), color="grey60", size=3.5)+
       geom_text(aes(label = paste('running time: ', round(Sys.time() - start_time_surv_reg, digits = 2), 's'), x = 95, y = 0.6), color="#a0a0a0", size=3.5)
    
  })
  ```